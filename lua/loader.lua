-- Pryvex Hub Premium Loader
-- Verifies a Premium license before downloading the Pryvex Hub UI Library.
-- DeviceId is client-reported and can be spoofed; it is not hardware attestation.

local env = (getgenv and getgenv()) or _G

local function stop(message)
    warn("[Pryvex] " .. tostring(message))
    return nil
end

if type(env.Key) ~= "string" or env.Key == "" then
    return stop("Missing Premium key. Set getgenv().Key first.")
end
if type(env.DeviceId) ~= "string" or #env.DeviceId < 8 then
    return stop("Missing stable DeviceId (minimum 8 characters).")
end

local libraryURL = "https://raw.githubusercontent.com/CallMeJackTH/Pryvex-Hub/main/dist/PryvexHub.lua"
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

local initOk, License = pcall(createLicense)
if not initOk or type(License) ~= "table" or type(License.verify) ~= "function" then
    return stop("License module did not initialize correctly.")
end

local verifyOk, isPremium = pcall(License.verify)
if not verifyOk or isPremium ~= true then
    return stop("Premium verification failed. Pryvex Hub was not downloaded.")
end

-- Only after the server confirms Premium do we request the UI Library.
local downloadOk, librarySource = pcall(function()
    return game:HttpGet(libraryURL)
end)
if not downloadOk or type(librarySource) ~= "string" or librarySource == "" then
    return stop("Could not download Pryvex Hub.")
end

local libraryCompileOk, loadLibrary = pcall(loadstring, librarySource)
if not libraryCompileOk or type(loadLibrary) ~= "function" then
    return stop("Could not compile Pryvex Hub.")
end

local executeOk, library = pcall(loadLibrary)
if not executeOk or type(library) ~= "table" then
    return stop("Pryvex Hub initialization failed: " .. tostring(library))
end

env.PryvexHub = library
print("[Pryvex] Premium verified. Pryvex Hub is ready.")
return library
