--[[ License information
Copyright 2019 - 2021 Lars Mueller alias LMD or appguru(eu)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

This has been heavily modified by jordan4ibanez
]]

-- https://github.com/appgurueu/modlib/blob/master/vector.lua

-- Returns new heap objects
local function subtract_scalar(vec, scalar)
    local new_vec = vector.new(vec.x, vec.y, vec.z)
    new_vec.x = new_vec.x - scalar
    new_vec.y = new_vec.y - scalar
    new_vec.z = new_vec.z - scalar
    return new_vec
end
local function divide_scalar(vec, scalar)
    local new_vec = vector.new(vec.x, vec.y, vec.z)
    new_vec.x = new_vec.x / scalar
    new_vec.y = new_vec.y / scalar
    new_vec.z = new_vec.z / scalar
    return new_vec
end


-- https://github.com/appgurueu/modlib/blob/master/minetest/liquid.lua

local liquid_level_max = 8

local function get_corner_level(neighbors, x, z)
    local air_neighbor
    local levels = 0
    local neighbor_count = 0
    for nx = x - 1, x do
        for nz = z - 1, z do
            local neighbor = neighbors[nx][nz]
            if neighbor.above_is_same_liquid then
                return 1
            end
            local level = neighbor.level
            if level then
                if level == 1 then
                    return 1
                end
                levels = levels + level
                neighbor_count = neighbor_count + 1
            elseif neighbor.air then
                if air_neighbor then
                    return 0.02
                end
                air_neighbor = true
            end
        end
    end
    if neighbor_count == 0 then
        return 0
    end
    return levels / neighbor_count
end

--+ Calculates the corner levels of a flowingliquid node
--> 4 corner levels from -0.5 to 0.5 as list of `modlib.vector`
local function get_liquid_corner_levels(pos)
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	local source, flowing = def.liquid_alternative_source, node.name
	local range = def.liquid_range or liquid_level_max
	local neighbors = {}
	for x = -1, 1 do
		neighbors[x] = {}
		for z = -1, 1 do
			local neighbor_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
			local neighbor_node = minetest.get_node(neighbor_pos)
			local level
			if neighbor_node.name == source then
				level = 1
			elseif neighbor_node.name == flowing then
				local neighbor_level = neighbor_node.param2 % 8
				level = (math.max(0, neighbor_level - liquid_level_max + range) + 0.5) / range
			end
			neighbor_pos.y = neighbor_pos.y + 1
			local node_above = minetest.get_node(neighbor_pos)
			neighbors[x][z] = {
				air = neighbor_node.name == "air",
				level = level,
				above_is_same_liquid = node_above.name == flowing or node_above.name == source
			}
		end
	end
    local corner_levels = {
        vector.new(0, 0, 0),
        vector.new(1, 0, 0),
        vector.new(1, 0, 1),
        vector.new(0, 0, 1)
    }
	for index, corner_level in pairs(corner_levels) do
		corner_level[2] = get_corner_level(neighbors, corner_level[1], corner_level[3])
		corner_levels[index] = subtract_scalar(vector.new(corner_level), 0.5)
	end
	return corner_levels
end

local flowing_downwards = vector.new(0, -1, 0)
--+ Calculates the flow direction of a flowingliquid node
--> `modlib.minetest.flowing_downwards = modlib.vector.new{0, -1, 0}` if only flowing downwards
--> surface direction as `modlib.vector` else
function get_liquid_flow_direction(pos)

	local corner_levels = get_liquid_corner_levels(pos)
	local max_level = corner_levels[1][2]
	for index = 2, 4 do
		local level = corner_levels[index][2]
		if level > max_level then
			max_level = level
		end
	end
	local dir = vector.new(0, 0, 0)
	local count = 0
	for max_level_index, corner_level in pairs(corner_levels) do
		if corner_level[2] == max_level then
			for offset = 1, 3 do
				local index = (max_level_index + offset - 1) % 4 + 1
				local diff = corner_level - corner_levels[index]
				if diff[2] ~= 0 then
					diff[1] = diff[1] * diff[2]
					diff[3] = diff[3] * diff[2]
					if offset == 3 then
						diff = divide_scalar(diff, math.sqrt(2))
					end
					dir = dir + diff
					count = count + 1
				end
			end
		end
	end
	if count ~= 0 then
		dir = divide_scalar(dir, count)
	end
	if dir == vector.new(0, 0, 0) then
		if minetest.get_node(pos).param2 % 32 > 7 then
			return flowing_downwards
		end
	end
	return dir
end



--[[
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
local node_name
local gotten_node
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
]]