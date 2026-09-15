// Web dashboard served at "/". A second client (besides the iPhone app) that reads the same REST API.
export const dashboardHtml = /* html */ `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Quiet Spots at Georgia Tech</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@500;700&family=Source+Sans+3:wght@400;600&display=swap" rel="stylesheet">
<style>
  :root {
    --navy: #003057; --gold: #B3A369; --paper: #F7F6F2; --ink: #1F2A33; --muted: #5E6B75;
    --quiet: #2E7D5B; --moderate: #C98A1B; --loud: #B53A2E; --unknown: #A9B1B8; --line: #E1DED5;
  }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--paper); color: var(--ink); font: 16px/1.5 "Source Sans 3", system-ui, sans-serif; }
  header { background: var(--navy); color: #fff; padding: 28px 20px 24px; }
  .wrap { max-width: 760px; margin: 0 auto; }
  h1 { font: 700 2.6rem/1 "Barlow Condensed", sans-serif; margin: 0; letter-spacing: .01em; }
  header p { margin: 6px 0 0; color: #C9D3DC; }
  main { padding: 20px; }
  .legend { display: flex; gap: 16px; flex-wrap: wrap; color: var(--muted); font-size: .9rem; margin: 4px 0 18px; }
  .legend span::before { content: ""; display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 6px; background: var(--c); }
  ol { list-style: none; margin: 0; padding: 0; }
  li { display: grid; grid-template-columns: 1fr auto; gap: 4px 16px; padding: 14px 0; border-bottom: 1px solid var(--line); }
  .name { font-weight: 600; }
  .where { color: var(--muted); font-size: .9rem; }
  .reading { grid-row: span 2; text-align: right; align-self: center; }
  .db { font: 700 2rem/1 "Barlow Condensed", sans-serif; color: var(--c); }
  .db small { font-size: 1rem; font-weight: 500; }
  .meta { color: var(--muted); font-size: .85rem; }
  .meter { grid-column: 1 / -1; height: 6px; background: var(--line); border-radius: 3px; overflow: hidden; }
  .meter i { display: block; height: 100%; background: var(--c); }
  footer { color: var(--muted); font-size: .85rem; padding: 12px 20px 40px; }
  a { color: var(--navy); }
  .empty { color: var(--muted); padding: 24px 0; }
  h2 { font: 700 1.6rem/1.1 "Barlow Condensed", sans-serif; color: var(--navy); margin: 36px 0 4px; }
  .sub { color: var(--muted); margin: 0 0 14px; font-size: .95rem; }
  .totals { display: flex; gap: 32px; flex-wrap: wrap; margin-bottom: 18px; }
  .totals b { display: block; font: 700 2rem/1 "Barlow Condensed", sans-serif; color: var(--ink); }
  .totals span { color: var(--muted); font-size: .9rem; }
  table { width: 100%; border-collapse: collapse; font-size: .95rem; }
  td { padding: 6px 0; border-bottom: 1px solid var(--line); }
  td:last-child { text-align: right; font-variant-numeric: tabular-nums; }
</style>
</head>
<body>
<header><div class="wrap">
  <h1>Quiet Spots</h1>
  <p>Live noise levels at Georgia Tech study spots, measured by students' phones.</p>
</div></header>
<main class="wrap">
  <div class="legend">
    <span style="--c:var(--quiet)">Quiet, under 45 dB</span>
    <span style="--c:var(--moderate)">Moderate, 45 to 60 dB</span>
    <span style="--c:var(--loud)">Loud, over 60 dB</span>
    <span style="--c:var(--unknown)">No reports in the last 2 hours</span>
  </div>
  <ol id="spots"><li class="empty">Loading spots…</li></ol>

  <h2>How people use it</h2>
  <p class="sub">Anonymous activity events sent by the iPhone app.</p>
  <div class="totals" id="totals"></div>
  <table><tbody id="events"></tbody></table>
</main>
<footer class="wrap">
  Updates every 30 seconds. Sorted quietest first. Data from the <a href="/api">Quiet Spots API</a>.
</footer>
<script>
  const colors = { quiet: 'var(--quiet)', moderate: 'var(--moderate)', loud: 'var(--loud)', unknown: 'var(--unknown)' };
  const esc = (s) => String(s).replace(/[&<>"']/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch]);
  function ago(ts) {
    if (!ts) return null;
    const mins = Math.round((Date.now() - Date.parse(ts.replace(' ', 'T') + 'Z')) / 60000);
    if (mins < 1) return 'just now';
    if (mins < 60) return mins + ' min ago';
    if (mins < 1440) return Math.round(mins / 60) + ' h ago';
    return Math.round(mins / 1440) + ' d ago';
  }
  async function load() {
    try {
      const spots = await (await fetch('/spots')).json();
      spots.sort((a, b) => (a.avg_db ?? 999) - (b.avg_db ?? 999));
      document.getElementById('spots').innerHTML = spots.map((s) => {
        const c = colors[s.level];
        const reading = s.avg_db === null ? '<span class="db">–</span>' : '<span class="db">' + Math.round(s.avg_db) + ' <small>dB</small></span>';
        const reports = s.recent_reports === 1 ? '1 report' : s.recent_reports + ' reports';
        return '<li style="--c:' + c + '">' +
          '<div class="name">' + esc(s.name) + '</div>' +
          '<div class="reading">' + reading + '<div class="meta">' + reports + '</div></div>' +
          '<div class="where">' + esc(s.building) + ' · ' + (ago(s.last_report_at) ? 'measured ' + ago(s.last_report_at) : 'not measured yet') + '</div>' +
          '<div class="meter"><i style="width:' + Math.min(100, ((s.avg_db ?? 0) / 90) * 100) + '%"></i></div>' +
        '</li>';
      }).join('');
    } catch {
      document.getElementById('spots').innerHTML = '<li class="empty">Could not reach the API. Retrying in 30 seconds.</li>';
    }
  }
  const eventNames = {
    app_open: 'App opened', screen_view: 'Screens viewed', report_posted: 'Reports posted',
    report_deleted: 'Reports deleted', quiet_alerts_toggled: 'Alert setting changed', quiet_alert_sent: 'Alerts delivered',
  };
  async function loadStats() {
    try {
      const s = await (await fetch('/stats')).json();
      document.getElementById('totals').innerHTML =
        '<div><b>' + s.users + '</b><span>accounts</span></div>' +
        '<div><b>' + s.reports + '</b><span>noise reports</span></div>' +
        '<div><b>' + s.active_users_24h + '</b><span>active in the last 24 h</span></div>';
      const rows = s.events.filter((e) => eventNames[e.name]);
      document.getElementById('events').innerHTML = rows.length
        ? rows.map((e) => '<tr><td>' + eventNames[e.name] + '</td><td>' + e.n + '</td></tr>').join('')
        : '<tr><td class="empty">No activity yet.</td><td></td></tr>';
    } catch {}
  }
  load();
  loadStats();
  setInterval(() => { load(); loadStats(); }, 30000);
</script>
</body>
</html>`
