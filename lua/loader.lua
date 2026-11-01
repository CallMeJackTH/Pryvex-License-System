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

-- Pryvex Map Pre-Loader (runs only after the Premium key has been verified).
-- Fill each URL below when the corresponding map script is ready.
do
    local mapScripts = {
        ["142823291"] = { Name = "Murder Mystery 2", URL = "" },
        ["10449761463"] = { Name = "The Strongest Battlegrounds", URL = "https://scriptblox.com/raw/The-Strongest-Battlegrounds-Relia-138974" },
        ["93978595733734"] = { Name = "[Treatment] Severity Zone", URL = "" },
        ["107778070777162"] = { Name = "Steal An Egg", URL = "" },
        ["100068273119174"] = { Name = "Clean All the Leaves", URL = "" }
    }

    local placeId = tostring(game.PlaceId)
    local map = mapScripts[placeId]

    if map then
        local player = game:GetService("Players").LocalPlayer
        local parent
        pcall(function() parent = game:GetService("CoreGui") end)
        if not parent then
            parent = player:WaitForChild("PlayerGui")
        end

        local oldGui = parent:FindFirstChild("PryvexMapPreLoader")
        if oldGui then oldGui:Destroy() end

        local TweenService = game:GetService("TweenService")
        local gui = Instance.new("ScreenGui")
        gui.Name = "PryvexMapPreLoader"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 999998
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = parent

        local function corner(object, radius)
            local item = Instance.new("UICorner")
            item.CornerRadius = UDim.new(0, radius)
            item.Parent = object
            return item
        end

        local function stroke(object, color, transparency, thickness)
            local item = Instance.new("UIStroke")
            item.Color = color
            item.Transparency = transparency or 0
            item.Thickness = thickness or 1
            item.Parent = object
            return item
        end

        local function label(parentObject, name, text, position, size, font, textSize, color)
            local item = Instance.new("TextLabel")
            item.Name = name
            item.BackgroundTransparency = 1
            item.Position = position
            item.Size = size
            item.Font = font
            item.Text = text
            item.TextSize = textSize
            item.TextColor3 = color
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.TextYAlignment = Enum.TextYAlignment.Center
            item.Parent = parentObject
            return item
        end

        -- Soft dim layer and Fluent-inspired dark acrylic window.
        local dim = Instance.new("Frame")
        dim.Name = "Backdrop"
        dim.Size = UDim2.fromScale(1, 1)
        dim.BackgroundColor3 = Color3.fromRGB(4, 5, 12)
        dim.BackgroundTransparency = 0.42
        dim.BorderSizePixel = 0
        dim.Parent = gui

        local panel = Instance.new("Frame")
        panel.Name = "AcrylicWindow"
        panel.AnchorPoint = Vector2.new(0.5, 0.5)
        panel.Position = UDim2.fromScale(0.5, 0.53)
        panel.Size = UDim2.fromOffset(470, 218)
        panel.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
        panel.BackgroundTransparency = 0.08
        panel.BorderSizePixel = 0
        panel.Parent = dim
        corner(panel, 15)
        stroke(panel, Color3.fromRGB(133, 112, 255), 0.58, 1)

        local panelGradient = Instance.new("UIGradient")
        panelGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 31, 58)),
            ColorSequenceKeypoint.new(0.48, Color3.fromRGB(22, 23, 37)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 17, 29))
        })
        panelGradient.Rotation = 25
        panelGradient.Parent = panel

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.Size = UDim2.new(1, -36, 0, 2)
        accent.Position = UDim2.fromOffset(18, 0)
        accent.BackgroundColor3 = Color3.fromRGB(151, 91, 255)
        accent.BorderSizePixel = 0
        accent.Parent = panel
        corner(accent, 2)
        local accentGradient = Instance.new("UIGradient")
        accentGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 75, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 105, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 150, 255))
        })
        accentGradient.Parent = accent

        local logo = Instance.new("Frame")
        logo.Name = "Logo"
        logo.Position = UDim2.fromOffset(22, 22)
        logo.Size = UDim2.fromOffset(42, 42)
        logo.BackgroundColor3 = Color3.fromRGB(105, 66, 220)
        logo.BorderSizePixel = 0
        logo.Parent = panel
        corner(logo, 12)
        local logoGradient = Instance.new("UIGradient")
        logoGradient.Color = ColorSequence.new(Color3.fromRGB(157, 93, 255), Color3.fromRGB(83, 72, 220))
        logoGradient.Rotation = 45
        logoGradient.Parent = logo
        local logoText = label(logo, "LogoText", "P", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBold, 25, Color3.fromRGB(255, 255, 255))
        logoText.TextXAlignment = Enum.TextXAlignment.Center

        label(panel, "Brand", "PRYVEX", UDim2.fromOffset(76, 20), UDim2.fromOffset(220, 23), Enum.Font.GothamBold, 17, Color3.fromRGB(246, 244, 255))
        local subTitle = label(panel, "SubTitle", "PREMIUM  /  MAP LOADER", UDim2.fromOffset(77, 43), UDim2.fromOffset(260, 17), Enum.Font.GothamMedium, 10, Color3.fromRGB(157, 151, 190))
        subTitle.TextXAlignment = Enum.TextXAlignment.Left

        local pill = Instance.new("Frame")
        pill.Name = "SecureBadge"
        pill.AnchorPoint = Vector2.new(1, 0)
        pill.Position = UDim2.new(1, -20, 0, 29)
        pill.Size = UDim2.fromOffset(92, 25)
        pill.BackgroundColor3 = Color3.fromRGB(65, 49, 103)
        pill.BackgroundTransparency = 0.25
        pill.BorderSizePixel = 0
        pill.Parent = panel
        corner(pill, 8)
        local badgeText = label(pill, "BadgeText", "● SECURE", UDim2.fromOffset(8, 0), UDim2.new(1, -12, 1, 0), Enum.Font.GothamBold, 9, Color3.fromRGB(197, 169, 255))
        badgeText.TextXAlignment = Enum.TextXAlignment.Center

        local separator = Instance.new("Frame")
        separator.Position = UDim2.fromOffset(20, 78)
        separator.Size = UDim2.new(1, -40, 0, 1)
        separator.BackgroundColor3 = Color3.fromRGB(104, 98, 133)
        separator.BackgroundTransparency = 0.72
        separator.BorderSizePixel = 0
        separator.Parent = panel

        label(panel, "LoadingCaption", "กำลังเตรียมสคริปต์สำหรับเกม", UDim2.fromOffset(23, 91), UDim2.new(1, -46, 0, 18), Enum.Font.Gotham, 11, Color3.fromRGB(164, 160, 187))
        -- Small game icon tile beside the detected experience name.
        local gameIconTile = Instance.new("Frame")
        gameIconTile.Name = "GameIcon"
        gameIconTile.Position = UDim2.fromOffset(22, 108)
        gameIconTile.Size = UDim2.fromOffset(30, 30)
        gameIconTile.BackgroundColor3 = Color3.fromRGB(54, 47, 83)
        gameIconTile.BackgroundTransparency = 0.12
        gameIconTile.BorderSizePixel = 0
        gameIconTile.Parent = panel
        corner(gameIconTile, 8)
        stroke(gameIconTile, Color3.fromRGB(150, 119, 255), 0.65, 1)

        local gameIcon = label(gameIconTile, "GameGlyph", "◇", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBold, 23, Color3.fromRGB(204, 177, 255))
        gameIcon.TextXAlignment = Enum.TextXAlignment.Center

        local gameLabel = label(panel, "GameName", map.Name, UDim2.fromOffset(62, 111), UDim2.new(1, -85, 0, 25), Enum.Font.GothamSemibold, 16, Color3.fromRGB(244, 242, 255))
        gameLabel.TextTruncate = Enum.TextTruncate.AtEnd

        local placeLabel = label(panel, "PlaceId", "PLACE ID  /  " .. placeId, UDim2.fromOffset(24, 138), UDim2.new(1, -48, 0, 15), Enum.Font.Gotham, 9, Color3.fromRGB(127, 125, 155))

        local barBack = Instance.new("Frame")
        barBack.Name = "ProgressTrack"
        barBack.Position = UDim2.fromOffset(23, 165)
        barBack.Size = UDim2.new(1, -46, 0, 5)
        barBack.BackgroundColor3 = Color3.fromRGB(58, 55, 78)
        barBack.BorderSizePixel = 0
        barBack.Parent = panel
        corner(barBack, 5)

        local barFill = Instance.new("Frame")
        barFill.Name = "ProgressFill"
        barFill.Size = UDim2.new(0.08, 0, 1, 0)
        barFill.BackgroundColor3 = Color3.fromRGB(151, 91, 255)
        barFill.BorderSizePixel = 0
        barFill.Parent = barBack
        corner(barFill, 5)
        local fillGradient = Instance.new("UIGradient")
        fillGradient.Color = ColorSequence.new(Color3.fromRGB(111, 91, 255), Color3.fromRGB(194, 106, 255))
        fillGradient.Parent = barFill

        local statusGlyph = label(panel, "StatusIcon", map.URL == "" and "!" or "●", UDim2.fromOffset(23, 178), UDim2.fromOffset(16, 20), Enum.Font.GothamBold, 11, map.URL == "" and Color3.fromRGB(255, 190, 115) or Color3.fromRGB(174, 139, 255))
        statusGlyph.TextXAlignment = Enum.TextXAlignment.Center
        local statusLabel = label(panel, "Status", map.URL == "" and "ยังไม่ได้กำหนดลิงก์สคริปต์ของเกมนี้" or "กำลังเชื่อมต่อและดาวน์โหลด...", UDim2.fromOffset(43, 178), UDim2.new(1, -66, 0, 20), Enum.Font.Gotham, 10, map.URL == "" and Color3.fromRGB(255, 190, 115) or Color3.fromRGB(185, 177, 215))
        statusLabel.TextTruncate = Enum.TextTruncate.AtEnd

        panel.Size = UDim2.fromOffset(440, 205)
        panel.BackgroundTransparency = 1
        panel.Position = UDim2.fromScale(0.5, 0.56)
        TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(470, 218),
            Position = UDim2.fromScale(0.5, 0.53),
            BackgroundTransparency = 0.08
        }):Play()

        local progressTween
        if map.URL ~= "" then
            progressTween = TweenService:Create(barFill, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Size = UDim2.new(0.82, 0, 1, 0)
            })
            progressTween:Play()

            task.spawn(function()
                local downloadOk, source = pcall(function()
                    return game:HttpGet(map.URL)
                end)
                if not downloadOk or type(source) ~= "string" or source == "" then
                    if progressTween then progressTween:Cancel() end
                    statusLabel.Text = "ดาวน์โหลดสคริปต์ไม่สำเร็จ"
                    statusLabel.TextColor3 = Color3.fromRGB(255, 112, 130)
                    barFill.BackgroundColor3 = Color3.fromRGB(225, 75, 100)
                    barFill.Size = UDim2.new(1, 0, 1, 0)
                    return
                end

                local compileOk, scriptFunction = pcall(loadstring, source)
                if not compileOk or type(scriptFunction) ~= "function" then
                    if progressTween then progressTween:Cancel() end
                    statusLabel.Text = "สคริปต์มีข้อผิดพลาด ไม่สามารถ Compile ได้"
                    statusLabel.TextColor3 = Color3.fromRGB(255, 112, 130)
                    barFill.BackgroundColor3 = Color3.fromRGB(225, 75, 100)
                    barFill.Size = UDim2.new(1, 0, 1, 0)
                    return
                end

                if progressTween then progressTween:Cancel() end
                statusLabel.Text = "ตรวจสอบเสร็จแล้ว กำลังเปิดสคริปต์..."
                statusLabel.TextColor3 = Color3.fromRGB(130, 224, 180)
                TweenService:Create(barFill, TweenInfo.new(0.25), {
                    Size = UDim2.new(1, 0, 1, 0)
                }):Play()
                task.wait(0.45)
                gui:Destroy()
                local runOk, runError = pcall(scriptFunction)
                if not runOk then
                    warn("[Pryvex Map Loader] " .. tostring(runError))
                end
            end)
        else
            barFill.Size = UDim2.new(1, 0, 1, 0)
            barFill.BackgroundColor3 = Color3.fromRGB(220, 155, 95)
            task.delay(4, function()
                if gui and gui.Parent then
                    TweenService:Create(panel, TweenInfo.new(0.2), {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(440, 205)
                    }):Play()
                    task.wait(0.22)
                    if gui and gui.Parent then gui:Destroy() end
                end
            end)
        end
    end
end



-- Pryvex runs without the external UI library.

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
    end, 0.5)
end

return License
