(() => {
 const cfg=window.PRYVEX_CONFIG, endpoint="https://yfsmtoetvajschaeyagc.supabase.co/functions/v1/script-gate";
 const $=id=>document.getElementById(id); let session=null;
 const client=window.supabase.createClient(cfg.SUPABASE_URL,cfg.SUPABASE_ANON_KEY);
 const toast=t=>{$("toast").textContent=t;};
 async function api(action,payload={}) {
  if(!session?.access_token) throw Error("Sign in again.");
  const r=await fetch(endpoint,{method:"POST",headers:{"Content-Type":"application/json","Authorization":"Bearer "+session.access_token,"apikey":cfg.SUPABASE_ANON_KEY},body:JSON.stringify({action,...payload})});
  const d=await r.json().catch(()=>({})); if(!r.ok) throw Error(d.error||"Request failed"); return d;
 }
 async function refresh(){
  const {scripts=[]}=await api("list_scripts"), body=$("rows"); body.replaceChildren();
  if(!scripts.length){const tr=document.createElement("tr"),td=document.createElement("td");td.colSpan=4;td.textContent="No scripts added yet.";tr.append(td);body.append(tr);return;}
  for(const s of scripts){
   const tr=document.createElement("tr");
   const name=document.createElement("td");name.textContent=s.name;
   const url=document.createElement("td");url.textContent=s.raw_url;url.style.maxWidth="340px";url.style.overflowWrap="anywhere";
   const status=document.createElement("td");status.textContent=s.enabled?"Enabled":"Disabled";
   const actions=document.createElement("td");actions.className="actions";
   const button=(label,fn,cls="secondary-btn")=>{const b=document.createElement("button");b.className=cls;b.textContent=label;b.onclick=async()=>{b.disabled=true;try{await fn();}catch(e){toast(e.message);}finally{b.disabled=false;}};actions.append(b);};
   button("Issue permanent code",async()=>{const d=await api("issue_code",{id:s.id});const text=d.code;try{await navigator.clipboard.writeText(text);toast("Permanent access code copied. It does not expire.");}catch{prompt("Copy this permanent access code. Keep it private:",text);}});
   button("Edit",()=>{$("script-id").value=s.id;$("script-name").value=s.name;$("script-url").value=s.raw_url;window.scrollTo({top:0,behavior:"smooth"});});
   button(s.enabled?"Disable":"Enable",async()=>{await api("save_script",{id:s.id,name:s.name,raw_url:s.raw_url,enabled:!s.enabled});await refresh();toast("Script status updated.");});
   button("Delete",async()=>{if(!confirm("Delete this script? Existing handoff codes will also be deleted."))return;await api("delete_script",{id:s.id});await refresh();toast("Script deleted.");},"danger");
   tr.append(name,url,status,actions);body.append(tr);
  }
 }
 $("login-btn").onclick=async()=>{const {error}=await client.auth.signInWithOAuth({provider:"discord",options:{redirectTo:location.href.split("?")[0]}});if(error)$("login-error").textContent=error.message;};
 $("save").onclick=async()=>{const b=$("save");b.disabled=true;try{await api("save_script",{id:$("script-id").value||undefined,name:$("script-name").value,raw_url:$("script-url").value,enabled:true});$("script-id").value="";$("script-name").value="";$("script-url").value="";await refresh();toast("Script saved.");}catch(e){toast(e.message);}finally{b.disabled=false;}};
 $("refresh").onclick=()=>refresh().catch(e=>toast(e.message));
 $("logout").onclick=async()=>{await client.auth.signOut();location.reload();};
 async function setSession(s){session=s;$("login").hidden=!!s;$("app").hidden=!s;$("state").textContent=s?"Checking admin access…":"Signed out";if(s){try{await refresh();$("state").textContent="Admin verified";}catch(e){$("state").textContent="Access denied";$("login").hidden=false;$("app").hidden=true;$("login-error").textContent=e.message;}}}
 client.auth.onAuthStateChange((_e,s)=>queueMicrotask(()=>setSession(s)));
 client.auth.getSession().then(({data})=>setSession(data.session));
})();