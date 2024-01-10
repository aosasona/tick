import { JSX, ParentProps } from "solid-js";
import { twMerge } from "tailwind-merge";

type Variant = "unstyled" | "filled" | "menu";

interface Props extends JSX.HTMLAttributes<HTMLButtonElement> {
  type: "button" | "submit" | "reset";
  onClick?: () => void;
  variant?: Variant;
}

export default function Button(props: ParentProps<Props>) {
  const { type = "button" } = props;

  const variants: Record<Variant, string> = {
    unstyled: "",
    menu: "",
    filled: "w-full bg-orange-500 hover:bg-orange-600 text-white text-xs py-2 px-4 rounded focus:!ring-white",
  };

  const defaultClassName = variants[props.variant || "unstyled"];
  const className = twMerge(defaultClassName, props.class);

  return (
    <button {...props} type={type} class={className} onClick={props.onClick}>
      {props.children}
    </button>
  );
}
