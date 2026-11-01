-- Pryvex License client helper.
-- Re-checks the server so disabled/deleted licenses stop working in-session.
-- DeviceId is client-reported and is not hardware attestation.

local API_URL = "https://yfsmtoetvajschaeyagc.supabase.co/functions/v1/license-api"

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
            Headers = { ["Content-Type"] = "application/json" },
            Body = game:GetService("HttpService"):JSONEncode(body)
        })
    end)
    if not ok then return nil, tostring(response) end

    local statusCode = tonumber(response.StatusCode or response.Status or 0) or 0
    local responseBody = response.Body or response.body or ""
    local decodedOk, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(responseBody)
    end)
    if not decodedOk then return nil, "Invalid response from license server." end
    if statusCode < 200 or statusCode >= 300 then
        return decoded, decoded.error or "License verification failed."
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
        discord_id = type(discordId) == "string" and discordId or nil
    })

    if not result then
        return false, "NETWORK_ERROR", err or "License server unavailable"
    end

    if result.valid ~= true then
        return false,
            result.code or "KEY_INVALID",
            result.error or err or "License verification failed"
    end

    -- The API's valid=true response is authoritative. Older API responses
    -- do not include a plan field, so do not reject a valid key for that.
    return true, nil, nil
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
    intervalSeconds = math.max(15, tonumber(intervalSeconds) or 30)
    if License._monitorRunning then return false end
    License._monitorRunning = true

    task.spawn(function()
        while License._monitorRunning do
            task.wait(intervalSeconds)
            if not License._monitorRunning then break end

            local valid, code, message = checkLicense()
            if not valid then
                local revokedCodes = {
                    KEY_DISABLED = true,
                    KEY_DELETED = true,
                    KEY_BANNED = true,
                    KEY_INVALID = true,
                    KEY_EXPIRED = true,
                    DEVICE_MISMATCH = true
                }

                if revokedCodes[code] then
                    License._monitorRunning = false
                    if type(onRevoked) == "function" then
                        pcall(onRevoked, code, message)
                    end
                    break
                end

                -- Temporary network/API failures must never be treated as
                -- a wrong key or revoke a currently working session.
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
