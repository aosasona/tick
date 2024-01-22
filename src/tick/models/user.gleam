import sqlight.{type Connection}

pub type User {
  User(id: Int, email: String, password: String, created_at: Int)
}

pub fn create(conn: Connection, user: User) {
  todo
}
