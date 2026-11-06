-- =========================================================================
-- PRYVEX HUB | HOME + ESP
-- Clean Home UI + Sidebar Logo + Rounded Toggle + Player ESP
-- =========================================================================

local CoreGui     = game:GetService("CoreGui")
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

local LOGO_ID         = "rbxassetid://127972121421541"
local SIDEBAR_LOGO_ID = "rbxassetid://88534329518644"

-- =========================================================================
-- 1. CLEANUP
-- =========================================================================
if _G.PryvexHubInstance then
    pcall(function() _G.PryvexHubInstance:Destroy() end)
    _G.PryvexHubInstance = nil
end

if _G.SuperJumpConnection then
    pcall(function() _G.SuperJumpConnection:Disconnect() end)
    _G.SuperJumpConnection = nil
end

if _G.PryvexESPConnection then
    pcall(function() _G.PryvexESPConnection:Disconnect() end)
    _G.PryvexESPConnection = nil
end

if _G.PryvexBhopConnection then
    pcall(function() _G.PryvexBhopConnection:Disconnect() end)
    _G.PryvexBhopConnection = nil
end

if _G.PryvexBhopJumpConn then
    pcall(function() _G.PryvexBhopJumpConn:Disconnect() end)
    _G.PryvexBhopJumpConn = nil
end

if _G.PryvexAimbotConnection then
    pcall(function() _G.PryvexAimbotConnection:Disconnect() end)
    _G.PryvexAimbotConnection = nil
end

if _G.PryvexAimbotUnbind then
    pcall(_G.PryvexAimbotUnbind)
    _G.PryvexAimbotUnbind = nil
end
pcall(function()
    RunService:UnbindFromRenderStep("PryvexAimbot")
end)

local function getParents()
    local parents = { CoreGui, PlayerGui }
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then
            table.insert(parents, hui)
        end
    end
    return parents
end

local function destroyOldUI(name)
    for _, parent in ipairs(getParents()) do
        local old = parent:FindFirstChild(name)
        if old then
            pcall(function() old:Destroy() end)
        end
    end
end

destroyOldUI("Fluent")
destroyOldUI("Pryvex Hub")
destroyOldUI("PryvexHub")
destroyOldUI("PryvexOpenClose")
destroyOldUI("PryvexSidebarLogo")
destroyOldUI("PryvexCrosshair")
destroyOldUI("PryvexFlickButton")
destroyOldUI("PryvexFOVCircle")

-- =========================================================================
-- 2. LOAD PRYVEX LIBRARY
-- =========================================================================
local URL = "https://raw.githubusercontent.com/CallMeJackTH/Pryvex-Hub/fluent-clone-integration/dist/PryvexHub.lua"

local success, Pryvex = pcall(function()
    return loadstring(game:HttpGet(URL))()
end)

if not success or not Pryvex then
    warn("[Pryvex] Failed to load UI Library")
    return
end

-- =========================================================================
-- 3. CREATE WINDOW
-- =========================================================================
local Window = Pryvex:CreateWindow({
    Title       = "Flick Premium",
    SubTitle    = "Pryvex",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(580, 460),
    Acrylic     = false,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

if not Window then
    warn("[Pryvex] Window creation failed")
    return
end

_G.PryvexHubInstance = Window

-- =========================================================================
-- 4. TABS
-- =========================================================================
local HomeTab = Window:AddTab({ Title = "Home", Icon = "home" })
local AimbotTab = Window:AddTab({ Title = "Flick Mode", Icon = "crosshair" })
local ESPTab  = Window:AddTab({ Title = "ESP",  Icon = "eye" })
local MiscTab = Window:AddTab({ Title = "Misc", Icon = "settings" })

-- =========================================================================
-- 5. SIDEBAR LOGO
-- =========================================================================
do
    local TabFrame = Window.TabHolder and Window.TabHolder.Parent

    if TabFrame then
        local LOGO_HEIGHT = 120
        local LOGO_GAP    = 10
        local OFFSET      = LOGO_HEIGHT + LOGO_GAP

        local OriginalSelector
        for _, child in ipairs(TabFrame:GetChildren()) do
            if child ~= Window.TabHolder and child:IsA("Frame") then
                OriginalSelector = child
                break
            end
        end

        local LogoFrame = Instance.new("Frame")
        LogoFrame.Name                   = "PryvexSidebarBrand"
        LogoFrame.Position               = UDim2.fromOffset(0, 0)
        LogoFrame.Size                   = UDim2.new(1, 0, 0, LOGO_HEIGHT)
        LogoFrame.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        LogoFrame.BorderSizePixel        = 0
        LogoFrame.ClipsDescendants       = true
        LogoFrame.ZIndex                 = 5
        LogoFrame.Parent                 = TabFrame

        local LogoCorner = Instance.new("UICorner")
        LogoCorner.CornerRadius = UDim.new(0, 14)
        LogoCorner.Parent = LogoFrame

        local LogoImage = Instance.new("ImageLabel")
        LogoImage.Name                 = "PryvexLogo"
        LogoImage.AnchorPoint          = Vector2.new(0.5, 0.5)
        LogoImage.Position             = UDim2.fromScale(0.5, 0.5)
        LogoImage.Size                 = UDim2.fromScale(1, 1)
        LogoImage.BackgroundTransparency = 1
        LogoImage.BorderSizePixel      = 0
        LogoImage.Image                = SIDEBAR_LOGO_ID
        LogoImage.ScaleType            = Enum.ScaleType.Fit
        LogoImage.ZIndex               = 6
        LogoImage.Parent               = LogoFrame

        local ImageCorner = Instance.new("UICorner")
        ImageCorner.CornerRadius = UDim.new(0, 14)
        ImageCorner.Parent = LogoImage

        Window.TabHolder.Position = UDim2.new(0, 0, 0, OFFSET)
        Window.TabHolder.Size     = UDim2.new(1, 0, 1, -OFFSET)

        if OriginalSelector then
            local SelectorContainer = Instance.new("Frame")
            SelectorContainer.Name                   = "PryvexSelectorContainer"
            SelectorContainer.Size                   = UDim2.new(0, 4, 1, -OFFSET)
            SelectorContainer.Position               = UDim2.new(0, 0, 0, OFFSET)
            SelectorContainer.BackgroundTransparency = 1
            SelectorContainer.ZIndex                 = OriginalSelector.ZIndex
            SelectorContainer.Parent                 = TabFrame
            OriginalSelector.Parent = SelectorContainer
        end
    else
        warn("[Pryvex] Sidebar frame not found")
    end
end

-- =========================================================================
-- 6. CUSTOMIZE FLOATING TOGGLE
-- =========================================================================
task.spawn(function()
    local ToggleGui
    local StartTime = tick()

    while not ToggleGui and tick() - StartTime < 10 do
        for _, parent in ipairs(getParents()) do
            ToggleGui = parent:FindFirstChild("PryvexOpenClose")
            if ToggleGui then break end
        end
        if not ToggleGui then task.wait(0.1) end
    end

    if not ToggleGui then
        warn("[Pryvex] Toggle GUI not found")
        return
    end

    local ToggleButton = ToggleGui:FindFirstChild("PryvexIconButton", true)
    if not ToggleButton then
        warn("[Pryvex] Toggle button not found")
        return
    end

    if not (ToggleButton:IsA("TextButton") or ToggleButton:IsA("ImageButton")) then
        return
    end

    ToggleButton.AnchorPoint           = Vector2.new(0, 0.5)
    ToggleButton.Position              = UDim2.new(0, 20, 0.5, 0)
    ToggleButton.Size                  = UDim2.fromOffset(52, 52)
    ToggleButton.BackgroundTransparency = 1
    ToggleButton.BorderSizePixel       = 0
    ToggleButton.AutoButtonColor       = false

    if ToggleButton:IsA("TextButton") then
        ToggleButton.Text = ""
        ToggleButton.TextTransparency = 1
    else
        ToggleButton.Image = ""
    end

    for _, d in ipairs(ToggleButton:GetDescendants()) do
        if d:IsA("UIStroke") then d:Destroy() end
    end

    local OldCorner = ToggleButton:FindFirstChildOfClass("UICorner")
    if OldCorner then OldCorner:Destroy() end

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 14)
    Corner.Parent = ToggleButton

    local OldIcon = ToggleButton:FindFirstChild("PryvexToggleImage")
    if OldIcon then OldIcon:Destroy() end

    local Icon = Instance.new("ImageLabel")
    Icon.Name                 = "PryvexToggleImage"
    Icon.Size                 = UDim2.fromScale(1, 1)
    Icon.BackgroundTransparency = 1
    Icon.BorderSizePixel      = 0
    Icon.Image                = LOGO_ID
    Icon.ScaleType            = Enum.ScaleType.Stretch
    Icon.ZIndex               = ToggleButton.ZIndex + 1
    Icon.Parent               = ToggleButton

    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 14)
    IconCorner.Parent = Icon

    print("[Pryvex] Toggle customized")
end)

-- =========================================================================
-- 7. ESP SYSTEM
-- =========================================================================
local ESPConfig = {
    Enabled      = false,
    MaxDistance  = 2000,
    ShowName     = true,
    ShowDistance = true,
    FillColor    = Color3.fromRGB(40, 150, 255),
    OutlineColor = Color3.fromRGB(255, 255, 255),
}

-- Crosshair (เป้ากลางจอ)
local CrosshairConfig = {
    Enabled = false,
    Size    = 8,   -- แขนแต่ละด้าน (px)
    Gap     = 3,   -- ช่องว่างกลาง
    Thickness = 2,
    Color   = Color3.fromRGB(0, 255, 128),
}

local CrosshairGui = nil

local function DestroyCrosshair()
    if CrosshairGui then
        pcall(function() CrosshairGui:Destroy() end)
        CrosshairGui = nil
    end
end

local function CreateCrosshair()
    DestroyCrosshair()

    local parent = nil
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then parent = hui end
    end
    if not parent then
        parent = game:GetService("CoreGui")
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "PryvexCrosshair"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = 999998
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = parent
    CrosshairGui = screen

    local function makeLine(name, size, pos)
        local f = Instance.new("Frame")
        f.Name = name
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = pos
        f.Size = size
        f.BackgroundColor3 = CrosshairConfig.Color
        f.BackgroundTransparency = 0
        f.BorderSizePixel = 0
        f.ZIndex = 10
        f.Parent = screen
        return f
    end

    local s = CrosshairConfig.Size
    local g = CrosshairConfig.Gap
    local t = CrosshairConfig.Thickness
    local center = UDim2.fromScale(0.5, 0.5)

    -- บน ล่าง ซ้าย ขวา
    makeLine("Top",    UDim2.fromOffset(t, s), UDim2.new(0.5, 0, 0.5, -(g + s/2)))
    makeLine("Bottom", UDim2.fromOffset(t, s), UDim2.new(0.5, 0, 0.5,  (g + s/2)))
    makeLine("Left",   UDim2.fromOffset(s, t), UDim2.new(0.5, -(g + s/2), 0.5, 0))
    makeLine("Right",  UDim2.fromOffset(s, t), UDim2.new(0.5,  (g + s/2), 0.5, 0))

    -- จุดกลางเล็กๆ
    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = center
    dot.Size = UDim2.fromOffset(2, 2)
    dot.BackgroundColor3 = CrosshairConfig.Color
    dot.BorderSizePixel = 0
    dot.ZIndex = 11
    dot.Parent = screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot
end

local function SetCrosshair(enabled)
    CrosshairConfig.Enabled = enabled
    if enabled then
        CreateCrosshair()
    else
        DestroyCrosshair()
    end
end

local ESPObjects = {} -- [player] = { Highlight, Billboard, Label }

local function RemoveESP(player)
    local obj = ESPObjects[player]
    if not obj then return end
    pcall(function()
        if obj.Highlight then obj.Highlight:Destroy() end
        if obj.Billboard then obj.Billboard:Destroy() end
    end)
    ESPObjects[player] = nil
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    RemoveESP(player)

    local character = player.Character
    if not character then return end

    local head = character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local highlight = Instance.new("Highlight")
    highlight.Name                = "PryvexESP"
    highlight.Adornee             = character
    highlight.FillColor           = ESPConfig.FillColor
    highlight.OutlineColor        = ESPConfig.OutlineColor
    highlight.FillTransparency    = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent              = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name        = "PryvexESPInfo"
    billboard.Adornee     = head
    billboard.Size        = UDim2.fromOffset(160, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = ESPConfig.MaxDistance
    billboard.Parent      = head

    local label = Instance.new("TextLabel")
    label.Size                   = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3             = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.2
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = 11
    label.Text                   = player.DisplayName
    label.Parent                 = billboard

    ESPObjects[player] = {
        Highlight = highlight,
        Billboard = billboard,
        Label     = label,
    }
end

local function ClearAllESP()
    for player in pairs(ESPObjects) do
        RemoveESP(player)
    end
end

local function RefreshESPColors()
    for _, obj in pairs(ESPObjects) do
        if obj.Highlight then
            obj.Highlight.FillColor = ESPConfig.FillColor
            obj.Highlight.OutlineColor = ESPConfig.OutlineColor
        end
    end
end

local function RefreshCrosshairColor()
    if not CrosshairGui then return end
    for _, child in ipairs(CrosshairGui:GetChildren()) do
        if child:IsA("Frame") then
            child.BackgroundColor3 = CrosshairConfig.Color
        end
    end
end

local function UpdateESP()
    Camera = workspace.CurrentCamera

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not ESPConfig.Enabled then
            RemoveESP(player)
            continue
        end

        local obj = ESPObjects[player]
        if not obj
            or not obj.Highlight
            or not obj.Highlight.Parent
            or not obj.Billboard
            or not obj.Billboard.Parent
        then
            CreateESP(player)
            obj = ESPObjects[player]
        end

        if not obj or not player.Character then continue end

        local root = player.Character:FindFirstChild("HumanoidRootPart")
            or player.Character:FindFirstChild("Head")
        if not root then continue end

        local distance = (Camera.CFrame.Position - root.Position).Magnitude
        local show = distance <= ESPConfig.MaxDistance

        obj.Highlight.Enabled = show
        obj.Billboard.Enabled = show
        obj.Billboard.MaxDistance = ESPConfig.MaxDistance

        if show then
            local parts = {}
            if ESPConfig.ShowName then
                table.insert(parts, player.DisplayName)
            end
            if ESPConfig.ShowDistance then
                table.insert(parts, math.floor(distance) .. " studs")
            end
            obj.Label.Text = table.concat(parts, "\n")
        end
    end
end

_G.PryvexESPConnection = RunService.RenderStepped:Connect(UpdateESP)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

local function HookCharacter(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPConfig.Enabled then
            CreateESP(player)
        end
    end)
end

Players.PlayerAdded:Connect(HookCharacter)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        HookCharacter(p)
    end
end

-- =========================================================================
-- 8. AIMBOT + HITBOX EXPAND (simple — no Hold/Toggle)
-- =========================================================================
local AimbotConfig = {
    TargetPart  = "Head",
    WallCheck   = false,
    MaxDistance = 2000,
    FOV         = 250,
}

local FlickUntil = 0
local FlickDuration = 0.12
local FlickKeyMouse = Enum.UserInputType.MouseButton2
local FlickUseMouse = true
local FlickKeyKeyboard = Enum.KeyCode.E

local HitboxConfig = {
    Enabled = false,
    Scale   = 0.9,
}

local HitboxOriginal = {}

local function IsAlivePlayer(player)
    if player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function GetAimPart(character)
    if not character then return nil end
    if AimbotConfig.TargetPart == "Head" then
        return character:FindFirstChild("Head")
            or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("Head")
end

local function IsVisible(character, part)
    if not AimbotConfig.WallCheck then
        return true
    end
    local origin = workspace.CurrentCamera.CFrame.Position
    local direction = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, workspace.CurrentCamera }
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, params)
    if not result then return true end
    return result.Instance and result.Instance:IsDescendantOf(character)
end

local function GetClosestTarget()
    local cam = workspace.CurrentCamera
    if not cam then return nil end

    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closestPart = nil
    local bestScreen = AimbotConfig.FOV
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if IsAlivePlayer(player) then
            local character = player.Character
            local part = GetAimPart(character)
            if part then
                local worldDist = (part.Position - myRoot.Position).Magnitude
                if worldDist <= AimbotConfig.MaxDistance and IsVisible(character, part) then
                    local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen or screenPos.Z > 0 then
                        local delta = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if delta <= AimbotConfig.FOV and delta < bestScreen then
                            bestScreen = delta
                            closestPart = part
                        end
                    end
                end
            end
        end
    end
    return closestPart
end

local function RestoreHitboxes()
    for part, size in pairs(HitboxOriginal) do
        if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
            pcall(function()
                part.Size = size
            end)
        end
    end
    HitboxOriginal = {}
end

local function ApplyHitboxExpand()
    if not HitboxConfig.Enabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local headAny = char:FindFirstChild("Head")
        if typeof(headAny) ~= "Instance" or not headAny:IsA("BasePart") then
            continue
        end

        if HitboxOriginal[headAny] == nil then
            HitboxOriginal[headAny] = headAny.Size
        end

        local s = HitboxConfig.Scale
        pcall(function()
            headAny.Size = Vector3.new(s, s, s)
            headAny.CanCollide = false
            headAny.Massless = true
        end)
    end
end

if _G.PryvexAimbotConnection then
    pcall(function() _G.PryvexAimbotConnection:Disconnect() end)
    _G.PryvexAimbotConnection = nil
end

pcall(function()
    RunService:UnbindFromRenderStep("PryvexAimbot")
end)

local function DoFlick()
    FlickUntil = tick() + FlickDuration
    local part = GetClosestTarget()
    if not part then return end
    local cam = workspace.CurrentCamera
    if cam then
        cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    local match = false
    if FlickUseMouse then
        match = input.UserInputType == FlickKeyMouse
    else
        match = input.KeyCode == FlickKeyKeyboard
    end
    if match then
        DoFlick()
    end
end)

-- ปุ่ม Flick บนจอ — เฉพาะมือถือ (ลากได้อิสระ)
local function IsMobile()
    local ok, touch = pcall(function()
        return UserInputService.TouchEnabled
    end)
    if not ok or not touch then return false end
    local keyboard = false
    pcall(function()
        keyboard = UserInputService.KeyboardEnabled
    end)
    return touch and not keyboard
end

local function CreateMobileFlickButton()
    if not IsMobile() then
        print("[Pryvex] Not mobile — skip Flick button")
        return
    end

    destroyOldUI("PryvexFlickButton")

    local parent = nil
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then parent = hui end
    end
    if not parent then
        parent = game:GetService("CoreGui")
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PryvexFlickButton"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999997
    gui.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Name = "FlickBtn"
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.Position = UDim2.new(0.85, 0, 0.65, 0)
    btn.Size = UDim2.fromOffset(72, 72)
    btn.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    btn.BackgroundTransparency = 0.15
    btn.Text = "FLICK"
    btn.TextColor3 = Color3.fromRGB(0, 255, 128)
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    btn.Active = true
    btn.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 128)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = btn

    local dragging = false
    local dragMoved = false
    local dragStart = nil
    local startPos = nil

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragMoved = false
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        local delta = input.Position - dragStart
        if math.abs(delta.X) + math.abs(delta.Y) > 8 then
            dragMoved = true
        end
        btn.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end)

    btn.Activated:Connect(function()
        if dragMoved then
            dragMoved = false
            return
        end
        DoFlick()
    end)

    print("[Pryvex] Mobile Flick button created (draggable)")
end

-- FOV circle on screen
local FOVCircleConfig = {
    Enabled = false,
    Color   = Color3.fromRGB(0, 255, 128),
    Thickness = 1.5,
}

local FOVCircleGui = nil

local function DestroyFOVCircle()
    if FOVCircleGui then
        pcall(function() FOVCircleGui:Destroy() end)
        FOVCircleGui = nil
    end
end

local function CreateFOVCircle()
    DestroyFOVCircle()
    if not FOVCircleConfig.Enabled then return end

    local parent = nil
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then parent = hui end
    end
    if not parent then
        parent = game:GetService("CoreGui")
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PryvexFOVCircle"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999996
    gui.Parent = parent
    FOVCircleGui = gui

    -- วงกลมจาก Frame + UICorner หลายชิ้นไม่ดี → ใช้ ImageLabel วงกลม หรือ Drawing ถ้ามี
    -- ใช้ Frame ว่าง + UIStroke เป็นวงกลม
    local ring = Instance.new("Frame")
    ring.Name = "Ring"
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    local r = AimbotConfig.FOV * 2
    ring.Size = UDim2.fromOffset(r, r)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.Color = FOVCircleConfig.Color
    stroke.Thickness = FOVCircleConfig.Thickness
    stroke.Transparency = 0.2
    stroke.Parent = ring

    -- อัปเดตขนาดตาม FOV ทุกเฟรม
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not FOVCircleGui or not FOVCircleGui.Parent then
            if conn then conn:Disconnect() end
            return
        end
        if not FOVCircleConfig.Enabled then return end
        local size = AimbotConfig.FOV * 2
        ring.Size = UDim2.fromOffset(size, size)
        stroke.Color = FOVCircleConfig.Color
    end)
end

local function SetFOVCircle(on)
    FOVCircleConfig.Enabled = on
    if on then
        CreateFOVCircle()
    else
        DestroyFOVCircle()
    end
end

task.defer(CreateMobileFlickButton)


RunService:BindToRenderStep("PryvexAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    if tick() >= FlickUntil then return end
    local part = GetClosestTarget()
    if not part then return end
    local cam = workspace.CurrentCamera
    if cam then
        cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)
    end
end)

_G.PryvexAimbotConnection = RunService.Heartbeat:Connect(function()
    if HitboxConfig.Enabled then
        ApplyHitboxExpand()
    end
end)

_G.PryvexAimbotUnbind = function()
    pcall(function()
        RunService:UnbindFromRenderStep("PryvexAimbot")
    end)
end

Players.PlayerRemoving:Connect(function(player)
    local char = player.Character
    if char then
        local head = char:FindFirstChild("Head")
        if head then HitboxOriginal[head] = nil end
    end
end)

-- =========================================================================
-- 8b. BHOP-- =========================================================================
-- 8b. BHOP-- =========================================================================
-- 8b. BHOP-- =========================================================================
-- 8b. BHOP (fixed)
-- =========================================================================
local BhopConfig = {
    Enabled = false,
}

local function getHumanoid()
    local character = LocalPlayer.Character
    if not character then return nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    return humanoid, hrp
end

-- ตอนเกมยิง JumpRequest (กด space / มือถือกระโดด) → บังคับกระโดดซ้ำได้
if _G.PryvexBhopJumpConn then
    pcall(function() _G.PryvexBhopJumpConn:Disconnect() end)
    _G.PryvexBhopJumpConn = nil
end

if _G.PryvexAimbotConnection then
    pcall(function() _G.PryvexAimbotConnection:Disconnect() end)
    _G.PryvexAimbotConnection = nil
end

if _G.PryvexAimbotUnbind then
    pcall(_G.PryvexAimbotUnbind)
    _G.PryvexAimbotUnbind = nil
end
pcall(function()
    RunService:UnbindFromRenderStep("PryvexAimbot")
end)

_G.PryvexBhopJumpConn = UserInputService.JumpRequest:Connect(function()
    if not BhopConfig.Enabled then return end
    local humanoid = getHumanoid()
    if not humanoid or humanoid.Health <= 0 then return end
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end)

-- ลูป: ถ้าเปิด bhop แล้วแตะพื้น → กระโดดทันที (ไม่ต้องรอ space ก็ได้)
if _G.PryvexBhopConnection then
    pcall(function() _G.PryvexBhopConnection:Disconnect() end)
    _G.PryvexBhopConnection = nil
end

if _G.PryvexBhopJumpConn then
    pcall(function() _G.PryvexBhopJumpConn:Disconnect() end)
    _G.PryvexBhopJumpConn = nil
end

if _G.PryvexAimbotConnection then
    pcall(function() _G.PryvexAimbotConnection:Disconnect() end)
    _G.PryvexAimbotConnection = nil
end

if _G.PryvexAimbotUnbind then
    pcall(_G.PryvexAimbotUnbind)
    _G.PryvexAimbotUnbind = nil
end
pcall(function()
    RunService:UnbindFromRenderStep("PryvexAimbot")
end)

_G.PryvexBhopConnection = RunService.Heartbeat:Connect(function()
    if not BhopConfig.Enabled then return end

    local humanoid, hrp = getHumanoid()
    if not humanoid or not hrp or humanoid.Health <= 0 then return end

    -- อยู่บนพื้น / ไม่ได้อยู่กลางอากาศ
    local onGround = humanoid.FloorMaterial ~= Enum.Material.Air
        or humanoid:GetState() == Enum.HumanoidStateType.Landed
        or humanoid:GetState() == Enum.HumanoidStateType.Running

    if onGround then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        humanoid.Jump = true

        -- รักษาโมเมนตัมทิศทางเดินเล็กน้อย
        local move = humanoid.MoveDirection
        if move.Magnitude > 0.05 then
            local vel = hrp.AssemblyLinearVelocity
            local horizontal = Vector3.new(vel.X, 0, vel.Z)
            if horizontal.Magnitude < 50 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    move.X * math.max(horizontal.Magnitude, 16) * 1.05,
                    vel.Y,
                    move.Z * math.max(horizontal.Magnitude, 16) * 1.05
                )
            end
        end
    end
end)

-- =========================================================================
-- 9. HOME CONTENT
-- =========================================================================
HomeTab:AddParagraph({
    Title   = "Welcome to Pryvex",
    Content = "Welcome back! Pryvex Hub is ready to use."
})

HomeTab:AddParagraph({
    Title   = "Last updated",
    Content = "11/6/2026"
})

HomeTab:AddParagraph({
    Title   = "Type of Script | Expire on + ",
    Content = "Premium | No Expire"
})

HomeTab:AddParagraph({
    Title   = "Information",
    Content = "Pryvex Hub | [FPS] Flick"
})

-- =========================================================================
-- 9. ESP TAB
-- =========================================================================
ESPTab:AddParagraph({
    Title   = "Player ESP",
    Content = "Highlight + name/distance through walls"
})

ESPTab:AddToggle("ESPEnabled", {
    Title   = "Enable ESP",
    Default = false,
    Callback = function(value)
        ESPConfig.Enabled = value
        if not value then
            ClearAllESP()
        end
        Pryvex:Notify({
            Title    = "ESP",
            Content  = value and "Enabled" or "Disabled",
            Duration = 2
        })
    end
})

ESPTab:AddToggle("ESPShowName", {
    Title   = "Show Name",
    Default = true,
    Callback = function(value)
        ESPConfig.ShowName = value
    end
})

ESPTab:AddToggle("ESPShowDistance", {
    Title   = "Show Distance",
    Default = true,
    Callback = function(value)
        ESPConfig.ShowDistance = value
    end
})

ESPTab:AddSlider("ESPDistance", {
    Title    = "Max Distance (studs)",
    Default  = 2000,
    Min      = 100,
    Max      = 5000,
    Rounding = 0,
    Callback = function(value)
        ESPConfig.MaxDistance = value
    end
})

ESPTab:AddParagraph({
    Title   = "FOV",
    Content = "On-screen FOV circle and aim FOV size"
})

ESPTab:AddToggle("ShowFOVCircle", {
    Title = "Show FOV on Screen",
    Default = false,
    Callback = function(value)
        SetFOVCircle(value)
    end
})

ESPTab:AddSlider("AimbotFOV", {
    Title = "FOV Size (screen px)",
    Default = 250,
    Min = 40,
    Max = 800,
    Rounding = 0,
    Callback = function(value)
        AimbotConfig.FOV = value
    end
})

ESPTab:AddParagraph({
    Title   = "Crosshair",
    Content = "Center screen crosshair"
})

ESPTab:AddToggle("CrosshairEnabled", {
    Title   = "Enable Crosshair",
    Default = false,
    Callback = function(value)
        SetCrosshair(value)
    end
})

ESPTab:AddSlider("CrosshairSize", {
    Title    = "Crosshair Size",
    Default  = 8,
    Min      = 4,
    Max      = 24,
    Rounding = 0,
    Callback = function(value)
        CrosshairConfig.Size = value
        if CrosshairConfig.Enabled then
            CreateCrosshair()
        end
    end
})

ESPTab:AddSlider("CrosshairGap", {
    Title    = "Gap",
    Default  = 3,
    Min      = 0,
    Max      = 16,
    Rounding = 0,
    Callback = function(value)
        CrosshairConfig.Gap = value
        if CrosshairConfig.Enabled then
            CreateCrosshair()
        end
    end
})

-- สี ESP + Crosshair
local ColorPresets = {
    ["Blue"]   = Color3.fromRGB(40, 150, 255),
    ["Red"]    = Color3.fromRGB(255, 60, 60),
    ["Green"]  = Color3.fromRGB(0, 255, 128),
    ["Yellow"] = Color3.fromRGB(255, 220, 50),
    ["Purple"] = Color3.fromRGB(180, 80, 255),
    ["White"]  = Color3.fromRGB(255, 255, 255),
    ["Orange"] = Color3.fromRGB(255, 140, 40),
    ["Cyan"]   = Color3.fromRGB(0, 220, 255),
    ["Pink"]   = Color3.fromRGB(255, 100, 180),
}
local ColorNames = { "Blue", "Red", "Green", "Yellow", "Purple", "White", "Orange", "Cyan", "Pink" }

ESPTab:AddParagraph({
    Title   = "ESP Colors",
    Content = "Highlight colors"
})

-- ลอง Colorpicker ก่อน ถ้าไม่มีใช้ Dropdown
local usedColorpicker = false
local okFill = pcall(function()
    ESPTab:AddColorpicker("ESPFillColor", {
        Title = "ESP Fill",
        Default = ESPConfig.FillColor,
        Callback = function(value)
            ESPConfig.FillColor = value
            RefreshESPColors()
        end
    })
end)
local okOutline = pcall(function()
    ESPTab:AddColorpicker("ESPOutlineColor", {
        Title = "ESP Outline",
        Default = ESPConfig.OutlineColor,
        Callback = function(value)
            ESPConfig.OutlineColor = value
            RefreshESPColors()
        end
    })
end)
usedColorpicker = okFill and okOutline

if not usedColorpicker then
    ESPTab:AddDropdown("ESPFillPreset", {
        Title = "ESP Fill Color",
        Values = ColorNames,
        Multi = false,
        Default = 1,
        Callback = function(value)
            local c = ColorPresets[value]
            if c then
                ESPConfig.FillColor = c
                RefreshESPColors()
            end
        end
    })
    ESPTab:AddDropdown("ESPOutlinePreset", {
        Title = "ESP Outline Color",
        Values = ColorNames,
        Multi = false,
        Default = 6,
        Callback = function(value)
            local c = ColorPresets[value]
            if c then
                ESPConfig.OutlineColor = c
                RefreshESPColors()
            end
        end
    })
end

ESPTab:AddParagraph({
    Title   = "Crosshair Color",
    Content = "Crosshair color"
})

local okCH = pcall(function()
    ESPTab:AddColorpicker("CrosshairColor", {
        Title = "Crosshair Color",
        Default = CrosshairConfig.Color,
        Callback = function(value)
            CrosshairConfig.Color = value
            RefreshCrosshairColor()
        end
    })
end)

if not okCH then
    ESPTab:AddDropdown("CrosshairColorPreset", {
        Title = "Crosshair Color",
        Values = ColorNames,
        Multi = false,
        Default = 3,
        Callback = function(value)
            local c = ColorPresets[value]
            if c then
                CrosshairConfig.Color = c
                if CrosshairConfig.Enabled then
                    CreateCrosshair()
                else
                    RefreshCrosshairColor()
                end
            end
        end
    })
end

-- =========================================================================
-- AIMBOT UI
-- =========================================================================
AimbotTab:AddParagraph({
    Title   = "Flick Mode",
    Content = "PC: key/mouse · Mobile: on-screen FLICK button (draggable)"
})

AimbotTab:AddDropdown("FlickBind", {
    Title = "Flick Key",
    Values = { "Mouse Right", "Mouse Left", "E", "Q", "F" },
    Multi = false,
    Default = 1,
    Callback = function(value)
        if value == "Mouse Right" then
            FlickUseMouse = true
            FlickKeyMouse = Enum.UserInputType.MouseButton2
        elseif value == "Mouse Left" then
            FlickUseMouse = true
            FlickKeyMouse = Enum.UserInputType.MouseButton1
        elseif value == "E" then
            FlickUseMouse = false
            FlickKeyKeyboard = Enum.KeyCode.E
        elseif value == "Q" then
            FlickUseMouse = false
            FlickKeyKeyboard = Enum.KeyCode.Q
        elseif value == "F" then
            FlickUseMouse = false
            FlickKeyKeyboard = Enum.KeyCode.F
        end
    end
})

AimbotTab:AddSlider("FlickTime", {
    Title = "Flick Duration (ms)",
    Default = 120,
    Min = 50,
    Max = 400,
    Rounding = 0,
    Callback = function(value)
        FlickDuration = value / 1000
    end
})

AimbotTab:AddDropdown("AimbotPart", {
    Title = "Target",
    Values = { "Head", "Body" },
    Multi = false,
    Default = 1,
    Callback = function(value)
        AimbotConfig.TargetPart = value
    end
})

AimbotTab:AddToggle("AimbotWallCheck", {
    Title = "WallCheck",
    Default = false,
    Callback = function(value)
        AimbotConfig.WallCheck = value
    end
})


AimbotTab:AddSlider("AimbotDist", {
    Title = "Max Distance",
    Default = 2000,
    Min = 50,
    Max = 5000,
    Rounding = 0,
    Callback = function(value)
        AimbotConfig.MaxDistance = value
    end
})


-- =========================================================================
-- MISC / BHOP-- =========================================================================
-- MISC / BHOP
-- =========================================================================
MiscTab:AddParagraph({
    Title   = "Movement",
    Content = "Auto jump while on the ground"
})

MiscTab:AddToggle("BhopEnabled", {
    Title   = "Enable Bhop",
    Default = false,
    Callback = function(value)
        BhopConfig.Enabled = value
        Pryvex:Notify({
            Title    = "Bhop",
            Content  = value and "Enabled" or "Disabled",
            Duration = 2
        })
    end
})

MiscTab:AddParagraph({
    Title   = "Hitbox Expand",
    Content = "Expand other players Head size (default 0.9)"
})

MiscTab:AddToggle("HitboxExpand", {
    Title = "Enable Hitbox Expand",
    Default = false,
    Callback = function(value)
        HitboxConfig.Enabled = value
        if not value then
            RestoreHitboxes()
        end
        Pryvex:Notify({
            Title = "Hitbox",
            Content = value and "ON" or "OFF",
            Duration = 1.5
        })
    end
})

MiscTab:AddSlider("HitboxScale", {
    Title = "Head Size",
    Default = 90,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        HitboxConfig.Scale = value / 100
        if HitboxConfig.Enabled then
            ApplyHitboxExpand()
        end
    end
})


-- =========================================================================
-- 10. SELECT HOME
-- =========================================================================
task.defer(function()
    pcall(function()
        Window:SelectTab(1)
    end)
end)

print("[Pryvex Hub] Home + ESP + Aimbot + Bhop loaded")
