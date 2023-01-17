local ipairs = ipairs
local find_nodes_in_area = minetest.find_nodes_in_area
local get_node = minetest.get_node
local set_node = minetest.set_node
local get_node_timer = minetest.get_node_timer
local get_item_group = minetest.get_item_group
local dig_node = minetest.dig_node

local math_random = math.random
local math_abs = math.abs


-- TODO: There can be an extreme amount of soil at once in huge farms so reuse as much data on the heap as possible

local farmland = {
    "wet","dry"
}
local water_nodes = {
    "main:water","main:waterflow"
}

local function find_water(pos)
    return #find_nodes_in_area( vector.new( pos.x - 3, pos.y, pos.z - 3 ), vector.new( pos.x + 3, pos.y, pos.z + 3 ), water_nodes) > 0
end

for level,dryness in ipairs(farmland) do

    local coloring = 160 / level
    local on_construct
    local on_timer

    if dryness == "wet" then
        on_construct = function(pos)
            if not find_water(pos) then
                set_node(pos,{name="farming:farmland_dry"})
            end
            get_node_timer(pos):start(1)
        end

        on_timer = function(pos)
            if not find_water(pos) then
                set_node(pos,{name="farming:farmland_dry"})
            end
            get_node_timer(pos):start(math_random(10,25))
        end
    else
        on_construct = function(pos)
            get_node_timer(pos):start(math_random(10,25))
        end

        on_timer = function(pos)
            if find_water(pos) then
                set_node(pos,{name="farming:farmland_wet"})
                get_node_timer(pos):start(1)
            else
                set_node(pos,{name="main:dirt"})
                if get_item_group( get_node( vector.new( pos.x, pos.y + 1, pos.z ) ).name, "plant" ) > 0 then
                    dig_node( vector.new( pos.x, pos.y + 1, pos.z ) )
                end
            end
        end
    end

    minetest.register_node("farming:farmland_" .. dryness,{
        description = "Farmland",
        paramtype = "light",
        drawtype = "nodebox",
        sounds = main.dirtSound(),
        node_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, 6/16, 0.5},
        },
        wetness = math_abs(level-2),
        collision_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, 6/16, 0.5},
        },
        tiles = {
            "dirt.png^farmland.png^[colorize:black:" .. coloring,
            "dirt.png^[colorize:black:" .. coloring,
            "dirt.png^[colorize:black:" .. coloring,
            "dirt.png^[colorize:black:" .. coloring,
            "dirt.png^[colorize:black:" .. coloring,
            "dirt.png^[colorize:black:" .. coloring
        },
        groups = { dirt = 1, soft = 1, shovel = 1, hand = 1, soil = 1, farmland = 1, pathable = 1 },
        drop="main:dirt",
        on_construct = on_construct,
        on_timer = on_timer,
    })
end
