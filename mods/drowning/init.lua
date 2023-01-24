local ipairs = ipairs
local get_item_group = minetest.get_item_group
local get_connected_players = minetest.get_connected_players


local mod_storage = minetest.get_mod_storage()
local pool = {}
local name
local temp_pool
local head
local hp

-- Update bubble bar
local update_breath_bar = function(player,breath)
    if breath > 20 then
        player:remove_hud("breath_bg")
        player:remove_hud("breath")
    else
        player:add_hud( "breath_bg", {
            hud_elem_type = "statbar",
            position = { x = 0.5, y = 1 },
            text = "bubble_bg.png",
            number = 20,
            direction = 1,
            size = { x = 24, y = 24 },
            offset = { x = 24 * 10, y = - ( 48 + 52 + 39 ) },
        })
        player:add_hud( "breath", {
            hud_elem_type = "statbar",
            position = { x = 0.5, y = 1 },
            text = "bubble.png",
            number = breath,
            direction = 1,
            size = { x = 24, y = 24 },
            offset = { x = 24 * 10, y = - ( 48 + 52 + 39 ) },
        })
        player:change_hud( "breath", {
            player    =  player ,
            element   = "number",
            data      =  breath
        })
    end
end

-- Loads data from mod storage
local load_data = function(player)
    name = player:get_player_name()
    pool[name] = {}
    temp_pool = pool[name]
    if mod_storage:get_int( name.."d_save" ) > 0 then
        temp_pool.breath = mod_storage:get_float( name .. "breath" )
        temp_pool.ticker = mod_storage:get_float( name .. "breath_ticker" )
        temp_pool.drowning = mod_storage:get_float( name .. "drowning" )
    else
        temp_pool.breath = 21
        temp_pool.ticker = 0
        temp_pool.drowning = 0
    end
end

-- Saves data to be utilized on next login
local save_data = function(name)
    if type(name) ~= "string" and name:is_player() then
        name = name:get_player_name()
    end
    temp_pool = pool[name]

    mod_storage:set_float( name .. "breath", temp_pool.breath )
    mod_storage:set_float( name .. "breath_ticker", temp_pool.ticker )
    mod_storage:set_float( name .. "drowning", temp_pool.drowning )
    mod_storage:set_int( name.."d_save", 1 )

    pool[name] = nil
end

-- Used for shutdowns to save all data
local save_all = function()
    for player_name,_ in pairs(pool) do
        save_data(player_name)
    end
end


-- remove stock health bar
minetest.hud_replace_builtin("breath",{
    hud_elem_type = "statbar",
    position = {x = 0, y = 0},
    text = "nothing.png",
    number = 0,
    direction = 0,
    size = {x = 0, y = 0},
    offset = {x = 0, y= 0},
})

minetest.register_on_joinplayer(function(player)
    load_data(player)
    player:hud_set_flags( { breathbar = false } )
end)

-- Save specific users data for when they relog
minetest.register_on_leaveplayer(function(player)
    save_data(player)
end)

-- Save all data to mod storage on shutdown
minetest.register_on_shutdown(function()
    save_all()
end)

function is_player_drowning(player)
    name = player:get_player_name()
    return pool[name].drowning
end

-- Reset the player's data
minetest.register_on_respawnplayer(function(player)
    name = player:get_player_name()
    temp_pool = pool[name]
    temp_pool.breath   = 21
    temp_pool.ticker   = 0
    temp_pool.drowning = 0
    update_breath_bar(player,temp_pool.breath)
end)

-- Handle the breath bar
local handle_breath = function(player,dtime)
    name = player:get_player_name()
    head = get_player_head_env(player)
    temp_pool = pool[name]
    hp = player:get_hp()

    if hp <= 0 then return end

    if get_item_group(head, "drowning") > 0 then

        temp_pool.ticker = temp_pool.ticker + dtime

        if temp_pool.breath > 0 and temp_pool.ticker >= 1.3 then

            if temp_pool.breath == 21 then
                temp_pool.breath = 20
            end
            temp_pool.breath = temp_pool.breath - 2

            temp_pool.drowning = 0

            update_breath_bar( player, temp_pool.breath )
        elseif temp_pool.breath <= 0 and temp_pool.ticker >= 1.3 then

            temp_pool.drowning = 1

            if hp > 0 then
                player:set_hp( hp - 2 )
            end
        end

        if temp_pool.ticker < 1.3 then return end

        temp_pool.ticker = 0

    else

        temp_pool.ticker = temp_pool.ticker + dtime

        if temp_pool.breath > 20 or temp_pool.ticker < 0.25 then return end

        temp_pool.breath = temp_pool.breath + 2
        temp_pool.drowning = 0
        temp_pool.ticker = 0

        update_breath_bar( player, temp_pool.breath )
    end
end

minetest.register_globalstep(function(dtime)
    for _,player in ipairs(get_connected_players()) do
        handle_breath( player, dtime )
    end
end)