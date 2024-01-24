import sqlight.{type Connection}

pub type User {
  User(id: Int, email: String, password: String, created_at: Int)
}

pub fn create(conn: Connection, user: User) {
  todo
}

fn hash_password(password: String) -> String {
  todo
}

@external(erlang, "Elixir.Argon2", "password_hash")
fn argon2_hash(password: String) -> String
