pub type SessionToken {
  SessionToken(
    id: String,
    token: String,
    parent_auth_token: Int,
    issued_at: Int,
  )
}
