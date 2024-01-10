import { Button, Input } from "$/ui";
import { A } from "@solidjs/router";

export default function SignIn() {
  return (
    <main class="auth-layout">
      <div class="auth-container">
        <h1>Sign In</h1>

        <div class="input-group">
          <Input type="email" placeholder="john@doe.com" variant="form" label="E-mail address" />
          <Input type="password" placeholder="******" variant="form" label="Password" />
        </div>

        <div class="text-center">
          <Button type="button" class="mb-4" variant="filled">
            Sign In
          </Button>
          <A href="/sign-up">Don't have an account?</A>
        </div>
      </div>
    </main>
  );
}
