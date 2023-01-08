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
    --flags = ""
}


-- Set singlenode mapgen (air nodes only).
-- Disable the engine lighting calculation since that will be done for a
-- mapchunk of air nodes and will be incorrect after we place nodes.
--minetest.set_mapgen_params({mgname = "singlenode", flags = "nolight"})
-- Get the content IDs for the nodes used.

local nobj_terrain = nil
local n_pos = {}
local node2 = ""
local vi
local sidelen
local permapdims3d  = {}
local vm = {}
local emin = {}
local emax = {}
local area = VoxelArea:new({MinEdge = vec_new(0,0,0), MaxEdge = vec_new(0,0,0)})
local node_index = 1
local density_noise  = {}

local perlin_data = {}
local data = {}

local c_dirt = get_content_id("aether:dirt")
local c_stone = get_content_id("aether:stone")
local c_air = get_content_id("air")
local c_grass = get_content_id("aether:grass")

local constant_area = {x = 80, y = 80, z = 80}
local constant_perlin

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

    perlin_data = constant_perlin:get_3d_map_flat(minp, perlin_data)
    node_index = 1
    vm, emin, emax = get_mapgen_object("voxelmanip")
    area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

    vm:get_data(data)

    for z = minp.z, maxp.z do
    for y = minp.y, maxp.y do

        vi = area:index(minp.x, y, z)
        for x = minp.x, maxp.x do

            density_noise = perlin_data[node_index]

            if density_noise > 0.1 then
                data[vi] = c_dirt
            else
                --force create grass
                n_pos = area:index(x,y-1,z)
                if data[n_pos] == c_dirt then
                    data[n_pos] = c_grass
                end
            end

            node_index = node_index + 1

            vi = vi + 1
        end
    end
    end


    vm:set_data(data)
    vm:set_lighting({day=15,night=10}, minp, maxp)
    vm:write_to_map()
        
        
    -- Liquid nodes were placed so set them flowing.
    --vm:update_liquids()

    -- Print generation time of this mapchunk.
    --local chugent = math.ceil((minetest.get_us_time()/1000000- t0) * 1000)
    --print ("[lvm_example] Mapchunk generation time " .. chugent .. " ms")
end)
