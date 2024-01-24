import { JSX, ParentProps } from "solid-js";
import { twMerge } from "tailwind-merge";

type Variant = "unstyled" | "filled" | "menu";

interface Props extends JSX.HTMLAttributes<HTMLButtonElement> {
  type: "button" | "submit" | "reset";
  onClick?: () => void;
  variant?: Variant;
}

const variants: Record<Variant, string> = {
  unstyled: "cursor-pointer",
  menu: "cursor-pointer",
  filled: "w-full bg-primary hover:bg-orange-600 text-white py-2 px-4 rounded focus:!ring-white cursor-pointer",
};

export default function Button(props: ParentProps<Props>) {
  const { type = "button" } = props;

  const defaultClassName = variants[props.variant || "unstyled"];
  const className = twMerge(defaultClassName, props.class);

  return (
    <button {...props} type={type} class={className} onClick={props.onClick}>
      {props.children}
    </button>
  );
}
