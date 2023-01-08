local ipairs = ipairs
local pairs = pairs
local add_particlespawner = minetest.add_particlespawner
local sound_play = minetest.sound_play
local get_connected_players = minetest.get_connected_players
local get_item_group = minetest.get_item_group
local table_copy = table.copy
local vec_add = vector.add
local vec_multiply = vector.multiply
local math_random = math.random

local name
local eating_step = {}
local eating_timer = {}

local particle_constant = {
    amount = 12,
    time = 0.01,
    minpos = {x=-0.1,y=-0.1,z=-0.1},
    maxpos = {x=0.1, y=0.3, z=0.1},
    minvel = {x=-0.5,y=0.2, z=-0.5},
    maxvel = {x=0.5,y=0.6,z=0.5},
    minacc = {x=0, y=-9.81, z=1},
    maxacc = {x=0, y=-9.81, z=1},
    minexptime = 0.5,
    maxexptime = 1.5,
    object_collision = false,
    collisiondetection = true,
    collision_removal = true,
    vertical = false,
}

minetest.register_on_joinplayer(function(player)
    name = player:get_player_name()
    eating_step[name] = 0
    eating_timer[name] = 0
end)

minetest.register_on_leaveplayer(function(player)
    name = player:get_player_name()
    eating_step[name] = nil
    eating_timer[name] = nil
end)

-- Logic for player eating effects
local position
local velocity
local offset
local temp_particle
local manage_eating_effects = function(player,timer,sneaking,item)
    position = player:get_pos()
    velocity = player:get_velocity()

    if sneaking then
        position.y = position.y + 1.2
        offset = 0.6
    else
        position.y = position.y + 1.3
        offset = 0.3
    end

    position = vec_add( position, vec_multiply( player:get_look_dir(), offset ) )

    temp_particle = table_copy( particle_constant )
    temp_particle.minpos = vec_add( position,temp_particle.minpos )
    temp_particle.maxpos = vec_add( position,temp_particle.maxpos )
    temp_particle.minvel = vec_add( velocity,temp_particle.minvel )
    temp_particle.maxvel = vec_add( velocity,temp_particle.maxvel )
    temp_particle.node   = { name = item.."node" }

    add_particlespawner(temp_particle)

    if timer >= 0.2 then
        sound_play("eat", {
            object = player,
            gain = 0.2                      ,
            pitch = math_random(60,85)/100}
        )
        return(0)
    end

    return(timer)
end


local item
local finish_eating = function(player,timer)
    if timer < 1 then return timer end

    item = player:get_wielded_item()

    player_eat_food(player,item)

    sound_play("eat_finish", {
        object = player,
        gain = 0.025,
        pitch = math_random(60,85)/100}
    )
    return(0)
end


local name
local control
local item
local satiation
local hunger
local eating_step
local eating_timer
local pool

-- TODO: break this down into individual flat tables
local manage_eating = function(player,dtime)

    control = player:get_player_control()
    name = player:get_player_name()
    pool = food_control_pool[name]

    -- Not eating
    if not control.RMB then
        pool.eating_step  = 0
        pool.eating_timer = 0
        return
    end

    -- Is eating


    -- Abusing dynamic types
    item = player:get_wielded_item()
    if not item then return end
    item = item:get_name()

    satiation = get_item_group( item, "satiation" )
    hunger = get_item_group( item, "hunger" )

    print(hunger)

    if hunger > 0 or satiation > 0  then

        pool.eating_step  = pool.eating_step  + dtime
        pool.eating_timer = pool.eating_timer + dtime

        pool.eating_timer = manage_eating_effects(
            player,
            pool.eating_timer,
            control.sneak,
            item
        )

        pool.eating_step = finish_eating(
            player,
            pool.eating_step
        )

    else
        pool.eating_step  = 0
        pool.eating_timer = 0
    end
end

minetest.register_globalstep(function(dtime)
    for _,player in ipairs(get_connected_players()) do
        manage_eating(player,dtime)
    end
end)
