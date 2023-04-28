
local ipairs = ipairs;
local null = nil;

local random = math.random;
local PI = math.pi;
local HALF_PI = PI / 2;
local DOUBLE_PI = PI * 2;

local wrap_angle = utility.wrap_angle;
local lerp = utility.lerp;
local randomTableSelection = utility.randomTableSelection;



---Builds the basic structure of the mob. Returns the mob with the new assembled components
---This is the entry point into constructing a mob.
---@param definition table definition.
---@return table table Newly constructed mob class.
return function(definition)

    ---@class mob The basis for a mob's class.
    local mob = {}

    -- print(dump(definition))

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

    -- Generic variables for locomotion
    mob.locomotion_type = definition.locomotion_type
    mob.min_speed = definition.min_speed
    mob.max_speed = definition.max_speed
    mob.gravity = definition.gravity or -9.81
    mob.locomotion_timer = 0
    mob.speed = 0
    mob.gravity_enabled = false;

    -- Yaw & yaw interpolation
    mob.yaw_start = 0
    mob.yaw_end = 0
    mob.yaw_interpolation_progress = 0
    mob.yaw_rotation_multiplier = 0
    mob.yaw_adjustment = math.rad(definition.yaw_adjustment or 0)

    -- Pitch & pitch interpolation
    mob.pitch_start = 0
    mob.pitch_end = 0
    mob.pitch_interpolation_progress = 0
    mob.pitch_rotation_multiplier = 0
    mob.pitch_adjustment = math.rad(definition.pitch_adjustment or 0)

    -- Pitch & pitch interpolation
    mob.pitch_start = 0
    mob.pitch_end = 0
    mob.pitch_interpolation_progress = 0
    mob.pitch_rotation_multiplier = 0
    mob.pitch_adjustment = (definition.pitch_adjustment and math.rad(definition.pitch_adjustment)) or 0

    -- Generic fields for behavior
    mob.following = false


    function mob:enable_gravity()
        -- Stop the lua to c++ interface from getting destroyed
        if (self.gravity_enabled) then return end
        print("gravity enabled for mob: ", definition.name)
        self.object:set_acceleration(vector.new(0,self.gravity,0))
        self.gravity_enabled = true
    end

    function mob:disable_gravity()
        -- Stop the lua to c++ interface from getting destroyed
        if (not self.gravity_enabled) then return end
        print("gravity disabled for mob: ", definition.name)
        self.object:set_acceleration(vector.new(0,0,0))


        --! This might cause a bad jolt, FIXME: if this doesn't work correctly
        self.object:set_velocity(vector.new(0,0,0))


        self.gravity_enabled = false
    end

    function mob:on_activate(staticdata, dtime)
        print(staticdata)
        if not staticdata or staticdata == "" then goto skip_data_assign end

        do
            local old_data = minetest.deserialize(staticdata)
            print(dump(staticdata))
        end

        ::skip_data_assign::
        self:enable_gravity()
    end

    function mob:on_deactivate()
        print("bye")
    end

    function mob:get_staticdata()
        return minetest.serialize({
            hp = self.hp
        })
    end

    function mob:reset_locomotion_timer()
        self.locomotion_timer = 0
    end

    function mob:get_yaw()
        return wrap_angle(self.object:get_yaw() - self.yaw_adjustment)
    end

    function mob:set_yaw(new_goal)
        self.yaw_interpolation_progress = 0
        local current_yaw = self:get_yaw()
        local smaller = math.min(current_yaw, new_goal)
        local larger = math.max(current_yaw, new_goal)
        local result = math.abs(larger - smaller)
        -- Brute force wrap it around, wrap_angle is used a few lines above
        if result > PI then
            if new_goal < 0 then
                new_goal = new_goal + DOUBLE_PI
            else
                new_goal = new_goal - DOUBLE_PI
            end
            result = result - PI
        end
        -- Keeps a constant rotation factor while interpolating
        local rotation_multiplier = 4 * PI / (PI + result)
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
        local oldRotation = self.object:get_rotation()
        oldRotation.y = new_yaw
        self.object:set_rotation(oldRotation)
    end

    function mob:get_pitch()
        --todo: This needs a better name because it can also wrap pitch
        return wrap_angle(self.object:get_rotation().x - self.pitch_adjustment)
    end

    function mob:set_pitch(new_goal)
        self.pitch_interpolation_progress = 0
        local current_pitch = self:get_pitch()
        local smaller = math.min(current_pitch, new_goal)
        local larger = math.max(current_pitch, new_goal)
        local result = math.abs(larger - smaller)
        -- Brute force wrap it around, wrap_pitch is used a few lines above
        if result > PI then
            if new_goal < 0 then
                new_goal = new_goal + DOUBLE_PI
            else
                new_goal = new_goal - DOUBLE_PI
            end
            result = result - PI
        end
        -- Keeps a constant rotation factor while interpolating
        local rotation_multiplier = 4 * PI / (PI + result)
        self.pitch_start = current_pitch
        self.pitch_end = new_goal
        self.pitch_rotation_multiplier = rotation_multiplier
    end
    
    function mob:interpolate_pitch(dtime)
        if self.pitch_interpolation_progress >= 1 then return end
        self.pitch_interpolation_progress = self.pitch_interpolation_progress + (dtime * self.pitch_rotation_multiplier)
        if self.pitch_interpolation_progress > 1 then
            self.pitch_interpolation_progress = 1
        end
        local new_pitch = lerp(self.pitch_start, self.pitch_end, self.pitch_interpolation_progress)
        new_pitch = new_pitch + self.pitch_adjustment

        local oldRotation = self.object:get_rotation()
        oldRotation.x = new_pitch;

        self.object:set_rotation(oldRotation)
    end

    function mob:locate_water(distance)
        local position = self.object:get_pos()
        local scalar = vector.new(distance, distance, distance);
        local foundPositions = minetest.find_nodes_in_area(vector.subtract(position, scalar), vector.add(position, scalar), self.swimmable_nodes, false)
        return randomTableSelection(foundPositions)
    end

    function mob:is_in_water()
        local pos = self.object:get_pos()
        local node = minetest.get_node(pos).name
        return node and (node == "main:water" or node == "main:waterflow")
    end

    --! BEGIN default implementations to avoid crashes

    ---This is the default action for placeholder methods.
    ---@param placeHolder string Method name.
    local function outputUnimplementedPlaceholder(placeHolder)
        ---@immutable <- Does nothing right now
        local mobName = definition.name;
        print("Mob: Warning! (", mobName,") does not implement (", placeHolder, ")!");
    end

    ---Placeholder method for following implementation
    ---@default
    ---@function
    function mob:follow(dtime)
        outputUnimplementedPlaceholder("follow");
    end


    return mob;
end