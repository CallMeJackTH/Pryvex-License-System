# Pryvex License Bot

Discord.js bot for the existing Pryvex License System.

## Features
- /redeem key: links a license to the invoking Discord account.
- /license: shows status and private Get Script / Reset HWID buttons.
- Get Script returns a private Lua file with the license key decrypted server-side.
- Reset HWID clears only the license bound to the invoking Discord account.
- License command responses are ephemeral and written in English.
- Posts one bilingual Thai/English usage guide in the configured channel.
- Deletes ordinary human chat messages in that channel after 10 seconds by default.
- Bot messages, webhook messages, and interaction-generated messages are excluded from auto-delete.

## Install on a VPS
1. Install Node.js 22 or newer.
2. Copy this folder to your VPS.
3. Copy .env.example to .env and fill every required secret.
4. Run npm install.
5. Run npm run deploy:commands.
6. Run npm start. Use systemd or PM2 to keep it online.

## Discord permissions and intents
Grant the bot these channel permissions in the auto-clean channel:
- View Channel
- Read Message History
- Send Messages
- Embed Links
- Manage Messages

The bot requests the standard `Guilds` and `GuildMessages` Gateway intents. It does not need the privileged Message Content intent because it only schedules deletion and never reads message text.

## Optional auto-clean settings
- `AUTO_CLEAN_CHANNEL_ID`: channel to post the guide and clean up chat. Defaults to the configured Pryvex channel.
- `AUTO_DELETE_DELAY_MS`: delay before deleting ordinary messages, in milliseconds. Defaults to `10000` (10 seconds).

The guide uses a stable footer marker to avoid posting a duplicate when the bot restarts. The guide itself is a bot-authored message and is never deleted by the auto-clean handler.

## Environment
Use the exact existing Supabase values:
- SUPABASE_SERVICE_ROLE_KEY
- KEY_HASH_SECRET
- LICENSE_ENCRYPTION_SECRET

These must match the secrets already configured in Supabase. Never commit .env or expose the service role key.

## Existing integration and caveats
- Uses existing license_keys columns key_hash, key_encrypted, discord_id_label, bound_device_hash, status, expires_at.
- Uses existing license_events for audit history.
- Does not create or modify Supabase tables or Edge Functions.
- Keys created before encrypted key storage was enabled may have no key_encrypted value and cannot be recovered for Get Script.
- Existing discord_id_label values from Lua metadata may need cleanup if they are not actual Discord IDs.
