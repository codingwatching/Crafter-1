local ipairs = ipairs
local tonumber = tonumber
local type = type
local get_us_time = minetest.get_us_time
local mod_channel_join = minetest.mod_channel_join
local serialize = minetest.serialize
local get_item_group = minetest.get_item_group
local get_connected_players = minetest.get_connected_players
local vec_new = vector.new


-- Holds every player's channel
local state_channels = {}
local pool = {}

-- Creates specific channels for players
local name
local temp_pool
minetest.register_on_joinplayer(function(player)
    name = player:get_player_name()

    state_channels[name] = mod_channel_join(name..":player_movement_state")
    player:set_physics_override({
        jump = 1.25,
        gravity = 1.25
    })

    pool[name] = {}
    temp_pool = pool[name]
    temp_pool.state        = 0
    temp_pool.old_state    = 0
    temp_pool.was_in_water = false
    temp_pool.swimming     = false
    temp_pool.swim_bumped  = get_us_time()/1000000
end)

-- Tells the client to stop sending running/bunnyhop data
local function local_send_running_cancellation(player,sneaking)
    name = player:get_player_name()
    state_channels[name]:send_all(
        serialize({
            stop_running = true,
            state = sneaking
        }
    ))
end

-- Resets the player's state on death
minetest.register_on_respawnplayer(function(player)
    name = player:get_player_name()
    pool[name].state = 0
    pool[name].was_in_water = false
    pool[name].swim_bumped = get_us_time() / 1000000
    local_send_running_cancellation(player,false)
    player:set_properties({
        collisionbox = { -0.3, 0.0, -0.3, 0.3, 1.7, 0.3 },
    })
end)


-- Delete data on player leaving
minetest.register_on_leaveplayer(function(player)
    name = player:get_player_name()
    pool[name] = nil
end)



-- Intercept incoming data messages
local channel_decyphered
local state
minetest.register_on_modchannel_message(function(channel_name, sender, message)
    channel_decyphered = channel_name:gsub(sender,"")
    if sender ~= "" and channel_decyphered == ":player_movement_state" then
        state = tonumber(message)
        if type(state) == "number" then
            pool[sender].state = state
        end
    end
end)




-- Allows other mods to retrieve data for the game to use
get_player_state = function(player)
    name = player:get_player_name()
    return(pool[name].state)
end
local name
is_player_swimming = function(player)
    name = player:get_player_name()
    return(pool[name].swimming)
end

-- Controls player states
local hunger
local head
local legs
local in_water
local swim_unlock
local swim_bump
local control_state = function(player)
    if get_if_player_attached(player) then
        return
    end
    hunger    = get_player_hunger(player)
    name      = player:get_player_name()
    temp_pool = pool[name]


    -- Water movement data
    head = get_item_group(get_player_head_env(player),"water") > 0
    -- TODO: implement legs
    legs = get_item_group(get_player_legs_env(player),"water") > 0

    in_water = temp_pool.swimming

    -- Check if in water
    if head then
        in_water = true
        temp_pool.swimming = true
    elseif temp_pool.swimming == true then
        swim_unlock = player_swim_under_check(player)
        swim_bump = player_swim_check(player)
        if swim_unlock then
            in_water = false
            temp_pool.swimming = false
            temp_pool.swim_bumped = get_us_time()/1000000
        elseif swim_bump and get_us_time()/1000000-temp_pool.swim_bumped > 1 then
            if player:get_velocity().y <= 0 then
                temp_pool.swim_bumped = get_us_time()/1000000
                player:add_velocity(vec_new(0,9,0))
            end
        end
    end
    if ( in_water ~= temp_pool.was_in_water ) or
    ( temp_pool.state ~= temp_pool.old_state ) or
    ( ( temp_pool.state == 1 or temp_pool.state == 2 ) and hunger <= 6 ) then

        if ( not in_water and temp_pool.was_in_water ) then
            player:set_physics_override({
                sneak = true,
            })

            force_update_animation(player)

            player:set_properties({
                collisionbox = { -0.3, 0.0, -0.3, 0.3, 1.7, 0.3 },
            })

        elseif in_water and not temp_pool.was_in_water then
            
            player:set_physics_override({
                sneak = false,
            })

            force_update_animation(player)

            player:set_properties({
                collisionbox = { -0.3, 0.8, -0.3, 0.3, 1.6, 0.3 },
            })
            player:set_eye_offset(
                { x = 0, y = 0, z = 0 },
                { x = 0, y = 0, z = 0 }
            )
        end

        -- running/swimming fov modifier
        if hunger > 6 and ( temp_pool.state == 1 or temp_pool.state == 2 ) then
            player:set_fov( 1.25, true, 0.15 )

            if temp_pool.state == 2 then
                player:set_physics_override( { speed = 1.75 } )
            elseif temp_pool.state == 1 then
                player:set_physics_override( { speed = 1.5 } )
            end

        elseif ( not in_water and temp_pool.state ~= 1 and temp_pool.state ~= 2 and
        ( temp_pool.old_state == 1 or temp_pool.old_state == 2 ) ) or
        ( in_water and temp_pool.state ~= 1 and temp_pool.state ~= 2 and temp_pool.state ~= 3 and
        ( temp_pool.old_state == 1 or temp_pool.old_state == 2 or temp_pool.old_state == 3 ) )then

            player:set_fov( 1, true,0.15 )
            player:set_physics_override( { speed = 1 } )

            -- Preserve network data
            local_send_running_cancellation( player, temp_pool.state==3 )

        elseif ( temp_pool.state == 1 or temp_pool.state == 2 ) and hunger <= 6 then
            player:set_fov( 1, true, 0.15 )
            player:set_physics_override( { speed = 1 } )
            -- Preserve network data
            local_send_running_cancellation( player, false )
        end

        -- Sneaking
        if temp_pool.state == 3 and in_water then
            -- Don't allow player to fast move under water as it's glitchy
            local_send_running_cancellation( player, false )
        elseif not in_water and temp_pool.state == 3 and temp_pool.old_state ~= 3 then
            player:set_eye_offset(
                { x = 0, y = -1, z = 0 },
                { x = 0, y = 0, z = 0 }
            )
        elseif not in_water and temp_pool.old_state == 3 and temp_pool.state ~= 3 then
            player:set_eye_offset(
                { x = 0, y = 0, z = 0 },
                { x = 0, y = 0, z = 0 }
            )
        end

        temp_pool.old_state = state
        temp_pool.was_in_water = in_water

    -- Water movement

    elseif in_water then
        if not temp_pool.was_in_water then
            player:set_physics_override({
                sneak = false,
            })
        end
        temp_pool.old_state = temp_pool.old_state
        temp_pool.was_in_water = in_water
    end

end

minetest.register_globalstep(function(dtime)
    for _,player in ipairs(get_connected_players()) do
        control_state(player)
    end
end)