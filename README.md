# Pryvex License System

Starter project for a server-verified license system with:
- Discord OAuth admin sign-in (Supabase Auth)
- One license key bound to one client-supplied device identifier
- Admin key generation, disable/enable, delete, and HWID reset
- Live license re-checks while the script is running; disabled/deleted keys terminate the active client
- Deleted-key tombstones distinguish deleted keys from never-valid keys
- Supabase Edge Function API and PostgreSQL schema
- A small Lua executor-side verification module

## Important security limitations

1. **A client-reported HWID/device ID is not strong device attestation.** A user controlling the executor can spoof or reset it. This project enforces one *reported device ID* per key; it cannot guarantee one physical device.
2. `getgenv().id` is treated as an optional Discord ID label only. It is not proof that the caller owns that Discord account.
3. Never put the Supabase `service_role` key, `KEY_HASH_SECRET`, `DEVICE_HASH_SECRET`, or `LICENSE_ENCRYPTION_SECRET` in browser JavaScript, Lua, or GitHub. Keep `LICENSE_ENCRYPTION_SECRET` backed up securely; losing it makes stored full keys unrecoverable.
4. A public Lua loader can be inspected or modified. Do not distribute valuable server-side secrets or assume client-side checks cannot be bypassed.
5. Use this only to license scripts/software you own or are authorized to distribute.

## Project layout

- `supabase/schema.sql` — database tables and RPCs
- `supabase/functions/license-api/index.ts` — verification and admin API
- `web/admin.html`, `web/admin.js`, `web/config.example.js` — admin dashboard
- `lua/PryvexLicense.lua` — client verification helper
- `.env.example` — names of secrets; contains no real credentials

## 1. Create services

### Supabase
1. Create a new Supabase project.
2. Open SQL Editor and run `supabase/schema.sql`.
3. In Authentication > Providers, enable **Discord** and configure Discord OAuth Client ID and Client Secret.
4. Set the allowed redirect URL to your deployed admin page, e.g. `https://YOUR-VERCEL-DOMAIN.vercel.app/admin.html`.
5. In Edge Functions secrets, set:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `KEY_HASH_SECRET` — long random secret (32+ random bytes)
   - `DEVICE_HASH_SECRET` — a different long random secret
   - `LICENSE_ENCRYPTION_SECRET` — another long random secret used only to encrypt stored keys for admin display
   - `ADMIN_DISCORD_IDS` — comma-separated Discord account IDs allowed to administer licenses
   - `ALLOWED_ORIGINS` — exact admin site origin, e.g. `https://YOUR-VERCEL-DOMAIN.vercel.app`
6. Deploy the `license-api` Edge Function.

Supabase project URL and anon/publishable key are public client configuration, not secrets. Do not use the service-role key in the web app.

### Vercel
1. Import this repository into Vercel.
2. Set the project root to `web` (or configure the output directory to `web`).
3. Copy `web/config.example.js` to `web/config.js`.
4. Fill in only `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `LICENSE_API_URL` in `config.js`. These are public values.
5. Deploy. Add the deployed origin to Supabase Auth redirect URLs and `ALLOWED_ORIGINS`.

## 2. Admin login

Sign in with the Discord account whose numeric Discord ID is listed in `ADMIN_DISCORD_IDS`.
The Edge Function checks the authenticated Supabase user identity for the Discord provider ID. Do not rely on a Discord ID typed into a form.

## 3. Lua integration

Configure the key, a stable device identifier, and the raw URL of the script you own:

```lua
getgenv().Key = "PRYVEX-XXX-XXX-X"
getgenv().DeviceId = "A_STABLE_DEVICE_IDENTIFIER_FROM_YOUR_SUPPORTED_EXECUTOR"
getgenv().ScriptURL = "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/main.lua"
getgenv().id = "YOUR_DISCORD_ID" -- optional metadata only; not authentication

loadstring(game:HttpGet("https://raw.githubusercontent.com/CallMeJackTH/Pryvex-License-System/main/lua/loader.lua"))()
```

The loader downloads `lua/PryvexLicense.lua`, verifies the key against the Supabase Edge Function, and only downloads/runs `ScriptURL` after verification succeeds. The client re-checks the license every 30 seconds; disabling or deleting a key causes the active client to close Pryvex UI and disconnect with a matching reason. Temporary network errors are retried rather than treated as a revoked key. The client-side monitor is a deterrent, not tamper-proof enforcement against a hostile executor.

`DeviceId` must remain stable between runs on the same installation. Executor APIs differ, so this project does not guess an undocumented HWID function. A client-provided identifier can be spoofed; it is not hardware attestation. Never put server secrets in Lua or GitHub.

## 4. Admin features

- Generate one or many keys
- Set optional expiry date
- View full keys and copy them from the inventory (keys generated before encrypted storage was enabled cannot be recovered; generate replacements for those)
- View status and device binding state
- Reset device binding (HWID reset)
- Disable/enable a key
- Delete a key

## 5. Before production

- Restrict CORS to your exact site origin.
- Configure Supabase Auth rate limits and CAPTCHA if appropriate.
- Add monitoring/alerts for repeated failed verifications.
- Review SQL and Edge Function code.
- Consider a native/server-mediated licensing design if stronger device assurance is required.
- Rotate secrets immediately if they are ever exposed.
