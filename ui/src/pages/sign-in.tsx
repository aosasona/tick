import { Button, Input } from "$/ui";
import { A } from "@solidjs/router";

export default function SignIn() {
  function handleForm(e: Event) {
    e.preventDefault();
    e.stopPropagation();

    const data = new FormData(e.target as HTMLFormElement);
    console.log(data.get("email"), data.get("password"));
  }

  return (
    <main class="auth-layout">
      <form class="auth-container" onSubmit={handleForm}>
        <h1>Sign In</h1>

        <div class="input-group">
          <Input type="email" name="email" placeholder="john@doe.com" variant="form" label="E-mail address" />
          <Input type="password" name="password" placeholder="******" variant="form" label="Password" minlength={6} />
        </div>

        <div class="text-center">
          <Button type="submit" class="mb-4" variant="filled">
            Sign In
          </Button>
          <A href="/sign-up">Don't have an account?</A>
        </div>
      </form>
    </main>
  );
}
