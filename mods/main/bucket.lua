local next = next

local function bucket_raycast(user)
    local pos = user:get_pos()
    pos.y = pos.y + user:get_properties().eye_height
    local look_dir = user:get_look_dir()
    look_dir = vector.multiply(look_dir,4)
    local pos2 = vector.add(pos,look_dir)

    local ray = minetest.raycast(pos, pos2, false, true)
    if ray then
        local pointed_thing = ray:next()
        return( { under = pointed_thing.under, above = pointed_thing.above } )
    end
end

local function take_function(itemstack, placer)
    local pointed_thing = bucket_raycast(placer)
    if not pointed_thing then return end
    local pos_under = pointed_thing.under
    local node = minetest.get_node(pos_under).name
    if node == "main:water" then
        itemstack:replace(ItemStack("main:bucket_water"))
        minetest.remove_node(pos_under)
        return(itemstack)
    elseif node == "main:lava" or node == "nether:lava" then
        itemstack:replace(ItemStack("main:bucket_lava"))
        minetest.remove_node(pos_under)
        return(itemstack)
    end
end

-- Item definitions
minetest.register_craftitem("main:bucket", {
    description = "Bucket",
    inventory_image = "bucket.png",
    stack_max = 1,
    --wield_image = "bucket.png",
    on_place = take_function,
    on_secondary_use = take_function,
})

local function bool_to_int(boolean)
    return boolean and 2 or 1
end

local lava_type = { "main:lava", "nether:lava" }

local function place_function(itemstack, placer)
    local pos = bucket_raycast(placer)
    if not pos then return end
    local bucket_type = itemstack:get_name():gsub("bucket_", "")
    local pos_under = pos.under
    local pos_above = pos.above
    local node_under = minetest.get_node(pos_under).name
    local node_above = minetest.get_node(pos_above).name
    local buildable_under = minetest.registered_nodes[node_under].buildable_to
    local buildable_above = minetest.registered_nodes[node_above].buildable_to

    -- No position found
    if not buildable_above and not buildable_under then return end

    local pos_storage = { pos_above, pos_under }

    if bucket_type == "main:water" then
        -- Set it to water
        minetest.set_node( pos_storage[ bool_to_int( buildable_under ) ],{name="main:water"})
        itemstack:replace(ItemStack("main:bucket"))
        return(itemstack)
    elseif bucket_type == "main:lava" then
        -- If you place lava in the aether you're going to be dissapointed
        if pos_under.y >= 20000 then
            itemstack:replace(ItemStack("main:bucket"))
            return(itemstack)
        end
        -- Set it to lava
        if buildable_under == true then
            -- Nether check
            if pos_under.y > -10033 then
                minetest.add_node(pos_under,{name="main:lava"})
            else
                minetest.add_node(pos_under,{name="nether:lava"})
            end
            itemstack:replace(ItemStack("main:bucket"))
            return(itemstack)
        elseif buildable_above then
            if pos_above.y > -10033 then
                minetest.add_node(pos_above,{name="main:lava"})
            else
                minetest.add_node(pos_above,{name="nether:lava"})
            end
            itemstack:replace(ItemStack("main:bucket"))
            return(itemstack)
        end
    end
end


minetest.register_craftitem("main:bucket_water", {
    description = "Bucket of Water",
    inventory_image = "bucket_water.png",
    stack_max = 1,
    on_place = place_function,
    on_secondary_use = place_function,
})

minetest.register_craftitem("main:bucket_lava", {
    description = "Bucket of Lava",
    inventory_image = "bucket_lava.png",
    stack_max = 1,
    on_place = place_function,
    on_secondary_use = place_function,
})
