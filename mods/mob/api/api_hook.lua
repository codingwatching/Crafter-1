
--mobs = {}

local path = minetest.get_modpath(minetest.get_current_modname()).."/api/"
dofile(path.."movement.lua")
dofile(path.."interaction.lua")
dofile(path.."data_handling.lua")
dofile(path.."head_code.lua")
dofile(path.."animation.lua")
dofile(path.."timers.lua")

function minetest.register_mob(definition)



local mob_register = {}

register_mob_spawner(definition.mobname,definition.textures,definition.mesh)

------------------------------------------------
mob_register.initial_properties = {
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


mob_register.hp = definition.hp
mob_register.max_speed = definition.max_speed
mob_register.jump_timer = 0


if definition.head_bone then
    mob_register.head_bone = definition.head_bone
    mobs.create_head_functions(definition,mob_register)
    mob_register.debug_head_pos = definition.debug_head_pos
    mob_register.head_directional_offset = definition.head_directional_offset
    mob_register.head_height_offset = definition.head_height_offset
    mob_register.head_rotation_offset = definition.head_rotation_offset
    mob_register.head_position_correction = definition.head_position_correction
    mob_register.head_coord = definition.head_coord
    mob_register.flip_pitch = definition.flip_pitch
else
    --print("create some other functions to turn mob " .. definition.mobname)
end

mob_register.hurt_inside_timer = 0
mob_register.death_animation_timer = 0
mob_register.dead = false

mob_register.mob = true
mob_register.mobname = definition.mobname

mob_register.hostile = definition.hostile
if definition.friendly_in_daylight == true then
    mob_register.friendly_in_daylight = definition.friendly_in_daylight
    mob_register.friendly_in_daylight_timer = 0
end

mob_register.hostile_cooldown = definition.hostile_cooldown

mob_register.hostile_timer = 0
mob_register.timer = 0

mob_register.state = definition.state

mob_register.hunger = 200

mob_register.view_distance = definition.view_distance

mob_register.punch_timer = 0
mob_register.punched_timer = 0
mob_register.group_attack = definition.group_attack

mob_register.death_rotation = definition.death_rotation

mob_register.head_mount = definition.head_mount
mob_register.rotational_correction = definition.rotational_correction or 0

mob_register.hurt_sound = definition.hurt_sound
mob_register.die_sound = definition.die_sound

mob_register.attack_type = definition.attack_type
if definition.attack_type == "explode" then
    mob_register.tnt_tick_timer = 0
    mob_register.explosion_type = definition.explosion_type
end
mob_register.explosion_radius = definition.explosion_radius
mob_register.explosion_power = definition.explosion_power
mob_register.tnt_timer = nil
mob_register.explosion_time = definition.explosion_time
mob_register.explosion_blink_color = definition.explosion_blink_color or "white"
mob_register.explosion_blink_timer = definition.explosion_blink_timer or 0.2

mob_register.custom_function_begin = definition.custom_function_begin
mob_register.custom_function = definition.custom_function
mob_register.custom_function_end = definition.custom_function_end

mob_register.projectile_timer_cooldown = definition.projectile_timer_cooldown
mob_register.attacked_hostile = definition.attacked_hostile
if not definition.hostile and not definition.attacked_hostile then
    mob_register.scared = false
    mob_register.scared_timer = 0
end
mob_register.attack_damage = definition.attack_damage

mob_register.projectile_timer = 0
mob_register.projectile_type = definition.projectile_type

mob_register.takes_fall_damage = definition.takes_fall_damage or true
mob_register.make_jump_noise = definition.make_jump_noise
mob_register.jump_animation = definition.jump_animation
mob_register.jumping_frame = definition.jumping_frame

mob_register.item_drop = definition.item_drop
mob_register.item_minimum = definition.item_minimum or 1
mob_register.item_max = definition.item_max

mob_register.die_in_light = definition.die_in_light
mob_register.die_in_light_level = definition.die_in_light_level

mob_register.current_animation = 0
mob_register.hurt_color_timer = 0
mob_register.damage_color = definition.damage_color or "red"
mob_register.custom_on_death = definition.custom_on_death

mob_register.custom_on_activate = definition.custom_on_activate

mob_register.custom_on_punch = definition.custom_on_punch

mob_register.c_mob_data = definition.c_mob_data

mob_register.deactivating = false

mob_register.on_fire = false

mob_register.fire_table = definition.fire_table

mob_register.sound_pitch_mod_min = definition.sound_pitch_mod_min
mob_register.sound_pitch_mod_max = definition.sound_pitch_mod_max

mob_register.sound_pitch_mod_min_die = definition.sound_pitch_mod_min_die
mob_register.sound_pitch_mod_max_die = definition.sound_pitch_mod_max_die

mob_register.is_mob = true

function mob_register:get_hp()
    return self.hp
end


if definition.pathfinds then
    --mob_register.path = {}
    mob_register.pathfinding_timer = 0
end

if definition.custom_timer then
    mob_register.c_timer = 0
    mob_register.custom_timer = definition.custom_timer
    mob_register.custom_timer_function = definition.custom_timer_function
end

mobs.create_movement_functions(definition,mob_register)
mobs.create_interaction_functions(definition,mob_register)
mobs.create_data_handling_functions(definition,mob_register)
mobs.create_animation_functions(definition,mob_register)
mobs.create_timer_functions(definition,mob_register)


mob_register.on_step = function(self, dtime,moveresult)
    if self.custom_function_begin then
        self.custom_function_begin(self,dtime)
    end

    self.collision_detection(self)
    if self.fall_damage then
        self.fall_damage(self)
    end

    if self.dead == false and self.death_animation_timer == 0 then
        if self.do_custom_timer then
            self.do_custom_timer(self,dtime)
        end

        if self.custom_function then
            self.custom_function(self,dtime,moveresult)
        end

        self.move(self,dtime,moveresult)

        self.flow(self)
        --self.debug_nametag(self,dtime)

        self.manage_hurt_color_timer(self,dtime)

        if self.manage_scared_timer then
            self.manage_scared_timer(self,dtime)
        end

        if self.set_animation then
            self.set_animation(self)
        end

        if self.look_around then
            self.look_around(self,dtime)
        end

        if self.pathfinding then
            self.pathfinding(self,dtime)
        end

        if self.handle_friendly_in_daylight_timer then
            self.handle_friendly_in_daylight_timer(self,dtime)
        end

        self.manage_punch_timer(self,dtime)
    else
        self.manage_death_animation(self,dtime)
        if self.move_head then
            self.move_head(self,nil,dtime)
        end
    end

    --fix zombie state again
    if self.dead == true and self.death_animation_timer <= 0 then
        self.on_death(self)
    end

    if self.tnt_timer then
        self.manage_explode_timer(self,dtime)
    end

    if self.projectile_timer then
        self.manage_projectile_timer(self,dtime)
    end

    if self.custom_function_end then
        self.custom_function_end(self,dtime)
    end
end

minetest.register_entity("mob:"..definition.mobname, mob_register)

end
