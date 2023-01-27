minetest.register_abm({
    label = "Lava cooling",
    nodenames = {"main:lava"},
    neighbors = {"main:water", "main:waterflow"},
    interval = 3,
    chance = 1,
    catch_up = false,
    action = function(pos)

        local lava = minetest.find_node_near(pos, 1, {"main:lava"})
        local water = minetest.find_node_near(pos, 1, {"main:waterflow", "main:water"})

        if lava and water then
            local dir1 = vector.direction(pos, lava)
            local dir2 = vector.direction(pos, water)
            -- Only allow direct contact
            if (math.abs(dir1.x) == 1 or math.abs(dir1.z) == 1) and (math.abs(dir2.x) == 1 or math.abs(dir2.z) == 1) then
                minetest.set_node(pos,{name="nether:obsidian"})
            end
        end
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

        local lava = minetest.find_node_near(pos, 1, {"main:lavaflow"})
        local water = minetest.find_node_near(pos, 1, {"main:waterflow", "main:water"})

        if lava and water then
            local dir1 = vector.direction(pos, lava)
            local dir2 = vector.direction(pos, water)
            -- Only allow direct contact
            if (math.abs(dir1.x) == 1 or math.abs(dir1.z) == 1) and (math.abs(dir2.x) == 1 or math.abs(dir2.z) == 1) then
                minetest.set_node(pos,{name="main:cobble"})
                minetest.get_meta(pos):set_int("lava_cooled", 1)
            end
        end
    end,
})
