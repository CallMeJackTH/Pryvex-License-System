-- =========================================================================
-- PRYVEX HUB | WORKSPACE
-- Logo on top of sidebar + rounded corners + single draggable toggle
-- =========================================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local LOGO_ID = "rbxassetid://127972121421541"
local SIDEBAR_LOGO_ID = "rbxassetid://88534329518644"

-- =========================================================================
-- 1. CLEANUP
-- =========================================================================

if _G.PryvexHubInstance then
    pcall(function()
        _G.PryvexHubInstance:Destroy()
    end)
    _G.PryvexHubInstance = nil
end

if type(getgenv) == "function" and getgenv().Fluent then
    pcall(function()
        getgenv().Fluent:Destroy()
    end)
end

if _G.SuperJumpConnection then
    pcall(function()
        _G.SuperJumpConnection:Disconnect()
    end)
    _G.SuperJumpConnection = nil
end

local function getParents()
    local list = {CoreGui, PlayerGui}

    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then
            table.insert(list, hui)
        end
    end

    return list
end

local function destroyOldUI(name)
    for _, parent in ipairs(getParents()) do
        local old = parent:FindFirstChild(name)

        if old then
            pcall(function()
                old:Destroy()
            end)
        end
    end
end

destroyOldUI("Fluent")
destroyOldUI("Pryvex Hub")
destroyOldUI("PryvexHub")
destroyOldUI("PryvexOpenClose")
destroyOldUI("PryvexSidebarLogo")

-- =========================================================================
-- 2. CONFIG SYSTEM
-- =========================================================================

local ConfigFolder = "Pryvex_Hub"
local ConfigFile = ConfigFolder .. "/config.json"

if type(makefolder) == "function"
    and type(isfolder) == "function"
    and not isfolder(ConfigFolder) then

    pcall(makefolder, ConfigFolder)
end

local SavedData = {}

local function SaveConfig()
    if type(writefile) ~= "function" then
        return
    end

    local success, json = pcall(function()
        return HttpService:JSONEncode(SavedData)
    end)

    if success and json then
        pcall(writefile, ConfigFile, json)
    end
end

local function LoadConfig()
    if type(readfile) ~= "function"
        or type(isfile) ~= "function"
        or not isfile(ConfigFile) then

        return false
    end

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(ConfigFile))
    end)

    if success and type(data) == "table" then
        SavedData = data
        return true
    end

    return false
end

local HasOldConfig = LoadConfig()

-- =========================================================================
-- 3. LOAD PRYVEX LIBRARY
-- =========================================================================

local URL = "https://raw.githubusercontent.com/CallMeJackTH/Pryvex-Hub/fluent-clone-integration/dist/PryvexHub.lua"

local success, Pryvex = pcall(function()
    return loadstring(game:HttpGet(URL))()
end)

if not success or not Pryvex then
    warn("[Pryvex] Failed to load UI Library")
    return
end

local Window = Pryvex:CreateWindow({
    Title = "Pryvex Hub",
    SubTitle = "Workspace",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

if not Window then
    warn("[Pryvex] Window creation failed")
    return
end

_G.PryvexHubInstance = Window

-- =========================================================================
-- 4. CREATE TABS
-- =========================================================================

local MainTab = Window:AddTab({
    Title = "Main",
    Icon = "home"
})

local FunTab = Window:AddTab({
    Title = "Fun",
    Icon = "gamepad-2"
})

local SettingsTab = Window:AddTab({
    Title = "Settings",
    Icon = "settings"
})

-- =========================================================================
-- 5. SIDEBAR LOGO
-- Rounded image corners
-- =========================================================================

do
    local TabFrame = Window.TabHolder and Window.TabHolder.Parent

    if TabFrame then
        local LOGO_HEIGHT = 120
        local LOGO_GAP = 10
        local OFFSET = LOGO_HEIGHT + LOGO_GAP

        -- Find original selector before creating custom frames
        local OriginalSelector

        for _, child in ipairs(TabFrame:GetChildren()) do
            if child ~= Window.TabHolder and child:IsA("Frame") then
                OriginalSelector = child
                break
            end
        end

        -- Logo container
        local LogoFrame = Instance.new("Frame")
        LogoFrame.Name = "PryvexSidebarBrand"
        LogoFrame.AnchorPoint = Vector2.new(0, 0)
        LogoFrame.Position = UDim2.fromOffset(0, 0)
        LogoFrame.Size = UDim2.new(1, 0, 0, LOGO_HEIGHT)
        LogoFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        LogoFrame.BorderSizePixel = 0
        LogoFrame.ClipsDescendants = true
        LogoFrame.ZIndex = 5
        LogoFrame.Parent = TabFrame

        -- Container rounded corners
        local LogoCorner = Instance.new("UICorner")
        LogoCorner.CornerRadius = UDim.new(0, 14)
        LogoCorner.Parent = LogoFrame

        -- Sidebar logo image
        local LogoImage = Instance.new("ImageLabel")
        LogoImage.Name = "PryvexLogo"
        LogoImage.AnchorPoint = Vector2.new(0.5, 0.5)
        LogoImage.Position = UDim2.fromScale(0.5, 0.5)
        LogoImage.Size = UDim2.fromScale(1, 1)
        LogoImage.BackgroundTransparency = 1
        LogoImage.BorderSizePixel = 0
        LogoImage.Image = SIDEBAR_LOGO_ID
        LogoImage.ScaleType = Enum.ScaleType.Fit
        LogoImage.ZIndex = 6
        LogoImage.Parent = LogoFrame

        -- NEW: Rounded corners for the actual logo image
        local LogoImageCorner = Instance.new("UICorner")
        LogoImageCorner.CornerRadius = UDim.new(0, 14)
        LogoImageCorner.Parent = LogoImage

        -- Move tab list below the logo
        Window.TabHolder.Position = UDim2.new(0, 0, 0, OFFSET)
        Window.TabHolder.Size = UDim2.new(1, 0, 1, -OFFSET)

        -- Preserve original selector
        if OriginalSelector then
            local SelectorContainer = Instance.new("Frame")
            SelectorContainer.Name = "PryvexSelectorContainer"
            SelectorContainer.Size = UDim2.new(0, 4, 1, -OFFSET)
            SelectorContainer.Position = UDim2.new(0, 0, 0, OFFSET)
            SelectorContainer.BackgroundTransparency = 1
            SelectorContainer.ClipsDescendants = false
            SelectorContainer.ZIndex = OriginalSelector.ZIndex
            SelectorContainer.Parent = TabFrame

            OriginalSelector.Parent = SelectorContainer
        end

        print("[Pryvex] Sidebar logo inserted with rounded corners")
    else
        warn("[Pryvex] Sidebar frame not found")
    end
end

-- =========================================================================
-- 6. CUSTOMIZE EXISTING TOGGLE
-- =========================================================================

task.spawn(function()
    local ToggleGui
    local StartTime = tick()

    while not ToggleGui and tick() - StartTime < 10 do
        for _, parent in ipairs(getParents()) do
            ToggleGui = parent:FindFirstChild("PryvexOpenClose")

            if ToggleGui then
                break
            end
        end

        if not ToggleGui then
            task.wait(0.1)
        end
    end

    if not ToggleGui then
        warn("[Pryvex] Toggle ScreenGui not found")
        return
    end

    local ToggleButton = ToggleGui:FindFirstChild("PryvexIconButton", true)

    if not (
        ToggleButton
        and (
            ToggleButton:IsA("TextButton")
            or ToggleButton:IsA("ImageButton")
        )
    ) then
        warn("[Pryvex] Existing toggle button not found")
        return
    end

    ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
    ToggleButton.Position = UDim2.new(0, 20, 0.5, 0)
    ToggleButton.Size = UDim2.fromOffset(52, 52)

    if ToggleButton:IsA("TextButton") then
        ToggleButton.Text = ""
        ToggleButton.TextTransparency = 1
    else
        ToggleButton.Image = ""
    end

    ToggleButton.BackgroundTransparency = 1
    ToggleButton.BorderSizePixel = 0
    ToggleButton.AutoButtonColor = false

    -- Remove existing outlines
    for _, descendant in ipairs(ToggleButton:GetDescendants()) do
        if descendant:IsA("UIStroke") then
            descendant:Destroy()
        end
    end

    local ExistingStroke = ToggleButton:FindFirstChildOfClass("UIStroke")

    if ExistingStroke then
        ExistingStroke:Destroy()
    end

    local ExistingCorner = ToggleButton:FindFirstChildOfClass("UICorner")

    if ExistingCorner then
        ExistingCorner:Destroy()
    end

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 14)
    Corner.Parent = ToggleButton

    local OldIcon = ToggleButton:FindFirstChild("PryvexToggleImage")

    if OldIcon then
        OldIcon:Destroy()
    end

    -- Custom toggle image
    local Icon = Instance.new("ImageLabel")
    Icon.Name = "PryvexToggleImage"
    Icon.AnchorPoint = Vector2.new(0, 0)
    Icon.Position = UDim2.fromScale(0, 0)
    Icon.Size = UDim2.fromScale(1, 1)
    Icon.BackgroundTransparency = 1
    Icon.BorderSizePixel = 0
    Icon.Image = LOGO_ID
    Icon.ScaleType = Enum.ScaleType.Stretch
    Icon.ZIndex = ToggleButton.ZIndex + 1
    Icon.Parent = ToggleButton

    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 14)
    IconCorner.Parent = Icon

    print("[Pryvex] Toggle customized")
end)

-- =========================================================================
-- 7. SUPER JUMP SYSTEM
-- =========================================================================

local SuperJumpActive = false

local CLIMB_IDS = {
    "rbxassetid://180436334",
    "180436334"
}

local DASH_IDS = {
    "rbxassetid://10480793962",
    "10480793962"
}

local function animMatches(animId, animationList)
    if not animId or type(animId) ~= "string" then
        return false
    end

    for _, id in ipairs(animationList) do
        if animId == id or animId:find(id, 1, true) then
            return true
        end
    end

    return false
end

_G.SuperJumpConnection = RunService.Heartbeat:Connect(function()
    if not SuperJumpActive then
        return
    end

    local character = LocalPlayer.Character

    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then
        return
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")

    if not animator then
        return
    end

    local hasClimb = false
    local hasDash = false

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
        local velocity = hrp.AssemblyLinearVelocity

        hrp.AssemblyLinearVelocity = Vector3.new(
            velocity.X,
            180,
            velocity.Z
        )
    end
end)

-- =========================================================================
-- 8. MAIN TAB
-- =========================================================================

MainTab:AddParagraph({
    Title = "Welcome",
    Content = "Pryvex Hub is ready."
})

local AutoFarmToggle = MainTab:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm",
    Default = SavedData["AutoFarm"] == true
})

AutoFarmToggle:OnChanged(function(Value)
    SavedData["AutoFarm"] = Value
    SaveConfig()

    print("[Pryvex] Auto Farm " .. (Value and "ON" or "OFF"))
end)

MainTab:AddButton({
    Title = "Test notification",
    Description = "Check that the UI is working",

    Callback = function()
        Pryvex:Notify({
            Title = "Pryvex Hub",
            Content = "Interface loaded successfully.",
            Duration = 5
        })
    end
})

-- =========================================================================
-- 9. FUN TAB
-- =========================================================================

FunTab:AddParagraph({
    Title = "Fun",
    Content = "Super Jump: Climb + Dash animation simultaneously."
})

local SuperJumpToggle = FunTab:AddToggle("SuperJumpToggle", {
    Title = "Super Jump",
    Description = "ปีนค้าง + Dash = พุ่งขึ้น",
    Default = SavedData["SuperJump"] == true
})

SuperJumpToggle:OnChanged(function(Value)
    SavedData["SuperJump"] = Value
    SuperJumpActive = Value
    SaveConfig()

    print("[Pryvex] Super Jump " .. (Value and "ON" or "OFF"))
end)

-- =========================================================================
-- 10. SETTINGS TAB
-- =========================================================================

SettingsTab:AddParagraph({
    Title = "Config",
    Content = "บันทึก / ลบการตั้งค่าบนเครื่อง"
})

SettingsTab:AddButton({
    Title = "Manual Save Config",
    Description = "บันทึกการตั้งค่าปัจจุบัน",

    Callback = function()
        SaveConfig()

        Pryvex:Notify({
            Title = "Config",
            Content = "บันทึกเรียบร้อย",
            Duration = 3
        })
    end
})

SettingsTab:AddButton({
    Title = "Reset / Delete Config",
    Description = "ลบไฟล์ config",

    Callback = function()
        if type(delfile) == "function"
            and type(isfile) == "function"
            and isfile(ConfigFile) then

            pcall(delfile, ConfigFile)
            SavedData = {}

            Pryvex:Notify({
                Title = "Config",
                Content = "ลบแล้ว — รันสคริปต์ใหม่",
                Duration = 4
            })
        else
            Pryvex:Notify({
                Title = "Config",
                Content = "ไม่มีไฟล์ หรือไม่รองรับ delfile",
                Duration = 3
            })
        end
    end
})

-- =========================================================================
-- 11. LOAD CONFIG
-- =========================================================================

if HasOldConfig then
    SuperJumpActive = SavedData["SuperJump"] == true

    Pryvex:Notify({
        Title = "Pryvex Hub",
        Content = "โหลดการตั้งค่าล่าสุดแล้ว",
        Duration = 4
    })
else
    Pryvex:Notify({
        Title = "Pryvex Hub",
        Content = "พร้อมใช้งาน",
        Duration = 3
    })
end

-- =========================================================================
-- 12. SELECT MAIN TAB
-- =========================================================================

task.defer(function()
    pcall(function()
        Window:SelectTab(1)
    end)
end)

print("[Pryvex Hub] Loaded successfully")
