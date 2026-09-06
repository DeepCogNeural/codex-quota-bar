// Local CodexBar provider. No OAuth files, cookies, or model requests.
// Account aliases are optional local settings, never embedded in this file.
defineProvider({
  id: "subrouter",
  name: "Subrouter",
  icon: { monogram: "SR", tint: "#3584E4" },
  endpoints: [{ setting: "BASE_URL", policy: "https-or-loopback-http" }],
  settings: [
    { key: "BASE_URL", title: "Router URL", subtitle: "http://127.0.0.1:31415", type: "plain" },
    { key: "ALIASES", title: "Account aliases (JSON)", type: "plain" },
  ],
  async fetchUsage(ctx) {
    const base = (ctx.settings.get("BASE_URL") || "").replace(/\/+$/, "");
    // This integration deliberately supports only the installed loopback router.
    if (base !== "http://127.0.0.1:31415") {
      throw ctx.fail.permissionDenied("Use http://127.0.0.1:31415 for the local router.");
    }
    let aliases = {};
    const aliasText = ctx.settings.get("ALIASES");
    if (aliasText) {
      try { aliases = JSON.parse(aliasText); } catch (_) {
        throw ctx.fail.parseFailure("Account aliases must be a JSON object.");
      }
      if (!aliases || typeof aliases !== "object" || Array.isArray(aliases)) {
        throw ctx.fail.parseFailure("Account aliases must be a JSON object.");
      }
    }
    const response = await ctx.http.getJSON(base + "/_subrouter/usage-status");
    const accounts = response.json;
    if (!Array.isArray(accounts) || accounts.length > 8) {
      throw ctx.fail.parseFailure("Expected up to eight router accounts.");
    }
    const now = ctx.date.nowMillis();
    const extraWindows = [];
    const details = [];
    for (const [index, account] of accounts.entries()) {
      if (!account || typeof account.email !== "string" || !account.email) {
        throw ctx.fail.parseFailure("Router account identity is missing.");
      }
      const alias = aliases[account.email];
      const name = (typeof alias === "string" && alias.trim() ? alias.trim() : account.email).slice(0, 70);
      const plan = typeof account.plan_type === "string" ? account.plan_type.toUpperCase().slice(0, 20) : "";
      const rows = [];
      const windows = Array.isArray(account.windows) ? account.windows : [];
      const quotas = windows.filter(w => w && !w.Feature && Number.isFinite(w.LimitWindowSeconds) && w.LimitWindowSeconds > 0);
      if (quotas.length > 8) throw ctx.fail.parseFailure("Too many account quota windows.");
      for (const [windowIndex, quota] of quotas.entries()) {
        if (!Number.isFinite(quota.UsedPercent) || quota.UsedPercent < 0 || quota.UsedPercent > 100) {
          throw ctx.fail.parseFailure("Invalid router usage percentage.");
        }
        const seconds = quota.LimitWindowSeconds;
        const label = seconds % 86400 === 0 ? `${seconds / 86400}d` : `${seconds / 3600}h`;
        const window = { usedPercent: quota.UsedPercent, windowMinutes: Math.max(1, Math.round(seconds / 60)) };
        if (Number.isFinite(quota.ResetAfterSeconds) && quota.ResetAfterSeconds >= 0) {
          const reset = new Date(now + quota.ResetAfterSeconds * 1000);
          if (Number.isFinite(reset.getTime())) window.resetsAt = reset.toISOString();
        }
        // An invalid login must not look like an available routing account.
        if (account.auth_checked === true && account.auth_valid === true) {
          extraWindows.push({ id: `account-${index}-${windowIndex}`, title: `${name} · ${label}`, window });
        }
        rows.push({ label, value: `${ctx.format.number(100 - quota.UsedPercent, { maximumFractionDigits: 1 })}%`, secondaryValue: window.resetsAt || "—" });
      }
      if (!rows.length) rows.push({ label: "—", value: "—" });
      const auth = account.auth_checked === true ? (account.auth_valid === true ? "✓" : "!") : "?";
      details.push({ title: `${name} · ${plan} ${auth}`, rows });
    }
    if (!details.length) throw ctx.fail.providerUnavailable("No accounts returned by the router.");
    // No synthetic aggregate: percentages belong to distinct subscription limits.
    return { extraWindows, details, dataConfidence: "percentOnly" };
  },
});
