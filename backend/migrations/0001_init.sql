-- Users who sign up through the app. Passwords are stored as PBKDF2 hashes, never plaintext.
CREATE TABLE users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  username      TEXT    NOT NULL UNIQUE COLLATE NOCASE,
  password_hash TEXT    NOT NULL,
  salt          TEXT    NOT NULL,
  created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- A check-in is user-generated content that every signed-in user can see in the feed.
-- Weather columns are filled by the server from Open-Meteo (third-party API).
CREATE TABLE checkins (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  note         TEXT    NOT NULL,
  mood         TEXT    NOT NULL,
  lat          REAL,
  lon          REAL,
  steps        INTEGER,
  temp_c       REAL,
  weather_desc TEXT,
  created_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_checkins_created ON checkins(created_at DESC);

-- Lightweight app analytics: screen views, button taps, etc.
CREATE TABLE events (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER REFERENCES users(id) ON DELETE SET NULL,
  name       TEXT    NOT NULL,
  props      TEXT,
  platform   TEXT,
  created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_events_name ON events(name);
