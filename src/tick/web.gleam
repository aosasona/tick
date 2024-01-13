import sqlight

pub type Context {
  Context(database: sqlight.Connection, web_directory: String)
}
