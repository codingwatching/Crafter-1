local random = math.random;
local PI = utility.PI;

--- Builds walking methods & fields into the mob.
---@param mob mob
---@param definition table
---@return mob mob
return function(mob, definition)

    -- Walk locomotion type variables
    mob.jump_timer = 0
    mob.still_on_wall = false

    -- Random direction state change when wandering
    function mob:manage_wandering_direction_change(dtime)
        if self.following then return end
        self.locomotion_timer = self.locomotion_timer - dtime
        if self.locomotion_timer > 0 then return end
        self.locomotion_timer = random(2,6) + random()
        local new_dir = ( random() * ( PI * 2 ) ) - PI
        self.direction = minetest.yaw_to_dir(new_dir)
        self:set_yaw(minetest.dir_to_yaw(self.direction))
        self.speed = random(self.min_speed,self.max_speed)
    end

    function mob:manage_wandering()
        local currentvel = self.object:get_velocity()
        currentvel.y = 0
        -- Mob will not move when still jumping up against the side of a wall
        if self.still_on_wall then
            self.object:add_velocity(vector.new(0 - currentvel.x,0,0 - currentvel.z))
            return
        end
        local goal = vector.multiply(self.direction,self.speed)
        local acceleration = vector.new( goal.x - currentvel.x, 0, goal.z - currentvel.z )
        acceleration = vector.multiply(acceleration, 0.05)


        --[[ whip_turn used to be used for when a mob was on a path TODO: change this to fast_turn
        if self.whip_turn then
            self.whip_turn = self.whip_turn - dtime
            if self.whip_turn <= 0 then
                self.whip_turn = nil
            end
        else
            
        end
        ]]

        self.object:add_velocity(acceleration)
    end

    function mob:manage_jumping(moveresult)
        self.still_on_wall = false
        if not moveresult then return end
        if not moveresult.collides then return end
        local collisions = moveresult.collisions
        if #collisions <= 0 then return end
        local should_jump = false
        local still_on_wall = false
        -- Only try to jump over nodes in the way
        for _,collision in ipairs(collisions) do
            if collision.axis == "y" or collision.type ~= "node" then goto continue end

            if moveresult.touching_ground then
                local check_pos = collision.node_pos
                check_pos.y = check_pos.y + 1
                if minetest.registered_nodes[minetest.get_node(check_pos).name].walkable then
                    self:reset_locomotion_timer()
                else
                    should_jump = true
                end
            else
                still_on_wall = true
            end
            do break end
            ::continue::
        end

        self.still_on_wall = still_on_wall

        if not should_jump then return end
        self.object:add_velocity(vector.new(0,5,0))
    end

    function mob:move(dtime,moveresult)
        self:manage_wandering_direction_change(dtime)

        --- self:manage_jumping(moveresult)
        self:manage_wandering()
        self:interpolate_yaw(dtime)
    end


    return mob;
end