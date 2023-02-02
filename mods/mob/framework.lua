local ipairs = ipairs

local HALF_PI = math.pi / 2
local DOUBLE_PI = math.pi * 2

-- TODO: mobs figuring out a path up stairs & slabs

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
mob.is_mob = true
mob.initial_properties = {
    physical = definition.physical,
    collide_with_objects = false,
    collisionbox = definition.collisionbox,
    visual = definition.visual,
    visual_size = definition.visual_size,
    mesh = definition.mesh,
    textures = definition.textures,
    is_visible = definition.is_visible,
    pointable = definition.pointable,
    makes_footstep_sound = definition.makes_footstep_sound,
    backface_culling = definition.backface_culling
}

-- Generic variables for movement
mob.min_speed = definition.min_speed
mob.max_speed = definition.max_speed
mob.movement_type = (definition.movement_type and MOVEMENT_TYPE[definition.movement_type]) or MOVEMENT_TYPE.walk
mob.gravity = definition.gravity or -9.81

-- Walk movement type variables
mob.jump_timer = 0
mob.movement_timer = 0
mob.still_on_wall = false
mob.speed = 0

-- Swim movement type variables
mob.swim_goal = vector.new(0,0,0)

-- Yaw & yaw interpolation
mob.yaw_start = 0
mob.yaw_end = 0
mob.yaw_interpolation_progress = 0
mob.yaw_rotation_multiplier = 0
mob.yaw_adjustment = math.rad(definition.yaw_adjustment)

-- Pitch & pitch interpolation
mob.pitch_start = 0
mob.pitch_end = 0
mob.pitch_interpolation_progress = 0
mob.pitch_rotation_multiplier = 0
mob.pitch_adjustment = (definition.pitch_adjustment and math.rad(definition.pitch_adjustment)) or 0


-- Dispatcher functions
local function match_move(input)
    return mob.movement_type == input
end

-- Mob methods

function mob:on_activate(staticdata, dtime_s)
    print(staticdata)
    if not staticdata or staticdata == "" then goto skip_data_assign end

    do
        local old_data = minetest.deserialize(staticdata)
        print(dump(staticdata))
    end

    ::skip_data_assign::
    self.object:set_acceleration(vector.new(0,self.gravity,0))
end

--[[
function mob:on_deactivate()
    print("bye")
end
]]

function mob:get_staticdata()
    return minetest.serialize({
        hp = self.hp
    })
end


-- Random direction state change when wandering
function mob:manage_wandering_direction_change(dtime)
    if self.following then return end
    self.movement_timer = self.movement_timer - dtime
    if self.movement_timer > 0 then return end
    self.movement_timer = math.random(2,6) + math.random()
    local new_dir = ( math.random() * ( math.pi * 2 ) ) - math.pi
    self.direction = minetest.yaw_to_dir(new_dir)
    self:set_yaw(minetest.dir_to_yaw(self.direction))
    self.speed = math.random(self.min_speed,self.max_speed)
end

function mob:reset_movement_timer()
    self.movement_timer = 0
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
                self:reset_movement_timer()
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

function mob:get_yaw()
    return wrap_yaw(self.object:get_yaw() - self.yaw_adjustment)
end

function mob:set_yaw(new_goal)
    self.yaw_interpolation_progress = 0
    local current_yaw = self:get_yaw()
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
end



function mob:manage_swim_direction_change(dtime)

end



-- Dispatch the correct method based on what the mob movement type is
-- TODO: move walk type into final else branch as a catchall
if match_move(MOVEMENT_TYPE.walk) then
    function mob:move(dtime,moveresult)
        self:manage_wandering_direction_change(dtime)
        self:manage_jumping(moveresult)
        self:manage_wandering()
        self:interpolate_yaw(dtime)
    end
elseif match_move(MOVEMENT_TYPE.swim) then
    function mob:move(dtime,moveresult)

        -- self:manage_wandering_direction_change(dtime)
        -- self:manage_jumping(moveresult)
        -- self:manage_wandering()
        self:interpolate_yaw(dtime)
    end
end


function mob:on_step(dtime,moveresult)
    if self.dead then
        -- TODO: make death management it's own set of procedures
        if self.death_animation_timer >= 0 then
            self.manage_death_animation(self,dtime)
            if self.move_head then
                -- TODO: recenter head here
                -- self.move_head(self,nil,dtime)
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
