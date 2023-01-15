local type = type
local tostring = tostring

-- What the heck is this
minetest.register_node(":crafterclient_version_checker:this_is_a_hack_to_not_crash_other_servers",{})

local client_versions = {}
local client_version_channels = {}

-- Storing a semantic versioning in a table like: {"alpha", 0.071}. This is serialized.
local current_development_cycle = "alpha"
-- 0.0.7b
local current_version = 0.071
local current_client_link = "https://github.com/jordan4ibanez/crafter_client"

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    client_version_channels[name] = minetest.mod_channel_join(name..":client_version_channel")
end)

-- TODO: inform the person that they need the client mod 10 seconds after they join if they're not in the version channel

-- TODO: all of these return ends needs to jump to a section that kicks them with the correct client mod link
minetest.register_on_modchannel_message(function(channel_name, sender, message)

    local channel_decyphered = channel_name:gsub(sender,"")

    if channel_decyphered ~= ":client_version_channel" then return end

    -- I don't know why this would ever happen but check anyways
    if not message then goto a_serious_error_occured end

    local version_info = minetest.deserialize(message)

    -- Player tried to do something weird to crash the server
    if not version_info then goto youre_an_asshole end

    -- Random data, tried to crash the server
    if not type(version_info) == "table" then goto youre_an_asshole end

    -- Not the right amount of data, tried to crash the server
    if #version_info ~= 2 then goto youre_an_asshole end

    -- Not the right type of data, tried to crash the server
    if type(version_info[1]) ~= "string" or type(version_info[2]) ~= "number" then goto youre_an_asshole end

    -- We know everything is okay and this person is just trying to play, let's continue
    local reported_development_cycle = version_info[1]
    local reported_version = version_info[2]

    -- Unfortunately, the client info does not match, kick them and tell them
    if reported_development_cycle ~= current_development_cycle or reported_version ~= current_version then goto wrong_client_version end


    -- This person is a piece of crap and is trying to crash an opensource game server, let's kick their ass out
    ::youre_an_asshole::

    minetest.kick_player(sender, "Stop trying to crash the server.")
    minetest.log("action", sender .. " tried to crash the server.")

    do return end

    -- This person has an outdated or future client mod, let them know in a kick message
    ::wrong_client_version::

    minetest.kick_player(sender,
        "You have the wrong client version.\n" ..
        "Your version: " .. tostring(reported_version) .. " " .. reported_development_cycle .. "\n" ..
        "Server version: " .. tostring(current_version) .. " " .. current_development_cycle .. "\n" ..
        "To install the correct version, please go to:\n" .. current_client_link
    )

    -- Something that absolutely isn't supposed to happen, happened
    ::a_serious_error_occured::

    minetest.kick_player(sender, "Something has gone seriously wrong, please check your client mod version.")
    minetest.log("action", sender .. " had a serious glitch occur with their client mod.")
end)

