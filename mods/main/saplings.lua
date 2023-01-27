local get_node_light = minetest.get_node_light
local get_item_group = minetest.get_item_group
local get_node = minetest.get_node
local set_node = minetest.set_node
local place_schematic = minetest.place_schematic
local register_node = minetest.register_node
local remove_node = minetest.remove_node
local get_node_timer = minetest.get_node_timer
local dig_node = minetest.dig_node
local vec_new = vector.new
local math_random = math.random

local function start_grow_timer(pos)
    get_node_timer(pos):start(math_random(20,250))
end

local function sapling_grow(pos)
    if get_node_light(pos) < 10 then
        start_grow_timer(pos)
        return
    end

    if get_item_group(get_node(vec_new(pos.x,pos.y-1,pos.z)).name, "soil") > 0 then
        local good_to_grow = true
        -- Check if room to grow (leaves or air)
        for i = 1,4 do
            local node_name = get_node(vec_new(pos.x,pos.y+i,pos.z)).name
            if node_name ~= "air" and node_name ~= "main:leaves" then
                good_to_grow = false
            end
        end
        if good_to_grow == true then
            remove_node(pos)
            local schematic = math_random(1,2)
            if schematic == 1 then
                place_schematic(pos, tree_big,"0",nil,false,"place_center_x, place_center_z")
            elseif schematic == 2 then
                place_schematic(pos, tree_small,"0",nil,false,"place_center_x, place_center_z")
            end
            --override leaves
            local max = 3
            if schematic == 2 then
                max = 1
            end
            for i = 1,max do
                set_node(vec_new(pos.x,pos.y+i,pos.z),{name="main:tree"})
            end
        end
    end
end

register_node("main:sapling", {
    description = "Sapling",
    drawtype = "plantlike",
    inventory_image = "sapling.png",
    waving = 1,
    walkable = false,
    climbable = false,
    paramtype = "light",
    is_ground_content = false,
    tiles = {"sapling.png"},
    groups = {leaves = 1, plant = 1, axe = 1, hand = 0,instant=1, sapling=1, attached_node=1,flammable=1},
    sounds = main.dirtSound(),
    drop = "main:sapling",
    node_placement_prediction = "",
    selection_box = {
        type = "fixed",
        fixed = {-4 / 16, -0.5, -4 / 16, 4 / 16, 7 / 16, 4 / 16}
    },
    on_construct = function(pos)
        if get_item_group(get_node(vec_new(pos.x, pos.y - 1, pos.z)).name, "soil") <= 0 then
            dig_node(pos)
            return
        end
        start_grow_timer(pos)
    end,
    on_timer = sapling_grow
})