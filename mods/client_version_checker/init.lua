local type = type

-- What the heck is this
minetest.register_node(":crafterclient_version_checker:this_is_a_hack_to_not_crash_other_servers",{})

local client_versions = {}
local client_version_channels = {}

-- Storing a semantic versioning in a table like: {"alpha", 0.071}. This is serialized.
local current_development_cycle = "alpha"
local current_version = 0.071

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    client_version_channels[name] = minetest.mod_channel_join(name..":client_version_channel")
end)

minetest.register_on_modchannel_message(function(channel_name, sender, message)

    local channel_decyphered = channel_name:gsub(sender,"")

    if channel_decyphered == ":client_version_channel" then
        local version = tonumber(message)
        if type(version) ~= "number" then
            minetest.chat_send_player(sender, minetest.colorize("yellow", "Please do not try to crash the server."))
            for _ = 1,5 do
                minetest.log("warning", sender .. " tried to crash the server!")
            end
        elseif type(version) == "number" then
            if current_development_cycle == "alpha" and version > 0.0999 then
                minetest.chat_send_player(sender, minetest.colorize("yellow", "Please update your client mod."))
                minetest.log("warning", sender.." logged in with an outdated client.")
            elseif version < current_version then
                minetest.chat_send_player(sender, minetest.colorize("yellow", "You need to update your clientmod. Your client version: ")..
                minetest.colorize("white",version)..minetest.colorize("yellow",". Current server version: ").. minetest.colorize("white",current_version)..
                minetest.colorize("yellow",". The game might not work as intended or crash."))
                minetest.log("warning", sender.." logged in with an outdated client.")
            elseif version > current_version then
                minetest.chat_send_player(sender, minetest.colorize("yellow", "Your client mod is new than the server version. Your client version: ")..
                minetest.colorize("white",version)..minetest.colorize("yellow",". Current server version: ")..
                minetest.colorize("white",current_version)..minetest.colorize("yellow",". The game might not work as intended or crash."))
                minetest.log("warning", sender.." logged in with a client new than the server version.")
            end
        end
    end
end)

