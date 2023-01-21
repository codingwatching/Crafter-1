-- TODO: Make this not a global
-- define global
hopper = {}

-- internationalization boilerplate
local MP = minetest.get_modpath(minetest.get_current_modname())
local S = minetest.get_translator("hopper")

hopper.formspec_bg = "background[-0.19,-0.25;9.41,9.49;gui_hb_bg.png]"

dofile(MP.."/config.lua")
dofile(MP.."/api.lua")
dofile(MP.."/utility.lua")
dofile(MP.."/doc.lua")
dofile(MP.."/nodes/hoppers.lua")
dofile(MP.."/nodes/chute.lua")
dofile(MP.."/nodes/sorter.lua")
dofile(MP.."/crafts.lua")
dofile(MP.."/abms.lua")


-------------------------------------------------------------------------------------------
-- Formspec handling

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if "hopper_formspec:" == string.sub(formname, 1, 16) then
        local pos = minetest.string_to_pos(string.sub(formname, 17, -1))
        local meta = minetest.get_meta(pos)
        local eject_setting = meta:get_string("eject") == "true"
        local filter_all_setting = meta:get_string("filter_all") == "true"
        if fields.eject then
            if eject_setting then
                meta:set_string("eject", nil)
            else
                meta:set_string("eject", "true")
            end
        end
        if fields.filter_all then
            if filter_all_setting then
                meta:set_string("filter_all", nil)
            else
                meta:set_string("filter_all", "true")
            end            
        end
    end
end)
