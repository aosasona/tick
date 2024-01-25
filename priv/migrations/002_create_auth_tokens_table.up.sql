-- we should probably be hashing the token, but for now we'll just store it in plain text for simplicity
-- hashing them right now would mean the client would only be able to login on one device at a time
-- and to fix that, we would have to fetch all tokens for a user and compare them all (expensive!)
CREATE TABLE auth_tokens (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    ttl_in_seconds INTEGER NOT NULL,
    issued_at INTEGER NOT NULL DEFAULT (unixepoch()),
    FOREIGN KEY (user_id) REFERENCES users (id)
);
