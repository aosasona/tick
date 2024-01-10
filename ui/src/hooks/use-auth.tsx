type AuthState = {
  token: string | null;
  isAuthenticated: boolean;
};

function useAuth(): AuthState {
  const token = localStorage.getItem("token");
  const isAuthenticated = !!token;

  return { token, isAuthenticated };
}

export default useAuth;
