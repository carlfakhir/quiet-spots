import { Hono, type Context, type Next } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { sign, verify } from 'hono/jwt'
import { dashboardHtml } from './dashboard'

type Bindings = {
  DB: D1Database
  JWT_SECRET: string
}
type Variables = { userId: number; username: string }
type Env = { Bindings: Bindings; Variables: Variables }

const VOTES = ['quiet', 'ok', 'busy'] as const
const TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30
const PBKDF2_ITERATIONS = 100_000 // Workers caps PBKDF2 at 100k iterations
const RECENT_WINDOW = '-2 hours' // reports older than this don't count toward a spot's current level

const app = new Hono<Env>()
app.use('*', logger())
app.use('*', cors())

// ---------- helpers ----------

const toHex = (buf: ArrayBuffer | Uint8Array) =>
  [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('')

async function hashPassword(password: string, saltHex: string): Promise<string> {
  const salt = new Uint8Array(saltHex.match(/../g)!.map((h) => parseInt(h, 16)))
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, [
    'deriveBits',
  ])
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt, iterations: PBKDF2_ITERATIONS },
    key,
    256,
  )
  return toHex(bits)
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false
  let diff = 0
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i)
  return diff === 0
}

async function issueToken(c: Context<Env>, id: number, username: string) {
  const now = Math.floor(Date.now() / 1000)
  return sign({ sub: id, username, iat: now, exp: now + TOKEN_TTL_SECONDS }, c.env.JWT_SECRET, 'HS256')
}

async function userFromHeader(c: Context<Env>): Promise<{ id: number; username: string } | null> {
  const header = c.req.header('Authorization') ?? ''
  if (!header.startsWith('Bearer ')) return null
  try {
    const payload = await verify(header.slice(7), c.env.JWT_SECRET, 'HS256')
    return { id: Number(payload.sub), username: String(payload.username) }
  } catch {
    return null
  }
}

async function requireAuth(c: Context<Env>, next: Next) {
  const user = await userFromHeader(c)
  if (!user) return c.json({ error: 'Sign in required' }, 401)
  c.set('userId', user.id)
  c.set('username', user.username)
  await next()
}

// WMO weather codes used by Open-Meteo: https://open-meteo.com/en/docs
function describeWeather(code: number): string {
  if (code === 0) return 'Clear'
  if (code <= 3) return 'Partly cloudy'
  if (code <= 48) return 'Fog'
  if (code <= 57) return 'Drizzle'
  if (code <= 67) return 'Rain'
  if (code <= 77) return 'Snow'
  if (code <= 82) return 'Rain showers'
  if (code <= 86) return 'Snow showers'
  return 'Thunderstorm'
}

async function fetchWeather(lat: number, lon: number): Promise<{ temp_c: number; weather_desc: string } | null> {
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code`
  try {
    const res = await fetch(url, { cf: { cacheTtl: 600 } })
    if (!res.ok) return null
    const data = (await res.json()) as { current?: { temperature_2m: number; weather_code: number } }
    if (!data.current) return null
    return { temp_c: data.current.temperature_2m, weather_desc: describeWeather(data.current.weather_code) }
  } catch {
    return null // weather is a nice-to-have; never fail a request because of it
  }
}

function distanceMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6_371_000
  const toRad = (d: number) => (d * Math.PI) / 180
  const dLat = toRad(lat2 - lat1)
  const dLon = toRad(lon2 - lon1)
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2
  return 2 * R * Math.asin(Math.sqrt(a))
}

function noiseLevel(db: number | null): 'quiet' | 'moderate' | 'loud' | 'unknown' {
  if (db === null) return 'unknown'
  if (db < 45) return 'quiet'
  if (db < 60) return 'moderate'
  return 'loud'
}

const isFiniteNumber = (v: unknown): v is number => typeof v === 'number' && Number.isFinite(v)

type SpotRow = {
  id: number
  name: string
  building: string
  area: string
  category: string
  lat: number
  lon: number
  description: string
  avg_db: number | null
  last_db: number | null
  last_report_at: string | null
  recent_reports: number
  quiet_votes: number
  busy_votes: number
}

// Spot plus aggregate noise stats over the recent window.
const SPOT_SELECT = `
  SELECT s.*,
         ROUND(AVG(CASE WHEN r.created_at >= datetime('now', '${RECENT_WINDOW}') THEN r.db END), 1) AS avg_db,
         (SELECT db FROM reports WHERE spot_id = s.id ORDER BY created_at DESC, id DESC LIMIT 1) AS last_db,
         MAX(r.created_at) AS last_report_at,
         COUNT(CASE WHEN r.created_at >= datetime('now', '${RECENT_WINDOW}') THEN 1 END) AS recent_reports,
         COUNT(CASE WHEN r.created_at >= datetime('now', '${RECENT_WINDOW}') AND r.vote = 'quiet' THEN 1 END) AS quiet_votes,
         COUNT(CASE WHEN r.created_at >= datetime('now', '${RECENT_WINDOW}') AND r.vote = 'busy' THEN 1 END) AS busy_votes
    FROM spots s LEFT JOIN reports r ON r.spot_id = s.id`

const withLevel = (s: SpotRow) => ({ ...s, level: noiseLevel(s.avg_db) })

// ---------- routes ----------

app.get('/', (c) => c.html(dashboardHtml))

app.get('/api', (c) =>
  c.json({
    name: 'Quiet Spots API',
    endpoints: [
      'GET    /health',
      'POST   /auth/register {username, password}',
      'POST   /auth/login    {username, password}',
      'GET    /me                          (auth)',
      'GET    /spots',
      'GET    /spots/:id',
      'POST   /spots/:id/reports {db, vote?, note?, lat?, lon?} (auth)',
      'DELETE /reports/:id                 (auth, owner only)',
      'GET    /weather?lat=&lon=',
      'POST   /events {name, props?, platform?} (auth optional)',
      'GET    /stats',
    ],
  }),
)

app.get('/health', (c) => c.json({ ok: true, time: new Date().toISOString() }))

app.post('/auth/register', async (c) => {
  const body = await c.req.json<{ username?: string; password?: string }>().catch(() => ({}) as any)
  const username = body.username?.trim() ?? ''
  const password = body.password ?? ''
  if (!/^[a-zA-Z0-9_]{3,24}$/.test(username))
    return c.json({ error: 'Username must be 3-24 letters, numbers, or underscores' }, 400)
  if (password.length < 8) return c.json({ error: 'Password must be at least 8 characters' }, 400)

  const salt = toHex(crypto.getRandomValues(new Uint8Array(16)))
  const hash = await hashPassword(password, salt)
  try {
    const row = await c.env.DB.prepare('INSERT INTO users (username, password_hash, salt) VALUES (?, ?, ?) RETURNING id')
      .bind(username, hash, salt)
      .first<{ id: number }>()
    return c.json({ token: await issueToken(c, row!.id, username), user: { id: row!.id, username } }, 201)
  } catch (e) {
    if (String(e).includes('UNIQUE')) return c.json({ error: 'That username is taken' }, 409)
    throw e
  }
})

app.post('/auth/login', async (c) => {
  const body = await c.req.json<{ username?: string; password?: string }>().catch(() => ({}) as any)
  const user = await c.env.DB.prepare('SELECT id, username, password_hash, salt FROM users WHERE username = ?')
    .bind(body.username?.trim() ?? '')
    .first<{ id: number; username: string; password_hash: string; salt: string }>()
  if (!user || !timingSafeEqual(await hashPassword(body.password ?? '', user.salt), user.password_hash))
    return c.json({ error: 'Wrong username or password' }, 401)
  return c.json({ token: await issueToken(c, user.id, user.username), user: { id: user.id, username: user.username } })
})

app.get('/me', requireAuth, async (c) => {
  const userId = c.get('userId')
  const [count, recent] = await c.env.DB.batch([
    c.env.DB.prepare('SELECT COUNT(*) AS n, COUNT(DISTINCT spot_id) AS spots FROM reports WHERE user_id = ?').bind(userId),
    c.env.DB.prepare(
      `SELECT r.id, r.spot_id, s.name AS spot_name, r.db, r.vote, r.note, r.created_at
         FROM reports r JOIN spots s ON s.id = r.spot_id
        WHERE r.user_id = ? ORDER BY r.created_at DESC, r.id DESC LIMIT 20`,
    ).bind(userId),
  ])
  const totals = count.results[0] as { n: number; spots: number }
  return c.json({
    id: userId,
    username: c.get('username'),
    reports: totals.n,
    spots_measured: totals.spots,
    recent: recent.results,
  })
})

app.get('/spots', async (c) => {
  const { results } = await c.env.DB.prepare(`${SPOT_SELECT} GROUP BY s.id ORDER BY s.id`).all<SpotRow>()
  return c.json(results.map(withLevel))
})

app.get('/spots/:id', async (c) => {
  const id = Number(c.req.param('id'))
  const spot = await c.env.DB.prepare(`${SPOT_SELECT} WHERE s.id = ? GROUP BY s.id`).bind(id).first<SpotRow>()
  if (!spot) return c.json({ error: 'Spot not found' }, 404)

  const viewer = await userFromHeader(c)
  const [{ results: reports }, weather] = await Promise.all([
    c.env.DB.prepare(
      `SELECT r.id, r.db, r.vote, r.note, r.distance_m, r.temp_c, r.weather_desc, r.created_at,
              u.username, (r.user_id = ?) AS mine
         FROM reports r JOIN users u ON u.id = r.user_id
        WHERE r.spot_id = ? ORDER BY r.created_at DESC, r.id DESC LIMIT 25`,
    )
      .bind(viewer?.id ?? -1, id)
      .all(),
    fetchWeather(spot.lat, spot.lon),
  ])
  return c.json({
    ...withLevel(spot),
    weather,
    reports: reports.map((r) => ({ ...r, mine: Boolean(r.mine) })),
  })
})

app.post('/spots/:id/reports', requireAuth, async (c) => {
  const spotId = Number(c.req.param('id'))
  const spot = await c.env.DB.prepare('SELECT id, lat, lon FROM spots WHERE id = ?')
    .bind(spotId)
    .first<{ id: number; lat: number; lon: number }>()
  if (!spot) return c.json({ error: 'Spot not found' }, 404)

  const body = await c.req.json<Record<string, unknown>>().catch(() => ({}) as Record<string, unknown>)
  if (!isFiniteNumber(body.db) || body.db < 0 || body.db > 130)
    return c.json({ error: 'db must be a number between 0 and 130' }, 400)
  const vote = body.vote ?? null
  if (vote !== null && !VOTES.includes(vote as (typeof VOTES)[number]))
    return c.json({ error: `vote must be one of: ${VOTES.join(', ')}` }, 400)
  const note = typeof body.note === 'string' && body.note.trim() ? body.note.trim().slice(0, 140) : null

  const hasLocation = isFiniteNumber(body.lat) && isFiniteNumber(body.lon)
  const lat = hasLocation ? (body.lat as number) : null
  const lon = hasLocation ? (body.lon as number) : null
  const distance = hasLocation ? Math.round(distanceMeters(lat!, lon!, spot.lat, spot.lon)) : null
  const weather = await fetchWeather(spot.lat, spot.lon)

  const row = await c.env.DB.prepare(
    `INSERT INTO reports (spot_id, user_id, db, vote, note, lat, lon, distance_m, temp_c, weather_desc)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     RETURNING id, db, vote, note, distance_m, temp_c, weather_desc, created_at`,
  )
    .bind(
      spotId,
      c.get('userId'),
      Math.round(body.db * 10) / 10,
      vote,
      note,
      lat,
      lon,
      distance,
      weather?.temp_c ?? null,
      weather?.weather_desc ?? null,
    )
    .first()
  return c.json({ ...row, username: c.get('username'), mine: true }, 201)
})

app.delete('/reports/:id', requireAuth, async (c) => {
  const result = await c.env.DB.prepare('DELETE FROM reports WHERE id = ? AND user_id = ?')
    .bind(Number(c.req.param('id')), c.get('userId'))
    .run()
  if (result.meta.changes === 0) return c.json({ error: 'Report not found or not yours' }, 404)
  return c.body(null, 204)
})

app.get('/weather', async (c) => {
  const lat = Number(c.req.query('lat'))
  const lon = Number(c.req.query('lon'))
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) return c.json({ error: 'lat and lon are required' }, 400)
  const weather = await fetchWeather(lat, lon)
  return weather ? c.json(weather) : c.json({ error: 'Weather unavailable' }, 502)
})

app.post('/events', async (c) => {
  const body = await c.req.json<{ name?: string; props?: unknown; platform?: string }>().catch(() => ({}) as any)
  if (!body.name || typeof body.name !== 'string' || body.name.length > 64)
    return c.json({ error: 'Event name is required (max 64 chars)' }, 400)
  // Auth is optional so events from before sign-in (like app_open) are still recorded.
  const user = await userFromHeader(c)
  await c.env.DB.prepare('INSERT INTO events (user_id, name, props, platform) VALUES (?, ?, ?, ?)')
    .bind(user?.id ?? null, body.name, body.props ? JSON.stringify(body.props).slice(0, 2000) : null, body.platform ?? null)
    .run()
  return c.json({ ok: true }, 201)
})

app.get('/stats', async (c) => {
  const [users, reports, bySpot, events, platforms, activeToday] = await c.env.DB.batch([
    c.env.DB.prepare('SELECT COUNT(*) AS n FROM users'),
    c.env.DB.prepare('SELECT COUNT(*) AS n FROM reports'),
    c.env.DB.prepare(
      `SELECT s.name, COUNT(r.id) AS reports, ROUND(AVG(r.db), 1) AS avg_db
         FROM spots s LEFT JOIN reports r ON r.spot_id = s.id
        GROUP BY s.id ORDER BY reports DESC`,
    ),
    c.env.DB.prepare('SELECT name, COUNT(*) AS n FROM events GROUP BY name ORDER BY n DESC LIMIT 25'),
    c.env.DB.prepare('SELECT COALESCE(platform, \'unknown\') AS platform, COUNT(*) AS n FROM events GROUP BY platform'),
    c.env.DB.prepare("SELECT COUNT(DISTINCT user_id) AS n FROM events WHERE created_at >= datetime('now', '-1 day')"),
  ])
  return c.json({
    users: (users.results[0] as { n: number }).n,
    reports: (reports.results[0] as { n: number }).n,
    active_users_24h: (activeToday.results[0] as { n: number }).n,
    reports_by_spot: bySpot.results,
    events: events.results,
    platforms: platforms.results,
  })
})

app.notFound((c) => c.json({ error: 'Not found' }, 404))

app.onError((err, c) => {
  console.error(err)
  return c.json({ error: 'Internal server error' }, 500)
})

export default app
