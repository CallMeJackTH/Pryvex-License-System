--[[
    Pryvex Hub - Custom Module Template
    Runtime: Roblox Executor
    UI Library: Pryvex Hub

    Copy this file when creating your own module.
    Keep this module separate from the license verification code.

    IMPORTANT:
    - Do not put Supabase service-role keys or other server secrets here.
    - The client-side license check is not tamper-proof.
    - Add only code you own or are authorized to run.
]]

local Module = {}

-- Called after the main loader has verified the license and created the UI.
-- Pass the existing Window and Tabs objects from the main loader.
function Module.Initialize(Window, Tabs)
    assert(Window, "[Pryvex] Window is required")
    assert(Tabs, "[Pryvex] Tabs table is required")

    -- TODO: Create your own tab or attach controls to an existing tab.
    -- Example:
    -- local MyTab = Window:AddTab({
    --     Title = "My Module",
    --     Icon = "code"
    -- })

    -- TODO: Add your own controls here.
    -- Keep game-specific implementation in its own file.

    print("[Pryvex] Custom module initialized.")
    return true
end

return Module
