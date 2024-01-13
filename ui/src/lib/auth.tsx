type AuthState = {
  token: string | null;
  isAuthenticated: boolean;
};

function getAuthState(): AuthState {
  const token = localStorage.getItem("token");
  const isAuthenticated = !!token;

  // TODO: Check if token is valid

  return { token, isAuthenticated };
}

export { getAuthState };
