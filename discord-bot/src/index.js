import "dotenv/config";
import crypto from "node:crypto";
import {ActionRowBuilder,ButtonBuilder,ButtonStyle,Client,EmbedBuilder,Events,GatewayIntentBits,MessageFlags} from "discord.js";
import {createClient} from "@supabase/supabase-js";

const required=["DISCORD_TOKEN","DISCORD_APPLICATION_ID","DISCORD_GUILD_ID","SUPABASE_URL","SUPABASE_SERVICE_ROLE_KEY","KEY_HASH_SECRET","LICENSE_ENCRYPTION_SECRET","PRYVEX_HANDOFF_CODE"];
for(const name of required) if(!process.env[name]) throw new Error("Missing environment variable: "+name);
const db=createClient(process.env.SUPABASE_URL,process.env.SUPABASE_SERVICE_ROLE_KEY,{auth:{persistSession:false,autoRefreshToken:false}});
const HANDOFF_CODE=process.env.PRYVEX_HANDOFF_CODE.trim();
if(!/^[a-f0-9]{64}$/i.test(HANDOFF_CODE)) throw new Error("Handoff code must be 64 hex characters");
const LOADER_URL=process.env.PROTECTED_LOADER_URL||"https://raw.githubusercontent.com/CallMeJackTH/Pryvex-License-System/main/lua/ProtectedLoader.lua";
const keyHash=key=>crypto.createHmac("sha256",process.env.KEY_HASH_SECRET).update(key.trim().toUpperCase()).digest("hex");
function decryptKey(value){
 const [ivPart,dataPart]=String(value||"").split(".");
 if(!ivPart||!dataPart) throw new Error("คีย์นี้ไม่มีข้อมูลเข้ารหัส กรุณาติดต่อผู้ดูแล");
 const iv=Buffer.from(ivPart,"base64"),packed=Buffer.from(dataPart,"base64");
 if(iv.length!==12||packed.length<17) throw new Error("ข้อมูลคีย์เข้ารหัสไม่ถูกต้อง");
 const secret=crypto.createHash("sha256").update(process.env.LICENSE_ENCRYPTION_SECRET).digest();
 const decipher=crypto.createDecipheriv("aes-256-gcm",secret,iv);
 decipher.setAuthTag(packed.subarray(packed.length-16));
 return Buffer.concat([decipher.update(packed.subarray(0,packed.length-16)),decipher.final()]).toString("utf8");
}
const usable=row=>row&&row.status==="active"&&(!row.expires_at||new Date(row.expires_at).getTime()>Date.now());
async function owned(discordId){
 const {data,error}=await db.from("license_keys").select("id,key_prefix,key_encrypted,status,expires_at,bound_device_hash,discord_id_label").eq("discord_id_label",discordId).maybeSingle();
 if(error) throw error; return data;
}
async function audit(id,event_type,detail){
 const {error}=await db.from("license_events").insert({license_id:id,event_type,detail});
 if(error) console.error("Audit error:",error.message);
}
const client=new Client({intents:[GatewayIntentBits.Guilds]});
client.once(Events.ClientReady,c=>console.log("Pryvex bot online: "+c.user.tag));
client.on(Events.InteractionCreate,async i=>{
 try{
  if(i.isChatInputCommand()){
   if(i.guildId!==process.env.DISCORD_GUILD_ID) return i.reply({content:"ใช้คำสั่งได้เฉพาะเซิร์ฟเวอร์ที่กำหนด",flags:MessageFlags.Ephemeral});
   if(i.commandName==="help") return i.reply({content:"/redeem key — ผูกคีย์กับ Discord\n/license — ดูสถานะและเมนู Get Script / Reset HWID",flags:MessageFlags.Ephemeral});
   if(i.commandName==="redeem"){
    await i.deferReply({flags:MessageFlags.Ephemeral});
    const key=i.options.getString("key",true).trim().toUpperCase();
    if(!/^PRYVEX-[A-Z0-9-]{12,64}$/.test(key)) return i.editReply("รูปแบบ License Key ไม่ถูกต้อง");
    const {data:lic,error}=await db.from("license_keys").select("id,status,expires_at,discord_id_label").eq("key_hash",keyHash(key)).maybeSingle();
    if(error) throw error;
    if(!lic) return i.editReply("ไม่พบ License Key นี้");
    if(!usable(lic)) return i.editReply("คีย์ถูกปิดใช้งาน ถูกแบน หรือหมดอายุแล้ว");
    if(lic.discord_id_label&&lic.discord_id_label!==i.user.id) return i.editReply("คีย์นี้ถูกผูกกับ Discord บัญชีอื่นแล้ว");
    const {data:linked,error:linkError}=await db.from("license_keys").update({discord_id_label:i.user.id,updated_at:new Date().toISOString()}).eq("id",lic.id).or("discord_id_label.is.null,discord_id_label.eq."+i.user.id).select("id").maybeSingle();
    if(linkError) throw linkError;
    if(!linked) return i.editReply("คีย์นี้ถูกผูกกับบัญชีอื่นไปแล้ว");
    await audit(lic.id,"discord_redeem",{discord_user_id:i.user.id});
    return i.editReply("Redeem สำเร็จ! ใช้ /license เพื่อเปิดเมนูจัดการคีย์");
   }
   if(i.commandName==="license"){
    await i.deferReply({flags:MessageFlags.Ephemeral});
    const lic=await owned(i.user.id);
    if(!lic) return i.editReply("ยังไม่มี License ที่ผูกกับบัญชีนี้ ใช้ /redeem ก่อน");
    const embed=new EmbedBuilder().setColor(usable(lic)?0x6b2fa0:0xd64545).setTitle("PRYVEX LICENSE").setDescription("จัดการ License ของคุณ")
     .addFields({name:"Key",value:lic.key_prefix||"PRYVEX-********",inline:true},{name:"Status",value:usable(lic)?"ACTIVE":String(lic.status).toUpperCase(),inline:true},{name:"Device",value:lic.bound_device_hash?"BOUND":"UNBOUND",inline:true},{name:"Expires",value:lic.expires_at?new Date(lic.expires_at).toLocaleString("th-TH"):"Never"});
    const row=new ActionRowBuilder().addComponents(new ButtonBuilder().setCustomId("pryvex:getscript").setLabel("Get Script").setStyle(ButtonStyle.Primary),new ButtonBuilder().setCustomId("pryvex:resethwid").setLabel("Reset HWID").setStyle(ButtonStyle.Secondary));
    return i.editReply({embeds:[embed],components:[row]});
   }
  }
  if(i.isButton()&&i.customId.startsWith("pryvex:")){
   await i.deferReply({flags:MessageFlags.Ephemeral});
   const lic=await owned(i.user.id);
   if(!lic||!usable(lic)) return i.editReply("ไม่พบ License ที่ใช้งานได้ หรือคีย์หมดอายุ/ถูกปิดใช้งาน");
   if(i.customId==="pryvex:getscript"){
    const fullKey=decryptKey(lic.key_encrypted);
    const lua=['getgenv().Key = "'+fullKey+'" -- ใส่คีย์ของคุณในนี้ --','getgenv().PryvexHandoffCode = "'+HANDOFF_CODE+'"',"","loadstring(game:HttpGet(", '    "'+LOADER_URL+'"',"))()"].join("\n");
    await audit(lic.id,"discord_get_script",{discord_user_id:i.user.id});
    return i.editReply({content:"ดาวน์โหลดไฟล์ Lua ส่วนตัวของคุณ:",files:[{attachment:Buffer.from(lua),name:"PryvexLoader.lua"}]});
   }
   if(i.customId==="pryvex:resethwid"){
    const {error}=await db.from("license_keys").update({bound_device_hash:null,updated_at:new Date().toISOString()}).eq("id",lic.id).eq("discord_id_label",i.user.id);
    if(error) throw error;
    await audit(lic.id,"discord_reset_hwid",{discord_user_id:i.user.id});
    return i.editReply("Reset HWID สำเร็จ! เมื่อเปิดสคริปต์ครั้งถัดไป ระบบจะผูกอุปกรณ์ใหม่");
   }
  }
 }catch(e){
  console.error("Interaction error:",e);
  const msg="ระบบขัดข้องชั่วคราว กรุณาลองใหม่ภายหลัง";
  if(i.deferred||i.replied) await i.editReply(msg).catch(()=>{});
  else await i.reply({content:msg,flags:MessageFlags.Ephemeral}).catch(()=>{});
 }
});
client.login(process.env.DISCORD_TOKEN);
