import useAuth from "$/hooks/use-auth";
import { useNavigate } from "@solidjs/router";

export default function Home() {
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) {
    navigate("/sign-in", { replace: true });
  }

  return (
    <div>
      <h1>Home</h1>
    </div>
  );
}
