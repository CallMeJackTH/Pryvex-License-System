import "dotenv/config";
import { REST, Routes, SlashCommandBuilder } from "discord.js";

const { DISCORD_TOKEN, DISCORD_APPLICATION_ID, DISCORD_GUILD_ID } = process.env;
if (!DISCORD_TOKEN || !DISCORD_APPLICATION_ID || !DISCORD_GUILD_ID) {
 throw new Error("Missing Discord environment variables");
}

const commands = [
 new SlashCommandBuilder()
  .setName("redeem")
  .setDescription("Link your Pryvex key to Discord | ผูกคีย์ Pryvex กับ Discord")
  .addStringOption(option =>
   option
    .setName("key")
    .setDescription("Your Pryvex key | คีย์ Pryvex ของคุณ")
    .setRequired(true)
  ),
 new SlashCommandBuilder()
  .setName("license")
  .setDescription("View your licenses | ดู License ของคุณ"),
 new SlashCommandBuilder()
  .setName("help")
  .setDescription("Pryvex bot usage guide | วิธีใช้งานบอท Pryvex")
].map(command => command.toJSON());

const rest = new REST({ version: "10" }).setToken(DISCORD_TOKEN);
await rest.put(
 Routes.applicationGuildCommands(DISCORD_APPLICATION_ID, DISCORD_GUILD_ID),
 { body: commands }
);

console.log("Registered Pryvex slash commands.");
