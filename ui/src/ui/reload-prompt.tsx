import { Show } from "solid-js";
import { useRegisterSW } from "virtual:pwa-register/solid";
import { pwaInfo } from "virtual:pwa-info";

console.log(pwaInfo);

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

  return <div></div>;
}

export default ReloadPrompt;
