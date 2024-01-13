import { getAuthState } from "$/lib/auth";
import { useNavigate } from "@solidjs/router";

// TODO: handle note state
export default function Dashboard() {
  const navigate = useNavigate();
  const { isAuthenticated } = getAuthState();
  if (!isAuthenticated) {
    navigate("/sign-in", { replace: true });
  }

  return (
    <div>
      <h1>Home</h1>
    </div>
  );
}
