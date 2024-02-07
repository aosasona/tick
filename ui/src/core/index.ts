import env from "./env";

const KEYS = {
  periodicConnection: {
    isEnabled: "checkEnabled",
    interval: "checkInterval",
  },
} as const;

type PeriodicConnectionCheck = {
  isEnabled: boolean;
  interval: number;
};

class Core {
  private static instance: Core;
  private _isOnline: Boolean = false;
  private periodicConnectionCheck: PeriodicConnectionCheck = {
    isEnabled: false,
    interval: 60000,
  };

  get isOnline(): Boolean {
    return this._isOnline;
  }

  private constructor() {
    this.loadCheckInterval();
    this.checkOnlineStatus();

    if (this.periodicConnectionCheck.isEnabled) {
      this.checkConnectionPeriodically();
    }
  }

  public setPeriodicConnectionCheck(isEnabled: boolean, interval: number) {
    this.periodicConnectionCheck = { isEnabled, interval };
    localStorage.setItem(KEYS.periodicConnection.isEnabled, isEnabled.toString());
    localStorage.setItem(KEYS.periodicConnection.interval, interval.toString());
  }

  private loadCheckInterval() {
    const isEnabled = localStorage.getItem(KEYS.periodicConnection.isEnabled) === "true";
    const interval = parseInt(localStorage.getItem(KEYS.periodicConnection.interval) ?? "") || 60_000;

    this.periodicConnectionCheck = { isEnabled, interval };
  }

  private checkConnectionPeriodically() {
    setInterval(() => {
      this.checkOnlineStatus();
    }, this.periodicConnectionCheck.interval);
  }

  private checkOnlineStatus() {
    try {
      fetch(env.apiUrl, { mode: "no-cors" })
        .then(() => (this._isOnline = true))
        .catch(() => (this._isOnline = false));
    } catch (error) {
      this._isOnline = false;
    }
  }

  public static getInstance(): Core {
    if (!Core.instance) {
      Core.instance = new Core();
    }
    return Core.instance;
  }
}

export default Core.getInstance();
