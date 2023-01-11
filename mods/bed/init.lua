local register_on_joinplayer = minetest.register_on_joinplayer
local register_on_modchannel_message =  minetest.register_on_modchannel_message
local get_connected_players = minetest.get_connected_players
local get_player_by_name = minetest.get_player_by_name
local close_formspec = minetest.close_formspec
local show_formspec = minetest.show_formspec
local get_timeofday = minetest.get_timeofday
local set_timeofday = minetest.set_timeofday
local register_on_player_receive_fields = minetest.register_on_player_receive_fields
local register_on_respawnplayer = minetest.register_on_respawnplayer
local register_on_leaveplayer = minetest.register_on_leaveplayer
local register_globalstep = minetest.register_globalstep
local mod_channel_join = minetest.mod_channel_join
local chat_send_player = minetest.chat_send_player
local facedir_to_dir = minetest.facedir_to_dir
local dir_to_yaw = minetest.dir_to_yaw
local yaw_to_dir = minetest.yaw_to_dir
local ipairs = ipairs
local vec_new = vector.new
local vec_equals = vector.equals
local vec_add = vector.add
local vec_subtract = vector.subtract
local vec_divide = vector.divide
local vec_multiply = vector.multiply
local table_insert = table.insert
local table_remove = table.remove

local night_begins = 19000 / 24000
local night_ends   = 5500  / 24000


--[[
    store the player's old position and look direction

    TODO: store the player's bed position in mod storage! I don't know why this was removed >:(
]]
local players_in_bed = {}
local name
local channel_decyphered
local time
local sleep_channel = {}
local sleep_check_timer = 0
local new_pos = {}
local sleeping_counter = 0
local yaw
local adjusted_dir
local this_player
local pos2
local param2
local sneak
local nodedef
local facedir
local dir

local bed_gui = "size[16,12]"..
                "position[0.5,0.5]"..
                "bgcolor[#00000000]"..
                "button[5.5,8.5;5,2;button;leave bed]"

-- Bed vector is a table that holds the data of the player's bed state, dispatches a new object
local function new_bed_vec( player, position )
    if not player or not position then return end
    local bed_vec = {}
    bed_vec.name = player:get_player_name()
    bed_vec.sleeping = false
    bed_vec.x = position.x
    bed_vec.y = position.y
    bed_vec.z = position.z
    return bed_vec
end

local function remove_player_from_beds( player )
    if not player then return end
    name = player:get_player_name()
    if not name then return end
    for index,bed_vec in ipairs( players_in_bed ) do
        if name ~= bed_vec.name then goto continue end
        table_remove(players_in_bed, index)
        do return end
        ::continue::
    end
end

local function insert_player_into_bed(player, position)
    table_insert( players_in_bed, new_bed_vec( player, position ) )
end


--TODO: run a check on a simpler data table because this is a mess

register_on_joinplayer( function( player )
    name = player:get_player_name()
    sleep_channel[ name ] = mod_channel_join( name .. ":sleep_channel" )
end )

local function csm_send_player_to_sleep( player )
    name = player:get_player_name()
    sleep_channel[ name ]:send_all( "1" )
end

local function csm_wake_player_up( player )
    name = player:get_player_name()
    sleep_channel[ name ]:send_all( "0" )
end

register_on_modchannel_message( function( channel_name, sender )
    channel_decyphered = channel_name:gsub( sender, "" )
    if channel_decyphered ~= ":sleep_channel" then return end
    for _,bed_vec in ipairs( players_in_bed ) do
        if bed_vec.name ~= sender then goto continue end
        bed_vec.sleeping = true
        do return end
        ::continue::
    end
end )

local wake_up = function( player )
    name = player:get_player_name()
    player_is_sleeping( player, false )
    player:set_eye_offset( { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 } )
    for index,bed_vec in ipairs( players_in_bed ) do
        if bed_vec.name ~= name then goto continue end

        table_remove(players_in_bed, index)
        close_formspec( name, "bed" )
        csm_wake_player_up( player )
        do return end

        ::continue::
    end
end

local function sleep_check()

    -- No one is in bed, don't continue
    if #players_in_bed == 0 then
        return
    end

    sleeping_counter = 0

    -- Locks the players in bed until they get up or the night skips
    for _,bed_vec in ipairs( players_in_bed ) do
        this_player = get_player_by_name( bed_vec.name )
        if not this_player then goto continue end
        local check_vec = vec_new( bed_vec.x, bed_vec.y, bed_vec.z )
        if vec_equals( check_vec, this_player:get_pos() ) then
            this_player:set_pos(check_vec)
        end
        -- Group in a check of the players sleeping state
        if not bed_vec.sleeping then goto continue end
        sleeping_counter = sleeping_counter + 1
        ::continue::
    end

    -- Not everyone is in bed, don't continue
    if #players_in_bed ~= sleeping_counter then return end

    set_timeofday( night_ends )

    for _,player in ipairs(get_connected_players()) do
        wake_up(player)
    end
end

register_globalstep(function(dtime)

    sleep_check_timer = sleep_check_timer + dtime

    if sleep_check_timer < 1 then return end

    sleep_check_timer = 0

    sleep_check()

end)

-- Delete data on player leaving
register_on_leaveplayer(function(player)
    remove_player_from_beds(player)
end)


local do_sleep = function( player, pos, direction )

    time = get_timeofday()
    name = player:get_player_name()

    if time > night_ends and time < night_begins then
        chat_send_player( name, "You can only sleep at night" )
        return
    end

    yaw = dir_to_yaw( facedir_to_dir( direction ) )
    adjusted_dir = yaw_to_dir( yaw )

    player:add_velocity( vec_multiply( player:get_velocity(), -1 ) )

    new_pos = vec_subtract( pos, vec_divide( adjusted_dir, 2 ) )

    player:move_to( new_pos )
    player:set_look_vertical( 0 )
    player:set_look_horizontal( yaw * -1  )

    show_formspec( name, "bed", bed_gui )

    player_is_sleeping( player, true )
    set_player_animation( player, "lay", 0, false )
    player:set_eye_offset( { x = 0, y = -12, z = -7 }, { x = 0, y = 0, z = 0 } )

    insert_player_into_bed(player, new_pos)

    csm_send_player_to_sleep( player )
end

register_on_player_receive_fields( function( player, formname )
    if formname and formname == "bed" then
        wake_up( player )
    end
end)


register_on_respawnplayer( function( player )
    wake_up( player )
end )



-- The bed node definition
minetest.register_node("bed:bed", {
    description = "Bed",
    inventory_image = "bed.png",
    wield_image = "bed.png",
    paramtype2 = "facedir",
    tiles = {"bed_top.png^[transform1","wood.png","bed_side.png","bed_side.png^[transform4","bed_front.png","nothing.png"},
    groups = {wood = 1, hard = 1, axe = 1, hand = 3, instant=1},
    sounds = main.woodSound({placing=""}),
    drawtype = "nodebox",
    node_placement_prediction = "",
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        sneak = placer:get_player_control().sneak
        nodedef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]
        if not sneak and nodedef.on_rightclick then
            minetest.item_place(itemstack, placer, pointed_thing)
            return
        end
        local _,pos = minetest.item_place_node(ItemStack("bed:bed_front"), placer, pointed_thing)
        if pos then
            param2 = minetest.get_node(pos).param2
            pos2 = vec_add(pos, vec_multiply(minetest.facedir_to_dir(param2),-1))

            local buildable = minetest.registered_nodes[minetest.get_node(pos2).name].buildable_to

            if not buildable then
                minetest.remove_node(pos)
                return(itemstack)
            else
                minetest.add_node(pos2,{name="bed:bed_back", param2=param2})
                itemstack:take_item()
                minetest.sound_play("wood", {
                      pos = pos,
                })
                return(itemstack)
            end
        end
        return(itemstack)
    end,
})

minetest.register_node("bed:bed_front", {
    description = "Bed",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {"bed_top.png^[transform1","wood.png","bed_side.png","bed_side.png^[transform4","bed_front.png","nothing.png"},
    groups = {wood = 1, hard = 1, axe = 1, hand = 3, instant=1,bouncy=50},
    sounds = main.woodSound({placing=""}),
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {
                {-0.5, -5/16, -0.5, 0.5, 0.06, 0.5},
                {-0.5, -0.5, 0.5, -5/16, -5/16, 5/16},
                {0.5, -0.5, 0.5, 5/16, -5/16, 5/16},
            },
        },
    node_placement_prediction = "",
    drop = "bed:bed",
    on_dig = function(pos, node, digger)
        param2 = minetest.get_node(pos).param2
        facedir = minetest.facedir_to_dir(param2)    
        facedir = vec_multiply(facedir,-1)
        minetest.add_item(pos, "bed:bed")
        minetest.remove_node(pos)
        minetest.remove_node(vec_add(pos,facedir))
        minetest.punch_node(vec_new(pos.x,pos.y+1,pos.z))
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if pos.y <= -10033 then
            tnt(pos,10)
            return
        end

        param2 = minetest.get_node(pos).param2
        do_sleep(clicker,pos,param2)
    end,
})

minetest.register_node("bed:bed_back", {
    description = "Bed",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {"bed_top_end.png^[transform1","wood.png","bed_side_end.png","bed_side_end.png^[transform4","nothing.png","bed_end.png"},
    groups = {wood = 1, hard = 1, axe = 1, hand = 3, instant=1,bouncy=50},
    sounds = main.woodSound(),
    drawtype = "nodebox",
    node_placement_prediction = "",
    node_box = {
        type = "fixed",
        fixed = {
                {-0.5, -5/16, -0.5, 0.5, 0.06, 0.5},
                {-0.5, -0.5, -0.5, -5/16, -5/16, -5/16},
                {0.5, -0.5, -0.5, 5/16, -5/16, -5/16},
            },
        },
    drop = "",
    on_dig = function(pos)
        param2 = minetest.get_node(pos).param2
        facedir = minetest.facedir_to_dir(param2)    
        minetest.add_item(pos, "bed:bed")
        minetest.remove_node(pos)
        minetest.remove_node(vec_add(pos,facedir))
        --remove_spawnpoint(pos,digger)
        --remove_spawnpoint(vec_add(pos,facedir),digger)
        minetest.punch_node(vec_new(pos.x,pos.y+1,pos.z))
    end,
    on_rightclick = function(pos,_,clicker)
        if pos.y <= -10033 then
            tnt(pos,10)
            return
        end

        param2 = minetest.get_node(pos).param2
        dir = minetest.facedir_to_dir(param2)
        pos = vec_add(pos,dir)
        do_sleep(clicker,pos,param2)
    end,
})

minetest.register_craft({
    output = "bed:bed",
    recipe = {
        {"main:dropped_leaves", "main:dropped_leaves", "main:dropped_leaves"},
        {"main:wood"          , "main:wood"          , "main:wood"          },
    },
})
