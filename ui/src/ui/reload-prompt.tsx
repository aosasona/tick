import { Show } from "solid-js";
import { useRegisterSW } from "virtual:pwa-register/solid";
import Button from "./button";

function ReloadPrompt() {
  const sw = useRegisterSW({
    immediate: true,
    onRegisteredSW(swUrl, r) {
      console.log("registered", swUrl, r);
    },
    onRegisterError(e) {
      console.error("failed to register", e);
    },
  });
  const [offlineReady, setOfflineReady] = sw.offlineReady;
  const [needRefresh, setNeedRefresh] = sw.needRefresh;

  const close = () => {
    setOfflineReady(false);
    setNeedRefresh(false);
  };

  const buttonClass = "text-primary bg-white text-xs px-2 py-0.5 rounded-sm hover:scale-95 transition-all shadow-sm";

  return (
    <Show when={needRefresh() || offlineReady()}>
      <div class="flex gap-5 justify-center items-center py-2 px-3 bg-primary">
        <Show when={needRefresh()} fallback={<p>App is ready to work offline!</p>}>
          <p>A new version of this app is available</p>
        </Show>

        <Show when={needRefresh()}>
          <Button type="button" variant="unstyled" class={buttonClass} onClick={() => sw.updateServiceWorker(true)}>
            Reload now
          </Button>
        </Show>

        <Show when={offlineReady()}>
          <Button type="button" variant="unstyled" class={buttonClass} onClick={close}>
            Close
          </Button>
        </Show>
      </div>
    </Show>
  );
}

export default ReloadPrompt;
