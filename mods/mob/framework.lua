local ipairs = ipairs;
local null = nil;

local PI = math.pi
local HALF_PI = PI / 2;
local DOUBLE_PI = PI * 2;

-- TODO: mobs figuring out a path up stairs & slabs
---Todo: shovel a few of these functions into a utility mod.

---Under/over flows yaw to stay within boundary of -pi to pi.
---@param yaw number Input yaw.
---@return number number Corrected yaw.
local function wrap_yaw(yaw)
    if yaw < -PI then
        return yaw + DOUBLE_PI
    elseif yaw > PI then
        return yaw - DOUBLE_PI
    end
    return yaw
end


---X precision of float equality (x ^ 2 == 100 or 0.00)
---@param comparitor1 number
---@param comparitor2 number
---@param precision integer Float precision past the decimal point.
---@return boolean boolean Equality of comparitor1 and comparitor2 within float precision.
local function yaw_equals(comparitor1, comparitor2, precision)
    local multiplier = 10 ^ precision
    local x = math.floor(comparitor1 * multiplier + 0.5) / multiplier
    local y = math.floor(comparitor2 * multiplier + 0.5) / multiplier
    return x == y or x + y == 0
end

---1 dimensional linear interpolation.
---@param origin number Starting point.
---@param amount number Amount, 0.0 to 1.0.
---@param destination number Destination point.
---@return number number Interpolated float along 1 dimensional axis.
local function fma(origin, amount, destination)
    return (origin * amount) + destination
end

-- This is wrappered to make this more understandable

---1 dimensional linear interpolation.
---@param start number Starting point.
---@param finish number Finishing point.
---@param amount number Point between the two. Valid: 0.0 to 1.0.
---@return number
local function lerp(start, finish, amount)
    return fma(finish - start, amount, start)
end

---Capitalizes the first letter in a string.
---@param inputString string Input string to capitalize the first letter of.
---@return string Returns string with capitalized first letter.
local function capitalizeFirstLetter(inputString)
    ---@Immutable <- Doesn't do anything yet
    local output = inputString:gsub("^%l",string.upper);
    return output;
end

---Converts a dynamic mutable table into an immutable table.
---@param inputTable table The table which will become immutable.
---@return table The new immutable table.
local function makeImmutable(inputTable)
    local proxy = {};
    local meta = {
        __index = inputTable,
        __newindex = function (table,key,value)
            error(
                "ERROR! Attempted to modify an immutable table!\n" ..
                "Pointer: " .. tostring(table) .. "\n" ..
                "Key: " .. key .. "\n" ..
                "Value: " .. value .. "\n"
            );
        end
    }
    setmetatable(proxy, meta);
    return proxy;
end

---Auto dispatcher for readonly enumerators via functions & direct values.
---@param dataSet { [string]: any } Input data set of key value enumerators.
---@return function[] Immutable data output getters.
local function dispatchGetterTable(dataSet)
    ---@type function[]
    local output = {};
    ---Creates hanging references so the GC does not collect them.
    for key,value in pairs(dataSet) do
        ---@Immutable <- Doesn't do anything yet
        local fieldGetterName = "get" .. capitalizeFirstLetter(key);
        ---OOP style. Example: data.getName();
        output[fieldGetterName] = function ()
            return value;
        end
        ---Functional style. Example: data.name; 
        output[key] = output[fieldGetterName]();
    end
    return makeImmutable(output);
end

---@type any[] Immutable mob movement type enumerators. Field names accessed via direct or getName().
local MOVEMENT_TYPE = dispatchGetterTable({
    walk = 1,
    jump = 2,
    swim = 3,
    fly = 4
})
--- Possible choices: none, punch, jump, explode, projectile.
---
---@type any[] Immutable mob attack type enumerators. Field names accessed via direct or getName().
minetest.attack_types = dispatchGetterTable({
    none = 0,
    punch = 1,
    jump = 2,
    explode = 3,
    projectile = 4
})
--- Localized version of the table above.
---@type any[]
local attack_types = dispatchGetterTable({
    none = 0,
    punch = 1,
    jump = 2,
    explode = 3,
    projectile = 4
})

---Basic data return gate. Boolean case -> (true data | false data)
---@param case boolean
---@param trueResult any
---@param falseResult any
---@return any
local function ternary(case, trueResult, falseResult)
    if (case) then
        return trueResult;
    end
    return falseResult;
end

---Basic function exectution gate. Boolean case -> (true function | false function)
---@param case boolean
---@param trueFunction function
---@param falseFunction function
---@return any
local function ternaryExec(case, trueFunction, falseFunction)
    if (case) then
        return trueFunction();
    end
    return falseFunction();
end

---Basic function execution gate with parameters. Bool case (parameters...) -> (true function ... | false function ...)
---@param case boolean
---@param trueFunction function
---@param falseFunction function
---@param ...  any A collection of parameters which you define.
---@return any
local function ternaryExecParam(case, trueFunction, falseFunction, ...)
    if (case) then
        return trueFunction(...);
    end
    return falseFunction(...);
end

---This function piggybacks on top of error simply because I like using the word throw more.
---@param errorOutput string The error message.
---@return nil
local function throw(errorOutput)
    error(errorOutput);
end

---Throws an error corresponding to the name of the data which was null.
---@param fieldName string Name of field within defined table.
---@param mobName string Name of the mob.
---@return nil
local function throwUnfound(fieldName, mobName)
    ---@type string
    local output = "Mob: Error! (" .. tostring(mobName) .. ") is missing field (" .. fieldName .. ")!";
    throw(output);
end

---Checks a piece of data and automatically throws an error if it does not exist.
---@param field any A piece of data.
---@param fieldName string The name of the piece of data for debugging.
---@param mobName string The name of the mob.
---@return nil
local function nullCheck(field, fieldName, mobName)
    if (field ~= null) then return end
    throwUnfound(fieldName, mobName)
end

---Required fields in the mob's registration table.
---@type string[]
local REQUIRED = {
    "name",
    "physical",
    "collisionbox",
    "visual",
    "visual_size",
    "textures",
    "yaw_adjustment",
    "is_visible",
    "pointable",
    "makes_footstep_sound",
    "hp",
    "movement_type",
    "min_speed",
    "max_speed",
    "view_distance",
    "hostile",
    "attacked_hostile",
    "attack_type",
    "group_attack",
};
---Scan the mob's definition 
---@param definition table The mob definition table.
---@return nil
local function scanRequired(definition)
    ---@Immutable <- This doesn't do anything yet.
    local mobName = definition.name;
    for _,fieldName in ipairs(REQUIRED) do
        nullCheck(definition[fieldName], fieldName, mobName);
    end
end

---Registers a new mob into the game.
---@param definition table Holds the definition of the mob.
---@return nil
function minetest.register_mob(definition)

    scanRequired(definition);

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
    mob.movement_type = (definition.movement_type and MOVEMENT_TYPE[definition.movement_type]) or MOVEMENT_TYPE.walk
    mob.min_speed = definition.min_speed
    mob.max_speed = definition.max_speed
    mob.gravity = definition.gravity or -9.81
    mob.movement_timer = 0
    mob.speed = 0

    -- Walk movement type variables
    mob.jump_timer = 0
    mob.still_on_wall = false

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
        local new_dir = ( math.random() * ( PI * 2 ) ) - PI
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
        self.object:set_yaw(new_yaw)
    end

    function mob:is_in_water()
        local pos = self.object:get_pos()
        local node = minetest.get_node(pos).name
        return node and (node == "main:water" or node == "main:waterflow")
    end

    function mob:manage_swim_direction_change(dtime)

        if self.following then return end

        self.movement_timer = self.movement_timer - dtime

        if self.movement_timer > 0 then return end

        self.movement_timer = math.random(2,6) + math.random()

        if not self:is_in_water() then return end

        local new_dir = ( math.random() * ( PI * 2 ) ) - PI

        self.direction = minetest.yaw_to_dir(new_dir)

        self:set_yaw(minetest.dir_to_yaw(self.direction))

        self.speed = math.random(self.min_speed,self.max_speed)
    end



    -- Dispatch the correct method based on what the mob movement type is
    -- TODO: move walk type into final else branch as a catchall
    if match_move(MOVEMENT_TYPE.walk) then
        function mob:move(dtime,moveresult)
            self:manage_wandering_direction_change(dtime)

            --- self:manage_jumping(moveresult)
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

end -- !END REGISTER_MOB
