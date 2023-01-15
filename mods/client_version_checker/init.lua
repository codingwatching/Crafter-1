local type = type

-- What the heck is this
minetest.register_node(":crafterclient_version_checker:this_is_a_hack_to_not_crash_other_servers",{})

local client_versions = {}
local client_version_channels = {}

-- Storing a semantic versioning in a table like: {"alpha", 0.071}. This is serialized.
local current_development_cycle = "alpha"
-- 0.0.7b
local current_version = 0.071

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    client_version_channels[name] = minetest.mod_channel_join(name..":client_version_channel")
end)

-- TODO: all of these return ends needs to jump to a section that kicks them with the correct client mod link
minetest.register_on_modchannel_message(function(channel_name, sender, message)

    local channel_decyphered = channel_name:gsub(sender,"")

    if channel_decyphered ~= ":client_version_channel" then return end

    -- I don't know why this would ever happen but check anyways
    if not message then return end

    local version_info = minetest.deserialize(message)

    -- Player tried to do something weird to crash the server
    if not version_info then return end

    -- Random data, tried to crash the server
    if not type(version_info) == "table" then return end
    
    -- Not the right amount of data, tried to crash the server
    if #version_info ~= 2 then return end

    -- Not the right type of data, tried to crash the server
    if type(version_info[1]) ~= "string" or type(version_info[2]) ~= "number" then return end


    -- We know everything is okay and this person is just trying to play, let's continue




    -- We know this person is a piece of crap and is trying to crash an opensource game server, let's kick their ass out
    ::youre_an_asshole::


    -- This person has an outdated or future client mod, let them know
    ::wrong_client_version::



    
    
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
end)

