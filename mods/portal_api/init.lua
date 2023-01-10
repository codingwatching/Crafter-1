local add_vector      = vector.add
local vec_distance    = vector.distance
local vec_new         = vector.new
local table_insert    = table.insert
local ipairs          = ipairs
local get_node        = minetest.get_node
local bulk_set_node   = minetest.bulk_set_node


local portal_node = ""
local frame_node = ""
local size_limit = 0


--TODO: add biome information into this thing, or dimensions? or maybe a dimension ID?

-- Micro 7d vector factory function
local function assemble_vec7d( vec, axis, origin )
    -- Piggyback on vec3d for new pointers in lua vm
    local initializing_vector = vec_new(vec)
    initializing_vector.axis = axis
    initializing_vector.a = origin.x
    initializing_vector.b = origin.y
    initializing_vector.c = origin.z
    return initializing_vector
end

-- Queue is build upon 7d vectors with:
--[[
    x,y,z = new position
    axis = x or z definition (boolean) - false = x, true = z
    a,b,c = origin position
]]

-- This is single threaded, only one queue can exist at a time, it will pause the server while it builds it
local queue = {}
local failure = false

local steps_x = {
    vec_new(  1,  0,  0 ),
    vec_new( -1,  0,  0 ),
    vec_new(  0,  1,  0 ),
    vec_new(  0, -1,  0 ),
}

local steps_z = {
    vec_new(  0,  1,  0 ),
    vec_new(  0, -1,  0 ),
    vec_new(  0,  0,  1 ),
    vec_new(  0,  0, -1 ),
}

local steps = {
    steps_x,
    steps_z
}

local steps_3d = {
    vec_new(  1,  0,  0 ),
    vec_new( -1,  0,  0 ),
    vec_new(  0,  1,  0 ),
    vec_new(  0, -1,  0 ),
    vec_new(  0,  0,  1 ),
    vec_new(  0,  0, -1 ),
}

local function axis_to_integer(axis)
    if axis then return 2 end
    return 1
end

local function match_origin( a, b, c, vec)
    return vec.a == a and vec.b == b and vec.c == c
end

local iterator_keys = {
    "x", "y", "z", "axis", "a", "b", "c"
}
local function match_full_queue(vec_3d)
    for _,this in ipairs(queue) do
        if this.x == vec_3d.x and this.y == vec_3d.y and this.z == vec_3d.z then return true end
    end
    return false
end

local function insert_new_queue_item(vec_7d)
    table_insert(queue, vec_7d)
end

local function clear_queue()
    queue = {}
end

local pos = {}
local axis = false
local origin = {}
local new_position = {}
local current_index = 0
local length = 0
local vec3d_cache = {}
local second_loop = false

local function generate_portal(vec_7d)

    pos = vec_new( vec_7d.x, vec_7d.y, vec_7d.z )
    axis = vec_7d.axis
    origin = vec_new( vec_7d.a, vec_7d.b, vec_7d.c )

    -- 2d virtual memory map creation
    for _,direction in ipairs( steps[ axis_to_integer( axis ) ] ) do

        new_position = add_vector( pos, direction )

        if match_full_queue( new_position ) then goto continue end

        if get_node( new_position ).name == "air" then
            if vec_distance( new_position, origin ) < size_limit then
                -- Everything is going well
                insert_new_queue_item( assemble_vec7d( new_position, axis, origin ) )
            else
                -- This means the portal failed to intialize, so try the other axis
                clear_queue()
                insert_new_queue_item( assemble_vec7d( origin, not axis, origin ) )
            end
        elseif get_node( new_position ).name ~= frame_node then
            -- This part basically means the portal exceeded the size limit and it failed completely, exits out here in the globalstep
            -- Might have hit a wall, random node, who knows! It's not air, and it's not the portal frame
            failure = true
        end

        ::continue::
    end
end

-- This is the entry point for portal creation and logic loop
function create_portal(position, new_frame_node, new_portal_node, new_size_limit, return_portal_callback)

    frame_node = new_frame_node
    portal_node = new_portal_node
    size_limit = new_size_limit

    failure = false

    insert_new_queue_item( assemble_vec7d( position, false, position ) )

    current_index = 1

    second_loop = false

    -- Keep the heap objects alive so the gc isn't abused
    while not failure and current_index <= #queue do

        generate_portal(queue[current_index])
        current_index = current_index + 1

        if failure and not second_loop then
            clear_queue()
            insert_new_queue_item( assemble_vec7d( position, true, position ) )
            second_loop = true
            failure = false
            current_index = 1
        end
    end

    -- Failed to build one, now gc clear the queue
    if failure then
        clear_queue()
        return
    end

    -- Success! Place the precalculated indexes

    vec3d_cache = {}

    length = 1
    for _,vec_7d in ipairs(queue) do
        vec3d_cache[length] = vec_new(vec_7d.x, vec_7d.y,vec_7d.z)
        length = length + 1
    end

    bulk_set_node( vec3d_cache, { name = portal_node } )

    return_portal_callback(position)

    -- Clean up memory
    clear_queue()
end

local function delete_portal(vec_7d)

    pos = vec_new( vec_7d.x, vec_7d.y, vec_7d.z )
    axis = vec_7d.axis
    origin = vec_new( vec_7d.a, vec_7d.b, vec_7d.c )

    -- 3d virtual memory map creation
    for _,position in ipairs( steps_3d ) do

        new_position = add_vector( pos, position )

        if match_full_queue( new_position ) then goto continue end
        if get_node( new_position ).name ~= portal_node then goto continue end
        if vec_distance( new_position, origin ) >= size_limit then goto continue end

        insert_new_queue_item( assemble_vec7d( new_position, axis, origin ) )

        ::continue::
    end
end

-- The entry point for the portal deletion and logic loop
function destroy_portal( position, new_frame_node, new_portal_node, new_size_limit)

    frame_node = new_frame_node
    portal_node = new_portal_node
    size_limit = new_size_limit

    insert_new_queue_item( assemble_vec7d( position, false, position ) )

    current_index = 1

    -- Logic loop
    while current_index <= #queue do
        delete_portal( queue[ current_index ] )
        current_index = current_index + 1
    end

    -- Didn't have a portal
    if #queue <= 1 then
        clear_queue()
        return
    end

    vec3d_cache = {}

    length = 1

    -- Convert the 7d vector into a usable 3d vector
    for _,vec_7d in ipairs( queue ) do
        vec3d_cache[ length ] = vec_new( vec_7d.x, vec_7d.y,vec_7d.z )
        length = length + 1
    end

    -- Apply the changes
    bulk_set_node( vec3d_cache, { name = "air" } )

    -- Clean up memory
    clear_queue()
end
