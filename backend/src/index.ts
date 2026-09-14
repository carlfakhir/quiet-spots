import { Hono, type Context, type Next } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { sign, verify } from 'hono/jwt'

type Bindings = {
  DB: D1Database
  JWT_SECRET: string
}
type Variables = { userId: number; username: string }
type Env = { Bindings: Bindings; Variables: Variables }

const MOODS = ['great', 'good', 'meh', 'bad'] as const
const TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30
const PBKDF2_ITERATIONS = 100_000 // Workers caps PBKDF2 at 100k iterations

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

async function requireAuth(c: Context<Env>, next: Next) {
  const header = c.req.header('Authorization') ?? ''
  const token = header.startsWith('Bearer ') ? header.slice(7) : null
  if (!token) return c.json({ error: 'Missing bearer token' }, 401)
  try {
    const payload = await verify(token, c.env.JWT_SECRET, 'HS256')
    c.set('userId', Number(payload.sub))
    c.set('username', String(payload.username))
  } catch {
    return c.json({ error: 'Invalid or expired token' }, 401)
  }
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
    const res = await fetch(url)
    if (!res.ok) return null
    const data = (await res.json()) as { current?: { temperature_2m: number; weather_code: number } }
    if (!data.current) return null
    return { temp_c: data.current.temperature_2m, weather_desc: describeWeather(data.current.weather_code) }
  } catch {
    return null // weather is a nice-to-have; never fail a check-in because of it
  }
}

const isFiniteNumber = (v: unknown): v is number => typeof v === 'number' && Number.isFinite(v)

// ---------- routes ----------

app.get('/', (c) =>
  c.json({
    name: 'CheckIn API',
    endpoints: [
      'GET  /health',
      'POST /auth/register {username, password}',
      'POST /auth/login    {username, password}',
      'GET  /me                       (auth)',
      'GET  /checkins?limit=50        (auth)',
      'POST /checkins {note, mood, lat?, lon?, steps?} (auth)',
      'DELETE /checkins/:id           (auth, owner only)',
      'GET  /weather?lat=&lon=',
      'POST /events {name, props?, platform?} (auth optional)',
      'GET  /stats',
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
    if (String(e).includes('UNIQUE')) return c.json({ error: 'Username already taken' }, 409)
    throw e
  }
})

app.post('/auth/login', async (c) => {
  const body = await c.req.json<{ username?: string; password?: string }>().catch(() => ({}) as any)
  const user = await c.env.DB.prepare('SELECT id, username, password_hash, salt FROM users WHERE username = ?')
    .bind(body.username?.trim() ?? '')
    .first<{ id: number; username: string; password_hash: string; salt: string }>()
  if (!user || !timingSafeEqual(await hashPassword(body.password ?? '', user.salt), user.password_hash))
    return c.json({ error: 'Invalid username or password' }, 401)
  return c.json({ token: await issueToken(c, user.id, user.username), user: { id: user.id, username: user.username } })
})

app.get('/me', requireAuth, async (c) => {
  const stats = await c.env.DB.prepare('SELECT COUNT(*) AS checkins FROM checkins WHERE user_id = ?')
    .bind(c.get('userId'))
    .first<{ checkins: number }>()
  return c.json({ id: c.get('userId'), username: c.get('username'), checkins: stats?.checkins ?? 0 })
})

app.get('/checkins', requireAuth, async (c) => {
  const limit = Math.min(Math.max(Number(c.req.query('limit')) || 50, 1), 200)
  const { results } = await c.env.DB.prepare(
    `SELECT c.id, c.note, c.mood, c.lat, c.lon, c.steps, c.temp_c, c.weather_desc, c.created_at,
            u.username, (c.user_id = ?) AS mine
       FROM checkins c JOIN users u ON u.id = c.user_id
      ORDER BY c.created_at DESC, c.id DESC
      LIMIT ?`,
  )
    .bind(c.get('userId'), limit)
    .all()
  return c.json(results.map((r) => ({ ...r, mine: Boolean(r.mine) })))
})

app.post('/checkins', requireAuth, async (c) => {
  const body = await c.req.json<Record<string, unknown>>().catch(() => ({}) as Record<string, unknown>)
  const note = typeof body.note === 'string' ? body.note.trim() : ''
  const mood = body.mood as string
  if (!note || note.length > 280) return c.json({ error: 'Note is required (max 280 chars)' }, 400)
  if (!MOODS.includes(mood as (typeof MOODS)[number]))
    return c.json({ error: `Mood must be one of: ${MOODS.join(', ')}` }, 400)

  const hasLocation = isFiniteNumber(body.lat) && isFiniteNumber(body.lon)
  const lat = hasLocation ? (body.lat as number) : null
  const lon = hasLocation ? (body.lon as number) : null
  const steps = isFiniteNumber(body.steps) ? Math.max(0, Math.round(body.steps)) : null
  const weather = hasLocation ? await fetchWeather(lat!, lon!) : null

  const row = await c.env.DB.prepare(
    `INSERT INTO checkins (user_id, note, mood, lat, lon, steps, temp_c, weather_desc)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
     RETURNING id, note, mood, lat, lon, steps, temp_c, weather_desc, created_at`,
  )
    .bind(c.get('userId'), note, mood, lat, lon, steps, weather?.temp_c ?? null, weather?.weather_desc ?? null)
    .first()
  return c.json({ ...row, username: c.get('username'), mine: true }, 201)
})

app.delete('/checkins/:id', requireAuth, async (c) => {
  const result = await c.env.DB.prepare('DELETE FROM checkins WHERE id = ? AND user_id = ?')
    .bind(Number(c.req.param('id')), c.get('userId'))
    .run()
  if (result.meta.changes === 0) return c.json({ error: 'Not found or not yours' }, 404)
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

  // Auth is optional here so we can also log events from before sign-in (e.g. app_open).
  let userId: number | null = null
  const header = c.req.header('Authorization') ?? ''
  if (header.startsWith('Bearer ')) {
    try {
      userId = Number((await verify(header.slice(7), c.env.JWT_SECRET, 'HS256')).sub)
    } catch {}
  }
  await c.env.DB.prepare('INSERT INTO events (user_id, name, props, platform) VALUES (?, ?, ?, ?)')
    .bind(userId, body.name, body.props ? JSON.stringify(body.props).slice(0, 2000) : null, body.platform ?? null)
    .run()
  return c.json({ ok: true }, 201)
})

app.get('/stats', async (c) => {
  const [users, checkins, events, moods] = await c.env.DB.batch([
    c.env.DB.prepare('SELECT COUNT(*) AS n FROM users'),
    c.env.DB.prepare('SELECT COUNT(*) AS n FROM checkins'),
    c.env.DB.prepare('SELECT name, COUNT(*) AS n FROM events GROUP BY name ORDER BY n DESC LIMIT 20'),
    c.env.DB.prepare('SELECT mood, COUNT(*) AS n FROM checkins GROUP BY mood'),
  ])
  return c.json({
    users: (users.results[0] as { n: number }).n,
    checkins: (checkins.results[0] as { n: number }).n,
    moods: moods.results,
    events: events.results,
  })
})

app.onError((err, c) => {
  console.error(err)
  return c.json({ error: 'Internal server error' }, 500)
})

export default app
