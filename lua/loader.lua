-- Pryvex Hub Premium Loader
-- Automatically creates and persists a device identifier on first run.
-- The identifier is executor-local and client-reported, not hardware attestation.

local env = (getgenv and getgenv()) or _G

local function stop(message)
    warn("[Pryvex] " .. tostring(message))
    return nil
end

if type(env.Key) ~= "string" or env.Key == "" then
    return stop("Missing Premium key. Set getgenv().Key first.")
end

-- Remember this executor's device ID after the first successful creation.
local deviceFile = "Pryvex_DeviceId.txt"
if type(env.DeviceId) ~= "string" or #env.DeviceId < 8 then
    if type(isfile) ~= "function" or type(readfile) ~= "function"
        or type(writefile) ~= "function" then
        return stop("This executor must support isfile, readfile, and writefile to remember this device.")
    end

    local fileOk, deviceId = pcall(function()
        if isfile(deviceFile) then
            return readfile(deviceFile)
        end

        local newId = game:GetService("HttpService"):GenerateGUID(false)
        writefile(deviceFile, newId)
        return newId
    end)

    if not fileOk or type(deviceId) ~= "string" or #deviceId < 8 then
        return stop("Could not create or read the saved device ID.")
    end

    env.DeviceId = deviceId
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

-- Download the UI library only after Premium verification succeeds.
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
