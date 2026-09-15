-- Pivot from generic check-ins to study spots with crowdsourced noise reports.
DROP TABLE IF EXISTS checkins;

CREATE TABLE spots (
  id          INTEGER PRIMARY KEY,
  name        TEXT NOT NULL,
  building    TEXT NOT NULL,
  area        TEXT NOT NULL,
  category    TEXT NOT NULL CHECK (category IN ('Library', 'Lounge', 'Cafe', 'Outdoors')),
  lat         REAL NOT NULL,
  lon         REAL NOT NULL,
  description TEXT NOT NULL
);

-- One noise measurement from one user's phone at one spot.
CREATE TABLE reports (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  spot_id      INTEGER NOT NULL REFERENCES spots(id) ON DELETE CASCADE,
  user_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  db           REAL    NOT NULL,          -- approximate sound level in dB measured by the phone mic
  vote         TEXT    CHECK (vote IN ('quiet', 'ok', 'busy')),
  note         TEXT,
  lat          REAL,
  lon          REAL,
  distance_m   REAL,                      -- how far the phone was from the spot when measuring
  temp_c       REAL,                      -- from Open-Meteo at report time
  weather_desc TEXT,
  created_at   TEXT    NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_reports_spot_time ON reports(spot_id, created_at DESC);
CREATE INDEX idx_reports_user ON reports(user_id);

-- Coordinates are approximate building centers on the Georgia Tech campus.
INSERT INTO spots (id, name, building, area, category, lat, lon, description) VALUES
  (1,  'Crosland Tower 4th Floor',   'Crosland Tower',                       '4th floor',        'Library',  33.77435, -84.39561, 'Silent-study floor of the library tower with tall windows over Tech Green.'),
  (2,  'Crosland Tower 1st Floor',   'Crosland Tower',                       '1st floor',        'Library',  33.77425, -84.39571, 'Entrance level with group tables. Usually busy between classes.'),
  (3,  'Price Gilbert Grand Reading Room', 'Price Gilbert Memorial Library', 'Main reading room','Library',  33.77395, -84.39530, 'Large reading room with long tables and natural light.'),
  (4,  'Clough Commons 2nd Floor',   'Clough Undergraduate Learning Commons','2nd floor',        'Lounge',   33.77470, -84.39640, 'Open study area with whiteboards next to classrooms.'),
  (5,  'Clough Commons Rooftop',     'Clough Undergraduate Learning Commons','Roof garden',      'Outdoors', 33.77480, -84.39630, 'Green roof with seating. Quiet except when events are running.'),
  (6,  'Klaus Atrium',               'Klaus Advanced Computing Building',    'Atrium',           'Lounge',   33.77710, -84.39630, 'Central atrium with couches. Echoes easily when crowded.'),
  (7,  'College of Computing Commons','College of Computing Building',       '1st floor',        'Lounge',   33.77740, -84.39730, 'Tables near Brewed Awakening coffee in CoC.'),
  (8,  'John Lewis Student Center',  'John Lewis Student Center',            'Main level',       'Lounge',   33.77380, -84.39890, 'Lounges and food court. Rarely quiet at lunch.'),
  (9,  'Scheller Library Nook',      'Scheller College of Business',         'Tech Square',      'Library',  33.77630, -84.38840, 'Business school study rooms and lounge in Tech Square.'),
  (10, 'Kendeda Building Atrium',    'Kendeda Building',                     'Atrium',           'Lounge',   33.77880, -84.39970, 'Living building with wooden stairs and plenty of daylight.'),
  (11, 'Engineered Biosystems Lobby','Engineered Biosystems Building',       'Lobby',            'Cafe',     33.78060, -84.39800, 'Quiet lobby seating on the north side of campus.'),
  (12, 'Tech Green',                 'Tech Green',                           'Lawn',             'Outdoors', 33.77460, -84.39750, 'Main campus lawn. Loud during tabling, peaceful in the evening.');
