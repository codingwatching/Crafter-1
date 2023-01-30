local creative_mode = minetest.settings:get_bool("creative_mode")

-- Make stack max 64 for everything
minetest.register_on_mods_loaded(function()
    for name,def in pairs(minetest.registered_nodes) do
        if creative_mode == true then
            local groups = def.groups
            groups["dig_immediate"] = 3
        end
        local stack_max = minetest.registered_items[name].stack_max
        if stack_max == 99 then
            stack_max = 64
        end
        minetest.override_item(name, {
            stack_max = stack_max,
        })
    end
    for name,_ in pairs(minetest.registered_craftitems) do
        local stack_max = minetest.registered_items[name].stack_max
        if stack_max == 99 then
            minetest.override_item(name, {
                stack_max = 64,
            })
        end
    end
end)
