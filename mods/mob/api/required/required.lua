---Builds the basic structure of the mob. Returns the mob with the new assembled components
---This is the entry point into constructing a mob.
---@param definition table definition.
---@return table table Newly constructed mob class.
return function(definition)

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

    -- Generic variables for locomotion
    mob.locomotion_type = definition.locomotion_type
    mob.min_speed = definition.min_speed
    mob.max_speed = definition.max_speed
    mob.gravity = definition.gravity or -9.81
    mob.locomotion_timer = 0
    mob.speed = 0
    mob.gravity_enabled = false;


    return mob;
end