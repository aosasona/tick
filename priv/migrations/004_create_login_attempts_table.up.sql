-- This table is poorly named since we mostly use it to track failed login attempts and not successful ones (yet).
CREATE TABLE login_attempts (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  status VARCHAR(255) NOT NULL,
  attempted_at INTEGER NOT NULL DEFAULT (unixepoch()),
  FOREIGN KEY (user_id) REFERENCES users(id),
  CHECK (status IN ('success', 'failure'))
);
