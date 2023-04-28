local ipairs = ipairs;
local null = nil;

local random = math.random;
local PI = math.pi;
local HALF_PI = PI / 2;
local DOUBLE_PI = PI * 2;

local dispatchGetterTable = utility.dispatchGetterTable;
local throw = utility.throw;


-- TODO: mobs figuring out a path up stairs & slabs
---Todo: shovel a few of these functions into a utility mod.


--- Possible choices: walk, jump, swim, fly.
--- 
--- Immutable mob locomotion type enumerators. Field names accessed via direct or getName().
---@type any[]
---@enum
---@class locomotion_types
---@field walk integer
---@field jump integer
---@field swim integer
---@field fly integer
minetest.locomotion_types = dispatchGetterTable({
    walk = 1,
    jump = 2,
    swim = 3,
    fly = 4
})

---Localized version of the table above.
---@type any[]
---@enum
---@class locomotion_types
local locomotion_types = dispatchGetterTable({
    walk = 1,
    jump = 2,
    swim = 3,
    fly = 4
})
--- Possible choices: none, punch, jump, explode, projectile.
---
---@type any[] Immutable mob attack type enumerators. Field names accessed via direct or getName().
---@enum
---@class attack_types
---@field none integer
---@field punch integer
---@field jump integer
---@field explode integer
---@field projectile integer
minetest.attack_types = dispatchGetterTable({
    none = 0,
    punch = 1,
    jump = 2,
    explode = 3,
    projectile = 4
})
---Localized version of the table above.
---@type any[]
---@class attack_types
local attack_types = dispatchGetterTable({
    none = 0,
    punch = 1,
    jump = 2,
    explode = 3,
    projectile = 4
})




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
    "locomotion_type",
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
    ---@immutable <- This Does nothing for now.
    local mobName = definition.name;
    for _,fieldName in ipairs(REQUIRED) do
        nullCheck(definition[fieldName], fieldName, mobName);
    end
end


---@immutable <- Does nothing for now
local apiDirectory = minetest.get_modpath("mob") .. "/api/";

---Automatically loads in api components.
---@param package string The package in which the file resides.
---@param apiFile string The file in which contains that portion of the api resides.
---@return function function The usable API element which streams in required class methods & fields.
local function load(package, apiFile)
    return dofile(apiDirectory .. package .. "/" .. apiFile .. ".lua");
end

-- Required
local attachRequired = load("required", "required");

-- Locomotion
local attachLocomotionFly  = load("locomotion", "fly");
local attachLocomotionJump = load("locomotion", "jump");
local attachLocomotionSwim = load("locomotion", "swim");
local attachLocomotionWalk = load("locomotion", "walk");

-- Attack
local attachAttackExplode    = load("attack", "explode");
local attachAttackJump       = load("attack", "jump");
local attachAttackNone       = load("attack", "none");
local attachAttackProjectile = load("attack", "projectile");
local attachAttackPunch      = load("attack", "punch");


---Registers a new mob into the game.
---@param definition table Holds the definition of the mob.
---@return nil
function minetest.register_mob(definition)

    scanRequired(definition);
    

    minetest.register_mob_spawner(definition.name,definition.textures,definition.mesh)

    local mob = attachRequired(definition);

    local function matchLocomotion(input)
        return mob.locomotion_type == input;
    end
    local function matchAttack(input)
        return mob.attack_type == input;
    end

    if matchLocomotion(locomotion_types.fly) then
        mob = attachLocomotionFly(mob, definition)
    elseif (matchLocomotion(locomotion_types.jump)) then
        mob = attachLocomotionJump(mob, definition)
    elseif (matchLocomotion(locomotion_types.swim)) then
        mob = attachLocomotionSwim(mob, definition)
    elseif (matchLocomotion(locomotion_types.walk)) then
        mob = attachLocomotionWalk(mob, definition);
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

    minetest.register_entity("mob:" .. definition.name, mob)

end -- !END REGISTER_MOB
