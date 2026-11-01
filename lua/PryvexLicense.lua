-- Pryvex License client helper.
-- Periodically re-checks server authorization and terminates the local session
-- only when the server confirms that the license is no longer valid.
-- DeviceId is client-reported and is not hardware attestation.

local API_URL = "https://yfsmtoetvajschaeyagc.supabase.co/functions/v1/license-api"
-- Public publishable key: safe for client-side use; never place service-role secrets here.
local SUPABASE_PUBLISHABLE_KEY = "sb_publishable_6tWpyvbWT0rbifARzeI0og_zaPbEAlG"
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
local SESSION_ID = env._PryvexSessionId
if type(SESSION_ID) ~= "string" or #SESSION_ID < 8 then
    SESSION_ID = HttpService:GenerateGUID(false)
    env._PryvexSessionId = SESSION_ID
end

local function getRequestFunction()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if syn and typeof(syn.request) == "function" then return syn.request end
    return nil
end

local function postJson(url, body)
    local requestFunction = getRequestFunction()
    if not requestFunction then
        return nil, "This executor does not expose a supported HTTP request function."
    end

    local ok, response = pcall(function()
        return requestFunction({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["apikey"] = SUPABASE_PUBLISHABLE_KEY
            },
            Body = game:GetService("HttpService"):JSONEncode(body)
        })
    end)
    if not ok then return nil, tostring(response) end
    if type(response) ~= "table" then
        return nil, "License server returned an invalid HTTP response."
    end

    local statusCode = tonumber(response.StatusCode or response.Status or 0) or 0
    local responseBody = response.Body or response.body or ""
    local decodedOk, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(responseBody)
    end)
    if not decodedOk or type(decoded) ~= "table" then
        return nil, "Invalid response from license server."
    end

    if statusCode < 200 or statusCode >= 300 then
        -- Only explicit license rejection codes count as a confirmed revocation.
        if decoded.valid == false and type(decoded.code) == "string" then
            local rejectionCodes = {
                KEY_INVALID = true,
                KEY_DELETED = true,
                KEY_DISABLED = true,
                KEY_BANNED = true,
                KEY_EXPIRED = true,
                DEVICE_MISMATCH = true,
                DEVICE_INVALID = true
            }
            if rejectionCodes[decoded.code] then
                return decoded
            end
        end
        return nil, decoded.error or ("License server HTTP error " .. tostring(statusCode))
    end

    return decoded
end

local License = {}

local function checkLicense()
    local env = (getgenv and getgenv()) or _G
    local key = env.Key
    local deviceId = env.DeviceId
    local discordId = env.id

    if type(key) ~= "string" or key == "" then
        return false, "KEY_INVALID", "Missing license key"
    end
    if type(deviceId) ~= "string" or #deviceId < 8 then
        return false, "DEVICE_INVALID", "Invalid device identifier"
    end

    local result, err = postJson(API_URL, {
        action = "verify",
        key = key,
        device_id = deviceId,
        discord_id = type(discordId) == "string" and discordId or nil,
        session_id = SESSION_ID,
        roblox_username = LocalPlayer and LocalPlayer.Name or "Unknown",
        roblox_display_name = LocalPlayer and LocalPlayer.DisplayName or (LocalPlayer and LocalPlayer.Name) or "Unknown",
        roblox_user_id = LocalPlayer and LocalPlayer.UserId or 0,
        place_id = game.PlaceId,
        game_id = game.JobId
    })

    if not result then
        return false, "NETWORK_ERROR", err or "License server unavailable"
    end

    if result.valid ~= true then
        local code = result.code
        if type(code) ~= "string" then
            return false, "NETWORK_ERROR", result.error or "Unexpected license server response"
        end
        return false, code, result.error or "License verification failed"
    end

    return true, nil, nil, result
end

local function terminateSession(message)
    local players = game:GetService("Players")
    local player = players.LocalPlayer
    if player then
        pcall(function()
            player:Kick("[Pryvex] " .. (message or "Premium access has been revoked."))
        end)
    end
end

function License.verify()
    local valid, code, message = checkLicense()
    if not valid then
        return false, code, message
    end
    print("[Pryvex] Premium license verified.")
    return true
end

function License.startMonitor(onRevoked, intervalSeconds)
    -- Fast polling gives Disable/Delete a short detection delay.
    -- This is client polling, not a guaranteed server push; network latency still applies.
    intervalSeconds = math.max(0.5, tonumber(intervalSeconds) or 0.5)
    if License._monitorRunning then return false end
    License._monitorRunning = true

    task.spawn(function()
        while License._monitorRunning do
            task.wait(intervalSeconds)
            if not License._monitorRunning then break end

            local valid, code, message, details = checkLicense()
            if not valid then
                local revokedCodes = {
                    KEY_DISABLED = true,
                    KEY_DELETED = true,
                    KEY_BANNED = true,
                    KEY_INVALID = true,
                    KEY_EXPIRED = true,
                    DEVICE_MISMATCH = true,
                    DEVICE_INVALID = true
                }

                if revokedCodes[code] then
                    License._monitorRunning = false
                    if type(onRevoked) == "function" then
                        pcall(onRevoked, code, message)
                    end
                    terminateSession(message or code)
                    break
                end

                -- Temporary network/API failures do not revoke a valid license.
                warn("[Pryvex] License check temporarily unavailable: " .. tostring(message))
            end
        end
    end)

    return true
end

function License.stopMonitor()
    License._monitorRunning = false
end

return License
