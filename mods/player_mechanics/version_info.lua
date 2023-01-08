local register_on_joinplayer = minetest.register_on_joinplayer

local release_state = "Alpha"
local release_version = "0.07b"

local version_info = release_state .. " " .. release_version

local function addVersionInfo(player)

    -- This adds the version info to the hud to emulate how MC used to show it

    player:hud_add({
        name = "versionbg",
        text = version_info,
        hud_elem_type = "text",
        position = {
            x = 1,
            y = 0
        },
        number = 0x000000,
        offset = {
            x = -98,
            y = 20
        },
        size = {
            x = 2,
            y = 2
        },
        z_index = 0,
    })
    player:hud_add({
        hud_elem_type = "text",
        position = {
            x = 1,
            y = 0
        },
        name = "versionfg",
        text = version_info,
        number = 0xFFFFFF,
        offset = {
            x = -100,
            y = 18
        },
        size = {
            x = 2,
            y = 2
        },
        z_index = 0,
    })
end

register_on_joinplayer(
    function(player)
        addVersionInfo(player)
    end
)
