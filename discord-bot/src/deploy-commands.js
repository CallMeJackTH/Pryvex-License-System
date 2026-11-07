import "dotenv/config";
import { REST, Routes, SlashCommandBuilder } from "discord.js";

const { DISCORD_TOKEN, DISCORD_APPLICATION_ID, DISCORD_GUILD_ID } = process.env;
if (!DISCORD_TOKEN || !DISCORD_APPLICATION_ID || !DISCORD_GUILD_ID) {
 throw new Error("Missing Discord environment variables");
}

const commands = [
 new SlashCommandBuilder()
  .setName("redeem")
  .setDescription("Link your Pryvex License Key to Discord")
  .addStringOption(option =>
   option
    .setName("key")
    .setDescription("Your Pryvex License Key")
    .setRequired(true)
  ),
 new SlashCommandBuilder()
  .setName("license")
  .setDescription("View your license status and management menu"),
 new SlashCommandBuilder()
  .setName("help")
  .setDescription("Show the Pryvex License Bot usage guide")
].map(command => command.toJSON());

const rest = new REST({ version: "10" }).setToken(DISCORD_TOKEN);
await rest.put(
 Routes.applicationGuildCommands(DISCORD_APPLICATION_ID, DISCORD_GUILD_ID),
 { body: commands }
);

console.log("Registered Pryvex slash commands.");
