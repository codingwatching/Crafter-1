local ipairs = ipairs
local type = type
local mod_storage = minetest.get_mod_storage()

local pool = {}


-- Loads data from mod storage
local name
local data_container

local load_data = function(player_name)

    data_container = pool[player_name]

    if mod_storage:get_int( player_name .. "h_save" ) > 0 then
        data_container.hunger = mod_storage:get_int( player_name .. "hunger" )
        data_container.satiation = mod_storage:get_int( player_name .. "satiation" )
        data_container.exhaustion = mod_storage:get_int( player_name .. "exhaustion" )
        data_container.regeneration_interval = mod_storage:get_int( player_name .. "regeneration_interval" )
    else
        data_container.hunger = 20
        data_container.satiation = 20
        data_container.regeneration_interval = 0
        data_container.exhaustion = 0
    end

    print(dump(data_container))
end

-- Saves data to be utilized on next login
local save_data = function(player_name)

    data_container = pool[player_name]

    mod_storage:set_int( player_name .. "hunger", data_container.hunger )
    mod_storage:set_int( player_name .. "satiation", data_container.satiation )
    mod_storage:set_int( player_name .. "exhaustion", data_container.exhaustion )
    mod_storage:set_int( player_name .. "regeneration_interval",data_container.regeneration_interval )

    mod_storage:set_int( player_name .. "h_save", 1 )

    pool[player_name] = nil
end

-- Saves specific users data for when they relog
minetest.register_on_leaveplayer(function(player)
    save_data(player:get_player_name())
end)

-- Used for shutdowns to save all data
local save_all = function()
    for _,player in ipairs(minetest.get_connected_players()) do
        save_data(player:get_player_name())
    end
end

-- An easy translation pool
local satiation_pool = {
    [0]   = 1,
    [0.5] = 3,
    [1]   = 6,
    [2]   = 8,
    [3]   = 1
}
-- Ticks up the exhaustion when counting down satiation
local tick_up_satiation = function( state,exhaustion )
    return( exhaustion + satiation_pool[ state ] )
end

-- An easy translation pool
local hunger_pool = {
    [0]   = 1,
    [0.5] = 2,
    [1]   = 3,
    [2]   = 4,
    [3]   = 1
}
-- ticks up the exhaustion when counting down hunger
local tick_up_hunger = function(state,exhaustion)
    return(exhaustion + hunger_pool[state])
end

-- allows other mods to set hunger data
get_player_hunger = function(player_name)
    data_container = pool[player_name]
    return (data_container and data_container.hunger) or 0
end

-- save all data to mod storage on shutdown
minetest.register_on_shutdown(function()
    save_all()
end)

-- Create new data for hunger per player
minetest.register_on_joinplayer(function(player)
    name = player:get_player_name()
    pool[name] = {}
    load_data(name)

    minetest.after(0,function()
    player:add_hud( "hunger_bg", {
        hud_elem_type = "statbar",
        position      = {x = 0.5, y = 1},
        text          = "hunger_icon_bg.png",
        number        = 20,
        direction     = 1,
        size          = {x = 24, y = 24},
        offset        = {x = 24*10, y= -(48 + 24 + 39)},
    })
    player:add_hud( "hunger", {
        hud_elem_type = "statbar",
        position      = {x = 0.5, y = 1},
        text          = "hunger_icon.png",
        number        = pool[name].hunger,
        direction     = 1,
        size          = {x = 24, y = 24},
        offset        = {x = 24*10, y= -(48 + 24 + 39)},
    })
    end)
end)

-- Resets the players hunger settings to max
minetest.register_on_respawnplayer(function(player)
    name = player:get_player_name()
    data_container = pool[name]
    data_container.hunger                = 20
    data_container.satiation             = 20
    data_container.regeneration_interval = 0
    data_container.exhaustion            = 0
    player:change_hud( "hunger", {
        element   = "number",
        data      =  data_container.hunger
    })
end)


local exhaustion_peak  = 512
local hunger_peak      = 128
local state
local input
local hp
local drowning
local hunger_update = function()

    for _,player in ipairs(minetest.get_connected_players()) do

        -- Do not regen player's health if dead - this will be reused for 1up apples
        if player:get_hp() <= 0 then goto continue end

        name = player:get_player_name()

        data_container = pool[name]

        -- Player's movement state
        state = get_player_state(player)

        -- If player is moving in state 0 add 0.5
        if state == 0 then
            input = player:get_player_control()
            if input.jump or input.right or input.left or input.down or input.up then
                state = 0.5
            end
        end
        -- count down invisible satiation bar
        if data_container.satiation > 0 and data_container.hunger >= 20 then

            data_container.exhaustion = tick_up_satiation(state, data_container.exhaustion)

            if data_container.exhaustion > exhaustion_peak then

                data_container.satiation = data_container.satiation - 1

                data_container.exhaustion = data_container.exhaustion - exhaustion_peak
                
                --reset this to use for the hunger tick
                if data_container.satiation == 0 then
                    data_container.exhaustion = 0
                end
            end
        -- count down hunger bars
        elseif data_container.hunger > 0 then

            data_container.exhaustion = tick_up_hunger(state,data_container.exhaustion)
            
            if data_container.exhaustion >= hunger_peak then
                --don't allow hunger to go negative
                if data_container.hunger > 0 then

                    data_container.exhaustion = data_container.exhaustion - hunger_peak

                    data_container.hunger = data_container.hunger - 1

                end

                player:change_hud( "hunger", {
                    element   = "number",
                    data      =  data_container.hunger
                })
            end
        -- hurt the player if hunger bar empty
        elseif data_container.hunger <= 0 then

            data_container.exhaustion = data_container.exhaustion + 1

            hp = player:get_hp()

            if hp > 0 and data_container.exhaustion >= 2 then
                player:set_hp( hp - 1 )
                data_container.exhaustion = 0
            end
        end
        
        
        hp = player:get_hp()

        drowning = is_player_drowning(player)

        --make regeneration happen every second
        if not player:get_fire_state() and drowning == 0 and data_container.hunger >= 20 and hp < 20 then

            data_container.regeneration_interval = data_container.regeneration_interval + 1

            if data_container.regeneration_interval >= 2 then

                player:set_hp( hp + 1 )

                data_container.exhaustion = data_container.exhaustion + 32

                data_container.regeneration_interval = 0

            end
        --reset the regen interval
        else
            data_container.regeneration_interval = 0
        end

        ::continue::
    end
end

local hunger_tick = 0
minetest.register_globalstep(function(dtime)
    hunger_tick = hunger_tick + dtime
    if hunger_tick < 0.5 then return end
    hunger_tick = 0
    hunger_update()
end)

-- Take away hunger and satiation randomly while mining
minetest.register_on_dignode(function(_, _, digger)
    if not digger or not digger:is_player() then return end
    name = digger:get_player_name()
    pool[name].exhaustion = pool[name].exhaustion + math.random(0,2)
end)

-- Take away the food that the player ate
local item
local take_food = function(player)
    item = player:get_wielded_item()
    item:take_item()
    player:set_wielded_item(item)
end

-- players eat food
local satiation
local hunger
player_eat_food = function(player,item)
    name = player:get_player_name()
    data_container = pool[name]
    if type(item) == "string" then
        item = ItemStack(item)
    elseif type(item) == "table" then
        item = ItemStack(item.name)
    end
    item = item:get_name()
    
    satiation = minetest.get_item_group( item, "satiation" )
    hunger    = minetest.get_item_group( item, "hunger"    )
    
    data_container.hunger = data_container.hunger + hunger

    if data_container.hunger > 20 then
        data_container.hunger = 20
    end

    -- unlimited
    -- this makes the game easier
    data_container.satiation = data_container.satiation + satiation

    take_food(player)

    player:change_hud( "hunger", {
        element   = "number",
        data      =  data_container.hunger
    })
end

-- easily allows mods to register food
minetest.register_food = function(name,def)
    minetest.register_craftitem(":"..name, {
        description = def.description,
        inventory_image = def.texture,
        groups = {satiation=def.satiation,hunger=def.hunger},
    })

    minetest.register_node(":"..name.."node", {
        tiles = {def.texture},
        drawtype = "allfaces",
    })
end


minetest.register_chatcommand("hungry", {
    params = "<mob>",
    description = "A debug command to test food",
    privs = {server = true},
    func = function(name)
        local data_container = pool[name]
        data_container.exhaustion = 0
        data_container.hunger     = 1
        data_container.satiation  = 0
        local player = minetest.get_player_by_name(name)
        player:change_hud( "hunger", {
            element   = "number",
            data      =  data_container.hunger
        })
    end
})
