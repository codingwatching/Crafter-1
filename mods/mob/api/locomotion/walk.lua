--- Builds walking methods & fields into the mob.
---@param mob mob
---@param definition definition
---@return mob mob
return function(mob, definition)
    
    -- Walk locomotion type variables
    mob.jump_timer = 0
    mob.still_on_wall = false


    return mob;
end