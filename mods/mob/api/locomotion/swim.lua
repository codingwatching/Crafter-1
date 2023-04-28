local ipairs, null, random, PI, HALF_PI, DOUBLE_PI, wrap_yaw, yaw_equals, randomTableSelection, lerp, makeImmutable, dispatchGetterTable, locomotion_types, attack_types, ternary, ternaryExec, ternaryExecParam, throw = ...
--- Builds swimming methods & fields into the mob.
---@param mob mob
---@param definition table
---@return mob mob
return function(mob, definition)
    
    -- Swim locomotion type variables
    mob.swim_goal = nil
    mob.swimmable_nodes = definition.swimmable_nodes or {"main:water", "main:waterflow"}
    mob.swim_goal_cooldown_timer = 0



    function mob:manage_swimming(dtime)
        if (self:is_in_water()) then

            -- Basic locomotion calculations within water
            self:disable_gravity()
            if (self.swim_goal_cooldown_timer > 0.0) then
                self.swim_goal_cooldown_timer = self.swim_goal_cooldown_timer - dtime
            else
                if (self.swim_goal) then goto skipCalculation end

                self.swim_goal_cooldown_timer = 2--seconds
                self.swim_goal = self:locate_water()
                
                if (not self.swim_goal) then goto skipCalculation end

                local p1 = self.object:get_pos()
                local p2 = self.swim_goal

                print("found water at: ", p2.x, p2.y, p2.z)
                
                local directionVector = vector.direction(p1, p2)

                self:set_yaw(directionVector.y)
            end

            ::skipCalculation::


        else
            -- fall like a rock
            self:enable_gravity()
        end
    end

    function mob:manage_swim_direction_change(dtime)

        if self.following then return end

        self.locomotion_timer = self.locomotion_timer - dtime

        if self.locomotion_timer > 0 then return end

        self.locomotion_timer = random(2,6) + random()

        if not self:is_in_water() then return end

        local new_dir = ( random() * ( PI * 2 ) ) - PI

        self.direction = minetest.yaw_to_dir(new_dir)

        self:set_yaw(minetest.dir_to_yaw(self.direction))

        self.speed = random(self.min_speed,self.max_speed)
    end


    function mob:move(dtime,moveresult)

        self:manage_swimming(dtime);
        -- self:manage_wandering_direction_change(dtime)
        -- self:manage_jumping(moveresult)
        -- self:manage_wandering()

        self:interpolate_yaw(dtime)
    end



    return mob;
end