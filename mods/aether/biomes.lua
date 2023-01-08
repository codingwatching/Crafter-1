local VoxelArea = VoxelArea
local get_content_id = minetest.get_content_id
local get_perlin_map = minetest.get_perlin_map
local get_mapgen_object = minetest.get_mapgen_object
local vec_new = vector.new

minetest.register_biome({
    name = "aether",
    node_top = "air",
    depth_top = 1,
    node_filler = "air",
    depth_filler = 3,
    node_riverbed = "air",
    depth_riverbed= 0,
    node_stone = "air",
    node_water = "air",
    node_dungeon = "air",
    node_dungeon_alt = "air",
    node_dungeon_stair = "air",
    node_cave_liquid = "air",
    vertical_blend = 0,
    y_max = 31000,
    y_min = 21000,
    heat_point = -100,
    humidity_point = -100,
})

-- Set the 3D noise parameters for the terrain
local noise_parameters = {
    offset = 0,
    scale = 1,
    spread = {x = 200, y = 100, z = 200},
    seed = tonumber(minetest.get_mapgen_setting("seed")) or math.random(0,999999999),
    octaves = 5,
    persist = 0.63,
    lacunarity = 2.0,
}

local vm = {}
local emin = {}
local emax = {}
local area = VoxelArea:new({MinEdge = vec_new(0,0,0), MaxEdge = vec_new(0,0,0)})
local density_noise  = {}

local data = {}

local c_dirt = get_content_id("aether:dirt")
local c_stone = get_content_id("aether:stone")
local c_air = get_content_id("air")
local c_grass = get_content_id("aether:grass")

local index
local pos
local below_index

local constant_area = {x = 80, y = 80, z = 80}
local constant_perlin

-- This grabs the perlin generator on the start of the server, exactly on the first tick
minetest.register_on_mods_loaded(function()
    minetest.after(0,function()
        constant_perlin = get_perlin_map(noise_parameters, constant_area)
    end)
end)

minetest.register_on_generated(function(minp, maxp)

    --aether starts at 21000
    if minp.y < 21000 then
        return
    end

    constant_perlin:get_3d_map_flat(minp, density_noise)
    vm, emin, emax = get_mapgen_object("voxelmanip")
    vm:get_data(data)
    area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
    index = 1

    -- Use the much faster pointer based iterator
    -- Important note: z,y,x
    for weird_index in area:iterp(minp, maxp) do

        if density_noise[index] > 0.1 then
            data[weird_index] = c_dirt
        else
            -- This puts grass on top
            pos = area:position(weird_index)
            pos.y = pos.y - 1
            below_index = area:indexp(pos)

            if data[below_index] == c_dirt then
                data[below_index] = c_grass
            end
        end

        index = index + 1
    end

    vm:set_data(data)
    vm:calc_lighting(nil, nil, false)
    vm:write_to_map()
end)
