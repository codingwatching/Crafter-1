local type = type
local tostring = tostring

-- This is a simple check for the client mod to see if the player is on a crafter server
minetest.register_node(":crafter_client_version_checker:this_is_a_hack_to_not_crash_other_servers",{})

local checked_clients = {}
local client_version_channels = {}

-- Storing a semantic versioning in a table like: {"alpha", 0.071}. This is serialized.
local current_development_cycle = "alpha"
-- 0.0.8
local current_version = 0.08
local current_client_link = "https://github.com/jordan4ibanez/crafter_client"


-- This person does not have the client mod installed, kick them and tell them
local function client_not_installed(name)
    minetest.kick_player(name,
        "\nYou do not have the client mod installed.\n" ..
        "To install the correct version, please go to:\n" .. current_client_link
    )
end

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    client_version_channels[name] = minetest.mod_channel_join(name..":client_version_channel")

    -- Check if a client mod has successfully initialized
    minetest.after(5,
    function()

        if checked_clients[name] then return end

        client_not_installed(name)
    end)
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    checked_clients[name] = nil
end)



-- TODO: inform the person that they need the client mod 10 seconds after they join if they're not in the version channel

-- This person is a piece of crap and is trying to crash an opensource game server, let's kick their ass out
local function trying_to_crash_server(sender)
    minetest.kick_player(sender, "Stop trying to crash the server.")
    minetest.log("action", sender .. " tried to crash the server.")
end

-- Something that absolutely isn't supposed to happen, happened
local function a_serious_error(sender)
    minetest.kick_player(sender, "Something has gone seriously wrong, please check your client mod version.")
    minetest.log("action", sender .. " had a serious glitch occur with their client mod.")
end

-- This person has an outdated or future client mod, let them know in a kick message
local function wrong_client_version(sender, reported_development_cycle, reported_version)
    minetest.kick_player(sender,
        "\nYou have the wrong client version.\n" ..
        "Your version: " .. tostring(reported_version) .. " " .. reported_development_cycle .. "\n" ..
        "Server version: " .. tostring(current_version) .. " " .. current_development_cycle .. "\n" ..
        "To install the correct version, please go to:\n" .. current_client_link
    )
end

-- TODO: all of these return ends needs to jump to a section that kicks them with the correct client mod link
minetest.register_on_modchannel_message(function(channel_name, sender, message)

    local channel_decyphered = channel_name:gsub(sender,"")

    if channel_decyphered ~= ":client_version_channel" then return end

    -- I don't know why this would ever happen but check anyways
    if not message then
        a_serious_error(sender)
        return
    end

    local version_info = minetest.deserialize(message)

    -- Player tried to do something weird to crash the server
    if not version_info then
        trying_to_crash_server(sender)
        return
    end

    -- Random data, tried to crash the server
    if not type(version_info) == "table" then
        trying_to_crash_server(sender)
        return
    end

    -- Not the right amount of data, tried to crash the server
    if #version_info ~= 2 then
        trying_to_crash_server(sender)
        return
    end

    -- Not the right type of data, tried to crash the server
    if type(version_info[1]) ~= "string" or type(version_info[2]) ~= "number" then
        trying_to_crash_server(sender)
        return
    end

    -- We know everything is okay and this person is just trying to play, let's continue
    local reported_development_cycle = version_info[1]
    local reported_version = version_info[2]

    -- Unfortunately, the client info does not match, kick them and tell them
    if reported_development_cycle ~= current_development_cycle or reported_version ~= current_version then
        wrong_client_version(sender, reported_development_cycle, reported_version)
        return
    end

    -- Everything checked out
    checked_clients[sender] = true
end)

