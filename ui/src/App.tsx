import { Router, Route } from "@solidjs/router";
import { lazy } from "solid-js";

export default function App() {
  const Dashboard = lazy(() => import("$/pages/dashboard"));
  const SignIn = lazy(() => import("$/pages/sign-in"));
  const SignUp = lazy(() => import("$/pages/sign-up"));

  return (
    <Router>
      <Route path="/" component={Dashboard} />
      <Route path="/sign-in" component={SignIn} />
      <Route path="/sign-up" component={SignUp} />
      <Route path="/n/:id" component={Dashboard} />
      <Route path="*" component={lazy(() => import("$/pages/not-found"))} />
    </Router>
  );
}
