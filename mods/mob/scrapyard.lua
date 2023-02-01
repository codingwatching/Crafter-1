
--[[
function mob:jump(moveresult)

    if moveresult and moveresult.touching_ground and self.direction then

        local pos = self.object:get_pos()
        pos.y = pos.y+0.1

        if self.path_data and #self.path_data > 0 then
            --smart jump
            local y = math.floor(pos.y+0.5)
            local vel = self.object:get_velocity()
            if y < self.path_data[1].y then
                self.object:set_velocity(vector.new(vel.x,5,vel.z))
            elseif self.path_data[2] and y < self.path_data[2].y then
                self.object:set_velocity(vector.new(vel.x,5,vel.z))
            elseif self.path_data[3] and y < self.path_data[3].y then
                self.object:set_velocity(vector.new(vel.x,5,vel.z))
            elseif ((vel.x == 0 and self.direction.x ~= 0) or (vel.z == 0 and self.direction.z ~= 0)) then
                self.object:set_velocity(vector.new(vel.x,5,vel.z))
            end
        else
            --assume collisionbox is even x and z
            local modifier = self.object:get_properties().collisionbox[4]*3
            

            local pos2 = vector.add(vector.multiply(self.direction,modifier),pos)

            local ray = minetest.raycast(pos, pos2, false, false)
            
            local pointed_thing = nil

            if ray then
                pointed_thing = ray:next()
            end
                
            if pointed_thing then
                if minetest.get_nodedef(minetest.get_node(pointed_thing.under).name, "walkable") then
                    --print("jump")
                    local vel = self.object:get_velocity()
                    --self.jump_timer = 1+math.random()
                    self.object:set_velocity(vector.new(vel.x,5,vel.z))
                else
                    --print("velocity check")
                    vel = self.object:get_velocity()
                    if (vel.x == 0 and self.direction.x ~= 0) or (vel.z == 0 and self.direction.z ~= 0) then
                        self.object:set_velocity(vector.new(vel.x,5,vel.z))
                    end
                end
            else
                --print("velcheck 2")
                local vel = self.object:get_velocity()
                if (vel.x == 0 and self.direction.x ~= 0) or (vel.z == 0 and self.direction.z ~= 0) then
                    self.object:set_velocity(vector.new(vel.x,5,vel.z))
                end
            end
        end
    end
end
]]