--this is from https://github.com/HybridDog/builtin_item/blob/e6dfd9dce86503b3cbd1474257eca5f6f6ca71c2/init.lua#L50

local ipairs = ipairs
local get_node = minetest.get_node
local vec_new = vector.new
local vec_subtract = vector.subtract
local vec_add = vector.add
local registered_nodes

minetest.register_on_mods_loaded(function()
    registered_nodes = minetest.registered_nodes
end)

local index
local new_pos
local data
local param2
local name
local node_name
local gotten_node
local this_node
local this_name
local this_param2
local cached_node


-- Position instructions to step through
local position_instructions = {
    -- First get corners
    vec_new(-1, 0, -1 ),
    vec_new(-1, 0,  1 ),
    vec_new( 1, 0, -1 ),
    vec_new( 1, 0,  1 ),

    -- Then adjacent
    vec_new(-1, 0, 0 ),
    vec_new( 1, 0, 0 ),
    vec_new( 0, 0,-1 ),
    vec_new( 0, 0, 1 )
}

-- A data vector factory
local function create_data_vector( position, node_data )
    local new_data_vector = {}
    new_data_vector.x = position.x
    new_data_vector.y = position.y
    new_data_vector.z = position.z
    new_data_vector.name = node_data.name
    new_data_vector.param2 = node_data.param2
    return new_data_vector
end

local function get_local_nodes(pos)
    data = {}
    index = 1
    for _,checking_position in ipairs( position_instructions ) do
        new_pos = vec_add( pos, checking_position )
        data[index] = create_data_vector( new_pos, get_node( new_pos ) )
        index = index + 1
    end
end


local function get_water_flowing_dir(pos)
    gotten_node = get_node(pos)
    node_name = gotten_node.name
    if node_name ~= "main:waterflow" and node_name ~= "main:water" then return nil end
    param2 = gotten_node.param2
    if param2 > 7 then return nil end
    -- This getter stores the data within the scoped "data" variable
    get_local_nodes(pos)
    for _,data_vector in ipairs(data) do
        this_name   = data_vector.name
        this_param2 = data_vector.param2
        if node_name == "main:water" and this_name == "main:waterflow" and this_param2 == 7 then
            return( vec_subtract( vec_new(data_vector.x, data_vector.y, data_vector.z), pos ) )
        elseif this_name == "main:waterflow" and this_param2 < param2 then
            return( vec_subtract( vec_new( data_vector.x, data_vector.y, data_vector.z), pos ) )
        elseif this_name == "main:waterflow" and this_param2 >= 11 then
            return( vec_subtract( vec_new( data_vector.x, data_vector.y, data_vector.z), pos ) )
        elseif this_name ~= "main:waterflow" and this_name ~= "main:water" then
            -- This is a special one, this goes into the huge array of nodes so only check if it hit this logic gate
            cached_node = registered_nodes[this_name]
            if cached_node and not cached_node.walkable then
                return( vec_subtract( vec_new( data_vector.x, data_vector.y, data_vector.z ), pos ) )
            end
        end
    end
    return nil
end

function flow_in_water( pos )
    return( get_water_flowing_dir( pos ) )
end

-- This only works in the nether
local function get_lava_flowing_dir(pos)
    gotten_node = get_node(pos)
    node_name = gotten_node.name
    if node_name ~= "nether:lavaflow" and node_name ~= "nether:lava" then return nil end
    param2 = gotten_node.param2
    if param2 > 7 then return nil end
    -- This getter stores the data within the scoped "data" variable
    get_local_nodes(pos)
    for _,data_vector in ipairs(data) do
        this_name   = data_vector.name
        this_param2 = data_vector.param2
        if node_name == "nether:lava" and this_name == "nether:lavaflow" and this_param2 == 7 then
            return( vec_subtract( vec_new(data_vector.x, data_vector.y, data_vector.z), pos ) )
        elseif this_name == "nether:lavaflow" and this_param2 < param2 then
            return( vec_subtract( vec_new( data_vector.x, data_vector.y, data_vector.z), pos ) )
        elseif this_name == "nether:lavaflow" and this_param2 >= 11 then
            return( vec_subtract( vec_new( data_vector.x, data_vector.y, data_vector.z), pos ) )
        elseif this_name ~= "nether:lavaflow" and this_name ~= "nether:lava" then
            -- This is a special one, this goes into the huge array of nodes so only check if it hit this logic gate
            cached_node = registered_nodes[this_name]
            if cached_node and not cached_node.walkable then
                return( vec_subtract( vec_new( data_vector.x, data_vector.y, data_vector.z ), pos ) )
            end
        end
    end
    return nil
end

function flow_in_lava( pos )
    return( get_lava_flowing_dir( pos ) )
end