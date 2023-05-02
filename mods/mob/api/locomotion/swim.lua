local random = math.random;
local PI = utility.PI;
local HALF_PI = utility.HALF_PI;
local dir_to_pitch = utility.dir_to_pitch;

-- An important note: Swimming mobs are pretty stupid


--[[
TODO: Perhaps a field of ATTRACTED_TO_BAIT or something so fish mobs...can be fished
TODO: some sort of flop state -> make this a modifyable value, maybe the mob just sits there like a lump (like squids)
]]

local acceleration = vector.new(0,0,0);

--- Builds swimming methods & fields into the mob.
---@param mob mob
---@param definition table
---@return mob mob
return function(mob, definition)
    
    -- Swim locomotion type variables
    mob.swim_goal = nil
    mob.swimmable_nodes = definition.swimmable_nodes or {"main:water", "main:waterflow"}
    mob.swim_goal_cooldown_timer = 0


    function mob:swim()

        local currentvel = self.object:get_velocity()

        local goal = vector.multiply(self.direction, self.speed)

        ---W component in quaternion
        ---@immutable
        local scalar = 0.05;

        acceleration.x = (goal.x - currentvel.x) * scalar;
        acceleration.y = (goal.y - currentvel.y) * scalar;
        acceleration.z = (goal.z - currentvel.z) * scalar;

        self.object:add_velocity(acceleration)

    end

    function mob:track_towards_swim_goal()
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

    function mob:reset_trigger_when_too_close_to_swim_goal()
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

            self:reset_trigger_when_too_close_to_swim_goal()

            -- print("I'm swimming woo")
            self:track_towards_swim_goal()

            self:swim()


        else
            -- fall like a rock
            self:enable_gravity()
        end
    end

    function mob:move(dtime, moveresult)

        self:manage_swimming(dtime);

        self:interpolate_yaw(dtime)
        self:interpolate_pitch(dtime)
    end



    return mob;
end