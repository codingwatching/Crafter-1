local random = math.random;
local PI = utility.PI;
local HALF_PI = utility.HALF_PI;

-- An important note: Swimming mobs are pretty stupid

--!TODO: This probably should be part of the mob itself? Or it should be in utility. OR something!

-- A heap preallocations to be reused over and over since this is purely single threaded.
---@final
local p1 = vector.new(0,0,0);
---@final
local p2 = vector.new(0,0,0);
---@final
local p3 = vector.new(0,0,0);

---Convertes x,y,z component of vector into a pitch floating point value in radians.
---2D coordinate flipped into dir to yaw to calculate pitch.
---@param pos1 table Starting point.
---@param pos2 table Ending point.
---@return number number Pitch in radians.
local function dir_to_pitch(pos1, pos2)

    p1.x = pos1.x;
    p1.y = 0;
    p1.z = pos1.z;

    p2.x = pos2.x;
    p2.y = 0
    p2.z = pos2.z;

    -- print("-----\n","current" .. dump2(pos1), "goal" .. dump2(pos2) )

    ---@immutable
    local distanceComponent = vector.distance(p1, p2);

    ---@immutable
    local heightComponent = pos1.y - pos2.y;

    p3.x = distanceComponent;
    p3.y = 0;
    p3.z = heightComponent;

    -- print(dump2(p3))

    ---@immutable
    local yawIn90DegreeRotation = -minetest.dir_to_yaw(p3);

    -- print("distance:", distanceComponent)
    -- print("height:", heightComponent)
    -- print("yaw:", yawIn90DegreeRotation)

    return yawIn90DegreeRotation - HALF_PI;
end

--- Builds swimming methods & fields into the mob.
---@param mob mob
---@param definition table
---@return mob mob
return function(mob, definition)
    
    -- Swim locomotion type variables
    mob.swim_goal = nil
    mob.swimmable_nodes = definition.swimmable_nodes or {"main:water", "main:waterflow"}
    mob.swim_goal_cooldown_timer = 0


    function mob:swim(dtime)

        local currentvel = self.object:get_velocity()

        -- currentvel.y = 0

        local goal = vector.multiply(self.direction,self.speed)

        --FIXME: replace this with vector.subtract or something!
        local acceleration = vector.new( goal.x - currentvel.x, goal.y - currentvel.y, goal.z - currentvel.z )

        acceleration = vector.multiply(acceleration, 0.05)

        self.object:add_velocity(acceleration)

    end

    function mob:track_towards_swim_goal(dtime)
        --! YAW
        local pos1 = self.object:get_pos()
        local pos2 = self.swim_goal
        local directionVector = vector.direction(pos1, pos2)
        self.direction = directionVector;

        local yaw = minetest.dir_to_yaw(directionVector)

        self:set_yaw(yaw)

        --! PITCH
        local pitch = dir_to_pitch(pos1, pos2)

        self:set_pitch(pitch)

    end

    function mob:reset_trigger_when_too_close_to_swim_goal(dtime)
        local pos1 = self.object:get_pos()
        local pos2 = self.swim_goal
        if (vector.distance(pos1,pos2) < 0.25) then
            self.swim_goal_cooldown_timer = 0
        end
    end


    function mob:manage_swimming(dtime)
        if (self:is_in_water()) then
            -- Basic locomotion calculations within water
            self:disable_gravity()
            if (self.swim_goal_cooldown_timer > 0.0) then
                self.swim_goal_cooldown_timer = self.swim_goal_cooldown_timer - dtime
            else
                if (self.swim_goal and self.swim_goal_cooldown_timer > 0.0) then goto skipCalculation end

                self.swim_goal_cooldown_timer = 2--seconds
                self.swim_goal = self:locate_water(5)
                
                if (not self.swim_goal) then goto skipCalculation end

                self.speed = random(self.min_speed,self.max_speed)

            end

            ::skipCalculation::

            -- This thing couldn't figure out where to go, abort! ABORT!
            if (not self.swim_goal) then return end

            self:reset_trigger_when_too_close_to_swim_goal(dtime)

            -- print("I'm swimming woo")
            self:track_towards_swim_goal(dtime)

            self:swim(dtime)


        else
            -- fall like a rock
            self:enable_gravity()
        end
    end

    -- function mob:manage_swim_direction_change(dtime)

    --     if self.following then return end

    --     self.locomotion_timer = self.locomotion_timer - dtime

    --     if self.locomotion_timer > 0 then return end

    --     self.locomotion_timer = random(2,6) + random()

    --     if not self:is_in_water() then return end

    --     local new_dir = ( random() * ( PI * 2 ) ) - PI

    --     self.direction = minetest.yaw_to_dir(new_dir)

    --     self:set_yaw(minetest.dir_to_yaw(self.direction))

    --     self.speed = random(self.min_speed,self.max_speed)
    -- end


    function mob:move(dtime,moveresult)

        self:manage_swimming(dtime);
        -- self:manage_wandering_direction_change(dtime)
        -- self:manage_jumping(moveresult)
        -- self:manage_wandering()

        self:interpolate_yaw(dtime)
        self:interpolate_pitch(dtime)
    end



    return mob;
end