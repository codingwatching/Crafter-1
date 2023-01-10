local type                = type
local add_item            = minetest.add_item
local random              = math.random
local play_sound          = minetest.sound_play
local add_particlespawner = minetest.add_particlespawner
local math_abs            = math.abs
local math_ceil           = math.ceil
local vec_new             = vector.new
local vec_multiply        = vector.multiply
local minetest_after      = minetest.after
local get_us_time         = minetest.get_us_time

-- Hurt sound and disable fall damage group handling
minetest.register_on_player_hpchange(function(player, hp_change, reason)
    if type(reason) == "fall" then
        -- Fall damage is handled on another globalstep calculation
        return(0)
    elseif hp_change < 0 and reason.reason ~= "correction" then
        play_sound( "hurt", {
            object = player,
            gain = 1.0,
            max_hear_distance = 60,
            pitch = random( 80, 100) / 100
        })
    end
    return(hp_change)
end, true)

local pos
local inv
local stack
local count
local obj
local name

-- Dumps the inventory specified and slot
local function auto_dump(inv_name, slot, position)
    stack = inv:get_stack(inv_name, slot)
    name = stack:get_name()

    if name ~= "" then
        obj = add_item( position, stack )
        if obj then
            obj:set_velocity(vec_new(random(-3,3),random(4,8),random(-3,3)))
        end
        inv:set_stack(inv_name, slot, ItemStack(""))
    end
end

-- This dumps the players crafting table on closing the inventory and on death
local function local_dump_craft(player)
    pos = player:get_pos()
    inv = player:get_inventory()
    for i = 1,inv:get_size("craft") do
        stack = inv:get_stack("craft", i)
        name = stack:get_name()
        count = stack:get_count()

        if name == "" then goto continue end

        for _ = 1,count do
            obj = add_item(pos, name)
            if obj then
                obj:set_velocity(vec_new(random(-3,3),random(4,8),random(-3,3)))
            end
        end
        inv:set_stack("craft", i, ItemStack(""))

        ::continue::
    end
end

-- Dumps all inventory items in player's inventory onto the ground on death
minetest.register_on_dieplayer(function(player)
    pos = player:get_pos()
    inv = player:get_inventory()

    -- Dumps the main player inventory
    for i = 1,inv:get_size( "main" ) do

        stack = inv:get_stack( "main", i )
        name = stack:get_name()
        count = stack:get_count()

        if name == "" then goto continue end

        -- An explosion of items
        for _ = 1,count do

            obj = add_item(pos, name)

            if obj then
                obj:set_velocity( vec_new( random( -3, 3 ), random( 4, 8 ), random( -3, 3 ) ) )
            end
        end

        inv:set_stack( "main", i, ItemStack("") )

        ::continue::
    end

    auto_dump( "armor_head", 1, pos )
    auto_dump( "armor_torso", 1, pos )
    auto_dump( "armor_legs", 1, pos )
    auto_dump( "armor_feet", 1, pos )

    local_dump_craft(player)

    update_armor_visual(player)
end)

-- Send it out to global state
dump_craft = local_dump_craft



local registered_nodes
minetest.register_on_mods_loaded(function()
    registered_nodes = minetest.registered_nodes
end)

-- Play sound to keep up with player's placing vs inconsistent client placing sound
-- This also makes it easier for a player to tell how much lag the server has
local node
local sound
local placing
minetest.register_on_placenode(function(position, newnode, _, _, _, _)
    node = registered_nodes[newnode.name]
    sound = node.sounds
    placing = ""
    if sound then
        placing = sound.placing
    end
    -- Only play the sound when is defined
    if type(placing) == "table" then
        play_sound(placing.name, {
              pos = position,
              gain = placing.gain,
              max_hear_distance = 32,
              --pitch = random(60,100)/100
        })
    end
end)

-- Replace stack when you are building, aka, when you place the last node it will try to plop one back into your hand
local old
local new
minetest.register_on_placenode(function(_, _, placer, _, itemstack)

    old = itemstack:get_name()

    -- Pass through to check

    minetest_after( 0, function()
        if not placer then return end
        new = placer:get_wielded_item():get_name()

        if old == new and new ~= "" then return end

        inv = placer:get_inventory()

        -- Check if the inventory has another one of the items
        if not inv:contains_item("main", old) then return end

        --run through inventory
        for i = 1,inv:get_size("main") do

            if inv:get_stack("main", i):get_name() ~= old then goto continue end

            -- If found set wielded item and remove old stack

            count = inv:get_stack("main", i):get_count()
            placer:set_wielded_item( old.." "..count )
            inv:set_stack("main",i,ItemStack(""))

            play_sound("pickup", {
                to_player = placer,
                gain = 0.7,
                pitch = random( 60, 100 ) / 100
            })

            -- A logic flow trick
            if true then return end

            ::continue::
        end

    end)
end)

local do_critical_particles = function(position)
    add_particlespawner({
        amount = 40,
        time = 0.001,
        minpos = position,
        maxpos = position,
        minvel = vec_new( -2, -2, -2 ),
        maxvel = vec_new( 2, 8, 2 ),
        minacc = { x = 0, y = 4, z = 0},
        maxacc = { x = 0, y = 12, z = 0 },
        minexptime = 1.1,
        maxexptime = 1.5,
        minsize = 1,
        maxsize = 2,
        collisiondetection = false,
        vertical = false,
        texture = "critical.png",
    })
end

-- This needs to be done to override the default damages mechanics
local pool = {}

minetest.register_on_joinplayer(function(player)
    name = player:get_player_name()
    pool[name] = get_us_time() / 1000000
end)

function player_can_be_punched(player)
    name = player:get_player_name()
    return( ( get_us_time() / 1000000 ) - pool[name] >= 0.5 )
end

-- This throws the player when they're punched and activates the custom damage mechanics
local temp_pool
local hurt
local punch_diff
local hp
local puncher_vel
local vel
local hp_modifier
local modify_output
minetest.register_on_punchplayer(function(player, hitter, _, tool_capabilities, dir, _)

    name = player:get_player_name()
    temp_pool = pool[name]

    punch_diff = ( get_us_time() / 1000000 ) - temp_pool

    hurt = tool_capabilities.damage_groups.damage
    if not hurt then
        hurt = 0
    end
    hp = player:get_hp()

    if not (punch_diff >= 0.5 and hp > 0) then return end

    temp_pool = get_us_time() / 1000000

    if hitter:is_player() and hitter ~= player then
        puncher_vel = hitter:get_velocity().y
        if puncher_vel < 0 then
            hurt = hurt * 1.5
            do_critical_particles(player:get_pos())
            play_sound("critical", {
                pos = player:get_pos(),
                gain = 0.1,
                max_hear_distance = 16,
                pitch = random( 80, 100 ) / 100
            })
        end
    end

    dir = vec_multiply(dir,10)
    vel = player:get_velocity()
    dir.y = 0
    if vel.y <= 0 then
        dir.y = 7
    end

    hp_modifier = math_ceil( calculate_armor_absorbtion( player ) / 3 )

    damage_armor( player, math_abs( hurt ) )

    modify_output = ( hurt == 0 )

    hurt = hurt - hp_modifier

    if not modify_output and hurt <= 0 then
        hurt = 1
    elseif modify_output then
        hurt = 0
    end

    player:add_velocity(dir)

    player:set_hp( hp - hurt )
end)

minetest.register_on_respawnplayer(function(player)
    player:add_velocity( vec_multiply( player:get_velocity(), -1 ) )
    inv = player:get_inventory()
    inv:set_list( "main", {} )
    inv:set_list( "craft", {} )
    inv:set_list( "craftpreview", {} )
    inv:set_list( "armor_head", {} )
    inv:set_list( "armor_torso", {} )
    inv:set_list( "armor_legs", {} )
    inv:set_list( "armor_feet", {} )
end)