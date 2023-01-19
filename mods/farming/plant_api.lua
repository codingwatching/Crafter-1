local ipairs = ipairs
local find_nodes_in_area = minetest.find_nodes_in_area
local get_node = minetest.get_node
local set_node = minetest.set_node
local get_node_timer = minetest.get_node_timer
local get_item_group = minetest.get_item_group
local dig_node = minetest.dig_node
local math_random = math.random
local vec_new = vector.new


-- Plant growth time constants (in seconds)
local plant_min = 60
local plant_max = 240

local water_nodes = {
    "main:water","main:waterflow"
}

local stem_search_instructions = {
    vector.new( 1, 0, 0 ),
    vector.new(-1, 0, 0 ),
    vector.new( 0, 0, 1 ),
    vector.new( 0, 0,-1 )
}

-- TODO: Optimize this and reuse as much data as possible. Farms can be huge!
-- TODO: Custom functions for plants
-- TODO: Make soil check a function
-- TODO: Use node timers instead

local reused_vector1 = vector.new(0,0,0)
-- This second heap object only exists so we can do the find_water() calculation below
local reused_vector2 = vec_new(0,0,0)
local gotten_node
local gotten_name
local able_to_grow

-- Finds water nodes in a 1 x H x 1 area
local function find_water_vertical(pos, plant_height)
    reused_vector1.x = pos.x - 1
    reused_vector1.y = pos.y - plant_height
    reused_vector1.z = pos.z - 1
    reused_vector2.x = pos.x + 1
    reused_vector2.y = pos.y
    reused_vector2.z = pos.z + 1
    return #find_nodes_in_area(
        reused_vector1,
        reused_vector2,
        water_nodes
    ) > 0
end

local function too_dark_to_grow(pos)
    return minetest.get_node_light(pos) < 10
end

local function start_plant_timer(pos)
    --minetest.get_node_timer(pos):start(math.random(6, 250))
    minetest.get_node_timer(pos):start(1)
end

local soil_nodes = {
    ["farming:farmland_dry"] = true,
    ["farming:farmland_wet"] = true
}
local sugarcane_nodes = {
    ["main:dirt"] = true,
    ["main:grass"] = true,
    ["main:sand"] = true
}

local function is_soil(node_name)
    return soil_nodes[node_name] ~= nil
end

local function is_sugarcane_soil(node_name)
    return sugarcane_nodes[node_name] ~= nil
end

local function spawn_plant_particles(pos, plant_name)
    minetest.add_particlespawner({
        time = 0.0001,
        pos = {
            min = vector.subtract(pos, -0.5),
            max = vector.subtract(pos, 0.5)
        },
        acc = {
            min = vector.new(0,-9.81,0),
            max = vector.new(0,-9.81,0)
        },
        vel = {
            min = vector.new(-0.5,1,-0.5),
            max = vector.new(0.5,3,0.5)
        },
        drag = 0.2,
        amount = math.random(10,20),
        node = {name = plant_name},
        collisiondetection = true
    })
end

local function plant_dies(pos, plant_name)
    minetest.dig_node( pos )
    minetest.sound_play( "dirt", {
        pos = pos,
        gain = 0.2
    })
    spawn_plant_particles(pos, plant_name)
end

minetest.register_plant = function( name, def )

    local max = 1
    if def.stages then
        max = def.stages
    end

    for i = 1,max do

        local nodename

        if def.stages then
            nodename = "farming:" .. name .. "_" .. i
        else
            nodename = "farming:" .. name
        end

        local after_dig_node
        local on_construct
        local after_destruct
        local after_place_node
        local on_timer


        -- Plants that grow up, like sugarcane
        if def.grows == "up" then

            after_dig_node = function(pos, node, _, digger)

                if not digger then return end

                -- Check above
                pos.y = pos.y + 1

                gotten_node = minetest.get_node(pos)

                if gotten_node.name == node.name then
                    plant_dies( pos, nodename )
                end

                -- Now check below
                pos.y = pos.y - 2

                gotten_node = minetest.get_node(pos)
                if gotten_node.name == node.name then
                    start_plant_timer(pos)
                end
            end

            on_timer = function(pos)

                if too_dark_to_grow(pos) then
                    start_plant_timer(pos)
                    return
                end

                -- These plants grow vertically so search near in radius
                local found_water = find_water_vertical(pos, def.plant_height)

                pos.y = pos.y - 1

                gotten_name = minetest.get_node(pos).name

                able_to_grow = is_sugarcane_soil(gotten_name) or gotten_name == nodename

                if found_water and able_to_grow then

                    pos.y = pos.y + 2

                    if minetest.get_node(pos).name ~= "air" then return end

                    minetest.set_node( pos, { name = "farming:" .. name } )

                    start_plant_timer(pos)

                else

                    pos.y = pos.y + 1

                    plant_dies( pos, nodename )
                end

            end

            after_place_node = function(pos)

                pos.y = pos.y - 1

                gotten_name = minetest.get_node(pos).name

                pos.y = pos.y + 1

                if is_soil(gotten_name) then
                    start_plant_timer(pos)
                    return
                end

                plant_dies( pos, nodename )
            end

        -- Plants that grow in place, like wheat
        elseif def.grows == "in_place" then

            on_timer = function(pos)

                if too_dark_to_grow(pos) then
                    plant_dies( pos, nodename )
                    return
                end

                pos.y = pos.y - 1

                able_to_grow = is_soil(minetest.get_node(pos).name)

                if not able_to_grow then
                    plant_dies( pos, nodename )
                end

                if i < max then
                    pos.y = pos.y + 1
                    minetest.set_node( pos, { name = "farming:" .. name .. "_" .. ( i + 1 ) } )
                    start_plant_timer(pos)
                end

            end

            after_place_node = function(pos)

                pos.y = pos.y - 1

                able_to_grow = is_soil(minetest.get_node(pos).name)

                if able_to_grow then return end

                pos.y = pos.y + 1
                plant_dies( pos, nodename )

            end

        -- Plants that grow in place, but yield a crop, like pumpkins and melons
        -- Basically, consider this the plant's stem growing logic
        elseif def.grows == "in_place_yields" then

            on_timer = function(pos)

                if too_dark_to_grow(pos) then
                    plant_dies( pos, nodename )
                    return
                end

                pos.y = pos.y - 1

                able_to_grow = is_soil(minetest.get_node(pos).name)

                if not able_to_grow then
                    -- No farmland was found
                    plant_dies( pos, nodename )
                    return
                end

                -- Plant stem searches for an air node adjacent to it, yet has a dirt, soil, or grass block under it

                pos.y = pos.y + 1

                -- Stem is still growing
                if i < max then

                    minetest.set_node( pos, { name = "farming:" .. name .. "_" .. ( i + 1 ) } )

                -- Stem is yielding a crop
                else

                    local found = false

                    -- Hold this y position during loop
                    reused_vector1.y = pos.y

                    for _,direction in ipairs(stem_search_instructions) do

                        reused_vector1.x = pos.x + direction.x
                        reused_vector1.z = pos.z + direction.z

                        if minetest.get_node(reused_vector1).name == "air" then
                            -- Reused_vector1 is now the selected position
                            found = true
                            break
                        end

                    end

                    if not found then return end

                    local param2 = minetest.dir_to_fourdir( vector.direction( pos, reused_vector1 ) )

                    minetest.add_node( reused_vector1, { name = def.grown_node, param2 = param2 } )

                    minetest.set_node( pos, { name = "farming:" .. name .. "_complete", param2 = param2 } )

                end

                start_plant_timer(pos)

            end

            after_place_node = function(pos)

                pos.y = pos.y - 1

                if is_soil(minetest.get_node(pos).name) then return end

                pos.y = pos.y + 1
                plant_dies( pos, nodename )
            end
        end

        -- Only allow plants to drop their seeds at the max level
        local drop
        if i == max and def.grows ~= "in_place_yields" then
            drop = def.drop
        elseif max == 1 then
            drop = def.drop
        else
            drop = ""
        end

        local tiles
        if max > 1 then
            tiles = { def.tiles[ 1 ] .. "_" .. i .. ".png" }
        else
            tiles = def.tiles
        end

        def.groups.plants = 1

        minetest.register_node(nodename, {
            description               = def.description,
            drawtype                  = def.drawtype,
            waving                    = def.waving,
            inventory_image           = def.inventory_image,
            walkable                  = def.walkable,
            climbable                 = def.climbable,
            paramtype                 = def.paramtype,
            tiles                     = tiles,
            paramtype2                = def.paramtype2,
            buildable_to              = def.buildable_to,
            groups                    = def.groups,
            sounds                    = def.sounds,
            selection_box             = def.selection_box,
            drop                      = drop,
            sunlight_propagates       = def.sunlight_propagates,
            node_box                  = def.node_box,
            node_placement_prediction = "",
            is_ground_content         = false,

            on_timer                  = on_timer,

            floodable         = true,
            on_flood = function(pos)
                plant_dies( pos, nodename )
            end,

            after_dig_node   = after_dig_node,
            after_place_node = after_place_node,
            on_construct     = on_construct,
            after_destruct   = after_destruct,
        })

    end

    -- Final stage for grow in place plant stems that create food, ie, pumpkins, melons
    -- This node makes it look attached to the fruit
    if def.grows == "in_place_yields" then
        minetest.register_node("farming:" .. name .. "_complete", {
            description         = def.stem_description,
            tiles               = def.stem_tiles,
            drawtype            = def.stem_drawtype,
            walkable            = def.stem_walkable,
            sunlight_propagates = def.stem_sunlight_propagates,
            paramtype           = def.stem_paramtype,
            drop                = def.stem_drop,
            groups              = def.stem_groups,
            sounds              = def.stem_sounds,
            node_box            = def.stem_node_box,
            selection_box       = def.stem_selection_box,
            paramtype2          = "4dir",
        })

        minetest.register_node("farming:"..def.fruit_name, {
            description = def.fruit_description,
            tiles       = def.fruit_tiles,
            groups      = def.fruit_groups,
            sounds      = def.fruit_sounds,
            drop        = def.fruit_drop,
            paramtype2  = "4dir",
            after_destruct = function( pos, oldnode )

                local facedir = oldnode.param2
                facedir = minetest.fourdir_to_dir(facedir)
                local dir = vector.multiply(facedir,-1)
                local stem_pos = vector.add(dir,pos)

                if minetest.get_node(stem_pos).name == "farming:" .. name .. "_complete" then
                    minetest.set_node( stem_pos, { name = "farming:"..name.."_" .. max } )
                    start_plant_timer(stem_pos)
                end
            end
        })
    end

    if def.seed_name then
        minetest.register_craftitem( "farming:" .. def.seed_name .. "_seeds", {
            description = def.seed_description,
            inventory_image = def.seed_inventory_image,
            on_place = function(itemstack, placer, pointed_thing)

                if pointed_thing.type ~= "node" then
                    return itemstack
                end

                local nodedef = minetest.registered_nodes[get_node(pointed_thing.under).name]

                if nodedef.on_rightclick then return minetest.item_place(itemstack, placer, pointed_thing) end

                local buildable_to = nodedef.buildable_to

                if not buildable_to and vector.subtract(pointed_thing.above, pointed_thing.under) ~= vector.new(0,1,0) then print("fook") return end

                if not buildable_to and minetest.get_node(pointed_thing.above).name ~= "air" then return end

                reused_vector1.x = pointed_thing.above.x
                reused_vector1.y = pointed_thing.above.y - 1
                reused_vector1.z = pointed_thing.above.z

                if minetest.get_item_group(minetest.get_node(reused_vector1).name, "farmland") == 0 or minetest.get_node(pointed_thing.above).name ~= "air"  then
                    return itemstack
                end

                itemstack:take_item()
                minetest.sound_play( "leaves", {
                    pos = pointed_thing.above,
                    gain = 1.0
                })

                minetest.place_node(pointed_thing.above, { name = def.seed_plants })

                start_plant_timer(pointed_thing.above)

                return itemstack
            end
        })
    end
end
