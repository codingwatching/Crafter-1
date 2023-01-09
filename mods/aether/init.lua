local path = minetest.get_modpath("aether")
dofile(path.."/schem.lua")
dofile(path.."/nodes.lua")
dofile(path.."/biomes.lua")

local aether_portal_schematic = aether_portal_schematic

local abs    = math.abs
local random = math.random

local add_vector   = vector.add
local sub_vector   = vector.subtract
local vec_distance = vector.distance
local vec_new   = vector.new
local vec_copy = vector.copy

local table_copy   = table.copy
local table_insert = table.insert
local ipairs = ipairs

local emerge_area                  = minetest.emerge_area
local get_node                     = minetest.get_node
local find_node_near               = minetest.find_node_near
local find_nodes_in_area_under_air = minetest.find_nodes_in_area_under_air
local place_schematic              = minetest.place_schematic
local bulk_set_node                = minetest.bulk_set_node

local aether_channels = {}
local name
minetest.register_on_joinplayer(function(player)
    name = player:get_player_name()
    aether_channels[name] = minetest.mod_channel_join(name..":aether_teleporters")
end)

--TODO: add biome information into the thing, or dimensions? or maybe a dimension ID?
-- Micro 7d vector factory function
--[[
local function assemble_vec7d( x, y, z, axis, a, b, c )
    -- Piggyback on vec3d for new pointers in lua vm
    local initializing_vector = vec_new( x, y, z )
    initializing_vector.axis = axis
    initializing_vector.a = a
    initializing_vector.b = b
    initializing_vector.c = c
    return initializing_vector
end
]]
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
local build_queue = {}
local deletion_queue = {}
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
local function match_full_build_queue(vec_3d)
    for _,this in ipairs(build_queue) do
        if this.x == vec_3d.x and this.y == vec_3d.y and this.z == vec_3d.z then return true end
    end
    return false
end
local function match_full_deletion_queue(vec_3d)
    for _,this in ipairs(build_queue) do
        if this.x == vec_3d.x and this.y == vec_3d.y and this.z == vec_3d.z then return true end
    end
end

local function insert_new_build_item(vec_7d)
    table_insert(build_queue, vec_7d)
end
local function insert_new_deletion_item(vec_7d)
    table_insert(build_queue, vec_7d)
end

local function clear_build_queue()
    build_queue = {}
end
local function clear_deletion_queue()
    deletion_queue = {}
end

-- Creates an aether portal in the aether
-- This essentially makes it so you have to move 30 away from one portal to another otherwise it will travel to an existing portal
local aether_origin_pos = nil

local function spawn_portal_into_aether_callback(_, _, calls_remaining)

    if calls_remaining > 0 then goto continue end

    local portal_exists = find_node_near( aether_origin_pos, 30, { "aether:portal" } )

    if portal_exists then goto continue end

    local min = sub_vector(aether_origin_pos,30)
    local max = add_vector(aether_origin_pos,30)
    local platform = find_nodes_in_area_under_air(min, max, {"aether:dirt","aether:grass"})

    if platform and next(platform) then
        place_schematic( platform[ random( 1, #platform )] , aether_portal_schematic, "0", nil, true, "place_center_x, place_center_z" )
    else
        place_schematic( aether_origin_pos, aether_portal_schematic, "0", nil, true, "place_center_x, place_center_z" )
    end

    ::continue::
end

-- Creates aether portals in the overworld
local function spawn_portal_into_overworld_callback( _, _, calls_remaining )

    if calls_remaining > 0 then goto continue end

    if find_node_near( aether_origin_pos, 30, { "aether:portal" } ) then goto continue end

    local min = sub_vector( aether_origin_pos, 30 )
    local max = add_vector( aether_origin_pos, 30 )
    local platform = find_nodes_in_area_under_air( min, max, { "main:stone", "main:water", "main:grass", "main:sand", "main:dirt" } )

    if platform and next( platform ) then
        place_schematic( platform[ random( 1, #platform ) ], aether_portal_schematic, "0", nil, true, "place_center_x, place_center_z"  )
    else
        place_schematic( aether_origin_pos, aether_portal_schematic, "0", nil, true, "place_center_x, place_center_z" )
    end

    ::continue::
end

local function generate_return_portal(pos)
    if pos.y < 20000 then
        --center the location to the lava height
        pos.y = 25000--+random(-30,30)    
        aether_origin_pos = pos
        
        local min = sub_vector(aether_origin_pos,30)
        local max = add_vector(aether_origin_pos,30)
        
        --force load the area
        emerge_area(min, max, spawn_portal_into_aether_callback)
    else
        --center the location to the water height
        pos.y = 0--+random(-30,30)    
        aether_origin_pos = pos
        --prefer height for mountains
        local min = sub_vector(aether_origin_pos,vec_new(30,30,30))
        local max = add_vector(aether_origin_pos,vec_new(30,120,30))
        
        --force load the area
        emerge_area(min, max, spawn_portal_into_overworld_callback)
    end
end


-- TODO: make this name more generic
-- TODO: reuse as much data as possible
-- TODO: generic node cache, store in single value as only one portal creation exists at a time
local function local_create_aether_portal(vec_7d)

    -- TODO: make these a reused heap object
    local pos = vec_new( vec_7d.x, vec_7d.y, vec_7d.z )
    local axis = vec_7d.axis
    local origin = vec_new( vec_7d.a, vec_7d.b, vec_7d.c )

    -- 2d virtual memory map creation
    for _,direction in ipairs(steps[axis_to_integer(axis)]) do

        local new_position = add_vector(pos,direction)

        if match_full_build_queue(new_position) then goto continue end

        if get_node(new_position).name == "air" then
            if vec_distance(new_position,origin) < 50 then
                -- Everything is going well
                insert_new_build_item(assemble_vec7d(new_position, axis, origin))
            else
                -- This means the portal failed to intialize, so try the other axis
                clear_build_queue()
                insert_new_build_item(assemble_vec7d(origin, not axis, origin))
            end
        elseif get_node(new_position).name ~= "nether:glowstone" then
            -- This part basically means the portal exceeded the size limit and it failed completely, exits out here in the globalstep
            -- Might have hit a wall, random node, who knows! It's not air, and it's not the portal frame
            failure = true
        end

        ::continue::
    end
end

-- TODO: this is poop, generic this
-- This is the generic entry point for the portal creation
function create_aether_portal(position --[[frame_node, portal_node, size_limit, something_else?]])

    failure = false

    insert_new_build_item( assemble_vec7d( position, false, position ) )

    local current_index = 1

    local second_loop = false

    -- Keep the heap objects alive so the gc isn't abused
    while not failure and current_index <= #build_queue do
        -- print(dump(build_queue[current_index]))
        local_create_aether_portal(build_queue[current_index])
        current_index = current_index + 1

        if failure and not second_loop then
            clear_build_queue()
            insert_new_build_item( assemble_vec7d( position, true, position ) )
            second_loop = true
            failure = false
            current_index = 1
        end
    end

    -- Failed to build one, now gc clear the queue
    if failure then
        clear_build_queue()
        return
    end

    -- Success! Place the precalculated indexes

    -- TODO: reuse a heap object for this!

    local vec3d_cache = {}

    print(dump(build_queue))

    local length = 1
    for _,vec_7d in ipairs(build_queue) do
        vec3d_cache[length] = vec_new(vec_7d.x, vec_7d.y,vec_7d.z)
        length = length + 1
    end

    bulk_set_node( vec3d_cache, { name = "aether:portal" } )

    generate_return_portal(position)
end


-- TODO: make this a while loop!

local destroy_a_index = {}
local destroy_aether_portal_failure = false
local destroy_aether_portal_failed = false

--this can be used globally to create aether portals from obsidian
local function local_destroy_aether_portal(vec_7d)

    -- TODO: make these a reused heap object
    local pos = vec_new( vec_7d.x, vec_7d.y, vec_7d.z )
    local axis = vec_7d.axis
    local origin = vec_new( vec_7d.a, vec_7d.b, vec_7d.c )

    destroy_aether_portal_failed = true

    --3d virtual memory map creation (x axis)
    for _,position in ipairs(steps_3d) do
        local new_position = add_vector(pos,position)
        if match_full_deletion_queue(vec_7d) then goto continue end
        if get_node(new_position).name ~= "aether:portal" then goto continue end
        if vec_distance(new_position,origin) >= 50 then goto continue end
        
        insert_new_deletion_item(assemble_vec7d(new_position, axis, origin))
        destroy_aether_portal_failed = false

        ::continue::
    end
end

-- Send it out into the global scope
destroy_aether_portal = local_destroy_aether_portal





-------------------------------------------------------------------------------------------

-- The teleporter functions - Stored here for now so I can differentiate this portion of the code from the other parts
local teleporting_player = nil
local function teleport_to_overworld(_, _, calls_remaining)
    if calls_remaining > 0 then goto continue end

    local portal_exists = find_node_near( aether_origin_pos, 30, { "aether:portal" } )

    if not portal_exists then goto continue end

    if not teleporting_player then goto continue end

    teleporting_player:set_pos( vec_new( portal_exists.x, portal_exists.y - 0.5, portal_exists.z ) )

    teleporting_player = nil

    ::continue::
end
local function teleport_to_aether(_, _, calls_remaining)
    if calls_remaining > 0 then goto continue end

    local portal_exists = find_node_near( aether_origin_pos, 30, { "aether:portal" } )

    if not portal_exists then goto continue end
    --print(teleporting_player)
    if not teleporting_player then goto continue end

    teleporting_player:set_pos( vec_new( portal_exists.x, portal_exists.y - 0.5, portal_exists.z ) )

    teleporting_player = nil

    ::continue::
end

--this initializes all teleporter commands from the client
minetest.register_on_modchannel_message(function(channel_name, sender, _)
    local channel_decyphered = channel_name:gsub(sender,"")
    if channel_decyphered ~= ":aether_teleporters" then goto continue end

    local player = minetest.get_player_by_name(sender)
    local pos = player:get_pos()

    if pos.y < 20000 then
        --center the location to the lava height
        pos.y = 25000--+random(-30,30)    
        aether_origin_pos = pos

        local min = sub_vector(aether_origin_pos,30)
        local max = add_vector(aether_origin_pos,30)

        --force load the area
        teleporting_player = player
        emerge_area(min, max, teleport_to_aether)
    else
        --center the location to the water height
        pos.y = 0--+random(-30,30)    
        aether_origin_pos = pos
        --prefer height for mountains
        local min = sub_vector(aether_origin_pos,vec_new(30,30,30))
        local max = add_vector(aether_origin_pos,vec_new(30,120,30))

        --force load the area
        teleporting_player = player
        emerge_area(min, max, teleport_to_overworld)
    end

    ::continue::
end)
-------------------------------------------------------------------------------------------