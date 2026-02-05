local modname = "mod1"
local modpath = minetest.get_modpath(modname)
if not modpath then
    error("Mod path not found: " .. modname)
end

-- === Handler code ===
local mod_handler = {}

-- World path and JSON files
local worldpath = minetest.get_worldpath()
local grequest_file = worldpath .. "/grequest.json"
local userresponse_file = worldpath .. "/userresponse.json"

local shown = {} -- Store displayed responses

-- Read / create JSON
local function ensure_json(file)
    local f = io.open(file, "r")
    if not f then
        local f2 = io.open(file, "w")
        f2:write(minetest.write_json({}))
        f2:close()
        return {}
    end
    local content = f:read("*all")
    f:close()
    return minetest.parse_json(content) or {}
end

-- Save JSON
local function save_json(file, tbl)
    local f = io.open(file, "w")
    f:write(minetest.write_json(tbl))
    f:close()
end

-- Write player message to JSON and check userresponse
local function handle_message(player_name, message)
    -- ===== grequest.json =====
    local grequests = ensure_json(grequest_file)
    local found = false

    for _, req in ipairs(grequests) do
        if req.player == player_name then
            req.message = message
            found = true
            break
        end
    end

    if not found then
        table.insert(grequests, { player = player_name, message = message })
    end
    save_json(grequest_file, grequests)

    -- ===== userresponse.json =====
    local responses = ensure_json(userresponse_file)
    local resp_found = false

    for _, resp in ipairs(responses) do
        if resp.player == player_name and resp.message == message then
            resp_found = true
            break
        end
    end

    if not resp_found then
        table.insert(responses, { player = player_name, message = message, reply = "" })
        save_json(userresponse_file, responses)
    end
end

-- 🔁 Check AI responses and show only once
minetest.register_globalstep(function(dtime)
    local responses = ensure_json(userresponse_file)

    for _, resp in ipairs(responses) do
        local key = resp.player .. resp.message
        if not shown[key] and resp.reply ~= "" then
            minetest.chat_send_player(resp.player, "@Lexia: " .. resp.reply)
            shown[key] = true
        end
    end
end)

mod_handler.process_message = handle_message

-- === Capture chat messages ===
minetest.register_on_chat_message(function(name, message)
    if message:sub(1,1) == "@" then
        local clean_message = message:sub(2):gsub("^%s+", "")
        mod_handler.process_message(name, clean_message)
        return true
    end
end)

-- === Global reference for BoyKisser ===
mod1 = mod1 or {}
mod1.boykisser_obj = nil

-- Separate file for BoyKisser commands
dofile(modpath .. "/boykisser.lua")
