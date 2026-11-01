-- Pryvex Protected Pre-Loader
-- Verifies the Premium license, redeems the protected handoff code,
-- compiles the returned source, then runs it.
-- Delivered client code can still be inspected at runtime; this is not DRM.

local env = (getgenv and getgenv()) or _G
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ENDPOINT = "https://yfsmtoetvajschaeyagc.supabase.co/functions/v1/script-gate"
local LICENSE_MODULE_URL = "https://raw.githubusercontent.com/CallMeJackTH/Pryvex-License-System/main/lua/PryvexLicense.lua"
local DEVICE_FILE = "Pryvex_DeviceId.txt"

local function getRequest()
    if syn and type(syn.request) == "function" then return syn.request end
    if type(http_request) == "function" then return http_request end
    if type(request) == "function" then return request end
    return nil
end

local function stop(message)
    warn("[Pryvex Protected] " .. tostring(message))
    return nil
end

-- Build a lightweight pre-loader. It intentionally does not depend on Pryvex Hub UI.
local gui, statusLabel, detailLabel, progressFill
local function createPreloader()
    local player = Players.LocalPlayer
    local parent
    pcall(function() parent = game:GetService("CoreGui") end)
    if not parent and player then
        parent = player:FindFirstChildOfClass("PlayerGui")
    end
    if not parent then return end

    local old = parent:FindFirstChild("PryvexPreLoader")
    if old then old:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name = "PryvexPreLoader"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100000
    gui.Parent = parent

    local card = Instance.new("Frame")
    card.Name = "Panel"
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(350, 164)
    card.BackgroundColor3 = Color3.fromRGB(15, 17, 25)
    card.BorderSizePixel = 0
    card.Parent = gui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(55, 63, 86)
    stroke.Transparency = 0.25
    stroke.Parent = card

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(20, 15)
    title.Size = UDim2.new(1, -40, 0, 28)
    title.Font = Enum.Font.GothamBold
    title.Text = "PRYVEX  /  LOADER"
    title.TextColor3 = Color3.fromRGB(238, 241, 255)
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    detailLabel = Instance.new("TextLabel")
    detailLabel.BackgroundTransparency = 1
    detailLabel.Position = UDim2.fromOffset(20, 48)
    detailLabel.Size = UDim2.new(1, -40, 0, 19)
    detailLabel.Font = Enum.Font.Gotham
    detailLabel.Text = "Preparing secure session..."
    detailLabel.TextColor3 = Color3.fromRGB(151, 161, 185)
    detailLabel.TextSize = 12
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.Parent = card

    statusLabel = Instance.new("TextLabel")
    statusLabel.BackgroundTransparency = 1
    statusLabel.Position = UDim2.fromOffset(20, 78)
    statusLabel.Size = UDim2.new(1, -40, 0, 20)
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.Text = "Initializing"
    statusLabel.TextColor3 = Color3.fromRGB(220, 226, 245)
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = card

    local track = Instance.new("Frame")
    track.Position = UDim2.fromOffset(20, 111)
    track.Size = UDim2.new(1, -40, 0, 7)
    track.BackgroundColor3 = Color3.fromRGB(38, 43, 58)
    track.BorderSizePixel = 0
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.fromScale(0.04, 1)
    progressFill.BackgroundColor3 = Color3.fromRGB(126, 112, 255)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = track
    Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

    local footer = Instance.new("TextLabel")
    footer.BackgroundTransparency = 1
    footer.Position = UDim2.fromOffset(20, 128)
    footer.Size = UDim2.new(1, -40, 0, 20)
    footer.Font = Enum.Font.Gotham
    footer.Text = "PLACE ID: " .. tostring(game.PlaceId)
    footer.TextColor3 = Color3.fromRGB(105, 115, 139)
    footer.TextSize = 10
    footer.TextXAlignment = Enum.TextXAlignment.Left
    footer.Parent = card
end

local function setProgress(percent, status, detail)
    if statusLabel then statusLabel.Text = status or "" end
    if detailLabel then detailLabel.Text = detail or "" end
    if progressFill then
        progressFill:TweenSize(
            UDim2.new(math.clamp(percent / 100, 0.04, 1), 0, 1, 0),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
    end
end

local function closePreloader()
    if gui then
        gui:Destroy()
        gui = nil
    end
end

createPreloader()
setProgress(8, "Checking environment", "Preparing executor connection...")

local httpRequest = getRequest()
if not httpRequest then
    setProgress(100, "Unsupported executor", "HTTP request function is unavailable.")
    task.wait(2)
    closePreloader()
    return stop("This executor does not expose a supported HTTP request function.")
end

-- A handoff code is required before any protected source can be delivered.
local code = env.PryvexHandoffCode
if type(code) ~= "string" or not code:match("^[%da-fA-F]+$") or #code ~= 64 then
    setProgress(100, "Missing access code", "Set getgenv().PryvexHandoffCode first.")
    task.wait(2)
    closePreloader()
    return stop("Set getgenv().PryvexHandoffCode to the code issued by the admin panel.")
end

-- Reuse the same executor-local device ID used by lua/loader.lua.
setProgress(18, "Preparing device", "Loading saved device identifier...")
if type(env.DeviceId) ~= "string" or #env.DeviceId < 8 then
    if type(isfile) ~= "function" or type(readfile) ~= "function" or type(writefile) ~= "function" then
        closePreloader()
        return stop("Executor must support isfile, readfile and writefile for device binding.")
    end
    local fileOk, deviceId = pcall(function()
        if isfile(DEVICE_FILE) then
            return readfile(DEVICE_FILE)
        end
        local newId = HttpService:GenerateGUID(false)
        writefile(DEVICE_FILE, newId)
        return newId
    end)
    if not fileOk or type(deviceId) ~= "string" or #deviceId < 8 then
        closePreloader()
        return stop("Could not create or read the saved device ID.")
    end
    env.DeviceId = deviceId
end

-- Verify the existing Premium license before redeeming the protected script.
setProgress(30, "Verifying license", "Contacting Pryvex license service...")
local licenseDownloadOk, licenseSource = pcall(function()
    return game:HttpGet(LICENSE_MODULE_URL)
end)
if not licenseDownloadOk or type(licenseSource) ~= "string" or licenseSource == "" then
    closePreloader()
    return stop("Could not download the license module.")
end

local licenseCompileOk, createLicense = pcall(loadstring, licenseSource)
if not licenseCompileOk or type(createLicense) ~= "function" then
    closePreloader()
    return stop("Could not compile the license module.")
end

local licenseInitOk, License = pcall(createLicense)
if not licenseInitOk or type(License) ~= "table" or type(License.verify) ~= "function" then
    closePreloader()
    return stop("License module did not initialize correctly.")
end

local verifyCallOk, valid, verifyCode, verifyMessage = pcall(License.verify)
if not verifyCallOk or valid ~= true then
    local reasons = {
        KEY_INVALID = "License key is invalid.",
        KEY_DELETED = "License key was deleted.",
        KEY_DISABLED = "License key is disabled.",
        KEY_BANNED = "License key is banned.",
        KEY_EXPIRED = "License key has expired.",
        DEVICE_MISMATCH = "License is bound to another device.",
        DEVICE_INVALID = "Device identifier is invalid."
    }
    local message = reasons[verifyCode] or verifyMessage or "License verification failed."
    setProgress(100, "License rejected", message)
    task.wait(2)
    closePreloader()
    return stop(message)
end

setProgress(48, "License verified", "Checking protected script access...")

local requestOk, response = pcall(function()
    return httpRequest({
        Url = ENDPOINT,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            action = "redeem",
            code = code
        })
    })
end)

if not requestOk or type(response) ~= "table" then
    setProgress(100, "Connection failed", "Could not contact protected script service.")
    task.wait(2)
    closePreloader()
    return stop("Could not contact the protected script service.")
end

local status = tonumber(response.StatusCode or response.Status or 0) or 0
if status < 200 or status >= 300 then
    local message = "Access code rejected."
    if type(response.Body) == "string" then
        local decodedOk, decoded = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if decodedOk and type(decoded) == "table" and decoded.error then
            message = tostring(decoded.error)
        end
    end
    setProgress(100, "Access denied", message)
    task.wait(2)
    closePreloader()
    return stop(message)
end

setProgress(72, "Downloading protected script", "Source received from Pryvex...")
local decodeOk, payload = pcall(function()
    return HttpService:JSONDecode(response.Body or "")
end)
if not decodeOk or type(payload) ~= "table" or payload.success ~= true
    or type(payload.source) ~= "string" or payload.source == "" then
    setProgress(100, "Invalid response", "Protected service returned an invalid payload.")
    task.wait(2)
    closePreloader()
    return stop("Protected service returned an invalid payload.")
end

-- Clear the local code after successful redemption. Permanent codes remain reusable
-- on the server; this only prevents accidental reuse by this running loader.
env.PryvexHandoffCode = nil

setProgress(88, "Compiling script", "Validating Lua source...")
local compileOk, chunk = pcall(loadstring, payload.source)
if not compileOk or type(chunk) ~= "function" then
    setProgress(100, "Compile failed", "The delivered script could not be compiled.")
    task.wait(2)
    closePreloader()
    return stop("Could not compile the delivered Lua script.")
end

setProgress(96, "Starting script", "Protected script is ready.")
task.wait(0.35)
closePreloader()

local runOk, result = pcall(chunk)
if not runOk then
    return stop("Script error: " .. tostring(result))
end

return result
