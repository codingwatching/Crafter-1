local ipairs = ipairs

local pos
local node
local goalx
local goalz
local currentvel
local level
local level2
local nodename
local acceleration
local found
local player_name
local data
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

-- This is the flow function for iron boats
local function lavaflow(object)

    pos = object:get_pos()
    pos.y = pos.y + object:get_properties().collisionbox[2]
    pos = vector.round(pos)
    node = minetest.get_node(pos).name
    --node_above = minetest.get_node(vector.new(pos.x,pos.y+1,pos.z)).name
    goalx = 0
    goalz = 0
    found = false

    if node ~= "main:lavaflow" then return end

    currentvel = object:get_velocity()

    level = minetest.get_node_level(pos)

    -- Skip 0
    for x = -1,1,2 do
    for z = -1,1,2 do

        if found then goto continue end

        nodename = minetest.get_node(vector.new(pos.x+x,pos.y,pos.z+z)).name
        level2 = minetest.get_node_level(vector.new(pos.x+x,pos.y,pos.z+z))

        if level2 < level or nodename ~= "main:lavaflow" or nodename ~= "main:lava" then goto continue end

        goalx = -x
        goalz = -z
        found = true

        ::continue::
    end
    end

    -- Only add velocity if there is one, else this stops the player
    if goalx ~= 0 and goalz ~= 0 then
        acceleration = vector.new(goalx-currentvel.x,0,goalz-currentvel.z)
        object:add_velocity(acceleration)
    elseif goalx ~= 0 or goalz ~= 0 then
        acceleration = vector.new(goalx-currentvel.x,0,goalz-currentvel.z)
        object:add_velocity(acceleration)
    end
end


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
    minetest.add_item(pos, "boat:boat")
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

    self.beached = (bottom_node ~= "main:water" and bottom_node ~= "main:waterflow")

    if self.beached then goto double_check end
    do return end

    ::double_check::
    pos.y = pos.y - 0.7
    bottom_node = minetest.get_node(pos).name
    self.beached = (bottom_node ~= "main:water" and bottom_node ~= "main:waterflow" and bottom_node ~= "air")
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

    print(dump(goal))

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
    if node ~= "main:water" and node ~= "main:waterflow" then
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

    flow_dir = flow_in_water(self.object:get_pos())

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

minetest.register_entity("boat:boat", boat)




--[[
-- TODO: library this and pack these things together

minetest.register_craftitem("boat:boat", {
    description = "Boat",
    inventory_image = "boatitem.png",
    wield_image = "boatitem.png",
    liquids_pointable = true,
    on_place = function(itemstack, placer, pointed_thing)
        if not pointed_thing.type == "node" then
            return
        end
        
        sneak = placer:get_player_control().sneak
        nodedef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]
        if not sneak and nodedef.on_rightclick then
            minetest.item_place(itemstack, placer, pointed_thing)
            return
        end
        
        minetest.add_entity(pointed_thing.above, "boat:boat")

        itemstack:take_item()

        return itemstack
    end,
})

minetest.register_craft({
    output = "boat:boat",
    recipe = {
        {"main:wood", "", "main:wood"},
        {"main:wood", "main:wood", "main:wood"},
    },
})

----------------------------------



minetest.register_entity("boat:iron_boat", {
    initial_properties = {
        hp_max = 1,
        physical = true,
        collide_with_objects = false,
        collisionbox = {-0.4, 0, -0.4, 0.4, 0.5, 0.4},
        visual = "mesh",
        mesh = "boat.x",
        textures = {"iron_boat.png"},
        visual_size = {x=1,y=1,z=1},
        is_visible = true,
        automatic_face_movement_dir = -90.0,
        automatic_face_movement_max_rotation_per_sec = 600,
    },
    
    rider = nil,
    iron_boat = true,

    get_staticdata = function(self)
        return minetest.serialize({
            --itemstring = self.itemstring,
        })
    end,

    on_activate = function(self, staticdata, dtime_s)
        if string.sub(staticdata, 1, string.len("return")) == "return" then
            data = minetest.deserialize(staticdata)
            if data and type(data) == "table" then
                --self.itemstring = data.itemstring
            end
        else
            --self.itemstring = staticdata
        end
        self.object:set_armor_groups({immortal = 1})
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
    end,
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        pos = self.object:get_pos()
        minetest.add_item(pos, "boat:iron_boat")
        self.object:remove()
    end,
    
    
    on_rightclick = function(self,clicker)
        if not clicker or not clicker:is_player() then
            return
        end
        player_name = clicker:get_player_name()
        
        if self.rider and player_name == self.rider then
            clicker:set_detach()
            pos = self.object:get_pos()
            pos.y = pos.y + 1
            clicker:move_to(pos)
            clicker:add_velocity(vector.new(0,11,0))
            self.rider = nil
            
            player_is_attached(clicker,false)
            force_update_animation(clicker)

        elseif not self.rider then
            self.rider = player_name
            clicker:set_attach(self.object, "", {x=0, y=2, z=0}, {x=0, y=0, z=0})
            
            set_player_animation(clicker,"sit",0)
            player_is_attached(clicker,true)
        end
    end,
    --check if the boat is stuck on land
    check_if_on_land = function(self)
        pos = self.object:get_pos()
        pos.y = pos.y - 0.37
        bottom_node = minetest.get_node(pos).name
        if (bottom_node == "nether:lava" or bottom_node == "nether:lavaflow" or bottom_node == "air") then
            self.on_land = false
        else
            self.on_land = true
        end
    
    end,
    
    --players drive the baot
    drive = function(self)
        if self.rider and not self.on_land == true then
            rider = minetest.get_player_by_name(self.rider)
            move = rider:get_player_control().up
            self.being_rowed = false
            if move then
                currentvel = self.object:get_velocity()
                goal = rider:get_look_dir()
                goal = vector.multiply(goal,20)
                acceleration = vector.new(goal.x-currentvel.x,0,goal.z-currentvel.z)
                acceleration = vector.multiply(acceleration, 0.01)
                self.object:add_velocity(acceleration)
                self.being_rowed = true
            end
        else
            self.being_rowed = false
        end
    end,
    
    --players push boat
    push = function(self)
        pos = self.object:get_pos()
        for _,object in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
            if object:is_player() and object:get_player_name() ~= self.rider then
                player_pos = object:get_pos()
                pos.y = 0
                player_pos.y = 0
                
                currentvel = self.object:get_velocity()
                vel = vector.subtract(pos, player_pos)
                vel = vector.normalize(vel)
                distance = vector.distance(pos,player_pos)
                distance = (1-distance)*10
                vel = vector.multiply(vel,distance)
                acceleration = vector.new(vel.x-currentvel.x,0,vel.z-currentvel.z)
                self.object:add_velocity(acceleration)
                acceleration = vector.multiply(acceleration, -1)
                object:add_velocity(acceleration)
            end
        end
    end,
    
    --makes the boat float
    float = function(self)
        pos = self.object:get_pos()
        node = minetest.get_node(pos).name
        self.swimming = false
        
        --flow normally if floating else don't
        if node == "nether:lava" or node =="nether:lavaflow" then
            self.swimming = true
            vel = self.object:get_velocity()
            goal = 9
            acceleration = vector.new(0,goal-vel.y,0)
            acceleration = vector.multiply(acceleration, 0.01)
            self.object:add_velocity(acceleration)
            --self.object:set_acceleration(vector.new(0,0,0))
        else
            vel = self.object:get_velocity()
            goal = -9.81
            acceleration = vector.new(0,goal-vel.y,0)
            acceleration = vector.multiply(acceleration, 0.01)
            self.object:add_velocity(acceleration)
            --self.object:set_acceleration(vector.new(0,0,0))
        end
    end,
    
    --slows the boat down
    slowdown = function(self)
        if not self.being_rowed == true then
            vel = self.object:get_velocity()
            acceleration = vector.new(-vel.x,0,-vel.z)
            deceleration = vector.multiply(acceleration, 0.01)
            self.object:add_velocity(deceleration)
        end
    end,

    lag_correction = function(self,dtime)
        pos = self.object:get_pos()
        velocity = self.object:get_velocity()
        if self.lag_check then
            chugent = minetest.get_us_time()/1000000- self.lag_check

            --print("lag = "..chugent.." ms")
            if chugent > 70 and  self.old_pos and self.old_velocity then
                self.object:move_to(self.old_pos)
                self.object:set_velocity(self.old_velocity)
            end
        end
        self.old_pos = pos
        self.old_velocity = velocity
        self.lag_check = minetest.get_us_time()/1000000
    end,

    on_step = function(self, dtime)
        self.check_if_on_land(self)
        self.push(self)
        self.drive(self)
        self.float(self)
        lavaflow(self)
        self.slowdown(self)
        self.lag_correction(self,dtime)
    end,
})

minetest.register_craftitem("boat:iron_boat", {
    description = "Nether Iron Boat",
    inventory_image = "iron_boatitem.png",
    wield_image = "iron_boatitem.png",
    liquids_pointable = true,
    on_place = function(itemstack, placer, pointed_thing)
        if not pointed_thing.type == "node" then
            return
        end
        
        sneak = placer:get_player_control().sneak
        nodedef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]
        if not sneak and nodedef.on_rightclick then
            minetest.item_place(itemstack, placer, pointed_thing)
            return
        end
        
        minetest.add_entity(pointed_thing.above, "boat:iron_boat")

        itemstack:take_item()

        return itemstack
    end,
})

minetest.register_craft({
    output = "boat:iron_boat",
    recipe = {
        {"main:iron", "main:coal", "main:iron"},
        {"main:iron", "main:iron", "main:iron"},
    },
})
]]