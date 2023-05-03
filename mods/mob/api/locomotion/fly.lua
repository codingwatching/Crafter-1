local random = math.random;
local dir_to_pitch = utility.dir_to_pitch;

-- Important note: Flying mobs are probably even stupider than swimming mobs because it's easier to see than when they're in water


local acceleration = vector.new(0,0,0);

--- Builds flying locomotion methods & fields into the mob.
---@param mob mob
---@param definition table
---@return mob mob
return function(mob, definition)

        -- fly locomotion type variables
        mob.fly_goal = nil
        mob.flyable_nodes = definition.flyable_nodes or {"main:water", "main:waterflow"}
        mob.fly_goal_cooldown_timer = 0
    
    
        function mob:fly()
    
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
    
        function mob:track_towards_fly_goal()
            --! YAW
            local pos1 = self.object:get_pos()
            local pos2 = self.fly_goal
            local directionVector = vector.direction(pos1, pos2)
            self.direction = directionVector;
    
            local yaw = minetest.dir_to_yaw(directionVector)
    
            self:set_yaw(yaw)
    
            --! PITCH
            local pitch = dir_to_pitch(pos1, pos2, self.invert_pitch)
    
            self:set_pitch(pitch)
    
        end
    
        function mob:reset_trigger_when_too_close_to_fly_goal()
            local pos1 = self.object:get_pos()
            local pos2 = self.fly_goal
            if (vector.distance(pos1,pos2) < 0.25) then
                self.fly_goal_cooldown_timer = 0
            end
        end
    
    
        function mob:manage_flying(dtime)
            if (self:is_in_water() or self:is_in_lava()) then
                -- some sort of floating thing here - OR AN EXPLOSION WOOO
                tnt(self.object:get_pos(), 10)
                self.object:remove()
                return;
            end

            -- Basic locomotion calculations within water
            self:disable_gravity()
            if (self.fly_goal_cooldown_timer > 0.0) then
                self.fly_goal_cooldown_timer = self.fly_goal_cooldown_timer - dtime
            else
                if (self.fly_goal and self.fly_goal_cooldown_timer > 0.0) then goto skipCalculation end

                self.fly_goal_cooldown_timer = 2--seconds
                self.fly_goal = self:locate_air(10)
                
                if (not self.fly_goal) then goto skipCalculation end

                self.speed = random(self.min_speed,self.max_speed)

            end

            ::skipCalculation::

            -- This thing couldn't figure out where to go, abort! ABORT!
            if (not self.fly_goal) then return end

            self:reset_trigger_when_too_close_to_fly_goal()

            self:track_towards_fly_goal()

            self:fly()
            
        end
    
        function mob:move(dtime, moveresult)
    
            self:manage_flying(dtime);
    
            self:interpolate_yaw(dtime)
            self:interpolate_pitch(dtime)
        end
    

    return mob;
end