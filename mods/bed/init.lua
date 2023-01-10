local register_on_joinplayer = minetest.register_on_joinplayer
local register_on_modchannel_message =  minetest.register_on_modchannel_message
local get_connected_players = minetest.get_connected_players
local get_player_by_name = minetest.get_player_by_name
local ipairs = ipairs
local vec_new = vector.new
local table_remove = table.remove

local night_begins = 19000
local night_ends   = 5500


--[[
    So we gotta get the players that are in bed
    the player's bed position

    if a player leaves when they are in bed somehow then remove them from the thing
    disable the player's controls when they are in bed
]]
local players_in_bed = {}
local name
local channel_decyphered
local time
local sleep_channel = {}
local sleep_check_timer = 0

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


--TODO: run a check on a simpler data table because this is a mess

register_on_joinplayer( function( player )
    name = player:get_player_name()
    sleep_channel[ name ] = minetest.mod_channel_join( name .. ":sleep_channel" )
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
        do return end
        ::continue::
    end
    minetest.close_formspec( name, "bed" )
    csm_wake_player_up( player )
end

local function sleep_check()

    -- No one is in bed, don't continue
    if #players_in_bed == 0 then return end

    -- Locks the players in bed until they get up or the night skips
    for _,bed_vec in ipairs( players_in_bed ) do
        local player = get_player_by_name( bed_vec.name )
        if not player then goto continue end
        player:move_to( vec_new( bed_vec.x, bed_vec.y, bed_vec.z ) )
        ::continue::
    end

    -- Not everyone is in bed, don't continue
    if #players_in_bed ~= #get_connected_players() then return end

    minetest.set_timeofday(night_ends/24000)

    for _,player in ipairs(get_connected_players()) do
        wake_up(player)
    end
end

minetest.register_globalstep(function(dtime)

    sleep_check_timer = sleep_check_timer + dtime

    if sleep_check_timer < 1 then return end

    sleep_check_timer = 0

    sleep_check()

end)

-- Delete data on player leaving
minetest.register_on_leaveplayer(function(player)
    name = player:get_player_name()
    pool[name] = nil
end)


local do_sleep = function( player, pos, dir )

    time = minetest.get_timeofday() * 24000
    name = player:get_player_name()

    if time < night_begins or time > night_ends then
        minetest.chat_send_player( name, "You can only sleep at night" )
    end

    local real_dir = minetest.facedir_to_dir( dir )
    player:add_velocity( vector.multiply( player:get_velocity(), -1 ) )
    local new_pos = vector.subtract( pos, vector.divide( real_dir, 2 ) )
    player:move_to( new_pos )
    player:set_look_vertical( 0 )
    player:set_look_horizontal( ( dir + 1 ) * math.pi )

    minetest.show_formspec( ( dir + 1) * math.pi )

    player_is_sleeping( player, true )
    set_player_animation( player, "lay", 0, false )
    player:set_eye_offset( {
        x = 0,
        y = -12,
        z = -7
    },
    {
        x = 0,
        y = 0,
        z = 0
    } )

    pool[ name ] = {
        pos = new_pos,
        sleeping = false
    }

    csm_send_player_to_sleep( player )

    sleep_loop = true
end

minetest.register_on_player_receive_fields( function( player, formname )
    if formname and formname == "bed" then
        wake_up( player )
    end
end)


minetest.register_on_respawnplayer( function( player )
    wake_up( player )
end )

--these are beds
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
        local sneak = placer:get_player_control().sneak
        local noddef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]
        if not sneak and noddef.on_rightclick then
            minetest.item_place(itemstack, placer, pointed_thing)
            return
        end
        local _,pos = minetest.item_place_node(ItemStack("bed:bed_front"), placer, pointed_thing)
        if pos then
            local param2 = minetest.get_node(pos).param2
            local pos2 = vector.add(pos, vector.multiply(minetest.facedir_to_dir(param2),-1))

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
        local param2 = minetest.get_node(pos).param2
        local facedir = minetest.facedir_to_dir(param2)    
        facedir = vector.multiply(facedir,-1)
        local obj = minetest.add_item(pos, "bed:bed")
        minetest.remove_node(pos)
        minetest.remove_node(vector.add(pos,facedir))
        minetest.punch_node(vector.new(pos.x,pos.y+1,pos.z))
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if pos.y <= -10033 then
            tnt(pos,10)
            return
        end

        local param2 = minetest.get_node(pos).param2
        
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
    on_dig = function(pos, node, digger)
        local param2 = minetest.get_node(pos).param2
        local facedir = minetest.facedir_to_dir(param2)    
        local obj = minetest.add_item(pos, "bed:bed")
        minetest.remove_node(pos)
        minetest.remove_node(vector.add(pos,facedir))
        --remove_spawnpoint(pos,digger)
        --remove_spawnpoint(vector.add(pos,facedir),digger)
        minetest.punch_node(vector.new(pos.x,pos.y+1,pos.z))
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if pos.y <= -10033 then
            tnt(pos,10)
            return
        end

        local param2 = minetest.get_node(pos).param2
        local dir = minetest.facedir_to_dir(param2)    

        do_sleep(clicker,vector.add(pos,dir),param2)
    end,
})




minetest.register_craft({
    output = "bed:bed",
    recipe = {
        {"main:dropped_leaves", "main:dropped_leaves", "main:dropped_leaves"},
        {"main:wood"          , "main:wood"          , "main:wood"          },
    },
})
