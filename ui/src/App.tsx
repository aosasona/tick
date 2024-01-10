import { Router, Route } from "@solidjs/router";
import { lazy } from "solid-js";

export default function App() {
  const Home = lazy(() => import("$/pages/home"));
  const SignIn = lazy(() => import("$/pages/sign-in"));
  const SignUp = lazy(() => import("$/pages/sign-up"));

  return (
    <Router>
      <Route path="/" component={Home} />
      <Route path="/sign-in" component={SignIn} />
      <Route path="/sign-up" component={SignUp} />
    </Router>
  );
}
