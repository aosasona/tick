CREATE TABLE users (
    id INTEGER PRIMARY KEY, -- we will just use the rowid
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    created_at INT NOT NULL DEFAULT (unixepoch())
);
