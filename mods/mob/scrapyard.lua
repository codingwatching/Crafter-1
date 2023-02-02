
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

--[[
mob.hp = definition.hp

mob.head_bone = definition.head_bone
-- mobs.create_head_functions(definition,mob)
mob.debug_head_pos = definition.debug_head_pos
mob.head_directional_offset = definition.head_directional_offset
mob.head_height_offset = definition.head_height_offset
mob.head_rotation_offset = definition.head_rotation_offset
mob.head_position_correction = definition.head_position_correction
mob.head_coord = definition.head_coord
mob.flip_pitch = definition.flip_pitch
mob.hurt_inside_timer = 0
mob.death_animation_timer = 0
mob.dead = false
mob.mob = true
mob.name = definition.name
mob.hostile = definition.hostile
mob.friendly_in_daylight = definition.friendly_in_daylight
mob.friendly_in_daylight_timer = 0
mob.hostile_cooldown = definition.hostile_cooldown
mob.hostile_timer = 0
mob.timer = 0
mob.state = definition.state
mob.hunger = 200
mob.view_distance = definition.view_distance
mob.punch_timer = 0
mob.punched_timer = 0
mob.group_attack = definition.group_attack
mob.death_rotation = definition.death_rotation
mob.head_mount = definition.head_mount
mob.rotational_correction = definition.rotational_correction or 0
mob.hurt_sound = definition.hurt_sound
mob.die_sound = definition.die_sound
mob.attack_type = definition.attack_type

if definition.attack_type == "explode" then
    mob.tnt_tick_timer = 0
    mob.explosion_type = definition.explosion_type
end
mob.explosion_radius = definition.explosion_radius
mob.explosion_power = definition.explosion_power
mob.tnt_timer = nil
mob.explosion_time = definition.explosion_time
mob.explosion_blink_color = definition.explosion_blink_color or "white"
mob.explosion_blink_timer = definition.explosion_blink_timer or 0.2

mob.custom_function_begin = definition.custom_function_begin
mob.custom_function = definition.custom_function
mob.custom_function_end = definition.custom_function_end
mob.projectile_timer_cooldown = definition.projectile_timer_cooldown
mob.attacked_hostile = definition.attacked_hostile
if not definition.hostile and not definition.attacked_hostile then
    mob.scared = false
    mob.scared_timer = 0
end
mob.attack_damage = definition.attack_damage
mob.projectile_timer = 0
mob.projectile_type = definition.projectile_type
mob.takes_fall_damage = definition.takes_fall_damage or true
mob.make_jump_noise = definition.make_jump_noise
mob.jump_animation = definition.jump_animation
mob.jumping_frame = definition.jumping_frame
mob.item_drop = definition.item_drop
mob.item_minimum = definition.item_minimum or 1
mob.item_max = definition.item_max
mob.die_in_light = definition.die_in_light
mob.die_in_light_level = definition.die_in_light_level
mob.current_animation = 0
mob.hurt_color_timer = 0
mob.damage_color = definition.damage_color or "red"
mob.deactivating = false
mob.on_fire = false


mob.custom_on_death = definition.custom_on_death
mob.custom_on_activate = definition.custom_on_activate
mob.custom_on_punch = definition.custom_on_punch
mob.c_mob_data = definition.c_mob_data

mob.fire_table = definition.fire_table
mob.sound_pitch_mod_min = definition.sound_pitch_mod_min
mob.sound_pitch_mod_max = definition.sound_pitch_mod_max

mob.sound_pitch_mod_min_die = definition.sound_pitch_mod_min_die
mob.sound_pitch_mod_max_die = definition.sound_pitch_mod_max_die

function mob:get_hp()
    return self.hp
end

if definition.pathfinds then
    mob.path = {}
    mob.pathfinding_timer = 0
end

if definition.custom_timer then
    mob.c_timer = 0
    mob.custom_timer = definition.custom_timer
    mob.custom_timer_function = definition.custom_timer_function
end

--[[
mobs.create_movement_functions(definition,mob)
mobs.create_interaction_functions(definition,mob)
mobs.create_data_handling_functions(definition,mob)
mobs.create_animation_functions(definition,mob)
mobs.create_timer_functions(definition,mob)
]]