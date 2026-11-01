-- Pryvex License Loader
-- Configure getgenv().Key, getgenv().DeviceId and getgenv().ScriptURL before loading.
-- DeviceId is client-reported and can be spoofed; it is not hardware attestation.

local env = (getgenv and getgenv()) or _G

local function stop(message)
    warn("[Pryvex] " .. tostring(message))
    return
end

if type(env.Key) ~= "string" or env.Key == "" then
    return stop("Missing license key. Set getgenv().Key first.")
end

if type(env.DeviceId) ~= "string" or #env.DeviceId < 8 then
    return stop("Missing stable DeviceId (minimum 8 characters).")
end

if type(env.ScriptURL) ~= "string" or not env.ScriptURL:match("^https://") then
    return stop("Missing ScriptURL. Set getgenv().ScriptURL to your authorized script's HTTPS raw URL.")
end

local helperURL = "https://raw.githubusercontent.com/CallMeJackTH/Pryvex-License-System/main/lua/PryvexLicense.lua"

local ok, helperSource = pcall(function()
    return game:HttpGet(helperURL)
end)
if not ok or type(helperSource) ~= "string" or helperSource == "" then
    return stop("Could not download the license module.")
end

local compileOk, createLicense = pcall(loadstring, helperSource)
if not compileOk or type(createLicense) ~= "function" then
    return stop("Could not compile the license module.")
end

local runOk, License = pcall(createLicense)
if not runOk or type(License) ~= "table" or type(License.verify) ~= "function" then
    return stop("License module did not initialize correctly.")
end

local verifyOk, isValid = pcall(License.verify)
if not verifyOk or isValid ~= true then
    return stop("License verification failed. Script was not started.")
end

local downloadOk, scriptSource = pcall(function()
    return game:HttpGet(env.ScriptURL)
end)
if not downloadOk or type(scriptSource) ~= "string" or scriptSource == "" then
    return stop("Could not download the authorized script.")
end

local scriptCompileOk, runScript = pcall(loadstring, scriptSource)
if not scriptCompileOk or type(runScript) ~= "function" then
    return stop("Could not compile the authorized script.")
end

local executeOk, executeError = pcall(runScript)
if not executeOk then
    return stop("The authorized script encountered an error: " .. tostring(executeError))
end
