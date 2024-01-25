-- session tokens are used to authenticate websocket sessions
-- the client has to send a "I am alive" message every specified interval to seep the session alive
--
-- this also is not very secure in itself, if the token is stolen
-- the attacker can essentially keep that session alive for as long as they want with no way to revoke it
-- that is why we have a `parent_auth_token`, when it is revoked, all session tokens created from it are revoked as well
CREATE TABLE session_tokens (
    id INTEGER PRIMARY KEY,
    token VARCHAR(255) NOT NULL UNIQUE,
    parent_auth_token INTEGER NOT NULL, --parent auth token
    issued_at TIMESTAMP NOT NULL DEFAULT current_timestamp,
    FOREIGN KEY (parent_auth_token) REFERENCES auth_tokens (id)
);
