local path = minetest.get_modpath("aether")
dofile(path.."/nodes.lua")
dofile(path.."/biomes.lua")

local random = math.random

local add_vector   = vector.add
local sub_vector   = vector.subtract
local vec_new   = vector.new

local emerge_area                  = minetest.emerge_area
local find_node_near               = minetest.find_node_near
local find_nodes_in_area_under_air = minetest.find_nodes_in_area_under_air
local place_schematic              = minetest.place_schematic

local aether_origin_pos
local new_pos
local min
local max
local player
local channel_decyphered
local platform

local glow = {name = "nether:glowstone"}
local port = {name = "aether:portal"}
local none = {name = "air"}


local aether_portal_schematic = {
    size = {x = 4, y = 5, z = 3},
    data = {
        -- The side of the bush, with the air on top
        glow,glow,glow,glow,
        none,none,none,none,
        none,none,none,none,
        none,none,none,none,-- lower layer
        none,none,none,none, -- top layer
        -- The center of the bush, with stem at the base and a pointy leave 2 nodes above
        glow,glow,glow,glow,
        glow,port,port,glow,
        glow,port,port,glow,
        glow,port,port,glow,-- lower layer
        glow,glow,glow,glow, -- top layer
        -- The other side of the bush, same as first side
        glow,glow,glow,glow,
        none,none,none,none,
        none,none,none,none,
        none,none,none,none,-- lower layer
        none,none,none,none, -- top layer
    }
}

-- The teleporter functions - Stored here for now so I can differentiate this portion of the code from the other parts
local teleporting_player = nil
local function teleport(_, _, calls_remaining)
    if calls_remaining > 0 then goto continue end

    local portal_exists = find_node_near( aether_origin_pos, 30, { "aether:portal" } )

    if not portal_exists then goto continue end

    if not teleporting_player then goto continue end

    teleporting_player:set_pos( vec_new( portal_exists.x, portal_exists.y - 0.5, portal_exists.z ) )

    teleporting_player = nil

    ::continue::
end

-- Initializes all teleporter commands from the client
minetest.register_on_modchannel_message(function(channel_name, sender, _)

    channel_decyphered = channel_name:gsub(sender,"")

    if channel_decyphered ~= ":aether_teleporters" then goto continue end

    player = minetest.get_player_by_name(sender)
    new_pos = player:get_pos()

    aether_origin_pos = new_pos

    if new_pos.y < 20000 then
        -- Center the location to the water height
        new_pos.y = 25000

        min = sub_vector(aether_origin_pos,30)
        max = add_vector(aether_origin_pos,30)

        -- Force load the area
        teleporting_player = player
        emerge_area(min, max, teleport)
    else
        -- Center the location to the water height
        new_pos.y = 0--+random(-30,30)    
        --prefer height for mountains
        min = sub_vector(aether_origin_pos,vec_new(30,30,30))
        max = add_vector(aether_origin_pos,vec_new(30,120,30))

        -- Force load the area
        teleporting_player = player
        emerge_area(min, max, teleport)
    end

    ::continue::
end)

-- Creates an aether portal in the aether
-- This essentially makes it so you have to move 30 away from one portal to another otherwise it will travel to an existing portal

local function spawn_portal_into_aether_callback(_, _, calls_remaining)

    if calls_remaining > 0 then goto continue end

    local portal_exists = find_node_near( aether_origin_pos, 30, { "aether:portal" } )

    if portal_exists then goto continue end

    min = sub_vector(aether_origin_pos,30)
    max = add_vector(aether_origin_pos,30)
    platform = find_nodes_in_area_under_air(min, max, {"aether:dirt","aether:grass"})

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

    min = sub_vector( aether_origin_pos, 30 )
    max = add_vector( aether_origin_pos, 30 )
    platform = find_nodes_in_area_under_air( min, max, { "main:stone", "main:water", "main:grass", "main:sand", "main:dirt" } )

    if platform and next( platform ) then
        place_schematic( platform[ random( 1, #platform ) ], aether_portal_schematic, "0", nil, true, "place_center_x, place_center_z"  )
    else
        place_schematic( aether_origin_pos, aether_portal_schematic, "0", nil, true, "place_center_x, place_center_z" )
    end

    ::continue::
end

local function generate_return_portal(pos)
    if pos.y < 20000 then

        -- Center the location to the water height
        pos.y = 25000
        aether_origin_pos = pos

        min = sub_vector(aether_origin_pos,30)
        max = add_vector(aether_origin_pos,30)

        -- Force load the area
        emerge_area(min, max, spawn_portal_into_aether_callback)
    else

        -- Center the location to the water height
        pos.y = 0
        aether_origin_pos = pos

        -- Prefer height for mountains
        min = sub_vector(aether_origin_pos,vec_new(30,30,30))
        max = add_vector(aether_origin_pos,vec_new(30,120,30))

        -- Force load the area
        emerge_area(min, max, spawn_portal_into_overworld_callback)
    end
end

function create_aether_portal(position)
    create_portal( position, "nether:glowstone", "aether:portal", 50, generate_return_portal )
end

function destroy_aether_portal(position)
    destroy_portal( position, "nether:glowstone", "aether:portal", 50 )
end