minetest.register_abm({
    label = "Lava cooling",
    nodenames = {"main:lava"},
    neighbors = {"main:water", "main:waterflow"},
    interval = 1,
    chance = 1,
    catch_up = false,
    action = function(pos)
        minetest.set_node(pos,{name="nether:obsidian"})
    end,
})

-- This sets up the initial cobblestone generator, there is no on_flow function in the api at the current moment
minetest.register_abm({
    label = "Lava cooling",
    nodenames = {"main:lavaflow"},
    neighbors = {"main:water", "main:waterflow"},
    interval = 3,
    chance = 1,
    catch_up = false,
    action = function(pos)
        minetest.set_node(pos,{name="main:cobble"})
        minetest.get_meta(pos):set_int("lava_cooled", 1)
    end,
})
