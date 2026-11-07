-- =========================================================================
-- [FPS] Flick | Pryvex Hub
-- Home + ESP + Flick + Misc
-- =========================================================================

local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")
local Camera           = workspace.CurrentCamera

local LOGO_ID         = "rbxassetid://127972121421541"
local SIDEBAR_LOGO_ID = "rbxassetid://88534329518644"

-- =========================================================================
-- 1. CLEANUP
-- =========================================================================
if _G.PryvexHubInstance then
    pcall(function() _G.PryvexHubInstance:Destroy() end)
    _G.PryvexHubInstance = nil
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
-- 2. LOAD UI LIBRARY
-- =========================================================================
local URL = "https://raw.githubusercontent.com/CallMeJackTH/Pryvex-Hub/fluent-clone-integration/dist/PryvexHub.lua"

local success, Pryvex = pcall(function()
    return loadstring(game:HttpGet(URL))()
end)

if not success or not Pryvex then
    warn("[FPS Flick] Failed to load UI Library")
    return
end

-- =========================================================================
-- 3. WINDOW
-- =========================================================================
local Window = Pryvex:CreateWindow({
    Title       = "[FPS] Flick",
    SubTitle    = "Pryvex",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(580, 460),
    Acrylic     = false,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

if not Window then
    warn("[FPS Flick] Window creation failed")
    return
end

_G.PryvexHubInstance = Window

local HomeTab   = Window:AddTab({ Title = "Home",        Icon = "home" })
local AimbotTab = Window:AddTab({ Title = "Flick Mode",  Icon = "crosshair" })
local ESPTab    = Window:AddTab({ Title = "ESP",         Icon = "eye" })
local MiscTab   = Window:AddTab({ Title = "Misc",        Icon = "settings" })

-- =========================================================================
-- 4. SIDEBAR LOGO
-- =========================================================================
do
    local TabFrame = Window.TabHolder and Window.TabHolder.Parent
    if TabFrame then
        local LOGO_HEIGHT = 120
        local OFFSET = LOGO_HEIGHT + 10

        local OriginalSelector
        for _, child in ipairs(TabFrame:GetChildren()) do
            if child ~= Window.TabHolder and child:IsA("Frame") then
                OriginalSelector = child
                break
            end
        end

        local LogoFrame = Instance.new("Frame")
        LogoFrame.Name = "PryvexSidebarBrand"
        LogoFrame.Size = UDim2.new(1, 0, 0, LOGO_HEIGHT)
        LogoFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        LogoFrame.BorderSizePixel = 0
        LogoFrame.ClipsDescendants = true
        LogoFrame.ZIndex = 5
        LogoFrame.Parent = TabFrame

        local LogoCorner = Instance.new("UICorner")
        LogoCorner.CornerRadius = UDim.new(0, 14)
        LogoCorner.Parent = LogoFrame

        local LogoImage = Instance.new("ImageLabel")
        LogoImage.Name = "PryvexLogo"
        LogoImage.AnchorPoint = Vector2.new(0.5, 0.5)
        LogoImage.Position = UDim2.fromScale(0.5, 0.5)
        LogoImage.Size = UDim2.fromScale(1, 1)
        LogoImage.BackgroundTransparency = 1
        LogoImage.Image = SIDEBAR_LOGO_ID
        LogoImage.ScaleType = Enum.ScaleType.Fit
        LogoImage.ZIndex = 6
        LogoImage.Parent = LogoFrame

        local ImageCorner = Instance.new("UICorner")
        ImageCorner.CornerRadius = UDim.new(0, 14)
        ImageCorner.Parent = LogoImage

        Window.TabHolder.Position = UDim2.new(0, 0, 0, OFFSET)
        Window.TabHolder.Size = UDim2.new(1, 0, 1, -OFFSET)

        if OriginalSelector then
            local SelectorContainer = Instance.new("Frame")
            SelectorContainer.Name = "PryvexSelectorContainer"
            SelectorContainer.Size = UDim2.new(0, 4, 1, -OFFSET)
            SelectorContainer.Position = UDim2.new(0, 0, 0, OFFSET)
            SelectorContainer.BackgroundTransparency = 1
            SelectorContainer.ZIndex = OriginalSelector.ZIndex
            SelectorContainer.Parent = TabFrame
            OriginalSelector.Parent = SelectorContainer
        end
    end
end

-- =========================================================================
-- 5. FLOATING TOGGLE ICON
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
    if not ToggleGui then return end

    local ToggleButton = ToggleGui:FindFirstChild("PryvexIconButton", true)
    if not ToggleButton then return end
    if not (ToggleButton:IsA("TextButton") or ToggleButton:IsA("ImageButton")) then return end

    ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
    ToggleButton.Position = UDim2.new(0, 20, 0.5, 0)
    ToggleButton.Size = UDim2.fromOffset(52, 52)
    ToggleButton.BackgroundTransparency = 1
    ToggleButton.BorderSizePixel = 0
    ToggleButton.AutoButtonColor = false

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
    Icon.Name = "PryvexToggleImage"
    Icon.Size = UDim2.fromScale(1, 1)
    Icon.BackgroundTransparency = 1
    Icon.Image = LOGO_ID
    Icon.ScaleType = Enum.ScaleType.Stretch
    Icon.ZIndex = ToggleButton.ZIndex + 1
    Icon.Parent = ToggleButton

    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 14)
    IconCorner.Parent = Icon
end)

-- =========================================================================
-- 6. ESP + CROSSHAIR + FOV CIRCLE
-- =========================================================================
local ESPConfig = {
    Enabled = false,
    MaxDistance = 2000,
    ShowName = true,
    ShowDistance = true,
    FillColor = Color3.fromRGB(40, 150, 255),
    OutlineColor = Color3.fromRGB(255, 255, 255),
}

local CrosshairConfig = {
    Enabled = false,
    Size = 8,
    Gap = 3,
    Thickness = 2,
    Color = Color3.fromRGB(0, 255, 128),
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
    if not parent then parent = CoreGui end

    local screen = Instance.new("ScreenGui")
    screen.Name = "PryvexCrosshair"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = 999998
    screen.Parent = parent
    CrosshairGui = screen

    local function makeLine(name, size, pos)
        local f = Instance.new("Frame")
        f.Name = name
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = pos
        f.Size = size
        f.BackgroundColor3 = CrosshairConfig.Color
        f.BorderSizePixel = 0
        f.ZIndex = 10
        f.Parent = screen
        return f
    end

    local s, g, t = CrosshairConfig.Size, CrosshairConfig.Gap, CrosshairConfig.Thickness
    makeLine("Top", UDim2.fromOffset(t, s), UDim2.new(0.5, 0, 0.5, -(g + s / 2)))
    makeLine("Bottom", UDim2.fromOffset(t, s), UDim2.new(0.5, 0, 0.5, (g + s / 2)))
    makeLine("Left", UDim2.fromOffset(s, t), UDim2.new(0.5, -(g + s / 2), 0.5, 0))
    makeLine("Right", UDim2.fromOffset(s, t), UDim2.new(0.5, (g + s / 2), 0.5, 0))

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.fromScale(0.5, 0.5)
    dot.Size = UDim2.fromOffset(2, 2)
    dot.BackgroundColor3 = CrosshairConfig.Color
    dot.BorderSizePixel = 0
    dot.ZIndex = 11
    dot.Parent = screen
    local dc = Instance.new("UICorner")
    dc.CornerRadius = UDim.new(1, 0)
    dc.Parent = dot
end

local function SetCrosshair(enabled)
    CrosshairConfig.Enabled = enabled
    if enabled then CreateCrosshair() else DestroyCrosshair() end
end

local ESPObjects = {}

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
    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "PryvexESP"
    highlight.Adornee = character
    highlight.FillColor = ESPConfig.FillColor
    highlight.OutlineColor = ESPConfig.OutlineColor
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PryvexESPInfo"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(160, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = ESPConfig.MaxDistance
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.Text = player.DisplayName
    label.Parent = billboard

    ESPObjects[player] = { Highlight = highlight, Billboard = billboard, Label = label }
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
        if not obj or not obj.Highlight or not obj.Highlight.Parent or not obj.Billboard or not obj.Billboard.Parent then
            CreateESP(player)
            obj = ESPObjects[player]
        end
        if not obj or not player.Character then continue end
        local root = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Head")
        if not root then continue end
        local distance = (Camera.CFrame.Position - root.Position).Magnitude
        local show = distance <= ESPConfig.MaxDistance
        obj.Highlight.Enabled = show
        obj.Billboard.Enabled = show
        obj.Billboard.MaxDistance = ESPConfig.MaxDistance
        if show then
            local parts = {}
            if ESPConfig.ShowName then table.insert(parts, player.DisplayName) end
            if ESPConfig.ShowDistance then table.insert(parts, math.floor(distance) .. " studs") end
            obj.Label.Text = table.concat(parts, "\n")
        end
    end
end

_G.PryvexESPConnection = RunService.RenderStepped:Connect(UpdateESP)

Players.PlayerRemoving:Connect(RemoveESP)

local function HookCharacter(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPConfig.Enabled then CreateESP(player) end
    end)
end

Players.PlayerAdded:Connect(HookCharacter)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then HookCharacter(p) end
end

-- =========================================================================
-- 7. FLICK AIMBOT
-- =========================================================================
local AimbotConfig = {
    TargetPart  = "Head",
    WallCheck   = false,
    MaxDistance = 2000,
    FOV         = 250,
}

local FlickUntil = 0
local FlickDuration = 0.12
local MobileLockHeld = false
local FlickKeyMouse = Enum.UserInputType.MouseButton2
local FlickUseMouse = true
local FlickKeyKeyboard = Enum.KeyCode.E

local HitboxConfig = { Enabled = false, Scale = 0.9 }
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
        return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("Head")
end

local function IsVisible(character, part)
    if not AimbotConfig.WallCheck then return true end
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

local function DoFlick()
    FlickUntil = tick() + FlickDuration
    local part = GetClosestTarget()
    if not part then return end
    local cam = workspace.CurrentCamera
    if cam then
        cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)
    end
end

UserInputService.InputBegan:Connect(function(input)
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

pcall(function() RunService:UnbindFromRenderStep("PryvexAimbot") end)

RunService:BindToRenderStep("PryvexAimbot", Enum.RenderPriority.Camera.Value + 1, function()
    local locking = MobileLockHeld or tick() < FlickUntil
    if not locking then return end
    local part = GetClosestTarget()
    if not part then return end
    local cam = workspace.CurrentCamera
    if cam then
        cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)
    end
end)

_G.PryvexAimbotUnbind = function()
    pcall(function() RunService:UnbindFromRenderStep("PryvexAimbot") end)
end

-- Hitbox
local function RestoreHitboxes()
    for part, size in pairs(HitboxOriginal) do
        if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
            pcall(function() part.Size = size end)
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
        if typeof(headAny) ~= "Instance" or not headAny:IsA("BasePart") then continue end
        if HitboxOriginal[headAny] == nil then
            HitboxOriginal[headAny] = headAny.Size
        end
        local s = HitboxConfi
