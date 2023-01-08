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


-- Micro 7d vector factory function
local function assemble_vec4d( x, y, z, axis, a, b, c )
    -- Piggyback on vec3d for new pointers in lua vm
    local initializing_vector = vec_new( x, y, z )
    initializing_vector.axis = axis
    initializing_vector.a = a
    initializing_vector.b = b
    initializing_vector.c = c
    return initializing_vector
end

-- Queue is build upon 7d vectors with:
--[[
    x,y,z = new position
    axis = x or z definition (boolean) - false = x, true = z
    a,b,c = origin position
]]
local build_queue = {}
local deletion_queue = {}

local steps_x = {
    vec_new(  1,  0,  0),
    vec_new( -1,  0,  0),
    vec_new(  0,  1,  0),
    vec_new(  0, -1,  0),
}

local steps_z = {
    vec_new(  0,  1,  0),
    vec_new(  0, -1,  0),
    vec_new(  0,  0,  1),
    vec_new(  0,  0, -1),
}

local steps = {
    steps_x,
    steps_z
}

local function axis_to_integer(axis)
    if axis then return 2 end
    return 1
end

local function match_origin( a, b, c, vec)
    return vec.a == a and vec.b == b and vec.c == c
end

local function match_full_build_queue(vec)
    for _,this in ipairs(build_queue) do
        for key,value in this do
            if vec[key] ~= value then goto continue end
        end
        ::continue::
    end
end
local function match_full_deletion_queue(vec)
    for _,this in ipairs(deletion_queue) do
        for key,value in this do
            if vec[key] ~= value then goto continue end
        end
        ::continue::
    end
end



--this can be used globally to create aether portals from obsidian
local function local_create_aether_portal(vec_7d)

    local pos = vec_new( vec_7d.x, vec_7d.y, vec_7d.z )
    local axis = vec_7d.axis or false

    --2d virtual memory map creation (x axis)
    if not axis then
        for direction in steps_x do
            
            local i = add_vector(pos,direction)

            if match_full_build_queue(vec_7d) then goto continue end

            if get_node(i).name == "air" then
                
                if vec_distance(i,origin) < 50 then
                    --add data to both maps
                    if not a_index[i.x] then a_index[i.x] = {} end
                    if not a_index[i.x][i.y] then a_index[i.x][i.y] = {} end
                    a_index[i.x][i.y][i.z] = {aether_portal=1} --get_group(i,"redstone_power")}        
                    --the data to the 3d array must be written to memory before this is executed
                    --or a stack overflow occurs!!!
                    --pass down info for activators
                    local_create_aether_portal(i,origin,"x")
                else
                    --print("try z")
                    x_failed = true
                    a_index = {}
                    local_create_aether_portal(origin,origin,"z")
                end
            elseif get_node(i).name ~= "nether:glowstone" then
                x_failed = true
                a_index = {}
                local_create_aether_portal(origin,origin,"z")
            end

            ::continue::
        end
    --2d virtual memory map creation (z axis)
    elseif axis == "z" then
        for direction in steps do
            --index only direct neighbors
            if not (x_failed == true and aether_portal_failure == false and (abs(z)+abs(y) == 1)) then goto continue end

            local i = add_vector(pos,vec_new(0,y,z))

            execute_collection = not (a_index[i.x] and a_index[i.x][i.y] and a_index[i.x][i.y][i.z])
            
            if not execute_collection then goto continue end

            if get_node(i).name == "air" then
                if vec_distance(i,origin) < 50 then
                    --add data to both maps
                    if not a_index[i.x] then a_index[i.x] = {} end
                    if not a_index[i.x][i.y] then a_index[i.x][i.y] = {} end
                    a_index[i.x][i.y][i.z] = {aether_portal=1}
                    --the data to the 3d array must be written to memory before this is executed
                    --or a stack overflow occurs!!!
                    --pass down info for activators
                    local_create_aether_portal(i,origin,"z")
                else
                    aether_portal_failure = true
                    a_index = {}
                end
            elseif get_node(i).name ~= "nether:glowstone" then
                aether_portal_failure = true
                a_index = {}
            end

            ::continue::
        end
    end
end

-- Send it off into the global scope
create_aether_portal = local_create_aether_portal

--creates a aether portal in the aether
--this essentially makes it so you have to move 30 away from one portal to another otherwise it will travel to an existing portal
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


local function generate_aether_portal_in_aether(pos)
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


--modify the map with the collected data
local function portal_modify_map(n_copy)
    local sorted_table = {}
    local created_portal = false
    for x,datax in pairs(n_copy) do
    for y,datay in pairs(datax) do
    for z,_ in pairs(datay) do

        --try to create a return side aether portal
        if created_portal then goto continue end

        created_portal = true
        generate_aether_portal_in_aether(vec_new(x,y,z))

        ::continue::

        table_insert(sorted_table, vec_new(x,y,z))
    end
    end
    end

    bulk_set_node( sorted_table, { name = "aether:portal" } )
end


-------------------------------------------------------------------------------

local destroy_a_index = {}
local destroy_aether_portal_failure = false
local destroy_aether_portal_failed = false

--this can be used globally to create aether portals from obsidian
local function local_destroy_aether_portal(pos,origin)
    --create the origin node for stored memory
    if not origin then
        origin = pos
    end
    --3d virtual memory map creation (x axis)
    for x = -1,1 do
    for z = -1,1 do
    for y = -1,1 do
        --index only direct neighbors
        if (abs(x)+abs(z)+abs(y) ~= 1) then goto continue end

        local i = add_vector(pos,vec_new(x,y,z))

        execute_collection = true

        execute_collection = not (destroy_a_index[i.x] and destroy_a_index[i.x][i.y] and destroy_a_index[i.x][i.y][i.z])

        if not execute_collection then goto continue end

        if get_node(i).name ~= "aether:portal" then goto continue end

        if vec_distance(i,origin) >= 50 then goto continue end

        --add data to both maps
        if not destroy_a_index[i.x] then destroy_a_index[i.x] = {} end
        if not destroy_a_index[i.x][i.y] then destroy_a_index[i.x][i.y] = {} end
        destroy_a_index[i.x][i.y][i.z] = {aether_portal=1} --get_group(i,"redstone_power")}                
        --the data to the 3d array must be written to memory before this is executed
        --or a stack overflow occurs!!!
        --pass down info for activators
        local_destroy_aether_portal(i,origin)

        ::continue::
    end
    end
    end
end

-- Send it out into the global scope
destroy_aether_portal = local_destroy_aether_portal

--modify the map with the collected data
local destroy_sorted_table
local function destroy_portal_modify_map(destroy_n_copy)
    destroy_sorted_table = {}
    for x,datax in pairs(destroy_n_copy) do
    for y,datay in pairs(datax) do
    for z,_ in pairs(datay) do
        table_insert( destroy_sorted_table, vec_new( x, y, z ) )
    end
    end
    end
    bulk_set_node( destroy_sorted_table, { name = "air" } )
end

minetest.register_globalstep(function()
    --if indexes exist then calculate redstone
    if a_index and next(a_index) and aether_portal_failure == false then
        --create the old version to help with deactivation calculation
        local n_copy = table_copy(a_index)
        portal_modify_map(n_copy)
        aether_portal_failure = false
    end
    if x_failed == true then
        x_failed = false
    end
    if aether_portal_failure == true then
        aether_portal_failure = false
    end
    --clear the index to avoid cpu looping wasting processing power
    a_index = {}
    
    -- TODO: why is this even a queue if it's relying on recursion?
    --if indexes exist then calculate redstone
    if destroy_a_index and next(destroy_a_index) and destroy_aether_portal_failure == false then
        --create the old version to help with deactivation calculation
        local destroy_n_copy = table_copy(destroy_a_index)
        destroy_portal_modify_map(destroy_n_copy)
    end
    --clear the index to avoid cpu looping wasting processing power
    destroy_a_index = {}
end)



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