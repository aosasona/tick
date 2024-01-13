import { Button, Input } from "$/ui";
import { A } from "@solidjs/router";

export default function SignUp() {
  function handleForm(e: Event) {
    e.preventDefault();
    e.stopPropagation();

    const data = new FormData(e.target as HTMLFormElement);
    console.log(data);
  }

  return (
    <main class="auth-layout">
      <form class="auth-container" onSubmit={handleForm}>
        <h1>Sign Up</h1>

        <div class="input-group">
          <Input type="email" name="email" placeholder="john@doe.com" variant="form" label="E-mail address" />
          <Input type="password" name="password" placeholder="******" variant="form" label="Password" minlength={6} />
          <Input type="password" name="confirmPassword" placeholder="******" variant="form" label="Password" minlength={6} />
        </div>

        <div class="text-center">
          <Button type="submit" class="mb-4" variant="filled">
            Sign Up
          </Button>
          <A href="/sign-in">Already have an account?</A>
        </div>
      </form>
    </main>
  );
}
