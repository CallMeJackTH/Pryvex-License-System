(() => {
  const cfg = window.PRYVEX_CONFIG;
  const $ = (id) => document.getElementById(id);
  const message = (text) => {
    $("global-message").textContent = text || "";
    if (text) {
      clearTimeout(message.timer);
      message.timer = setTimeout(() => { $("global-message").textContent = ""; }, 4200);
    }
  };

  // Clipboard API requires a secure context and may be blocked by embedded browsers.
  // Use execCommand as a compatibility fallback for older browsers.
  async function copyText(value) {
    if (!value) throw new Error("Nothing to copy.");
    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(value);
        return;
      }
    } catch (_) {}

    const field = document.createElement("textarea");
    field.value = value;
    field.setAttribute("readonly", "");
    field.style.position = "fixed";
    field.style.opacity = "0";
    field.style.pointerEvents = "none";
    document.body.appendChild(field);
    field.focus();
    field.select();
    field.setSelectionRange(0, field.value.length);
    let copied = false;
    try { copied = document.execCommand("copy"); } catch (_) {}
    field.remove();
    if (!copied) throw new Error("Clipboard unavailable. Select the key and copy it manually.");
  }

  if (!cfg || !cfg.SUPABASE_URL || !cfg.SUPABASE_ANON_KEY || !cfg.LICENSE_API_URL) {
    $("login-message").textContent = "Configuration missing. Copy config.example.js to config.js and fill public Supabase values.";
    $("login-btn").disabled = true;
    return;
  }

  const supabase = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);
  let session = null;
  let licenseCache = [];

  async function api(action, payload = {}) {
    if (!session?.access_token) throw new Error("Please sign in again.");
    const response = await fetch(cfg.LICENSE_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${session.access_token}`,
        "apikey": cfg.SUPABASE_ANON_KEY
      },
      body: JSON.stringify({ action, ...payload })
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(data.error || "Request failed");
    return data;
  }

  function renderLicenses() {
    const query = ($("search-input")?.value || "").trim().toLowerCase();
    const statusFilter = $("status-filter")?.value || "all";
    const rows = licenseCache.filter(item => {
      const matchesQuery = !query || String(item.key || item.key_prefix || "").toLowerCase().includes(query);
      const matchesStatus = statusFilter === "all" || item.status === statusFilter;
      return matchesQuery && matchesStatus;
    });

    const tbody = $("license-rows");
    tbody.replaceChildren();
    if (!rows.length) {
      const tr = document.createElement("tr");
      const td = document.createElement("td");
      td.colSpan = 6;
      td.textContent = licenseCache.length ? "No licenses match this filter." : "No keys yet.";
      tr.append(td);
      tbody.append(tr);
      return;
    }

    for (const item of rows) {
      const tr = document.createElement("tr");
      const status = document.createElement("span");
      status.className = `status ${item.status}`;
      status.textContent = item.status;

      const values = [
        ["Status", status, ""],
        ["Device", item.bound_device_hash ? "Bound" : "Not bound", item.bound_device_hash ? "device-state bound" : "device-state"],
        ["Expires", item.expires_at ? new Date(item.expires_at).toLocaleString() : "Never", ""],
        ["Last verified", item.last_verified_at ? new Date(item.last_verified_at).toLocaleString() : "Not yet", ""]
      ];
      const licenseCell = document.createElement("td");
      licenseCell.dataset.label = "License";
      licenseCell.className = "license-cell";
      const keyText = document.createElement("span");
      keyText.className = "license-code";
      keyText.textContent = item.key || item.key_prefix || "Unavailable";
      licenseCell.append(keyText);
      const copyKeyButton = document.createElement("button");
      copyKeyButton.type = "button";
      copyKeyButton.className = "copy-key-btn";
      copyKeyButton.textContent = "Copy";
      copyKeyButton.disabled = !item.key;
      copyKeyButton.title = item.key ? "Copy full license key" : "This key predates encrypted key storage and cannot be recovered";
      copyKeyButton.addEventListener("click", async () => {
        try {
          await copyText(item.key);
          message("Full license key copied.");
        } catch (error) {
          message(error.message || "Clipboard unavailable.");
        }
      });
      licenseCell.append(copyKeyButton);
      tr.append(licenseCell);

      for (const [label, value, className] of values) {
        const td = document.createElement("td");
        td.dataset.label = label;
        if (className) {
          const span = document.createElement("span");
          span.className = className;
          span.textContent = value;
          td.append(span);
        } else if (value instanceof Node) {
          td.append(value);
        } else {
          td.textContent = value;
        }
        tr.append(td);
      }

      const actions = document.createElement("td");
      actions.dataset.label = "Actions";
      actions.className = "actions";

      const add = (label, fn, cls = "secondary-btn") => {
        const btn = document.createElement("button");
        btn.className = cls;
        btn.textContent = label;
        btn.addEventListener("click", async () => {
          btn.disabled = true;
          try {
            await fn();
            await refresh();
            message(`${label} completed.`);
          } catch (error) {
            message(error.message);
          } finally {
            btn.disabled = false;
          }
        });
        actions.append(btn);
      };

      add("Reset device", () => api("reset_hwid", { license_id: item.id }));
      add(item.status === "active" ? "Disable" : "Enable", () =>
        api("set_status", {
          license_id: item.id,
          status: item.status === "active" ? "disabled" : "active"
        })
      );
      add("Delete", async () => {
        if (confirm("Delete this key permanently? Existing sessions will be disconnected at the next license check.")) {
          await api("delete", { license_id: item.id });
        }
      }, "danger");
      tr.append(actions);
      tbody.append(tr);
    }
  }

  async function refresh() {
    const data = await api("list");
    licenseCache = data.licenses || [];
    $("total-count").textContent = licenseCache.length;
    $("active-count").textContent = licenseCache.filter(x => x.status === "active").length;
    $("bound-count").textContent = licenseCache.filter(x => !!x.bound_device_hash).length;
    renderLicenses();
  }

  let sessionUpdateId = 0;
  async function updateSession(nextSession) {
    const updateId = ++sessionUpdateId;
    session = nextSession;
    const signedIn = !!session?.access_token;

    $("login-panel").hidden = signedIn;
    $("dashboard").hidden = !signedIn;
    $("session-state").textContent = signedIn ? "Signed in — checking admin access…" : "Signed out";

    if (!signedIn) {
      licenseCache = [];
      return;
    }

    try {
      await refresh();
      if (updateId !== sessionUpdateId) return;
      $("session-state").textContent = "Admin verified";
      $("login-message").textContent = "";
    } catch (error) {
      if (updateId !== sessionUpdateId) return;
      $("session-state").textContent = "Access denied";
      message(error.message);
      if (/not authorized|invalid session|authentication required/i.test(error.message)) {
        $("login-message").textContent = "Discord login succeeded, but this Discord account is not authorized as an administrator. Check ADMIN_DISCORD_IDS on the license API.";
      }
    }
  }

  $("login-btn").addEventListener("click", async () => {
    $("login-message").textContent = "Redirecting to Discord…";
    const { error } = await supabase.auth.signInWithOAuth({
      provider: "discord",
      options: { redirectTo: window.location.href }
    });
    if (error) $("login-message").textContent = error.message;
  });

  $("logout-btn").addEventListener("click", async () => {
    await supabase.auth.signOut();
    await updateSession(null);
  });

  $("refresh-btn").addEventListener("click", async () => {
    const btn = $("refresh-btn");
    btn.disabled = true;
    try { await refresh(); message("License inventory updated."); }
    catch (error) { message(error.message); }
    finally { btn.disabled = false; }
  });

  $("generate-btn").addEventListener("click", async () => {
    const btn = $("generate-btn");
    btn.disabled = true;
    try {
      const count = Math.max(1, Math.min(100, Number($("key-count").value) || 1));
      const localExpiry = $("key-expiry").value;
      const expiresAt = localExpiry ? new Date(localExpiry).toISOString() : null;
      const data = await api("generate", { count, expires_at: expiresAt });
      $("generated-keys").value = (data.keys || []).join("\n");
      await refresh();
      message(`Generated ${(data.keys || []).length} key(s). Copy and store them securely.`);
    } catch (error) {
      message(error.message);
    } finally {
      btn.disabled = false;
    }
  });

  $("copy-keys-btn").addEventListener("click", async () => {
    const value = $("generated-keys").value;
    if (!value) return message("There are no generated keys to copy.");
    try {
      await copyText(value);
      message("Keys copied to clipboard.");
    } catch (error) {
      message(error.message || "Clipboard unavailable; select and copy the keys manually.");
    }
  });

  $("search-input").addEventListener("input", renderLicenses);
  $("status-filter").addEventListener("change", renderLicenses);

  supabase.auth.onAuthStateChange((_event, nextSession) => {
    queueMicrotask(() => { void updateSession(nextSession); });
  });

  supabase.auth.getSession()
    .then(({ data, error }) => {
      if (error) throw error;
      return updateSession(data.session);
    })
    .catch(error => {
      $("login-message").textContent = "Could not restore your login session: " + error.message;
    });

  const params = new URLSearchParams(window.location.search);
  const authError = params.get("error_description") || params.get("error");
  if (authError) $("login-message").textContent = decodeURIComponent(authError.replace(/\\+/g, " "));
})();
