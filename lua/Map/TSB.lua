-- =========================================================================
-- Pryvex Hub (Fixed)
-- Super Jump = แอนิเมชันปีน + Dash
-- + Open/Close button (Image + ลากได้อิสระ)
-- =========================================================================

local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
destroyOldUI("PryvexOpenClose") -- ปุ่มเก่าจาก library

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
-- 4. Open / Close Button (Image + ลากได้อิสระ)
-- =========================================================================
do
    -- ลบปุ่มเก่าที่ library สร้างไว้ (TextButton)
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local oldToggle = playerGui:FindFirstChild("PryvexOpenClose")
    if oldToggle then
        pcall(function() oldToggle:Destroy() end)
    end

    local ICON_ID = "rbxassetid://127972121421541"

    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "PryvexOpenClose"
    toggleGui.ResetOnSpawn = false
    toggleGui.IgnoreGuiInset = true
    toggleGui.DisplayOrder = 1000000
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    toggleGui.Parent = playerGui

    -- ใช้ ImageButton แทน TextButton + ขนาดจัตุรัส
    local toggleButton = Instance.new("ImageButton")
    toggleButton.Name = "PryvexIconButton"
    toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleButton.Position = UDim2.new(1, -50, 0.5, 0) -- ขวากลางจอ
    toggleButton.Size = UDim2.fromOffset(52, 52)       -- จัตุรัส สมส่วน
    toggleButton.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    toggleButton.BackgroundTransparency = 0.15
    toggleButton.BorderSizePixel = 0
    toggleButton.AutoButtonColor = false
    toggleButton.Image = ICON_ID
    toggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.ScaleType = Enum.ScaleType.Fit
    toggleButton.ZIndex = 10
    toggleButton.Parent = toggleGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = toggleButton

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 94, 115)
    stroke.Transparency = 0.65
    stroke.Thickness = 1.2
    stroke.Parent = toggleButton

    -- Padding เล็กน้อยให้ไอคอนไม่ติดขอบ
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = toggleButton

    -- ========== Drag ได้อิสระ ==========
    local dragging = false
    local dragStart, startPos
    local wasDragged = false

    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = toggleButton.Position
            wasDragged = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then
                wasDragged = true
            end
            toggleButton.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            dragStart = nil
            startPos = nil
        end
    end)

    -- ========== Click = Toggle Open/Close ==========
    toggleButton.Activated:Connect(function()
        if wasDragged then
            wasDragged = false
            return
        end
        if Window and type(Window.Minimize) == "function" then
            Window:Minimize()
        end
    end)
end

-- =========================================================================
-- 5. Super Jump = ปีน (Climb) + Dash
-- =========================================================================
local SuperJumpActive = false

local CLIMB_IDS = {
    "rbxassetid://180436334",
    "180436334",
}

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

    if hasClimb and hasDash then
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X,
            180,
            hrp.AssemblyLinearVelocity.Z
        )
    end
end)

-- =========================================================================
-- 6. แท็บ UI (ปรับไอคอนให้สมส่วนและสื่อความหมาย)
-- =========================================================================
local MainTab     = Window:AddTab({ Title = "Main",     Icon = "house" })
local FunTab      = Window:AddTab({ Title = "Fun",      Icon = "sparkles" })
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

print("[Pryvex Hub] Loaded — Super Jump = Climb + Dash | Open/Close button ready")
