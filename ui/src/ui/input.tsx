import { JSX, Show } from "solid-js";
import { twMerge } from "tailwind-merge";

type Variant = "unstyled" | "form";

interface Props extends JSX.InputHTMLAttributes<HTMLInputElement> {
  variant?: Variant;
  label?: string;
}

const variants: Record<Variant, string> = {
  unstyled: "",
  form: "w-full bg-neutral-900 border border-neutral-800 text-neutral-100 text-xs py-2 px-3 rounded placeholder-neutral-500",
};

export default function Input(props: Props) {
  const { type = "text", name } = props;
  const className = twMerge(variants[props.variant || "unstyled"], props.class);

  return (
    <div>
      <Show when={!!props.label}>
        <label class="block px-1 mb-1.5 text-xs text-neutral-400" for={name}>
          {props.label}
        </label>
      </Show>

      <input {...props} type={type} name={name} class={className} />
    </div>
  );
}
