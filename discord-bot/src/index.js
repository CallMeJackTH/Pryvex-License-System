import "dotenv/config";
import crypto from "node:crypto";
import {
 ActionRowBuilder,
 ButtonBuilder,
 ButtonStyle,
 Client,
 EmbedBuilder,
 Events,
 GatewayIntentBits,
 MessageFlags
} from "discord.js";
import { createClient } from "@supabase/supabase-js";

const required = [
 "DISCORD_TOKEN",
 "DISCORD_APPLICATION_ID",
 "DISCORD_GUILD_ID",
 "SUPABASE_URL",
 "SUPABASE_SERVICE_ROLE_KEY",
 "KEY_HASH_SECRET",
 "LICENSE_ENCRYPTION_SECRET",
 "PRYVEX_HANDOFF_CODE"
];

for (const name of required) {
 if (!process.env[name]) throw new Error("Missing environment variable: " + name);
}

const db = createClient(
 process.env.SUPABASE_URL,
 process.env.SUPABASE_SERVICE_ROLE_KEY,
 { auth: { persistSession: false, autoRefreshToken: false } }
);

const HANDOFF_CODE = process.env.PRYVEX_HANDOFF_CODE.trim();
if (!/^[a-f0-9]{64}$/i.test(HANDOFF_CODE)) {
 throw new Error("Handoff code must be 64 hex characters");
}

const LOADER_URL = process.env.PROTECTED_LOADER_URL ||
 "https://raw.githubusercontent.com/CallMeJackTH/Pryvex-License-System/main/lua/ProtectedLoader.lua";

const AUTO_CLEAN_CHANNEL_ID =
 process.env.AUTO_CLEAN_CHANNEL_ID || "1478701584279011350";
const AUTO_DELETE_DELAY_MS = Math.max(
 1000,
 Number.parseInt(process.env.AUTO_DELETE_DELAY_MS || "10000", 10) || 10000
);
const GUIDE_MARKER = "PRYVEX_USAGE_GUIDE_V1";

const keyHash = key =>
 crypto.createHmac("sha256", process.env.KEY_HASH_SECRET)
  .update(key.trim().toUpperCase())
  .digest("hex");

function decryptKey(value) {
 const [ivPart, dataPart] = String(value || "").split(".");
 if (!ivPart || !dataPart) {
  throw new Error("This key has no encrypted payload. Please contact support.");
 }

 const iv = Buffer.from(ivPart, "base64");
 const packed = Buffer.from(dataPart, "base64");
 if (iv.length !== 12 || packed.length < 17) {
  throw new Error("The encrypted key data is invalid.");
 }

 const secret = crypto.createHash("sha256")
  .update(process.env.LICENSE_ENCRYPTION_SECRET)
  .digest();

 const decipher = crypto.createDecipheriv("aes-256-gcm", secret, iv);
 decipher.setAuthTag(packed.subarray(packed.length - 16));

 return Buffer.concat([
  decipher.update(packed.subarray(0, packed.length - 16)),
  decipher.final()
 ]).toString("utf8");
}

const usable = row =>
 row &&
 row.status === "active" &&
 (!row.expires_at || new Date(row.expires_at).getTime() > Date.now());

async function owned(discordId) {
 const { data, error } = await db.from("license_keys")
  .select("id,key_prefix,key_encrypted,status,expires_at,bound_device_hash,discord_id_label")
  .eq("discord_id_label", discordId)
  .order("created_at", { ascending: false });
 if (error) throw error;
 return data || [];
}

async function audit(id, event_type, detail) {
 const { error } = await db
  .from("license_events")
  .insert({ license_id: id, event_type, detail });

 if (error) console.error("Audit error:", error.message);
}

function createUsageGuide() {
 return new EmbedBuilder()
  .setColor(0x6b2fa0)
  .setTitle("📘 Pryvex License Bot | Usage Guide")
  .setDescription(
   "**🇹🇭 ภาษาไทย**\n" +
   "• ใช้ `/redeem` เพื่อผูก License Key กับบัญชี Discord\n" +
   "• ใช้ `/license` เพื่อดูสถานะและเปิดเมนูจัดการ License\n" +
   "• กด **Get Script** เพื่อดาวน์โหลดไฟล์สคริปต์ส่วนตัว\n" +
   "• กด **Reset HWID** เพื่อรีเซ็ตอุปกรณ์ที่ผูกไว้\n" +
   "• หากพบปัญหา กรุณาติดต่อทีมงาน\n\n" +
   "**🇬🇧 English**\n" +
   "• Use `/redeem` to link your License Key to Discord.\n" +
   "• Use `/license` to view your license status and management menu.\n" +
   "• Select **Get Script** to download your personal script file.\n" +
   "• Select **Reset HWID** to reset your bound device.\n" +
   "• If you need help, please contact the staff team."
  )
  .setFooter({ text: GUIDE_MARKER });
}

async function ensureUsageGuide(client) {
 try {
  const channel = await client.channels.fetch(AUTO_CLEAN_CHANNEL_ID);
  if (!channel?.isTextBased() || !channel.messages) {
   console.error("Auto-clean channel is not a text channel:", AUTO_CLEAN_CHANNEL_ID);
   return;
  }

  const recentMessages = await channel.messages.fetch({ limit: 100 });
  const guideExists = recentMessages.some(message =>
   message.author.id === client.user.id &&
   message.embeds.some(embed => embed.footer?.text === GUIDE_MARKER)
  );

  if (!guideExists) {
   await channel.send({ embeds: [createUsageGuide()] });
   console.log("Posted the bilingual Pryvex usage guide.");
  }
 } catch (error) {
  console.error("Could not verify or post the usage guide:", error);
 }
}

const client = new Client({
 intents: [
  GatewayIntentBits.Guilds,
  GatewayIntentBits.GuildMessages
 ]
});

client.once(Events.ClientReady, async c => {
 console.log("Pryvex bot online: " + c.user.tag);
 await ensureUsageGuide(c);
});

// Only ordinary human messages in the configured channel are temporary.
// Bot, webhook, and interaction-generated messages are deliberately excluded.
client.on(Events.MessageCreate, async message => {
 if (message.channelId !== AUTO_CLEAN_CHANNEL_ID) return;
 if (message.author.bot || message.webhookId) return;
 if (message.interactionMetadata || message.interaction || message.applicationId) return;
 if (!message.guildId || message.system) return;

 setTimeout(async () => {
  try {
   if (message.deletable) await message.delete();
  } catch (error) {
   if (error.code !== 10008) {
    console.error("Auto-delete failed:", error.message);
   }
  }
 }, AUTO_DELETE_DELAY_MS);
});

client.on(Events.InteractionCreate, async i => {
 try {
  if (i.isChatInputCommand()) {
   if (i.guildId !== process.env.DISCORD_GUILD_ID) {
    return i.reply({
     content: "This command is only available in the configured server.",
     flags: MessageFlags.Ephemeral
    });
   }

   if (i.commandName === "help") {
    return i.reply({
     content:
      "**Pryvex License Bot Help**\n" +
      "• `/redeem key` — Link your license key to Discord.\n" +
      "• `/license` — View your license status and open the management menu.",
     flags: MessageFlags.Ephemeral
    });
   }

   if (i.commandName === "redeem") {
    await i.deferReply({ flags: MessageFlags.Ephemeral });

    const key = i.options.getString("key", true).trim().toUpperCase();
    if (!/^PRYVEX-[A-Z0-9-]{12,64}$/.test(key)) {
     return i.editReply("Invalid License Key format.");
    }

    const { data: lic, error } = await db
     .from("license_keys")
     .select("id,status,expires_at,discord_id_label")
     .eq("key_hash", keyHash(key))
     .maybeSingle();

    if (error) throw error;
    if (!lic) return i.editReply("This License Key was not found.");
    if (!usable(lic)) return i.editReply("This key is disabled, banned, or expired.");
    if (lic.discord_id_label && lic.discord_id_label !== i.user.id) {
     return i.editReply("This key is already linked to another Discord account.");
    }

    const { data: linked, error: linkError } = await db
     .from("license_keys")
     .update({
      discord_id_label: i.user.id,
      updated_at: new Date().toISOString()
     })
     .eq("id", lic.id)
     .or("discord_id_label.is.null,discord_id_label.eq." + i.user.id)
     .select("id")
     .maybeSingle();

    if (linkError) throw linkError;
    if (!linked) return i.editReply("This key has already been linked to another account.");

    await audit(lic.id, "discord_redeem", { discord_user_id: i.user.id });
    return i.editReply("License redeemed successfully! Use /license to manage your key.");
   }

   if (i.commandName === "license") {
    await i.deferReply({ flags: MessageFlags.Ephemeral });

    const lic = await owned(i.user.id);
    if (!lic) {
     return i.editReply("No license is linked to this account. Please use /redeem first.");
    }

    const embed = new EmbedBuilder()
     .setColor(usable(lic) ? 0x6b2fa0 : 0xd64545)
     .setTitle("PRYVEX LICENSE")
     .setDescription("You own **" + licenses.length + "** license(s). Choose an action, then select the license to use.\nActive: **" + activeCount + "**")
     .addFields(licenses.slice(0, 10).map((lic, index) => ({
      name: "License " + (index + 1),
      value: (lic.key_prefix || "PRYVEX-********") + " · " + String(lic.status).toUpperCase(),
      inline: true
     })));

    const row = new ActionRowBuilder().addComponents(
     new ButtonBuilder()
      .setCustomId("pryvex:getscript")
      .setLabel("Get Script")
      .setStyle(ButtonStyle.Primary),
     new ButtonBuilder()
      .setCustomId("pryvex:resethwid")
      .setLabel("Reset HWID")
      .setStyle(ButtonStyle.Secondary)
    );

    return i.editReply({ embeds: [embed], components: [row] });
   }
  }

  if (i.isButton() && i.customId.startsWith("pryvex:")) {
   const action = i.customId === "pryvex:getscript" ? "getscript" :
    i.customId === "pryvex:resethwid" ? "resethwid" : null;
   if (!action) return;
   const available = (await owned(i.user.id)).filter(usable);
   if (!available.length) return i.reply({ content: "No active license was found. Your keys may be expired, disabled, or banned.", flags: MessageFlags.Ephemeral });
   const menu = new StringSelectMenuBuilder().setCustomId("pryvex:select:" + action)
    .setPlaceholder("Select a license key")
    .addOptions(available.slice(0, 25).map((lic, index) => ({
     label: (lic.key_prefix || "License " + (index + 1)).slice(0, 100),
     description: "Status: " + String(lic.status).toUpperCase(), value: lic.id
    })));
   return i.reply({
    content: available.length > 25 ? "Select an active license (showing the first 25)." : "Select the license you want to " + (action === "getscript" ? "download" : "reset the device for") + ".",
    components: [new ActionRowBuilder().addComponents(menu)], flags: MessageFlags.Ephemeral
   });
  }

  if (i.isStringSelectMenu() && i.customId.startsWith("pryvex:select:")) {
   await i.deferReply({ flags: MessageFlags.Ephemeral });
   const action = i.customId.slice("pryvex:select:".length);
   if (!["getscript", "resethwid"].includes(action)) return i.editReply("Invalid action.");
   const lic = (await owned(i.user.id)).find(item => item.id === i.values[0]);
   if (!lic || !usable(lic)) return i.editReply("This license is unavailable, expired, disabled, or not owned by your account.");
   if (action === "getscript") {
    const fullKey = decryptKey(lic.key_encrypted);
    const lua = [
     'getgenv().Key = "' + fullKey + '" -- Your license key',
     'getgenv().PryvexHandoffCode = "' + HANDOFF_CODE + '"', "",
     "loadstring(game:HttpGet(", '    "' + LOADER_URL + '"', "))()"
    ].join("\n");
    await audit(lic.id, "discord_get_script", { discord_user_id: i.user.id });
    return i.editReply({ content: "Your personal Lua script is ready to download:", files: [{ attachment: Buffer.from(lua), name: "PryvexLoader.lua" }] });
   }
   if (action === "resethwid") {
    const { error } = await db.from("license_keys").update({
     bound_device_hash: null, updated_at: new Date().toISOString()
    }).eq("id", lic.id).eq("discord_id_label", i.user.id);
    if (error) throw error;
    await audit(lic.id, "discord_reset_hwid", { discord_user_id: i.user.id });
    return i.editReply("HWID reset successfully! Your next script launch will bind the new device.");
   }
  }
 } catch (error) {
  console.error("Interaction error:", error);
  const message = "A temporary system error occurred. Please try again later.";

  if (i.deferred || i.replied) {
   await i.editReply(message).catch(() => {});
  } else {
   await i.reply({ content: message, flags: MessageFlags.Ephemeral }).catch(() => {});
  }
 }
});

client.login(process.env.DISCORD_TOKEN);
