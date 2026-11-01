(() => {
  const cfg = window.PRYVEX_CONFIG;
  const $ = (id) => document.getElementById(id);
  const message = (text) => { $("global-message").textContent = text || ""; };

  if (!cfg || !cfg.SUPABASE_URL || !cfg.SUPABASE_ANON_KEY || !cfg.LICENSE_API_URL) {
    $("login-message").textContent = "Configuration missing. Copy config.example.js to config.js and fill public Supabase values.";
    $("login-btn").disabled = true;
    return;
  }

  const supabase = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);
  let session = null;

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

  async function refresh() {
    const data = await api("list");
    const rows = data.licenses || [];
    $("total-count").textContent = rows.length;
    $("active-count").textContent = rows.filter(x => x.status === "active").length;
    $("bound-count").textContent = rows.filter(x => !!x.bound_device_hash).length;
    $("license-rows").innerHTML = "";
    if (!rows.length) {
      $("license-rows").innerHTML = '<tr><td colspan="5">No keys yet.</td></tr>';
      return;
    }
    for (const item of rows) {
      const tr = document.createElement("tr");
      const status = document.createElement("span");
      status.className = `status ${item.status}`;
      status.textContent = item.status;
      const cells = [
        item.key_prefix,
        status,
        item.bound_device_hash ? "Bound" : "Not bound",
        item.expires_at ? new Date(item.expires_at).toLocaleString() : "Never"
      ];
      for (const value of cells) {
        const td = document.createElement("td");
        if (value instanceof Node) td.append(value); else td.textContent = value;
        tr.append(td);
      }
      const actions = document.createElement("td");
      actions.className = "actions";
      const add = (label, fn, cls = "secondary") => {
        const btn = document.createElement("button");
        btn.className = cls;
        btn.textContent = label;
        btn.addEventListener("click", async () => {
          try { await fn(); await refresh(); message(`${label}: completed`); }
          catch (e) { message(e.message); }
        });
        actions.append(btn);
      };
      add("Reset HWID", () => api("reset_hwid", { license_id: item.id }));
      add(item.status === "active" ? "Disable" : "Enable",
        () => api("set_status", { license_id: item.id, status: item.status === "active" ? "disabled" : "active" }));
      add("Delete", async () => {
        if (confirm("Permanently delete this license?")) await api("delete", { license_id: item.id });
      }, "danger");
      tr.append(actions);
      $("license-rows").append(tr);
    }
  }

  async function updateSession(nextSession) {
    session = nextSession;
    const signedIn = !!session;
    $("login-panel").hidden = signedIn;
    $("dashboard").hidden = !signedIn;
    $("session-state").textContent = signedIn ? "Signed in" : "Signed out";
    if (signedIn) {
      try { await refresh(); } catch (e) { message(e.message); }
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
    try { await refresh(); message("Updated."); } catch (e) { message(e.message); }
  });

  $("generate-btn").addEventListener("click", async () => {
    try {
      const count = Math.max(1, Math.min(100, Number($("key-count").value) || 1));
      const localExpiry = $("key-expiry").value;
      const expiresAt = localExpiry ? new Date(localExpiry).toISOString() : null;
      const data = await api("generate", { count, expires_at: expiresAt });
      $("generated-keys").value = (data.keys || []).join("\n");
      await refresh();
      message(`Generated ${(data.keys || []).length} key(s). Copy and store them now.`);
    } catch (e) { message(e.message); }
  });

  $("copy-keys-btn").addEventListener("click", async () => {
    try { await navigator.clipboard.writeText($("generated-keys").value); message("Keys copied."); }
    catch { message("Clipboard unavailable; select and copy the keys manually."); }
  });

  supabase.auth.onAuthStateChange((_event, nextSession) => {
    updateSession(nextSession);
  });
  supabase.auth.getSession().then(({ data }) => updateSession(data.session));
})();
