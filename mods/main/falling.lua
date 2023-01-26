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


minetest.register_chatcommand("sand", {
    params = "<mob>",
    description = "Spawn x amount of a mob, used as /spawn 'mob' 10 or /spawn 'mob' for one",
    privs = {server = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        pos = player:get_pos()
        pos.y = pos.y + 3

        for x = -1,1 do
            for z = -1,1 do
                minetest.set_node(vector.add(pos, vector.new(x,0,z)), {name = "main:sand"})
            end
        end
    end,
})


-- This table is specifically ordered.
-- We don't walk diagonals, only our direct neighbors, and self.
-- Down first as likely case, but always before self. The same with sides.
-- Up must come last, so that things above self will also fall all at once.
local check_for_falling_neighbors = {
	vector.new(-1, -1,  0),
	vector.new( 1, -1,  0),
	vector.new( 0, -1, -1),
	vector.new( 0, -1,  1),
	vector.new( 0, -1,  0),
	vector.new(-1,  0,  0),
	vector.new( 1,  0,  0),
	vector.new( 0,  0,  1),
	vector.new( 0,  0, -1),
	vector.new( 0,  0,  0),
	vector.new( 0,  1,  0),
}

function minetest.check_for_falling(p)

    print("checking neighbors")
	-- Round p to prevent falling entities to get stuck.
	p = vector.round(p)

	-- We make a stack, and manually maintain size for performance.
	-- Stored in the stack, we will maintain tables with pos, and
	-- last neighbor visited. This way, when we get back to each
	-- node, we know which directions we have already walked, and
	-- which direction is the next to walk.
	local s = {}
	local n = 0
	-- The neighbor order we will visit from our table.
	local v = 1

	while true do
		-- Push current pos onto the stack.
		n = n + 1
		s[n] = {p = p, v = v}
		-- Select next node from neighbor list.
		p = vector.add(p, check_for_falling_neighbors[v])
		-- Now we check out the node. If it is in need of an update,
		-- it will let us know in the return value (true = updated).
		if not minetest.check_single_for_falling(p) then
            print("doing")
			-- If we don't need to "recurse" (walk) to it then pop
			-- our previous pos off the stack and continue from there,
			-- with the v value we were at when we last were at that
			-- node
			repeat
				local pop = s[n]
				p = pop.p
				v = pop.v
				s[n] = nil
				n = n - 1
				-- If there's nothing left on the stack, and no
				-- more sides to walk to, we're done and can exit
				if n == 0 and v == 11 then
					return
				end
			until v < 11
			-- The next round walk the next neighbor in list.
			v = v + 1
		else
			-- If we did need to walk the neighbor, then
			-- start walking it from the walk order start (1),
			-- and not the order we just pushed up the stack.
			v = 1
		end
	end
end
