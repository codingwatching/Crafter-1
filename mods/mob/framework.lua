local ipairs = ipairs

local HALF_PI = math.pi / 2
local DOUBLE_PI = math.pi * 2

-- Wrap around yaw calculations so addition can be applied freely
local function wrap_yaw(yaw)
    if yaw < -math.pi then
        return yaw + DOUBLE_PI
    elseif yaw > math.pi then
        return yaw - DOUBLE_PI
    end
    return yaw
end


-- X precision of float equality (x ^ 2 == 100 or 0.00)
local function yaw_equals( a, b, precision)
    local multiplier = 10 ^ precision
    local x = math.floor(a * multiplier + 0.5) / multiplier
    local y = math.floor(b * multiplier + 0.5) / multiplier
    return x == y or x + y == 0
end

-- Linear interpolation, start, end, 0 to 1
local function fma(x, y, z)
    return (x * y) + z
end

local function lerp(start, finish, amount)
    return fma(finish - start, amount, start)
end

-- Movement type enum
local MOVEMENT_TYPE = {
    walk = 1,
    jump = 2,
    swim = 3,
    fly = 4
}

function minetest.register_mob(definition)

minetest.register_mob_spawner(definition.name,definition.textures,definition.mesh)

-- Mob class
local mob = {}

-- Mob fields

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
    makes_footstep_sound = definition.makes_footstep_sound,
    static_save = false,
}


mob.is_mob = true
mob.jump_timer = 0
mob.movement_timer = 0
mob.min_speed = definition.min_speed
mob.max_speed = definition.max_speed
mob.gravity = definition.gravity or -9.81
mob.movement_type = (definition.movement_type and MOVEMENT_TYPE[definition.movement_type]) or MOVEMENT_TYPE.walk
mob.yaw_start = 0
mob.yaw_end = 0
mob.yaw_interpolation_progress = 0
mob.yaw_rotation_multiplier = 0
mob.yaw_adjustment = math.rad(definition.yaw_adjustment)
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

-- Mob methods

function mob:on_activate(staticdata, dtime_s)
    print("hi")
    self.object:set_acceleration(vector.new(0,self.gravity,0))
end

function mob:on_deactivate()
    print("bye")
end


-- Random direction state change when wandering
function mob:manage_wandering_direction_change(dtime)
    if self.following then return end
    self.movement_timer = self.movement_timer - dtime
    if self.movement_timer > 0 then return end
    self.movement_timer = 1--math.random(0,4) + math.random()
    local new_dir = ( math.random() * ( math.pi * 2 ) ) - math.pi
    self.direction = minetest.yaw_to_dir(new_dir)
    self:set_yaw(minetest.dir_to_yaw(self.direction))
    self.speed = math.random(self.min_speed,self.max_speed)
end

function mob:manage_wandering()
    local currentvel = self.object:get_velocity()
    currentvel.y = 0
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
    if not moveresult then return end
    if not moveresult.collides then return end
    if not moveresult.touching_ground then return end
    local collisions = moveresult.collisions
    if #collisions <= 0 then return end
    local should_jump = false
    for _,collision in ipairs(collisions) do
        if collision.axis ~= "y" then
            should_jump = true
            break
        end
    end
    if not should_jump then return end
    self.object:add_velocity(vector.new(0,5,0))
end


function mob:set_yaw(new_goal)

    self.yaw_interpolation_progress = 0

    local current_yaw = wrap_yaw(self.object:get_yaw() - self.yaw_adjustment)

    local smaller = math.min(current_yaw, new_goal)
    local larger = math.max(current_yaw, new_goal)

    local result = math.abs(larger - smaller)

    -- Brute force wrap it around, wrap_yaw is used a few lines above
    if result > math.pi then
        if new_goal < 0 then
            new_goal = new_goal + DOUBLE_PI
        else
            new_goal = new_goal - DOUBLE_PI
        end
        result = result - math.pi
    end

    -- Keeps a constant rotation factor while interpolating
    local rotation_multiplier = 4 * math.pi / (math.pi + result)

    self.yaw_start = current_yaw
    self.yaw_end = new_goal
    self.yaw_rotation_multiplier = rotation_multiplier
end

function mob:interpolate_yaw(dtime)
    if self.yaw_interpolation_progress >= 1 then return end

    self.yaw_interpolation_progress = self.yaw_interpolation_progress + (dtime * self.yaw_rotation_multiplier)
    if self.yaw_interpolation_progress > 1 then
        self.yaw_interpolation_progress = 1
    end

    local new_yaw = lerp(self.yaw_start, self.yaw_end, self.yaw_interpolation_progress)
    new_yaw = new_yaw + self.yaw_adjustment

    self.object:set_yaw(new_yaw)
    --[[
    local yaw_end = self.yaw_end

    local vel = self.object:get_velocity()
    vel.y = 0
    vel = vector.normalize(vel)
    local current_yaw = minetest.dir_to_yaw(vel)
    ]]--
end
function mob:move(dtime,moveresult)
    self:manage_wandering_direction_change(dtime)
    -- self:manage_jumping(moveresult)
    self:manage_wandering()
    self:interpolate_yaw(dtime)
end

function mob:on_step(dtime,moveresult)
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

minetest.register_entity("mob:"..definition.name, mob)

end
