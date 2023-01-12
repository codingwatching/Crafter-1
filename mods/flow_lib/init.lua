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
local function multiply_scalar(vec, scalar)
    local new_vec = vector.new(vec.x, vec.y, vec.z)
    new_vec.x = new_vec.x * scalar
    new_vec.y = new_vec.y * scalar
    new_vec.z = new_vec.z * scalar
    return new_vec
end
-- Indexing 1,9 this gives you x,z in a 1 node square area. Comparable to x = -1,1 and z = -1,1
local function convert_to_2d( index )
    -- Get carriage shift
    local x = math.ceil( index / 3 ) - 2
    -- Get carriage count
    local z = ( ( index - 1 ) % 3 ) - 1
    return x,z
end
local function convert_to_1d( x, z )
    -- Shift carriage to the right (jumps over values not in it's column)
    local m = x + 1
    -- Shift carriage to count
    local w = z + 2
    return (m * 3) + w
end



-- https://github.com/appgurueu/modlib/blob/master/minetest/liquid.lua

local liquid_level_max = 8

--! NOTE: this is step 3

local function get_corner_level(neighbors, x, z)

    local air_neighbor
    local levels = 0
    local neighbor_count = 0

    for i = 1,9 do

        local nx,nz = convert_to_2d( i )

        if (nx ~= x - 1 and nx ~= x) or (nz ~= z - 1 and nz ~= z) then goto continue end

        local neighbor = neighbors[i]

        if neighbor.above_is_same_liquid then return 1 end

        local level = neighbor.level

        if not level then goto skip end

        if level == 1 then return 1 end

        levels = levels + level

        neighbor_count = neighbor_count + 1

        ::skip::

        if not neighbor.air then goto continue end

        -- TODO: Figure out why the heck this is 0.02
        if air_neighbor then return 0.02 end

        air_neighbor = true

        ::continue::
    end

    if neighbor_count == 0 then return 0 end

    return levels / neighbor_count
end

--! NOTE: this is step 1 - BUT, this is not the entry point

--+ Calculates the corner levels of a flowingliquid node
--> 4 corner levels from -0.5 to 0.5 as list of `modlib.vector`
local function get_liquid_corner_levels(pos)

    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    local source = def.liquid_alternative_source
    local flowing = node.name
    local range = def.liquid_range or liquid_level_max
    local neighbors = {{},{},{},{},{},{},{},{},{},}

    -- Keep heap position allocated
    local function clear_neighbors()
        for i = 1,9 do
            neighbors[i] = nil
        end
    end

    -- TODO: preallocate outside scope and reuse this
    local neighbor_pos = vector.new( 0, 0, 0 )

    for i = 1,9 do

        local x,z = convert_to_2d( i )

        neighbor_pos.x = pos.x + x
        neighbor_pos.y = pos.y
        neighbor_pos.z = pos.z + z

        local neighbor_node = minetest.get_node(neighbor_pos)

        local level

        if neighbor_node.name == source then
            level = 1
        elseif neighbor_node.name == flowing then
            local neighbor_level = neighbor_node.param2 % 8
            level = ( math.max( 0, neighbor_level - liquid_level_max + range ) + 0.5 ) / range
        end

        neighbor_pos.y = neighbor_pos.y + 1

        local node_above = minetest.get_node(neighbor_pos)

        neighbors[i] = {
            air = neighbor_node.name == "air",
            level = level,
            above_is_same_liquid = node_above.name == flowing or node_above.name == source
        }

    end

    local corner_levels_to_be_modified = {
        vector.new(0, 0, 0),
        vector.new(1, 0, 0),
        vector.new(1, 0, 1),
        vector.new(0, 0, 1)
    }

    -- corner_levels_to_be_modified will pull out one of the data tables above { x = 0, y = 0, z = 0 }
    for index, corner_level in ipairs(corner_levels_to_be_modified) do
        corner_level.y = get_corner_level(neighbors, corner_level.x, corner_level.z)
        corner_levels_to_be_modified[index] = subtract_scalar( corner_level, 0.5)
    end

    return corner_levels_to_be_modified
end


--! NOTE: this is step 2 - BUT, it is the entry point

local flowing_downwards = vector.new(0, -1, 0)
--+ Calculates the flow direction of a flowingliquid node
--> `modlib.minetest.flowing_downwards = modlib.vector.new{0, -1, 0}` if only flowing downwards
--> surface direction as `modlib.vector` else
function get_liquid_flow_direction(pos)

    -- This returns a predefined linear array {1=data,2=data,3=data,4=data}
    local corner_levels = get_liquid_corner_levels(pos)

    local max_level = corner_levels[1].y

    for index = 2, 4 do

        local level = corner_levels[index].y

        if level > max_level then

            max_level = level

        end
    end

    local dir = vector.new(0, 0, 0)

    local count = 0

    -- Always indexed 1,2,3,4
    for max_level_index, corner_level in ipairs(corner_levels) do

        if corner_level.y ~= max_level then goto continue end

        -- 1,2,3
        for offset = 1,3 do

            local index = (max_level_index + offset - 1) % 4 + 1

            local diff = corner_level - corner_levels[index]

            if diff.y == 0 then goto skip end

            diff.x = diff.x * diff.y

            diff.z = diff.z * diff.y

            if offset == 3 then
                diff = divide_scalar(diff, math.sqrt(2))
            end

            dir = dir + diff

            count = count + 1

            ::skip::
        end

        ::continue::
    end

    if count ~= 0 then
        dir.y = 0
        dir = vector.normalize(dir)
        dir = multiply_scalar(dir, -1)
    end

    if dir == vector.new(0, 0, 0) and minetest.get_node(pos).param2 % 32 > 7 then
        return nil
    end

    return dir
end
