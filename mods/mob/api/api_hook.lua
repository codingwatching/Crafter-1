function minetest.register_mob(definition)


local mob = {}

register_mob_spawner(definition.mobname,definition.textures,definition.mesh)

mob.initial_properties = {
    physical = definition.physical,
    collide_with_objects = definition.collide_with_objects,
    collisionbox = definition.collisionbox,
    visual = definition.visual,
    visual_size = definition.visual_size,
    mesh = definition.mesh,
    textures = definition.textures,
    is_visible = definition.is_visible,
    pointable = definition.pointable,
    automatic_face_movement_dir = definition.automatic_face_movement_dir,
    automatic_face_movement_max_rotation_per_sec = definition.automatic_face_movement_max_rotation_per_sec,
    makes_footstep_sound = definition.makes_footstep_sound,
    static_save = false,
}

--[[
mob.is_mob = true
mob.hp = definition.hp
mob.max_speed = definition.max_speed
mob.jump_timer = 0
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
mob.mobname = definition.mobname
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


mob.on_step = function(self, dtime,moveresult)
    
    if self.dead then
        if self.death_animation_timer >= 0 then
            self.manage_death_animation(self,dtime)
            if self.move_head then
                self.move_head(self,nil,dtime)
            end
        else
            self.on_death(self)
        end
        return
    end

    self:move(dtime,moveresult)

    --[[
    self:collision_detection()
    if self.fall_damage then
        self:fall_damage()
    end
    ]]

    --[[
    if self.custom_function_begin then
        self:custom_function_begin(dtime)
    end
    
    if self.do_custom_timer then
        self:do_custom_timer(dtime)
    end
    if self.custom_function then
        self:custom_function(dtime,moveresult)
    end
    ]]

    --[[

    self:flow()

    self:manage_hurt_color_timer(dtime)

    if self.manage_scared_timer then
        self:manage_scared_timer(dtime)
    end

    if self.set_animation then
        self:set_animation()
    end

    if self.look_around then
        self:look_around(dtime)
    end

    if self.pathfinding then
        self:pathfinding(dtime)
    end

    
    if self.handle_friendly_in_daylight_timer then
        self:handle_friendly_in_daylight_timer(dtime)
    end
    

    self:manage_punch_timer(dtime)

    --fix zombie state again

    if self.tnt_timer then
        self.manage_explode_timer(self,dtime)
    end

    if self.projectile_timer then
        self.manage_projectile_timer(self,dtime)
    end

    if self.custom_function_end then
        self.custom_function_end(self,dtime)
    end
    ]]
end

minetest.register_entity("mob:"..definition.mobname, mob)

end
