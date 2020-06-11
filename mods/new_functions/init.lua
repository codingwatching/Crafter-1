local minetest,math,vector,table = minetest,math,vector,table

local environment_class            = {} -- environment class

local player_environment           = {} -- stores environment data per player

environment_class.registered_nodes = {} -- stored registered nodes into local table

environment_class.get_group        = minetest.get_item_group

environment_class.get_node         = minetest.get_node

environment_class.hurt_nodes       = {}

environment_class.tick             = nil

-- creates volitile player environment data for the game to use
environment_class.set_data = function(player,data)
	local name = player:get_player_name()
	if not player_environment[name] then
		player_environment[name] = {}
	end

	for index,i_data in pairs(data) do
		player_environment[name][index] = i_data
	end
end

-- indexes player environment data and returns it
environment_class.get_data = function(player,requested_data)
	local name = player:get_player_name()
	if player_environment[name] then
		local data_list = {}
		local count     = 0
		for index,i_data in pairs(requested_data) do
			if player_environment[name][i_data] then
				data_list[i_data] = player_environment[name][i_data]
				count = count + 1
			end
		end
		if count > 0 then
			return(data_list)
		else
			return(nil)
		end
	end
	return(nil)
end

-- removes player environment data
environment_class.terminate = function(player)
	local name = player:get_player_name()
	if player_environment[name] then
		player_environment[name] = nil
	end
end

-- create blank list for player environment data
minetest.register_on_joinplayer(function(player)
	environment_class.set_data(player,{})
end)

-- destroy player environment data
minetest.register_on_leaveplayer(function(player)
	environment_class.terminate(player)
end)

-- creates smaller table of "touch_hurt" nodes
minetest.register_on_mods_loaded(function()
	environment_class.registered_nodes = table.copy(minetest.registered_nodes)
	for _,def in pairs(environment_class.registered_nodes) do
		if environment_class.get_group(def.name, "touch_hurt") > 0 then
			table.insert(environment_class.hurt_nodes,def.name)
		end
	end
end)

--reset their drowning settings
--minetest.register_on_dieplayer(function(ObjectRef, reason))


-- handle damage when touching node
-- this is lua collision detection
local collision_class           = {}
collision_class.player_pos      = nil
collision_class.damage_nodes    = nil
collision_class.a_min           = nil
collision_class.a_max           = nil
collision_class.damage_amount   = nil
collision_class.gotten_node     = nil
collision_class.tick            = nil
collision_class.table_max       = table.getn
collision_class.subtract        = vector.subtract
collision_class.add             = vector.add
collision_class.new             = vector.new
collision_class.abs             = math.abs
collision_class.floor           = math.floor
collision_class.find            = minetest.find_nodes_in_area
collision_class.get_node        = minetest.get_node
collision_class.get_group       = minetest.get_item_group

collision_class.hurt_collide = function(player,dtime)
	if player:get_hp() <= 0 then
		return
	end
	--used for finding a damage node from the center of the player
	collision_class.player_pos = player:get_pos()
	collision_class.player_pos.y = collision_class.player_pos.y + (player:get_properties().collisionbox[5]/2)
	collision_class.a_min = collision_class.new(
		collision_class.player_pos.x-0.25,
		collision_class.player_pos.y-0.9,
		collision_class.player_pos.z-0.25
	)
	collision_class.a_max = collision_class.new(
		collision_class.player_pos.x+0.25,
		collision_class.player_pos.y+0.9,
		collision_class.player_pos.z+0.25
	)

	collision_class.damage_nodes = collision_class.find(collision_class.a_min, collision_class.a_max, {"group:touch_hurt"})

	collision_class.hurt = 0
	collision_class.damage_amount = nil
	collision_class.gotten_node   = nil
	collision_class.damage_amount = nil

	if collision_class.table_max(collision_class.damage_nodes) > 0 then
		for _,found_location in ipairs(collision_class.damage_nodes) do
			
			collision_class.gotten_node = collision_class.get_node(found_location).name

			collision_class.damage_amount = collision_class.get_group(collision_class.gotten_node, "touch_hurt")

			if collision_class.damage_amount > collision_class.hurt then
				collision_class.hurt = collision_class.damage_amount
			end
		end
		collision_class.handle_touch_hurting(player,collision_class.damage_amount,dtime)
	else
		environment_class.set_data(player,{hurt_ticker = 0})
	end
end

-- damages players 4 times a second
collision_class.handle_touch_hurting = function(player,damage,dtime)
	collision_class.tick = environment_class.get_data(player,{"hurt_ticker"})
	if collision_class.tick then
		collision_class.tick = collision_class.tick.hurt_ticker
	end
	if not collision_class.tick then
		environment_class.set_data(player,{hurt_ticker = 0.25})
		player:set_hp(player:get_hp()-damage)
	else
		collision_class.tick = collision_class.tick - dtime
		if collision_class.tick <= 0 then
			player:set_hp(player:get_hp()-damage)
			environment_class.set_data(player,{hurt_ticker = 0.25})
		else
			environment_class.set_data(player,{hurt_ticker = collision_class.tick})
		end
	end
end

-- handles being inside a hurt node
collision_class.hurt_inside = function(player,dtime)
	if player:get_hp() <= 0 then
		return
	end
	--used for finding a damage node from the center of the player
	collision_class.player_pos = player:get_pos()
	collision_class.player_pos.y = collision_class.player_pos.y + (player:get_properties().collisionbox[5]/2)
	collision_class.a_min = collision_class.new(
		collision_class.player_pos.x-0.25,
		collision_class.player_pos.y-0.85,
		collision_class.player_pos.z-0.25
	)
	collision_class.a_max = collision_class.new(
		collision_class.player_pos.x+0.25,
		collision_class.player_pos.y+0.85,
		collision_class.player_pos.z+0.25
	)

	collision_class.damage_nodes = collision_class.find(collision_class.a_min, collision_class.a_max, {"group:hurt_inside"})

	collision_class.hurt = 0
	collision_class.damage_amount = nil
	collision_class.gotten_node   = nil
	collision_class.damage_amount = nil

	if collision_class.table_max(collision_class.damage_nodes) > 0 then
		for _,found_location in ipairs(collision_class.damage_nodes) do
			
			collision_class.gotten_node = collision_class.get_node(found_location).name

			collision_class.damage_amount = collision_class.get_group(collision_class.gotten_node, "hurt_inside")

			if collision_class.damage_amount > collision_class.hurt then
				collision_class.hurt = collision_class.damage_amount
			end
		end
		collision_class.handle_inside_hurting(player,collision_class.damage_amount,dtime)
	else
		environment_class.set_data(player,{touch_hurt_ticker = 0})
	end
end

-- damages players 4 times a second
collision_class.handle_inside_hurting = function(player,damage,dtime)
	collision_class.tick = environment_class.get_data(player,{"touch_hurt_ticker"})
	if collision_class.tick then
		collision_class.tick = collision_class.tick.touch_hurt_ticker
	end
	if not collision_class.tick then
		environment_class.set_data(player,{touch_hurt_ticker = 0.25})
		player:set_hp(player:get_hp()-damage)
	else
		collision_class.tick = collision_class.tick - dtime
		if collision_class.tick <= 0 then
			player:set_hp(player:get_hp()-damage)
			environment_class.set_data(player,{touch_hurt_ticker = 0.25})
		else
			environment_class.set_data(player,{touch_hurt_ticker = collision_class.tick})
		end
	end
end


-- handles being inside a hurt node
collision_class.set_on_fire = function(player,dtime)
	if player:get_hp() <= 0 then
		return
	end
	--used for finding a damage node from the center of the player
	collision_class.player_pos = player:get_pos()
	collision_class.player_pos.y = collision_class.player_pos.y + (player:get_properties().collisionbox[5]/2)
	collision_class.a_min = collision_class.new(
		collision_class.player_pos.x-0.25,
		collision_class.player_pos.y-0.85,
		collision_class.player_pos.z-0.25
	)
	collision_class.a_max = collision_class.new(
		collision_class.player_pos.x+0.25,
		collision_class.player_pos.y+0.85,
		collision_class.player_pos.z+0.25
	)

	collision_class.damage_nodes = collision_class.find(collision_class.a_min, collision_class.a_max, {"group:hurt_inside"})

	if collision_class.table_max(collision_class.damage_nodes) > 0 then
		for _,found_location in ipairs(collision_class.damage_nodes) do
			start_fire(player)
		end
	end
end

-- handle player suffocating inside solid node
environment_class.handle_player_suffocation = function(player,dtime)
	if player:get_hp() <= 0 then
		return
	end
	
	local data = environment_class.get_data(player,{"head"})

	if data then
		data = data.head
		print(environment_class.registered_nodes[data].drawtype)
		if minetest.get_nodedef(data, "drawtype") == "normal" then
			environment_class.handle_suffocation_hurt(player,1,dtime)
		else
			environment_class.set_data(player,{suffocation_ticker = 0})
		end
	end		
end

-- damages players 4 times a second
environment_class.handle_suffocation_hurt = function(player,damage,dtime)
	environment_class.tick = environment_class.get_data(player,{"suffocation_ticker"})
	if environment_class.tick then
		environment_class.tick = environment_class.tick.suffocation_ticker
	end
	if not environment_class.tick then
		environment_class.set_data(player,{suffocation_ticker = 0.25})
		player:set_hp(player:get_hp()-damage)
	else
		environment_class.tick = environment_class.tick - dtime
		if environment_class.tick <= 0 then
			player:set_hp(player:get_hp()-damage)
			environment_class.set_data(player,{suffocation_ticker = 0.25})
		else
			environment_class.set_data(player,{suffocation_ticker = environment_class.tick})
		end
	end
end


-- environment indexing class
local index_class        = {}
index_class.pos          = nil
index_class.data_table   = nil
index_class.get_node     = minetest.get_node

-- creates data at specific points of the player
index_class.index_players_surroundings = function(dtime)
	for _,player in ipairs(minetest.get_connected_players()) do
		index_class.pos = player:get_pos()
		
		index_class.data_table = {}

		index_class.pos.y             = index_class.pos.y - 0.1
		index_class.data_table.under  = index_class.get_node(index_class.pos).name

		index_class.pos.y             = index_class.pos.y + 0.6
		index_class.data_table.legs   = index_class.get_node(index_class.pos).name

		index_class.pos.y             = index_class.pos.y + 0.940
		index_class.data_table.head   = index_class.get_node(index_class.pos).name

		environment_class.set_data(player,index_class.data_table)

		collision_class.hurt_collide(player,dtime)

		collision_class.hurt_inside(player,dtime)

		environment_class.handle_player_suffocation(player,dtime)
	end
end

minetest.register_globalstep(function(dtime)
	index_class.index_players_surroundings(dtime)
end)

--[[
--completely destroy the breath bar
minetest.hud_replace_builtin("breath",{
	hud_elem_type = "statbar",
	position = {x = 0.5, y = 1},
	text = "nothing.png",
	number = 50000,
	direction = 0,
	size = {x = 24, y = 24},
	offset = {x = 25, y= -(48 + 24 + 16)},
})

minetest.register_on_joinplayer(function(player)
	player:hud_set_flags({breathbar=false})
	
	local meta = player:get_meta()
	--give players new breath when they join
	meta:set_int("breath", 10)
	player:hud_add({
		hud_elem_type = "statbar",
		position = {x = 0.5, y = 1},
		text = "bubble_bg.png",
		number = 20,
		direction = 1,
		size = {x = 24, y = 24},
		offset = {x = 24*10, y= -(48 + 24 + 39)},
	})
	local bubble_id = player:hud_add({
		hud_elem_type = "statbar",
		position = {x = 0.5, y = 1},
		text = "bubble.png",
		number = 20,
		direction = 1,
		size = {x = 24, y = 24},
		offset = {x = 24*10, y= -(48 + 24 + 39)},
	})
	meta:set_int("breathbar", bubble_id)
end)

minetest.register_on_respawnplayer(function(player)
	local meta = player:get_meta()
	meta:set_int("breath", 10)
	meta:set_int("drowning", 0)
	meta:set_int("breath_ticker", 0)
	player:hud_change(meta:get_int("breathbar"), "number", 20)
end)

--begin custom breathbar
local name
local indexer
--handle the breath bar
local function fix_breath_hack()
	for _,player in ipairs(minetest.get_connected_players()) do
		player:set_breath(50000)
		name = player:get_player_name()
		if environment[name] then
			indexer = environment[name].head
			local meta = player:get_meta()
			local breath = meta:get_int("breath")
			local breathbar = meta:get_int("breathbar")
			
			if indexer == "main:water" or indexer == "main:waterflow" then
				local ticker = meta:get_int("breath_ticker")
			
				ticker = ticker + 1
				if ticker > 5 then ticker = 0 end

				meta:set_int("breath_ticker", ticker)
							
				if breath > 0 and ticker >= 5 then
					breath = breath - 1
					meta:set_int("breath", breath)
					player:hud_change(breathbar, "number", breath*2)
					meta:set_int("drowning", 0)
				elseif breath <= 0 and ticker >= 5 then
					local hp =  player:get_hp()
					meta:set_int("drowning", 1)
					if hp > 0 then
						player:set_hp(hp-2)
						player:add_player_velocity(vector.new(0,-15,0))
					end
				end
			elseif breath < 10 then --reset the bar
				breath = breath + 1
				meta:set_int("breath", breath)
				meta:set_int("drowning", 0)
				meta:set_int("breath_ticker", 0)
				player:hud_change(breathbar, "number", breath*2)
			end
		end
	end
	
	minetest.after(0.25, function()
		fix_breath_hack()
	end)
end
minetest.register_on_mods_loaded(function()
	minetest.after(0,function()
		fix_breath_hack()
	end)
end)
]]--

function minetest.get_nodedef(nodename, fieldname)
	if not minetest.registered_nodes[nodename] then
		return nil
	end
	return minetest.registered_nodes[nodename][fieldname]
end

function minetest.get_itemdef(itemname, fieldname)
	if not minetest.registered_items[itemname] then
		return nil
	end
	return minetest.registered_items[itemname][fieldname]
end
