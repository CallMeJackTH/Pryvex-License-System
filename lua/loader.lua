-- Pryvex Hub Premium Loader
-- License verification happens before the UI library is downloaded.
-- DeviceId is executor-local and client-reported, not hardware attestation.

local env = (getgenv and getgenv()) or _G

local function stop(message, shouldKick)
    message = tostring(message)
    warn("[Pryvex] " .. message)
    if shouldKick then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Pryvex License",
                Text = message,
                Duration = 5
            })
        end)
        task.wait(1)
        pcall(function()
            game:GetService("Players").LocalPlayer:Kick("[Pryvex] " .. message)
        end)
    end
    return nil
end

if type(env.Key) ~= "string" or env.Key == "" then
    return stop("Missing Premium key. Set getgenv().Key first.")
end

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

local verifyOk, isPremium, verifyCode, verifyMessage = pcall(License.verify)
if not verifyOk then
    return stop("License verification could not run: " .. tostring(isPremium))
end
if isPremium ~= true then
    local messages = {
        KEY_INVALID = "License key is invalid or not found.",
        KEY_DELETED = "This license key has been deleted.",
        KEY_DISABLED = "This license key has been disabled.",
        KEY_BANNED = "This license key has been banned.",
        KEY_EXPIRED = "This license key has expired.",
        DEVICE_MISMATCH = "This key is already bound to another device.",
        DEVICE_INVALID = "Device identifier is invalid."
    }
    local reason = messages[verifyCode] or verifyMessage or "License server is temporarily unavailable."
    local rejectCodes = {
        KEY_INVALID = true,
        KEY_DELETED = true,
        KEY_DISABLED = true,
        KEY_BANNED = true,
        KEY_EXPIRED = true,
        DEVICE_MISMATCH = true,
        DEVICE_INVALID = true
    }
    return stop(reason, rejectCodes[verifyCode] == true)
end

print("[Pryvex] Premium license verified.")

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

local windowOk, window = pcall(function()
    return library:CreateWindow({
        Title = "Pryvex Hub",
        SubTitle = "Premium",
        TabWidth = 150,
        Size = UDim2.fromOffset(580, 450),
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })
end)

if not windowOk or not window then
    return stop("UI window creation failed: " .. tostring(window))
end

pcall(function()
    if library.GUI then
        library.GUI.Enabled = true
        library.GUI.DisplayOrder = 999999
    end
    if window.Root then window.Root.Visible = true end
end)

local tabsOk, tabs = pcall(function()
    return {
        Main = window:AddTab({ Title = "หน้าหลัก", Icon = "house" }),
        Settings = window:AddTab({ Title = "ตั้งค่า", Icon = "settings" })
    }
end)
if not tabsOk then
    return stop("UI tab creation failed: " .. tostring(tabs))
end

env.PryvexWindow = window
env.PryvexTabs = tabs
pcall(function() window:SelectTab(1) end)

print("[Pryvex] Premium verified. Pryvex Hub UI is ready.")

if type(License.startMonitor) == "function" then
    License.startMonitor(function(code, serverMessage)
        local reasons = {
            KEY_INVALID = "License key is invalid.",
            KEY_DELETED = "License key was deleted.",
            KEY_DISABLED = "License key was disabled.",
            KEY_BANNED = "License key was banned.",
            KEY_EXPIRED = "License key expired.",
            DEVICE_MISMATCH = "License key is bound to another device.",
            DEVICE_INVALID = "Device identifier is invalid."
        }
        local reason = reasons[code] or serverMessage or "License is no longer valid."

        pcall(function()
            if env.PryvexWindow and env.PryvexWindow.Destroy then
                env.PryvexWindow:Destroy()
            end
            if library.GUI then library.GUI:Destroy() end
        end)

        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Pryvex License",
                Text = reason,
                Duration = 5
            })
        end)

        task.wait(1.5)
        pcall(function()
            game:GetService("Players").LocalPlayer:Kick(reason)
        end)
    end, 30)
end

return library
