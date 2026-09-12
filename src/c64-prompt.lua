-- c64's configurable, lightweight Clink prompt.

local function color(value, fallback)
    return value or fallback
end

local function folder_name(path)
    return path:match("[^\\/:]+$") or path
end

local function display_path(path)
    if prompt_useHomeSymbol then
        local home = clink.get_env("HOME")
        if home and home ~= "" and path:sub(1, #home) == home then
            path = (prompt_homeSymbol or "~") .. path:sub(#home + 1)
        end
    end
    if prompt_type == "folder" then
        path = folder_name(path)
    end
    return path
end

local function set_prompt()
    local cwd = display_path(clink.get_cwd())
    local user_at_host = ""
    if prompt_useUserAtHost then
        user_at_host = clink.get_env("USERNAME") .. "@" .. clink.get_env("COMPUTERNAME") .. " "
    end

    local separator = prompt_singleLine and " " or "\n"
    clink.prompt.value = color(uah_color, "\x1b[1;33;49m") .. user_at_host
        .. color(cwd_color, "\x1b[1;32;49m") .. cwd
        .. "\x1b[0m" .. separator
        .. color(lamb_color, "\x1b[1;30;49m") .. (prompt_lambSymbol or ">")
        .. "\x1b[0m "
end

clink.prompt.register_filter(set_prompt, 1)
