local ipairs = ipairs

local pos
local node
local currentvel
local acceleration
local player_name
local bottom_node
local rider
local move
local goal
local player_pos
local vel
local distance
local deceleration
local velocity
local flow_dir
local velocity_force
local sneak
local nodedef

local function register_boat( boat_definition )

-- Boat class
local boat = {}

-- Class fields

boat.initial_properties = {
    hp_max = 1,
    physical = true,
    collide_with_objects = false,
    collisionbox = {-0.4, 0, -0.4, 0.4, 0.5, 0.4},
    visual = "mesh",
    mesh = "boat.x",
    textures = {"boat.png"},
    visual_size = {x=1,y=1,z=1},
    is_visible = true,
    automatic_face_movement_dir = -90.0,
    automatic_face_movement_max_rotation_per_sec = 600,
}

boat.rider = nil
boat.boat = true
boat.beached = false
boat.being_rowed = false

-- Class methods

function boat:on_activate()
    self.object:set_armor_groups({immortal = 1})
end

function boat:on_punch()
    pos = self.object:get_pos()
    minetest.add_item(pos, boat_definition.name)
    self.object:remove()
end

function boat:on_rightclick( clicker )

    if not clicker or not clicker:is_player() then return end

    player_name = clicker:get_player_name()

    rider = self.rider

    if rider and player_name == rider then

        clicker:set_detach()
        pos = vector.add(self.object:get_pos(), vector.new(0,1,0))
        clicker:move_to(pos)
        clicker:add_velocity(vector.new(0,2,0))

        self.rider = nil

        player_is_attached(clicker,false)
        force_update_animation(clicker)

    elseif not rider then

        self.rider = player_name

        clicker:set_attach(self.object, "", {x=0, y=2, z=0}, {x=0, y=0, z=0})
        set_player_animation(clicker,"sit",0)
        player_is_attached(clicker,true)
    end
end

-- Boat checks if it's stuck on land
function boat:check_if_beached()

    pos = self.object:get_pos()
    pos.y = pos.y + 0.35
    bottom_node = minetest.get_node(pos).name

    self.beached = (bottom_node ~= boat_definition.liquid_source_node and bottom_node ~= boat_definition.liquid_flow_node)

    if self.beached then goto double_check end
    do return end

    ::double_check::
    pos.y = pos.y - 0.7
    bottom_node = minetest.get_node(pos).name
    self.beached = (bottom_node ~= boat_definition.liquid_source_node and bottom_node ~= boat_definition.liquid_flow_node and bottom_node ~= "air")
end

-- Method that allows players to control the boat
function boat:drive()
    rider = self.rider
    if not rider or self.beached then
        self.being_rowed = false
        return
    end
    rider = minetest.get_player_by_name( rider )
    move = rider:get_player_control().up
    if not move then
        self.being_rowed = false
        return
    end
    currentvel = self.object:get_velocity()
    -- 10 is the speed goal in nodes per second
    goal = vector.multiply( vector.normalize( minetest.yaw_to_dir( rider:get_look_horizontal() ) ), 10 )

    acceleration = vector.new( goal.x - currentvel.x, 0, goal.z - currentvel.z )
    acceleration = vector.multiply( acceleration, 0.01 )
    self.object:add_velocity( acceleration )

    self.being_rowed = true
end

function boat:push()

    pos = self.object:get_pos()

    for _,object in ipairs( minetest.get_objects_inside_radius( pos, 1 ) ) do

        if not object then goto continue end
        if not object:is_player() then goto continue end
        if object:get_player_name() == self.rider then goto continue end

        player_pos = object:get_pos()

        -- Turn it 2d
        pos.y = 0
        player_pos.y = 0

        currentvel = self.object:get_velocity()
        distance = ( 1 - vector.distance( pos, player_pos ) ) * 10
        vel = vector.multiply( vector.normalize( vector.subtract( pos, player_pos ) ), distance )
        velocity_force = vector.new( vel.x - currentvel.x, 0, vel.z - currentvel.z )

        -- Clamp the velocity
        if vector.length(velocity_force) > 0.3 then
            velocity_force = vector.multiply(vector.normalize(velocity_force), 0.3)
        end

        self.object:add_velocity( velocity_force )

        object:add_velocity( vector.multiply( velocity_force, -1 ) )

        ::continue::
    end

end

-- Makes the boat float in water
function boat:float()

    pos = self.object:get_pos()

    node = minetest.get_node(pos).name

    -- Not in water, sink like a stone
    if node ~= boat_definition.liquid_source_node and node ~= boat_definition.liquid_flow_node then
        self.swimming = false
        self.object:set_acceleration(vector.new(0,-10,0))
        return
    end
    -- Floating, go up
    self.object:set_acceleration( vector.new( 0, 0, 0 ) )
    self.swimming = true
    vel = self.object:get_velocity()

    -- Goal upward velocity is 9 nodes per second apparently
    goal = 9
    acceleration = vector.new( 0, goal-vel.y, 0 )
    acceleration = vector.multiply( acceleration, 0.01 )
    self.object:add_velocity( acceleration )
end

-- Method that tells the boat to slow down
function boat:slowdown()

    if self.being_rowed then return end

    vel = self.object:get_velocity()
    acceleration = vector.new(-vel.x,0,-vel.z)
    deceleration = vector.multiply(acceleration, 0.01)
    self.object:add_velocity(deceleration)

end

function boat:lag_correction(dtime)
    pos = self.object:get_pos()
    velocity = self.object:get_velocity()
    -- If the server step took more than 1 second to complete then we will put the boat back to the last known position
    -- This stops the boat from flying away as it's extremely dynamic
    if dtime < 1 then goto continue end
    self.object:move_to(self.old_pos)
    self.object:set_velocity(self.old_velocity)

    ::continue::
    self.old_pos = pos
    self.old_velocity = velocity
end

function boat:flow()

    flow_dir = boat_definition.flow_function( self.object:get_pos() )

    if not flow_dir then return end

    flow_dir = vector.multiply( flow_dir,10 )
    vel = self.object:get_velocity()
    acceleration = vector.new( flow_dir.x - vel.x, flow_dir.y - vel.y, flow_dir.z - vel.z )
    acceleration = vector.multiply( acceleration, 0.01 )
    self.object:add_velocity( acceleration )
end

function boat:on_step(dtime)
    self:check_if_beached()
    self:push()
    self:drive()
    self:float()
    self:flow()
    self:slowdown()
    self:lag_correction(dtime)
end

minetest.register_entity(boat_definition.name, boat)

minetest.register_craftitem(boat_definition.name, {
    description = boat_definition.description,
    inventory_image = boat_definition.image,
    wield_image = boat_definition.image,
    liquids_pointable = true,
    on_place = function(itemstack, placer, pointed_thing)
        -- TODO: take the bucket's raycast and turn it into an api
        if not pointed_thing.type == "node" then
            return
        end
        sneak = placer:get_player_control().sneak
        nodedef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]
        if not sneak and nodedef.on_rightclick then
            minetest.item_place(itemstack, placer, pointed_thing)
            return
        end
        minetest.add_entity(pointed_thing.above, boat_definition.name)
        itemstack:take_item()
        return itemstack
    end,
})

minetest.register_craft({
    output = boat_definition.name,
    recipe = boat_definition.recipe,
})

end

-- End API

register_boat({
    name = "boat:boat",
    description = "Boat",
    image = "boatitem.png",
    liquid_source_node = "main:water",
    liquid_flow_node = "main:waterflow",
    flow_function = flow_in_water,
    recipe = {
        { "main:wood", "",          "main:wood" },
        { "main:wood", "main:wood", "main:wood" },
    },
})

register_boat({
    name = "boat:iron_boat",
    description = "Nether Iron Boat",
    image = "iron_boatitem.png",
    liquid_source_node = "nether:lava",
    liquid_flow_node = "nether:lavaflow",
    flow_function = flow_in_lava,
    recipe = {
        { "main:iron", "",          "main:iron" },
        { "main:iron", "main:iron", "main:iron" },
    },
})