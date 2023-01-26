local ipairs = ipairs
local get_node_or_nil = minetest.get_node_or_nil
local serialize = minetest.serialize
local deserialize = minetest.deserialize
local sound_play = minetest.sound_play
local set_node = minetest.set_node
local check_for_falling = minetest.check_for_falling
local registered_nodes = minetest.registered_nodes
local get_item_group = minetest.get_item_group
local add_node_level = minetest.add_node_level
local get_node = minetest.get_node
local remove_node = minetest.remove_node
local get_node_drops = minetest.get_node_drops
local throw_item = minetest.throw_item
local get_meta = minetest.get_meta
local dig_node = minetest.dig_node
local vec_equals = vector.equals
local vec_new = vector.new
local vec_round = vector.round
local math_pi = math.pi

local param_translation = {
    [0] = 0,
    [3] = math_pi/2,
    [2] = math_pi,
    [1] = math_pi*1.5,
}

local ds
local pos
local bcp
local bcn
local bcd
local acceleration
local def
local addlevel
local np
local n2
local npos
local nd
local drops
local meta
local vel

-- Falling node class
local falling_node = {}

-- Falling node fields
falling_node.initial_properties = {
    visual = "wielditem",
    visual_size = {x = 0.667, y = 0.667},
    textures = {},
    physical = true,
    is_visible = false,
    collide_with_objects = false,
    collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
}

falling_node.node = {}
falling_node.meta = {}

-- Falling node methods
function falling_node:set_node( node, meta )

    self.node = node

    meta = meta or {}

    if type(meta.to_table) == "function" then
        meta = meta:to_table()
    end

    for _, list in ipairs(meta.inventory or {}) do
        for i, stack in ipairs(list) do
            if type(stack) == "userdata" then
                list[i] = stack:to_string()
            end
        end
    end
    self.meta = meta


    self.object:set_properties({
        is_visible = true,
        textures = {node.name},
    })

    if node.param2 then
        self.object:set_rotation(vec_new(0,param_translation[node.param2],0))
    end
end

function falling_node:get_staticdata()
    ds = {
        node = self.node,
        meta = self.meta,
    }
    return serialize(ds)
end

function falling_node:on_activate( staticdata )
    self.object:set_armor_groups({immortal = 1})

    ds = deserialize(staticdata)
    if ds and ds.node then
        self:set_node(ds.node, ds.meta)
    elseif ds then
        self:set_node(ds)
    elseif staticdata ~= "" then
        self:set_node({name = staticdata})
    end
end

function falling_node:on_step( dtime )
    -- Set gravity
    acceleration = self.object:get_acceleration()
    if not vec_equals(acceleration, {x = 0, y = -10, z = 0}) then
        self.object:set_acceleration({x = 0, y = -10, z = 0})
    end
    -- Turn to actual node when colliding with ground, or continue to move
    pos = self.object:get_pos()
    -- Position of bottom center point
    bcp = {x = pos.x, y = pos.y - 0.7, z = pos.z}
    -- 'bcn' is nil for unloaded nodes
    bcn = get_node_or_nil(bcp)
    -- Delete on contact with ignore at world edges
    if bcn and bcn.name == "ignore" then
        self.object:remove()
        return
    end
    bcd = bcn and registered_nodes[bcn.name]
    if bcn and
            (not bcd or bcd.walkable or
            (get_item_group(self.node.name, "float") ~= 0 and
            bcd.liquidtype ~= "none")) then
        if bcd and bcd.leveled and
                bcn.name == self.node.name then
            addlevel = self.node.level
            if not addlevel or addlevel <= 0 then
                addlevel = bcd.leveled
            end
            if add_node_level(bcp, addlevel) == 0 then
                self.object:remove()
                return
            end
        elseif bcd and bcd.buildable_to and
                (get_item_group(self.node.name, "float") == 0 or
                bcd.liquidtype == "none") then
            remove_node(bcp)
            return
        end
        np = {x = bcp.x, y = bcp.y + 1, z = bcp.z}
        -- Check what's here
        n2 = get_node(np)
        nd = registered_nodes[n2.name]
        -- If it's not air or liquid, remove node and replace it with
        -- it's drops
        if n2.name ~= "air" and (not nd or nd.liquidtype == "none") and not nd.buildable_to then
            drops = get_node_drops(self.node.name, "")
            if drops and #drops > 0 then
                for _,droppy in pairs(drops) do
                    throw_item(np,droppy)
                end
            else
                throw_item(np,self.node)
            end
            self.object:remove()
            return
        end
        -- Create node and remove entity
        def = registered_nodes[self.node.name]
        if def then
            -- Trigger drops
            dig_node(np)
            set_node(np, self.node)
            if self.meta then
                meta = get_meta(np)
                meta:from_table(self.meta)
            end
            if def.sounds and def.sounds.fall then
                sound_play(def.sounds.fall, {pos = np}, true)
            end
        end
        self.object:remove()
        check_for_falling(np)
        return
    end

    vel = self.object:get_velocity()
    if vec_equals(vel, {x = 0, y = 0, z = 0}) then
        npos = self.object:get_pos()
        self.object:set_pos(vec_round(npos))
    end
end

minetest.register_entity( ":__builtin:falling_node", falling_node  )


minetest.register_chatcommand("sandme", {
    params = "<mob>",
    description = "Spawn x amount of a mob, used as /spawn 'mob' 10 or /spawn 'mob' for one",
    privs = {server = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        pos = player:get_pos()
        pos.y = pos.y + 5

        for x = -20,20 do
            for z = -20,20 do
                minetest.set_node(vector.add(pos, vector.new(x,0,z)), {name = "main:sand"})
            end
        end
    end,
})