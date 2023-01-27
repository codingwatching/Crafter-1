local get_node_light = minetest.get_node_light
local set_node = minetest.set_node

-- Grass spread abm
minetest.register_abm({
    label = "Grass Grow",
    nodenames = {"main:dirt"},
    neighbors = {"main:grass", "air"},
    interval = 10,
    chance = 1000,
    action = function(pos)
        if get_node_light( pos, nil ) < 10 then return end
        set_node( pos, { name = "main:grass" } )
    end,
})
