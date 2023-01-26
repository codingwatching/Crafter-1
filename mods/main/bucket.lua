local raycast = minetest.raycast
local remove_node = minetest.remove_node
local get_node = minetest.get_node
local registered_nodes = minetest.registered_nodes
local set_node = minetest.set_node
local vec_multiply = vector.multiply
local vec_add = vector.add

local function bucket_raycast(user)
    local pos = user:get_pos()
    pos.y = pos.y + user:get_properties().eye_height
    local look_dir = user:get_look_dir()
    look_dir = vec_multiply(look_dir,4)
    local pos2 = vec_add(pos,look_dir)

    local ray = raycast(pos, pos2, false, true)
    if ray then
        local pointed_thing = ray:next()
        if pointed_thing then
            return( { under = pointed_thing.under, above = pointed_thing.above } )
        end
    end
end

local function do_water_effect(pos)
    minetest.sound_play( "splash", {
        pos = pos,
        gain = 0.2,
    })
    minetest.add_particlespawner({
        pos = {
            min = vector.subtract(pos, vector.new(0.5,0,0.5)),
            max = vector.add(pos, vector.new(0.5,0,0.5))
        },
        acc = vector.new(0,-9.81, 0),
        vel = {
            min = vector.new(0, 4, 0),
            max = vector.new(0, 6, 0),
        },
        attract = {
            kind = "point",
            strength = {
                min = -2,
                max = -2
            },
            origin = pos
        },
        drag = 1.5,
        amount = 20,
        exptime = {
            min = 0.8,
            max = 1.2
        },
        time = 0.01,
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        texture = {
            name = "bubble.png",
            alpha_tween = {0.6,0},
            scale_tween = {
                {x = 1, y = 1},
                {x = 0, y = 0}
            }
        }
    })
end

local function do_lava_effect(pos)
    minetest.sound_play( "lava_gloop", {
        pos = pos,
        gain = 1.5,
    })
    minetest.add_particlespawner({
        pos = {
            min = vector.add(pos, vector.new( -0.5, 0.5, -0.5 ) ),
            max = vector.add(pos, vector.new( 0.5, 0.5, 0.5 ) )
        },
        acc = vector.new(0, 3, 0),
        vel = vector.new(0,0,0),
        drag = 7,
        amount = 20,
        exptime = {
            min = 0.8,
            max = 1.2
        },
        time = 0.3,
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        texture = {
            name = "bubble.png^[colorize:red:215",
            alpha_tween = {1,0},
            scale = 1
        }
    })
end

local function take_function(itemstack, placer)
    local pointed_thing = bucket_raycast(placer)
    if not pointed_thing then return end
    local pos_under = pointed_thing.under
    local node = get_node(pos_under).name
    if node == "main:water" then
        itemstack:replace(ItemStack("main:bucket_water"))
        do_water_effect(pos_under)
        remove_node(pos_under)
        return(itemstack)
    elseif node == "main:lava" or node == "nether:lava" then
        itemstack:replace(ItemStack("main:bucket_lava"))
        do_lava_effect(pos_under)
        remove_node(pos_under)
        return(itemstack)
    end
end

-- Item definitions
minetest.register_craftitem("main:bucket", {
    description = "Bucket",
    inventory_image = "bucket.png",
    stack_max = 1,
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
    local node_under = get_node(pos_under).name
    local node_above = get_node(pos_above).name
    local buildable_under = registered_nodes[node_under].buildable_to
    local buildable_above = registered_nodes[node_above].buildable_to

    -- No position found
    if not buildable_above and not buildable_under then return end

    local pos_storage = { pos_above, pos_under }
    
    local new_position = pos_storage[ bool_to_int( buildable_under ) ]

    if bucket_type == "main:water" then
        -- If you place water in the nether, it's going to evaporate
        if new_position.y < -10033 then goto empty end
        -- Set it to water
        set_node( new_position, {name="main:water"})
        do_water_effect(new_position)
    elseif bucket_type == "main:lava" then
        -- If you place lava in the aether you're going to be disappointed
        if new_position.y >= 20000 then goto empty end
        -- Set it to lava
        set_node(new_position, {name=lava_type[bool_to_int(pos_under.y < -10033)]})
        do_lava_effect(new_position)
    end

    ::empty::
    itemstack:replace(ItemStack("main:bucket"))
    return(itemstack)
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
