import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const KEY_HASH_SECRET = Deno.env.get("KEY_HASH_SECRET")!;
const DEVICE_HASH_SECRET = Deno.env.get("DEVICE_HASH_SECRET")!;
const LICENSE_ENCRYPTION_SECRET = Deno.env.get("LICENSE_ENCRYPTION_SECRET")!;
const ADMIN_DISCORD_IDS = (Deno.env.get("ADMIN_DISCORD_IDS") ?? "")
  .split(",").map((s) => s.trim()).filter(Boolean);
const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",").map((s) => s.trim()).filter(Boolean);

const db = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

function corsHeaders(origin: string | null) {
  const allowed = origin && ALLOWED_ORIGINS.includes(origin) ? origin : "null";
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
    "Content-Type": "application/json",
  };
}

function json(data: unknown, status = 200, origin: string | null = null) {
  return new Response(JSON.stringify(data), { status, headers: corsHeaders(origin) });
}

async function hmacHex(secret: string, value: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(value));
  return [...new Uint8Array(signature)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function encryptionKey() {
  if (!LICENSE_ENCRYPTION_SECRET) throw new Error("License encryption is not configured");
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(LICENSE_ENCRYPTION_SECRET));
  return crypto.subtle.importKey("raw", digest, { name: "AES-GCM" }, false, ["encrypt", "decrypt"]);
}

function toBase64(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function fromBase64(value: string): Uint8Array {
  return Uint8Array.from(atob(value), (char) => char.charCodeAt(0));
}

// Keys remain HMAC-hashed for verification and are also AES-GCM encrypted
// so an authenticated administrator can view/copy them later.
async function encryptLicenseKey(value: string): Promise<string> {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv }, await encryptionKey(), new TextEncoder().encode(value),
  );
  return `${toBase64(iv)}.${toBase64(new Uint8Array(encrypted))}`;
}

async function decryptLicenseKey(value: string): Promise<string> {
  const [ivPart, encryptedPart] = value.split(".");
  if (!ivPart || !encryptedPart) throw new Error("Stored license key has an invalid format");
  const decrypted = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: fromBase64(ivPart) }, await encryptionKey(), fromBase64(encryptedPart),
  );
  return new TextDecoder().decode(decrypted);
}

function randomKey(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  const raw = [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("").toUpperCase();
  return `PRYVEX-${raw.slice(0, 8)}-${raw.slice(8, 16)}-${raw.slice(16, 24)}`;
}

async function requireAdmin(req: Request) {
  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (!token) throw new Error("Authentication required");

  const { data, error } = await db.auth.getUser(token);
  if (error || !data.user) throw new Error("Invalid session");

  const discordIdentity = (data.user.identities ?? []).find((identity: any) =>
    identity.provider === "discord"
  ) as any;
  const discordId = String(
    discordIdentity?.identity_data?.sub ??
    discordIdentity?.identity_data?.provider_id ??
    discordIdentity?.identity_id ??
    ""
  );

  if (!discordId || !ADMIN_DISCORD_IDS.includes(discordId)) {
    throw new Error("Not authorized");
  }
  return data.user;
}

Deno.serve(async (req) => {
  const origin = req.headers.get("Origin");
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders(origin) });
  }
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405, origin);

  try {
    if (!SUPABASE_URL || !SERVICE_ROLE_KEY || !KEY_HASH_SECRET || !DEVICE_HASH_SECRET || !LICENSE_ENCRYPTION_SECRET) {
      return json({ error: "Server is not configured" }, 500, origin);
    }
    const body = await req.json();
    const action = String(body.action ?? "");

    if (action === "verify") {
      const licenseKey = String(body.key ?? "").trim().toUpperCase();
      const deviceId = String(body.device_id ?? "").trim();
      const discordLabel = String(body.discord_id ?? "").trim().slice(0, 32) || null;

      if (!/^PRYVEX-[A-Z0-9-]{12,64}$/.test(licenseKey)) {
        return json({ valid: false, code: "KEY_INVALID", error: "Invalid license key" }, 400, origin);
      }
      if (deviceId.length < 8 || deviceId.length > 256) {
        return json({ valid: false, code: "DEVICE_INVALID", error: "Invalid device identifier" }, 400, origin);
      }

      const keyHash = await hmacHex(KEY_HASH_SECRET, licenseKey);
      const deviceHash = await hmacHex(DEVICE_HASH_SECRET, deviceId);

      // Check the stored record first so the client receives an accurate reason.
      const { data: license, error: lookupError } = await db.from("license_keys")
        .select("id,status,expires_at,bound_device_hash,plan")
        .eq("key_hash", keyHash)
        .maybeSingle();
      if (lookupError) throw lookupError;

      if (!license) {
        const { data: revoked, error: revokedError } = await db.from("license_key_revocations")
          .select("key_hash").eq("key_hash", keyHash).maybeSingle();
        if (revokedError) throw revokedError;
        return json({
          valid: false,
          code: revoked ? "KEY_DELETED" : "KEY_INVALID",
          error: revoked ? "This license key has been deleted" : "License key not found"
        }, 403, origin);
      }

      if (license.status === "disabled") {
        return json({ valid: false, code: "KEY_DISABLED", error: "This license key is disabled" }, 403, origin);
      }
      if (license.status === "banned") {
        return json({ valid: false, code: "KEY_BANNED", error: "This license key is banned" }, 403, origin);
      }
      if (license.expires_at && new Date(license.expires_at).getTime() <= Date.now()) {
        return json({ valid: false, code: "KEY_EXPIRED", error: "This license key has expired" }, 403, origin);
      }
      if (license.bound_device_hash && license.bound_device_hash !== deviceHash) {
        return json({ valid: false, code: "DEVICE_MISMATCH", error: "License key is bound to another device" }, 403, origin);
      }

      const { data, error } = await db.rpc("claim_license_device", {
        p_key_hash: keyHash,
        p_device_hash: deviceHash,
        p_discord_id_label: discordLabel,
      });
      if (error) throw error;

      const row = data?.[0];
      if (!row) {
        return json({ valid: false, code: "KEY_INVALID", error: "License verification failed" }, 403, origin);
      }

      // Register this Roblox client session for the admin's live-user list.
      const sessionId = String(body.session_id ?? "");
      const robloxUsername = String(body.roblox_username ?? "").trim().slice(0, 32);
      const robloxUserId = Number(body.roblox_user_id ?? 0);
      if (/^[0-9a-f-]{36}$/i.test(sessionId) && robloxUsername) {
        const { data: liveSession, error: sessionError } = await db
          .from("license_active_sessions")
          .upsert({
            session_id: sessionId,
            license_id: row.license_id,
            device_hash: deviceHash,
            roblox_user_id: Number.isSafeInteger(robloxUserId) && robloxUserId > 0 ? robloxUserId : null,
            roblox_username: robloxUsername,
            place_id: Number.isSafeInteger(Number(body.place_id)) && Number(body.place_id) > 0 ? Number(body.place_id) : null,
            game_id: String(body.game_id ?? "").slice(0, 128) || null,
            last_seen_at: new Date().toISOString()
          }, { onConflict: "session_id" })
          .select("kick_requested,kick_message")
          .single();
        if (sessionError) throw sessionError;
        if (liveSession?.kick_requested) {
          return json({
            valid: true,
            kick_requested: true,
            kick_message: liveSession.kick_message ?? "An administrator disconnected this session."
          }, 200, origin);
        }
      }

      await db.from("license_events").insert({
        license_id: row.license_id,
        event_type: "verify_success",
        detail: { device_bound: true },
      });
      return json({
        valid: true,
        kick_requested: false,
        plan: license.plan ?? "premium",
        status: row.license_status,
        expires_at: row.expires_at
      }, 200, origin);
    }

    // All actions below require an authenticated Discord admin.
    await requireAdmin(req);

    if (action === "generate") {
      const requestedCount = Number(body.count ?? 1);
      if (!Number.isInteger(requestedCount) || requestedCount < 1 || requestedCount > 100) {
        return json({ error: "Quantity must be an integer from 1 to 100" }, 400, origin);
      }
      const count = requestedCount;
      let expiresAt: string | null = null;
      if (body.expires_at !== null && body.expires_at !== undefined && body.expires_at !== "") {
        const expiryDate = new Date(body.expires_at);
        if (!Number.isFinite(expiryDate.getTime()) || expiryDate.getTime() <= Date.now()) {
          return json({ error: "Expiration must be a valid future date" }, 400, origin);
        }
        expiresAt = expiryDate.toISOString();
      }
      const generated: string[] = [];

      for (let i = 0; i < count; i++) {
        const key = randomKey();
        const keyHash = await hmacHex(KEY_HASH_SECRET, key);
        const prefix = key.slice(0, 16);
        const { error } = await db.from("license_keys").insert({
          key_hash: keyHash, key_prefix: prefix, key_encrypted: await encryptLicenseKey(key), expires_at: expiresAt,
        });
        if (error) throw error;
        generated.push(key);
      }
      return json({ keys: generated }, 200, origin);
    }

    if (action === "list_sessions") {
      const cutoff = new Date(Date.now() - 60_000).toISOString();
      const { data: sessions, error: sessionsError } = await db
        .from("license_active_sessions")
        .select("session_id,license_id,roblox_user_id,roblox_username,place_id,game_id,last_seen_at,kick_requested")
        .gte("last_seen_at", cutoff)
        .order("last_seen_at", { ascending: false })
        .limit(500);
      if (sessionsError) throw sessionsError;

      const licenseIds = [...new Set((sessions ?? []).map((s: any) => s.license_id))];
      let licensesById: Record<string, any> = {};
      if (licenseIds.length) {
        const { data: licenses, error: licenseError } = await db
          .from("license_keys").select("id,key_prefix,status").in("id", licenseIds);
        if (licenseError) throw licenseError;
        licensesById = Object.fromEntries((licenses ?? []).map((item: any) => [item.id, item]));
      }

      return json({
        sessions: (sessions ?? []).map((item: any) => ({
          ...item,
          license: licensesById[item.license_id] ?? null
        }))
      }, 200, origin);
    }

    if (action === "kick_session") {
      const sessionId = String(body.session_id ?? "");
      if (!/^[0-9a-f-]{36}$/i.test(sessionId)) {
        return json({ error: "Invalid session ID" }, 400, origin);
      }
      const cutoff = new Date(Date.now() - 90_000).toISOString();
      const { data: target, error: targetError } = await db
        .from("license_active_sessions")
        .select("session_id")
        .eq("session_id", sessionId)
        .gte("last_seen_at", cutoff)
        .maybeSingle();
      if (targetError) throw targetError;
      if (!target) return json({ error: "This player is no longer online." }, 404, origin);

      const { error } = await db.from("license_active_sessions")
        .update({
          kick_requested: true,
          kick_message: "You were disconnected by a Pryvex administrator."
        })
        .eq("session_id", sessionId);
      if (error) throw error;
      return json({ success: true }, 200, origin);
    }

    if (action === "list") {
      const { data, error } = await db.from("license_keys")
        .select("id,key_prefix,key_encrypted,status,expires_at,bound_device_hash,discord_id_label,created_at,last_verified_at")
        .order("created_at", { ascending: false }).limit(500);
      if (error) throw error;
      const licenses = await Promise.all((data ?? []).map(async (license: any) => {
        const { key_encrypted, ...safeLicense } = license;
        let key: string | null = null;
        if (key_encrypted) {
          try {
            key = await decryptLicenseKey(key_encrypted);
          } catch (decryptError) {
            // Keep inventory usable if one legacy/corrupt encrypted key cannot be opened.
            console.error("Could not decrypt a stored license key:", license.id, decryptError);
          }
        }
        return { ...safeLicense, key };
      }));
      return json({ licenses }, 200, origin);
    }

    const licenseId = String(body.license_id ?? "");
    if (!/^[0-9a-f-]{36}$/i.test(licenseId)) {
      return json({ error: "Invalid license ID" }, 400, origin);
    }

    if (action === "reset_hwid") {
      const { error } = await db.from("license_keys")
        .update({ bound_device_hash: null, updated_at: new Date().toISOString() })
        .eq("id", licenseId);
      if (error) throw error;
      await db.from("license_events").insert({ license_id: licenseId, event_type: "admin_reset_device" });
      return json({ success: true }, 200, origin);
    }

    if (action === "set_status") {
      const status = String(body.status ?? "");
      if (!["active", "disabled", "banned"].includes(status)) {
        return json({ error: "Invalid status" }, 400, origin);
      }
      const { error } = await db.from("license_keys")
        .update({ status, updated_at: new Date().toISOString() }).eq("id", licenseId);
      if (error) throw error;
      return json({ success: true }, 200, origin);
    }

    if (action === "delete") {
      const { data: existing, error: findError } = await db.from("license_keys")
        .select("key_hash,key_prefix").eq("id", licenseId).maybeSingle();
      if (findError) throw findError;
      if (existing) {
        const { error: revokeError } = await db.from("license_key_revocations")
          .upsert({ key_hash: existing.key_hash, key_prefix: existing.key_prefix }, { onConflict: "key_hash" });
        if (revokeError) throw revokeError;
      }
      const { error } = await db.from("license_keys").delete().eq("id", licenseId);
      if (error) throw error;
      return json({ success: true }, 200, origin);
    }

    return json({ error: "Unknown action" }, 400, origin);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Internal error";
    const status = message.includes("Authentication") || message.includes("Invalid session") ? 401 :
      message.toLowerCase().includes("authorized") ? 403 : 500;
    return json({ error: status === 500 ? "Request failed" : message }, status, origin);
  }
});
