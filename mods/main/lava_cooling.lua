minetest.register_abm({
    label = "Lava source cooling",
    nodenames = {"main:lava"},
    neighbors = {"main:water", "main:waterflow"},
    interval = 3,
    chance = 1,
    catch_up = false,
    action = function(pos)
        local water = minetest.find_node_near(pos, 0.5, {"main:waterflow", "main:water"})
        if not water then return end
        local dir = vector.direction(pos, water)
        -- Only allow direct contact
        if math.abs(dir.x) == 1 or math.abs(dir.z) == 1 then
            minetest.set_node(pos,{name="nether:obsidian"})
        end
    end,
})

-- This sets up the initial cobblestone generator, there is no on_flow function in the api at the current moment
minetest.register_abm({
    label = "Lava flow cooling",
    nodenames = {"main:lavaflow"},
    neighbors = {"main:water", "main:waterflow"},
    interval = 3,
    chance = 1,
    catch_up = false,
    action = function(pos)
        local water = minetest.find_node_near(pos, 1, {"main:waterflow", "main:water"})
        if not water then return end
        local dir = vector.direction(pos, water)
        -- Only allow direct contact
        if math.abs(dir.x) == 1 or math.abs(dir.z) == 1 then
            minetest.set_node(pos,{name="main:cobble"})
            minetest.get_meta(pos):set_int("lava_cooled", 1)
        end
    end,
})
