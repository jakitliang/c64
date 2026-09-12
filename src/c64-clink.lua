-- c64's Clink entry point. Clink loads this file from lib\clink after
-- c64_shell.cmd starts CMD. Load its bundled defaults first, then the vendored
-- completion collection in a deterministic order.

local c64_home = clink.get_env("C64_HOME")
if not c64_home or c64_home == "" then
    return
end

-- The --scripts option replaces Clink's normal script path, so explicitly
-- retain the standard functionality bundled with Clink itself.
dofile(c64_home .. "\\opt\\clink\\clink.lua")

local config = c64_home .. "\\etc\\c64_prompt_config.lua"
local file = io.open(config, "r")
if file then
    file:close()
    dofile(config)
end
dofile(c64_home .. "\\lib\\clink\\c64-prompt.lua")

local completions = c64_home .. "\\opt\\clink-completions\\"
-- This archive's `!init.lua` establishes its Lua search path before the
-- individual completion scripts are loaded.
dofile(completions .. "!init.lua")

for _, name in ipairs(clink.find_files(completions .. "*.lua")) do
    if name ~= "!init.lua" and not name:match("^_") then
        dofile(completions .. name)
    end
end
