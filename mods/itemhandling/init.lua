local ipairs = ipairs
local ItemStack = ItemStack
local settings = minetest.settings
local sound_play = minetest.sound_play
local get_node = minetest.get_node
local get_node_or_nil = minetest.get_node_or_nil
local get_objects_inside_radius = minetest.get_objects_inside_radius
local get_connected_players = minetest.get_connected_players
local get_item_group = minetest.get_item_group
local add_item = minetest.add_item
local add_entity = minetest.add_entity
local registered_nodes = minetest.registered_nodes
local serialize = minetest.serialize
local deserialize = minetest.deserialize
local get_player_by_name = minetest.get_player_by_name
local add_particlespawner = minetest.add_particlespawner
local vec_new = vector.new
local vec_subtract = vector.subtract
local vec_add = vector.add
local vec_distance = vector.distance
local vec_normalize = vector.normalize
local vec_round = vector.round
local vec_multiply = vector.multiply
local math_random = math.random
local math_abs = math.abs


local burn_nodes = {
    ["fire:fire"]       = true,
    ["nether:lava"]     = true,
    ["nether:lavaflow"] = true,
    ["main:lava"]       = true,
    ["main:lavaflow"]   = true
}

local water_nodes = {
    ["main:water"] = true,
    ["main:waterflow"] = true
}

local order = {
    { x = 1, y = 0, z = 0 },
    { x =-1, y = 0, z = 0 },
    { x = 0, y = 0, z = 1 },
    { x = 0, y = 0, z =-1 },
}

local collector
local player_velocity
local direction
local distance
local multiplier
local velocity
local node
local is_stuck
local snode
local shootdir
local cnode
local cdef
local fpos
local vel
local slip_factor
local change
local slippery
local i_node
local flow_dir
local acceleration
local pos
local pos2
local diff
local inv
local entity
local tick = false
local meta
local careful
local fortune
local autorepair
local count
local name
local object
local stack
local dropper_is_player
local sneak
local item
local dir
local itemname
local def
local data
local creative_mode = settings:get_bool("creative_mode")


local pool = {}

minetest.register_on_joinplayer(function(player)
    name = player:get_player_name()
    pool[name] = 0
end)

minetest.register_on_leaveplayer(function(player)
    name = player:get_player_name()
    pool[name] = nil
end)

--The item collection magnet
local function magnet(player)

    -- Don't magnetize to dead players
    name = player:get_player_name()
    if player:get_hp() <= 0 then
        pool[name] = 0
        return
    end

    pos = player:get_pos()
    inv = player:get_inventory()

    if not tick or pool[name] <= 0 then goto skip_playing_sound end

    sound_play("pickup", {
        to_player = player:get_player_name(),
        gain = 0.4,
        pitch = math_random(60,100)/100
    })

    if pool[name] > 6 then
        pool[name] = 6
    else
        pool[name] = pool[name] - 1
    end

    ::skip_playing_sound::

    -- Radial magnet detection
    for _,this_object in ipairs(get_objects_inside_radius({x=pos.x,y=pos.y+0.5,z=pos.z}, 2)) do
        if this_object:is_player() then goto continue end

        entity = this_object:get_luaentity()

        if not entity then goto continue end

        if entity.name == "__builtin:item" and entity.collectable == true and entity.collected == false then

            pos2 = this_object:get_pos()

            diff = vec_subtract(pos2,pos).y

            if diff < 0 or not inv:room_for_item("main", entity.itemstring) then goto continue end

            pool[name] = pool[name] + 1
            inv:add_item("main", entity.itemstring)
            entity.collector = player:get_player_name()
            entity.collected = true

        elseif entity.name == "experience:orb" then

            entity.collector = player:get_player_name()
            entity.collected = true

        end

        ::continue::
    end
end


minetest.register_globalstep(function()
    tick = not tick
    for _,player in ipairs(get_connected_players()) do
        magnet(player)
    end
end)

--handle node drops
--survival
if not creative_mode then
    function minetest.handle_node_drops(this_pos, drops, digger)
        meta = digger:get_wielded_item():get_meta()
        careful = meta:get_int("careful")
        fortune = meta:get_int("fortune") + 1
        autorepair = meta:get_int("autorepair")

        if careful > 0 then
            drops = {
                get_node(this_pos).name
            }
        end

        local experience_amount = get_item_group(get_node(this_pos).name,"experience")

        for _ = 1,fortune do

            for _,this_item in ipairs(drops) do

                if type(this_item) == "string" then
                    count = 1
                    name = this_item
                else
                    count = this_item:get_count()
                    name = this_item:get_name()
                end

                for _ = 1, count do
                    object = add_item(this_pos, name)
                    if object ~= nil then
                        object:set_velocity({
                            x=math_random(-2,2)*math_random(),
                            y=math_random(2,5),
                            z=math_random(-2,2)*math_random()
                        })
                    end
                end
            end
            if experience_amount > 0 then
                minetest.throw_experience(this_pos, experience_amount)
            end
        end
        --auto repair the item
        if autorepair > 0 and math_random(0,1000) < autorepair then
            local itemstack = digger:get_wielded_item()
            itemstack:add_wear(autorepair*-100)
            digger:set_wielded_item(itemstack)
        end
    end
-- Creative
else
    function minetest.handle_node_drops(this_pos, drops, digger)
    end
    minetest.register_on_dignode(function(this_pos, oldnode, digger)
        
        --if digger and digger:is_player() then
        --    local inv = digger:get_inventory()
        --    if inv and not inv:contains_item("main", oldnode) and inv:room_for_item("main", oldnode) then
        --        inv:add_item("main", oldnode)
        --    end
        --end
    end)
    minetest.register_on_placenode(function(_, _, _, _, itemstack)
        return itemstack
    end)
end

function minetest.throw_item(this_pos, this_item)
    object = add_entity(this_pos, "__builtin:item")
    if object then
        object:get_luaentity():set_item(this_item)
        object:set_velocity({
            x=math_random(-2,2)*math_random(),
            y=math_random(2,5),
            z=math_random(-2,2)*math_random()
        })
    end
    return object
end

function minetest.throw_experience(this_pos, amount)
    for _ = 1,amount do
        object = add_entity(this_pos, "experience:orb")
        if not object then return end
        object:set_velocity({
            x=math_random(-2,2)*math_random(),
            y=math_random(2,5),
            z=math_random(-2,2)*math_random()
        })
    end
end

-- Override drops
function minetest.item_drop(itemstack, dropper, this_pos)
    dropper_is_player = dropper and dropper:is_player()
    if dropper_is_player then
        sneak = dropper:get_player_control().sneak
        this_pos.y = this_pos.y + 1.2
        if not sneak then
            count = itemstack:get_count()
        else
            count = 1
        end
    else
        count = itemstack:get_count()
    end

    item = itemstack:take_item(count)
    object = add_item(this_pos, item)
    if object then
        if dropper_is_player then
            dir = dropper:get_look_dir()
            dir.x = dir.x * 2.9
            dir.y = dir.y * 2.9 + 2
            dir.z = dir.z * 2.9
            dir = vec_add(dir,dropper:get_velocity())
            object:set_velocity(dir)
            object:get_luaentity().dropped_by = dropper:get_player_name()
            object:get_luaentity().collection_timer = 0
        end
        return itemstack
    end
end


-- Item entity class
local item_entity = {}

-- Item entity fields
item_entity.initial_properties = {
    hp_max = 1,
    visual = "wielditem",
    physical = true,
    textures = {""},
    automatic_rotate = 1.5,
    is_visible = true,
    pointable = false,
    collide_with_objects = false,
    collisionbox = {-0.21, -0.21, -0.21, 0.21, 0.21, 0.21},
    selectionbox = {-0.21, -0.21, -0.21, 0.21, 0.21, 0.21},
    visual_size  = {x = 0.21, y = 0.21},
}
item_entity.itemstring = ""
item_entity.moving_state = true
item_entity.slippery_state = false
item_entity.physical_state = true
-- Item expiry
item_entity.age = 0
-- Pushing item out of solid nodes
item_entity.force_out = nil
item_entity.force_out_start = nil
-- Collection Variables
item_entity.collection_timer = 2
item_entity.collectable = false
item_entity.try_timer = 0
item_entity.collected = false
item_entity.delete_timer = 0
-- Used for server delay
item_entity.magnet_timer = 0
item_entity.poll_timer = 0

-- Item entity methods
function item_entity:set_item(this_item)
    stack = ItemStack(this_item or self.itemstring)
    self.itemstring = stack:to_string()
    if self.itemstring == "" then
        -- item not yet known
        return
    end

    itemname = stack:is_known() and stack:get_name() or "unknown"

    def = registered_nodes[itemname]

    self.object:set_properties({
        textures = {itemname},
        wield_item = self.itemstring,
        glow = def and def.light_source,
    })
end


function item_entity:get_staticdata()
    return serialize({
        itemstring = self.itemstring,
        age = self.age,
        dropped_by = self.dropped_by,
        collection_timer = self.collection_timer,
        collectable = self.collectable,
        try_timer = self.try_timer,
        collected = self.collected,
        delete_timer = self.delete_timer,
        collector = self.collector,
        magnet_timer = self.magnet_timer,
    })
end

function item_entity:on_activate(staticdata, dtime_s)
    if string.sub(staticdata, 1, string.len("return")) == "return" then
        data = deserialize(staticdata)
        if data and type(data) == "table" then
            self.itemstring = data.itemstring
            self.age = (data.age or 0) + dtime_s
            self.dropped_by = data.dropped_by
            self.magnet_timer = data.magnet_timer
            self.collection_timer = data.collection_timer
            self.collectable = data.collectable
            self.try_timer = data.try_timer
            self.collected = data.collected
            self.delete_timer = data.delete_timer
            self.collector = data.collector
        end
    else
        self.itemstring = staticdata
    end
    self.object:set_armor_groups({immortal = 1})
    self.object:set_velocity({x = 0, y = 2, z = 0})
    self.object:set_acceleration({x = 0, y = -9.81, z = 0})
    self:set_item(self.itemstring)
end

function item_entity:enable_physics()
    if not self.physical_state then
        self.physical_state = true
        self.object:set_properties({physical = true})
        self.object:set_velocity({x=0, y=0, z=0})
        self.object:set_acceleration({x=0, y=-9.81, z=0})
    end
end

function item_entity:disable_physics()
    if self.physical_state then
        self.physical_state = false
        self.object:set_properties({physical = false})
        self.object:set_velocity({x=0, y=0, z=0})
        self.object:set_acceleration({x=0, y=0, z=0})
    end
end

function item_entity:on_step(dtime, moveresult)

    pos = self.object:get_pos()

    -- I'm not sure why this is here, but I'm too scared to remove it
    if not pos then
        self.object:remove()
        return
    end

    -- If item set to be collected then only execute go to player
    if self.collected == true then

        if not self.collector then
            self.object:remove()
            return
        end

        collector = get_player_by_name(self.collector)

        if collector then

            self.magnet_timer = self.magnet_timer + dtime

            self:disable_physics()

            pos2 = collector:get_pos()
            player_velocity = collector:get_velocity()
            pos2.y = pos2.y + 0.5

            distance = vec_distance(pos2,pos)

            if distance > 2 or distance < 0.3 or self.magnet_timer > 0.2 or (self.old_magnet_distance and self.old_magnet_distance < distance) then
                self.object:remove()
                return
            end

            direction = vec_normalize(vec_subtract(pos2,pos))

            multiplier = 10 - distance -- changed

            velocity = vec_add(player_velocity,vec_multiply(direction,multiplier))

            self.object:set_velocity(velocity)

            self.old_magnet_distance = distance
        else
            -- the collector doesn't exist
            self.object:remove()
        end
        return
    end

    -- Allow entity to be collected after timer
    if self.collectable == false and self.collection_timer >= 2.5 then
        self.collectable = true
    elseif self.collectable == false then
        self.collection_timer = self.collection_timer + dtime
    end

    self.age = self.age + dtime
    if self.age > 300 then
        self.object:remove()
        return
    end

    -- Polling eases the server load
    if self.poll_timer > 0 then
        self.poll_timer = self.poll_timer - dtime
        if self.poll_timer <= 0 then
            self.poll_timer = 0
        end
        return
    end

    i_node = get_node_or_nil(pos)

    -- Remove nodes in 'ignore' and burns items
    if i_node then
        if i_node.name == "ignore" then
            self.object:remove()
            return
        elseif burn_nodes[i_node.name] then
            add_particlespawner({
                amount = 6,
                time = 0.001,
                minpos = pos,
                maxpos = pos,
                minvel = vec_new(-1,0.5,-1),
                maxvel = vec_new(1,1,1),
                minacc = {x=0, y=1, z=0},
                maxacc = {x=0, y=2, z=0},
                minexptime = 1.1,
                maxexptime = 1.5,
                minsize = 1,
                maxsize = 2,
                collisiondetection = false,
                vertical = false,
                texture = "smoke.png",
            })
            sound_play("fire_extinguish", {pos=pos,gain=0.3,pitch=math_random(80,100)/100})
            self.object:remove()
            return
        end
    end


    is_stuck = false
    snode = get_node_or_nil(pos)
    if snode and snode ~= "air" then
        snode = registered_nodes[snode.name] or {}
        is_stuck = (snode.walkable == nil or snode.walkable == true)
            and (snode.collision_box == nil or snode.collision_box.type == "regular")
            and (snode.node_box == nil or snode.node_box.type == "regular")
    end

    -- Push item out when stuck inside solid node
    change = false

    if is_stuck then
        change = true
        shootdir = nil
        -- Check which one of the 4 sides is free
        for o = 1, #order do
            cnode = get_node(vec_add(pos, order[o])).name
            cdef = registered_nodes[cnode] or {}
            if cnode ~= "ignore" and cdef.walkable == false then
                shootdir = order[o]
                break
            end
        end

        -- If none of the 4 sides is free, check upwards
        if not shootdir then
            shootdir = {x=0, y=1, z=0}
            cnode = get_node(vec_add(pos, shootdir)).name
            if cnode == "ignore" then
                shootdir = nil -- Do not push into ignore
                change = false
            end
        end

        if shootdir then
            -- Shove that thing outta there
            fpos = vec_round(pos)
            if shootdir.x ~= 0 then
                shootdir = vec_multiply(shootdir,0.74)
                self.object:move_to(vec_new(fpos.x+shootdir.x,pos.y,pos.z))
            elseif shootdir.y ~= 0 then
                shootdir = vec_multiply(shootdir,0.72)
                self.object:move_to(vec_new(pos.x,fpos.y+shootdir.y,pos.z))
            elseif shootdir.z ~= 0 then
                shootdir = vec_multiply(shootdir,0.74)
                self.object:move_to(vec_new(pos.x,pos.y,fpos.z+shootdir.z))
            end
            return
        end
    end

    -- Items flow in water
    if snode and water_nodes[snode.name] then
        flow_dir = get_liquid_flow_direction(pos)

        if flow_dir then
            flow_dir = vec_multiply(flow_dir,10)
            vel = self.object:get_velocity()
            acceleration = vec_new(flow_dir.x-vel.x,flow_dir.y-vel.y,flow_dir.z-vel.z)
            acceleration = vec_multiply(acceleration, 0.01)
            self.object:add_velocity(acceleration)
            return
        end
    end

    node = nil
    if moveresult and moveresult.touching_ground and #moveresult.collisions > 0 then
        node = get_node_or_nil(moveresult.collisions[1].node_pos)
    end

    -- Slide on slippery nodes
    def = node and registered_nodes[node.name]
    vel = self.object:get_velocity()
    if node and def and def.walkable then
        slippery = get_item_group(node.name, "slippery")
        if slippery ~= 0 then
            if math_abs(vel.x) > 0.2 or math_abs(vel.z) > 0.2 then
                -- Horizontal deceleration
                slip_factor = 4.0 / (slippery + 4)
                self.object:set_acceleration({
                    x = -vel.x * slip_factor,
                    y = -9.81,
                    z = -vel.z * slip_factor
                })
                change = true
            elseif (vel.x ~= 0 or vel.z ~= 0) and math_abs(vel.x) <= 0.2 and math_abs(vel.z) <= 0.2 then
                self.object:set_velocity(vec_new(0,vel.y,0))
                self.object:set_acceleration(vec_new(0,-9.81,0))
            end
        elseif node then
            if math_abs(vel.x) > 0.2 or math_abs(vel.z) > 0.2 then
                self.object:add_velocity({
                    x = -vel.x * 0.15,
                    y = 0,
                    z = -vel.z * 0.15
                })
                change = true
            elseif (vel.x ~= 0 or vel.z ~= 0) and math_abs(vel.x) <= 0.2 and math_abs(vel.z) <= 0.2 then
                self.object:set_velocity(vec_new(0,vel.y,0))
                self.object:set_acceleration(vec_new(0,-9.81,0))
            end
        end
    elseif vel.x ~= 0 or vel.y ~= 0 or vel.z ~= 0 then
        change = true
    end

    if change == false and self.poll_timer == 0 then
        self.poll_timer = 0.5
    end
end


minetest.register_entity(":__builtin:item", item_entity)


minetest.register_chatcommand("gimme", {
    params = "nil",
    description = "Spawn x amount of a mob, used as /spawn 'mob' 10 or /spawn 'mob' for one",
    privs = {server=true},
    func = function(player_name)
        local player = get_player_by_name(player_name)
        pos = player:get_pos()
        pos.y = pos.y + 5
        pos.x = pos.x + 8
        for _ = 1,1000 do
            minetest.throw_item(pos, "main:dirt")
        end
    end,
})
