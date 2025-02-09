local pairs                 = pairs
local ipairs                = ipairs
local vec_new               = vector.new
local table_insert          = table.insert
local find_nodes            = minetest.find_nodes_in_area
local get_item_group        = minetest.get_item_group
local sound_play            = minetest.sound_play
local add_particlespawner   = minetest.add_particlespawner
local get_node_or_nil       = minetest.get_node_or_nil
local get_connected_players = minetest.get_connected_players
local math_random           = math.random
local math_abs              = math.abs
local math_ceil             = math.ceil

local pos
local name
local saving_nodes
local real_nodes
local a_min
local a_max

local cancel_fall_damage = function(player)

    name = player:get_player_name()

    if player:get_hp() <= 0 then return true end

    -- Used for finding a damage node from the center of the player
    -- Rudementary collision detection
    pos = player:get_pos()
    pos.y = pos.y
    a_min = vec_new( pos.x-0.25, pos.y-0.85, pos.z-0.25 )
    a_max = vec_new( pos.x+0.25, pos.y+0.85, pos.z+0.25 )

    _,saving_nodes = find_nodes( a_min,  a_max, { "group:disable_fall_damage" } )

    real_nodes = {}

    for node_data,_ in pairs(saving_nodes) do
        if saving_nodes[node_data] > 0 then
            table_insert( real_nodes, node_data )
        end
    end

    -- Find the highest damage node
    return #real_nodes > 0
end

local inv
local stack
local absorption
local stack_name

local function calc_fall_damage(player,hp_change)

    if cancel_fall_damage(player) then return end

    inv = player:get_inventory()
    stack = inv:get_stack("armor_feet", 1)
    stack_name = stack:get_name()

    if stack_name ~= "" then

        absorption = get_item_group( stack_name, "armor_level" ) * 2

        local wear_level = ( ( 9 - get_item_group( stack_name, "armor_level" ) ) * 8 ) * ( 5 - get_item_group( stack_name, "armor_type" ) ) * math_abs( hp_change )

        stack:add_wear( wear_level )

        inv:set_stack( "armor_feet", 1, stack )

        local new_stack = inv:get_stack( "armor_feet", 1 ):get_name()

        if new_stack == "" then
            sound_play(
                "armor_break",
                {
                    to_player = player:get_player_name(),
                    gain = 1,
                    pitch = math_random( 80, 100 ) / 100
                }
            )
            update_armor_visual( player )
            set_armor_gui( player )

            -- Do particles as well
        elseif get_item_group(new_stack,"boots") > 0 then
            pos = player:get_pos()
            add_particlespawner({
                amount = 30,
                time = 0.00001,
                minpos = vec_new( pos.x - 0.5, pos.y + 0.1, pos.z - 0.5 ),
                maxpos = vec_new( pos.x + 0.5, pos.y + 0.1, pos.z + 0.5 ),
                minvel = vec_new( -0.5, 1, -0.5 ),
                maxvel = vec_new( 0.5, 2, 0.5 ),
                minacc = vec_new( 0, -9.81, 1 ),
                maxacc = vec_new( 0, -9.81, 1 ),
                minexptime = 0.5,
                maxexptime = 1.5,
                minsize = 0,
                maxsize = 0,
                --attached = player,
                collisiondetection = true,
                collision_removal = true,
                vertical = false,
                node = {name= stack_name.."particletexture"},
                --texture = "eat_particles_1.png"
            })
            sound_play(
                "armor_fall_damage",
                {
                    object = player,
                    gain = 1.0,
                    max_hear_distance = 60,
                    pitch = math_random( 80, 100 ) / 100
                }
            )
        end

        hp_change = hp_change + absorption

        if hp_change >= 0 then
            hp_change = 0
        else
            player:set_hp( player:get_hp() + hp_change, { reason = "correction" } )
        end
    else
        player:set_hp( player:get_hp() + hp_change,  { reason = "correction" } )
    end
end

local pool = {}
local damage_memory = {}
local new_vel
local old_vel
local timer

minetest.register_globalstep(function(dtime)

    for _,player in ipairs( get_connected_players() ) do

        name = player:get_player_name()

        old_vel = pool[name]

        new_vel = player:get_velocity().y

        timer = damage_memory[name]

        if timer > 0 then
            timer = timer - dtime
            goto continue
        end

        if not (old_vel < -15 and new_vel >= -0.5) then goto continue end

        -- Don't do fall damage on unloaded areas
        pos = player:get_pos()

        pos.y = pos.y - 1

        if not get_node_or_nil(pos) then goto continue end

        calc_fall_damage( player, math_ceil( old_vel + 14 ) )

        -- Reset the damage memory
        timer = 0.5

        ::continue::

        pool[name] = player:get_velocity().y
        damage_memory[name] = timer
    end
end)

-- Sets the intial memory in the memory pool
-- Let the player log out to reset this, if they find that glitch it's fun
minetest.register_on_joinplayer(
    function(player)
        local player_name = player:get_player_name()
        damage_memory[player_name] = 0
        pool[player_name] = 0
    end
)

-- Free the heap
minetest.register_on_leaveplayer(
    function(player)
        local player_name = player:get_player_name()
        damage_memory[player_name] = nil
        pool[player_name] = nil
    end
)