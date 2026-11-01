-- Pryvex License client helper.
-- DeviceId must be a stable identifier supplied by your supported executor/setup.
-- A client-supplied identifier can be spoofed; this is not hardware attestation.

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

    local statusCode = response.StatusCode or response.Status or 0
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

function License.verify()
    local env = getgenv and getgenv() or _G
    local key = env.Key
    local deviceId = env.DeviceId
    local discordId = env.id

    if type(key) ~= "string" or key == "" then
        warn("[Pryvex] Set getgenv().Key before loading.")
        return false
    end
    if type(deviceId) ~= "string" or #deviceId < 8 then
        warn("[Pryvex] Set a stable getgenv().DeviceId (minimum 8 characters).")
        return false
    end

    local result, err = postJson(API_URL, {
        action = "verify",
        key = key,
        device_id = deviceId,
        discord_id = type(discordId) == "string" and discordId or nil
    })

    if not result or result.valid ~= true then
        warn("[Pryvex] " .. tostring(err or (result and result.error) or "Verification failed"))
        return false
    end

    print("[Pryvex] License verified.")
    return true
end

return License
