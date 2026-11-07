# Pryvex License Bot

Discord.js bot for the existing Pryvex License System.

## Features
- /redeem key: binds a license to the invoking Discord account.
- /license: shows status and private Get Script / Reset HWID buttons.
- Get Script returns a private Lua file with the full encrypted-at-rest license key decrypted server-side and the fixed handoff code.
- Reset HWID clears only the license bound to the invoking Discord account.
- Responses are ephemeral.

## Install on a VPS
1. Install Node.js 22 or newer.
2. Copy this folder to your VPS.
3. Copy .env.example to .env and fill every secret.
4. Run npm install.
5. Run npm run deploy:commands.
6. Run npm start. Use systemd or PM2 to keep it online.

## Environment
Use the exact existing Supabase values:
- SUPABASE_SERVICE_ROLE_KEY
- KEY_HASH_SECRET
- LICENSE_ENCRYPTION_SECRET

These must match the secrets already configured in Supabase. Never commit .env or expose the service role key.

## Existing integration and caveats
- Uses existing license_keys columns key_hash, key_encrypted, discord_id_label, bound_device_hash, status, expires_at.
- Uses existing license_events for audit history.
- Does not invent or call a new Edge Function endpoint.
- The deployed script-gate Edge Function was inspected. It accepts a 64-character handoff code, HMAC-hashes it with KEY_HASH_SECRET, and requires a matching permanent handoff record plus an enabled script. The fixed code is configured in .env, but the matching database handoff row and successful source delivery have not yet been verified. Test that code against the existing script-gate before production.
- Keys created before encrypted key storage was enabled may have no key_encrypted value and cannot be recovered for Get Script.
- Existing discord_id_label values from Lua metadata may need cleanup if they are not actual Discord IDs.
