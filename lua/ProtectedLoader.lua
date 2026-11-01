-- Pryvex Protected Lua Loader
-- The one-time code is created by an authenticated Discord admin at /scripts.html.
-- Codes expire after 90 seconds and can only be redeemed once.
-- This is a delivery gate, not DRM: delivered client code can still be inspected at runtime.

local env = (getgenv and getgenv()) or _G
local CODE = env.PryvexHandoffCode
local ENDPOINT = "https://yfsmtoetvajschaeyagc.supabase.co/functions/v1/script-gate"

local function stop(message)
    warn("[Pryvex Protected] " .. tostring(message))
    return nil
end

if type(CODE) ~= "string" or not CODE:match("^[%da-fA-F]+$") or #CODE ~= 64 then
    return stop("Set getgenv().PryvexHandoffCode to the one-time code from the admin panel.")
end

local httpRequest =
    (syn and syn.request)
    or http_request
    or request

if type(httpRequest) ~= "function" then
    return stop("This executor does not expose a supported HTTP request function.")
end

local HttpService = game:GetService("HttpService")
local ok, response = pcall(function()
    return httpRequest({
        Url = ENDPOINT,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            action = "redeem",
            code = CODE
        })
    })
end)

if not ok or type(response) ~= "table" then
    return stop("Could not contact the protected script service.")
end

local status = tonumber(response.StatusCode or response.Status or 0)
if status < 200 or status >= 300 then
    local message = "Handoff code rejected or expired."
    if type(response.Body) == "string" then
        local decodedOk, decoded = pcall(HttpService.JSONDecode, HttpService, response.Body)
        if decodedOk and type(decoded) == "table" and decoded.error then
            message = tostring(decoded.error)
        end
    end
    return stop(message)
end

local decodeOk, payload = pcall(HttpService.JSONDecode, HttpService, response.Body or "")
if not decodeOk or type(payload) ~= "table" or payload.success ~= true
    or type(payload.source) ~= "string" or payload.source == "" then
    return stop("Protected service returned an invalid payload.")
end

-- Prevent accidental reuse of the same code in this executor session.
env.PryvexHandoffCode = nil

local compileOk, chunk = pcall(loadstring, payload.source)
if not compileOk or type(chunk) ~= "function" then
    return stop("Could not compile the delivered Lua script.")
end

local runOk, result = pcall(chunk)
if not runOk then
    return stop("Script error: " .. tostring(result))
end

return result
