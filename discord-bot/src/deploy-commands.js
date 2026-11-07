import "dotenv/config";
import { REST, Routes, SlashCommandBuilder } from "discord.js";
const { DISCORD_TOKEN, DISCORD_APPLICATION_ID, DISCORD_GUILD_ID } = process.env;
if (!DISCORD_TOKEN || !DISCORD_APPLICATION_ID || !DISCORD_GUILD_ID) throw new Error("Missing Discord environment variables");
const commands = [
 new SlashCommandBuilder().setName("redeem").setDescription("ผูก Pryvex License Key กับ Discord").addStringOption(o=>o.setName("key").setDescription("Pryvex License Key").setRequired(true)),
 new SlashCommandBuilder().setName("license").setDescription("ดูสถานะ License และเมนูจัดการ"),
 new SlashCommandBuilder().setName("help").setDescription("วิธีใช้งาน Pryvex License Bot")
].map(x=>x.toJSON());
const rest=new REST({version:"10"}).setToken(DISCORD_TOKEN);
await rest.put(Routes.applicationGuildCommands(DISCORD_APPLICATION_ID,DISCORD_GUILD_ID),{body:commands});
console.log("Registered Pryvex guild commands.");
