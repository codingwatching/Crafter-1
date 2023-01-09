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
local aether_origin_pos
local new_pos

minetest.register_on_joinplayer(function(player)
    name = player:get_player_name()
    aether_channels[name] = minetest.mod_channel_join(name..":aether_teleporters")
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
    new_pos = player:get_pos()

    if new_pos.y < 20000 then
        --center the location to the lava height
        new_pos.y = 25000--+random(-30,30)    
        aether_origin_pos = new_pos

        local min = sub_vector(aether_origin_pos,30)
        local max = add_vector(aether_origin_pos,30)

        --force load the area
        teleporting_player = player
        emerge_area(min, max, teleport_to_aether)
    else
        --center the location to the water height
        new_pos.y = 0--+random(-30,30)    
        aether_origin_pos = new_pos
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

-- Creates an aether portal in the aether
-- This essentially makes it so you have to move 30 away from one portal to another otherwise it will travel to an existing portal

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

function create_aether_portal(position)
    create_portal( position, "nether:glowstone", "aether:portal", 50, generate_return_portal )
end

function destroy_aether_portal(position)
    destroy_portal( position, "nether:glowstone", "aether:portal", 50 )
end