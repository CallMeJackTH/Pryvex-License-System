-- =========================================================================
-- Pryvex Hub (Fixed)
-- Super Jump = แอนิเมชันปีน + Dash
-- =========================================================================

local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

-- =========================================================================
-- 1. กันรันซ้อน
-- =========================================================================
if _G.PryvexHubInstance then
    pcall(function() _G.PryvexHubInstance:Destroy() end)
    _G.PryvexHubInstance = nil
end

if _G.SuperJumpConnection then
    pcall(function() _G.SuperJumpConnection:Disconnect() end)
    _G.SuperJumpConnection = nil
end

local function destroyOldUI(name)
    local fromCore = CoreGui:FindFirstChild(name)
    if fromCore then pcall(function() fromCore:Destroy() end) end
    if LocalPlayer then
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local fromPg = pg:FindFirstChild(name)
            if fromPg then pcall(function() fromPg:Destroy() end) end
        end
    end
end

destroyOldUI("Fluent")
destroyOldUI("Pryvex Hub")
destroyOldUI("PryvexHub")

-- =========================================================================
-- 2. Save / Load Config
-- =========================================================================
local ConfigFolder = "Pryvex_Hub"
local ConfigFile   = ConfigFolder .. "/config.json"

if type(makefolder) == "function" and not isfolder(ConfigFolder) then
    pcall(makefolder, ConfigFolder)
end

local SavedData = {}

local function SaveConfig()
    if type(writefile) ~= "function" then return end
    local ok, json = pcall(function()
        return HttpService:JSONEncode(SavedData)
    end)
    if ok and json then
        pcall(writefile, ConfigFile, json)
    end
end

local function LoadConfig()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return false end
    if not isfile(ConfigFile) then return false end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(ConfigFile))
    end)
    if ok and type(data) == "table" then
        SavedData = data
        return true
    end
    return false
end

local HasOldConfig = LoadConfig()

-- =========================================================================
-- 3. โหลด UI
-- =========================================================================
local URL = "https://raw.githubusercontent.com/CallMeJackTH/Pryvex-Hub/fluent-clone-integration/dist/PryvexHub.lua"
local Pryvex = loadstring(game:HttpGet(URL))()

local Window = Pryvex:CreateWindow({
    Title       = "Pryvex Hub",
    SubTitle    = "Workspace",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(580, 460),
    Acrylic     = false,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

_G.PryvexHubInstance = Window

-- =========================================================================
-- 4. Super Jump = ปีน (Climb) + Dash
-- =========================================================================
local SuperJumpActive = false

-- Climb
local CLIMB_IDS = {
    "rbxassetid://180436334",
    "180436334",
}

-- Dash (เดิมใส่ผิดว่าเป็นต่อย)
local DASH_IDS = {
    "rbxassetid://10480793962",
    "10480793962",
}

local function animMatches(animId, list)
    if not animId or type(animId) ~= "string" then return false end
    for _, id in ipairs(list) do
        if animId == id or animId:find(id, 1, true) then
            return true
        end
    end
    return false
end

_G.SuperJumpConnection = RunService.Heartbeat:Connect(function()
    if not SuperJumpActive then return end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp      = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    local hasClimb = false
    local hasDash  = false

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local anim = track.Animation
        if anim and anim.AnimationId then
            local id = anim.AnimationId
            if animMatches(id, CLIMB_IDS) then
                hasClimb = true
            elseif animMatches(id, DASH_IDS) then
                hasDash = true
            end
        end
    end

    -- ปีน + Dash พร้อมกัน → พุ่งขึ้น
    if hasClimb and hasDash then
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X,
            180,
            hrp.AssemblyLinearVelocity.Z
        )
    end
end)

-- =========================================================================
-- 5. แท็บ UI
-- =========================================================================
local MainTab     = Window:AddTab({ Title = "Main",     Icon = "home" })
local FunTab      = Window:AddTab({ Title = "Fun",      Icon = "smile" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

MainTab:AddParagraph({
    Title   = "Welcome",
    Content = "Pryvex Hub is ready."
})

local AutoFarmToggle = MainTab:AddToggle("AutoFarmToggle", {
    Title   = "Auto Farm",
    Default = SavedData["AutoFarm"] == true
})

AutoFarmToggle:OnChanged(function(Value)
    SavedData["AutoFarm"] = Value
    SaveConfig()
    print("[Pryvex] Auto Farm " .. (Value and "ON" or "OFF"))
end)

MainTab:AddButton({
    Title       = "Test notification",
    Description = "Check that the UI is working",
    Callback = function()
        Pryvex:Notify({
            Title    = "Pryvex Hub",
            Content  = "Interface loaded successfully.",
            Duration = 5
        })
    end
})

FunTab:AddParagraph({
    Title   = "Fun",
    Content = "Super Jump: แอนิเมชันปีน + Dash พร้อมกัน = พุ่งขึ้นฟ้า"
})

local SuperJumpToggle = FunTab:AddToggle("SuperJumpToggle", {
    Title       = "Super Jump",
    Description = "ปีนค้าง + Dash = พุ่งขึ้น",
    Default     = SavedData["SuperJump"] == true
})

SuperJumpToggle:OnChanged(function(Value)
    SavedData["SuperJump"] = Value
    SaveConfig()
    SuperJumpActive = Value
    print("[Pryvex] Super Jump " .. (Value and "ON" or "OFF"))
end)

SettingsTab:AddParagraph({
    Title   = "Config",
    Content = "บันทึก/ลบการตั้งค่าบนเครื่อง"
})

SettingsTab:AddButton({
    Title       = "Manual Save Config",
    Description = "บันทึกการตั้งค่าปัจจุบัน",
    Callback = function()
        SaveConfig()
        Pryvex:Notify({ Title = "Config", Content = "บันทึกเรียบร้อย", Duration = 3 })
    end
})

SettingsTab:AddButton({
    Title       = "Reset / Delete Config",
    Description = "ลบไฟล์ config",
    Callback = function()
        if type(delfile) == "function" and type(isfile) == "function" and isfile(ConfigFile) then
            pcall(delfile, ConfigFile)
            SavedData = {}
            Pryvex:Notify({
                Title    = "Config",
                Content  = "ลบแล้ว — รันสคริปต์ใหม่",
                Duration = 4
            })
        else
            Pryvex:Notify({
                Title    = "Config",
                Content  = "ไม่มีไฟล์ หรือไม่รองรับ delfile",
                Duration = 3
            })
        end
    end
})

if HasOldConfig then
    SuperJumpActive = SavedData["SuperJump"] == true
    Pryvex:Notify({
        Title    = "Pryvex Hub",
        Content  = "โหลดการตั้งค่าล่าสุดแล้ว",
        Duration = 4
    })
else
    Pryvex:Notify({
        Title    = "Pryvex Hub",
        Content  = "พร้อมใช้งาน",
        Duration = 3
    })
end

print("[Pryvex Hub] Loaded — Super Jump = Climb + Dash")

