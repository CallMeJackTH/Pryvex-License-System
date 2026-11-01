# Pryvex Hub modules

This folder is intentionally separate from the license and UI bootstrap code.

## Files

- `ModuleTemplate.lua` — copy this file as the starting point for a module you write.
- Keep each independently maintained feature in its own Lua file.
- Do not put license secrets or Supabase service-role credentials in client Lua.

## Module contract

Each module should return a table with an `Initialize(Window, Tabs)` function.

The main loader should call that function only after license verification succeeds and
the Pryvex Hub window and tabs have been created.

Example integration point:

```lua
-- TODO: Replace the URL with the raw URL of your own module.
-- local source = game:HttpGet(MODULE_URL)
-- local chunk = assert(loadstring(source))
-- local module = chunk()
-- assert(type(module) == "table" and type(module.Initialize) == "function")
-- module.Initialize(window, tabs)
```

This repository template does not include game-specific gameplay or automation code.
Only add code for experiences you own or are authorized to modify.
