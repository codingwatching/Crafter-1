local pairs = pairs
local register_node = minetest.register_node
local register_on_placenode = minetest.register_on_placenode
local register_chatcommand = minetest.register_chatcommand
local set_node = minetest.set_node
local get_node = minetest.get_node
local get_node_timer = minetest.get_node_timer
local after = minetest.after
local sound_play = minetest.sound_play
local find_node_near = minetest.find_node_near
local get_meta = minetest.get_meta
local get_objects_inside_radius = minetest.get_objects_inside_radius
local find_nodes_in_area_under_air = minetest.find_nodes_in_area_under_air
local registered_nodes = minetest.registered_nodes
local get_player_by_name = minetest.get_player_by_name
local bulk_set_node = minetest.bulk_set_node
local item_place_node = minetest.item_place_node
local item_place = minetest.item_place
local get_dig_params = minetest.get_dig_params
local node_dig = minetest.node_dig
local add_particlespawner = minetest.add_particlespawner
local remove_node = minetest.remove_node
local dir_to_wallmounted = minetest.dir_to_wallmounted
local math_floor = math.floor
local math_random = math.random
local vec_add = vector.add
local vec_new = vector.new
local vec_subtract = vector.subtract
local vec_direction = vector.direction


--ore def with required tool
local tool = {"main:woodpick","main:coalpick","main:stonepick","main:ironpick","main:lapispick","main:goldpick","main:diamondpick","main:emeraldpick","main:sapphirepick","main:rubypick"}
local ores = {
["coal"]={"main:woodpick","main:coalpick","main:stonepick","main:ironpick","main:lapispick","main:goldpick","main:diamondpick","main:emeraldpick","main:sapphirepick","main:rubypick"},
["iron"]={"main:coalpick","main:stonepick","main:ironpick","main:lapispick","main:goldpick","main:diamondpick","main:emeraldpick","main:sapphirepick","main:rubypick"},
["lapis"]={"main:ironpick","main:lapispick","main:goldpick","main:diamondpick","main:emeraldpick","main:sapphirepick","main:rubypick"},
["gold"]={"main:ironpick","main:lapispick","main:goldpick","main:diamondpick","main:emeraldpick","main:sapphirepick","main:rubypick"},
["diamond"]={"main:ironpick","main:lapispick","main:diamondpick","main:emeraldpick","main:sapphirepick","main:rubypick"},
["emerald"]={"main:diamondpick","main:emeraldpick","main:sapphirepick","main:rubypick"},
["sapphire"]={"main:diamondpick","main:emeraldpick","main:sapphirepick","main:rubypick"},
["ruby"]={"main:diamondpick","main:emeraldpick","main:sapphirepick","main:rubypick"},
}

local drops ={
    ["coal"]={"main:coal"},
    ["iron"]={"main:ironore"},
    ["lapis"]={"main:lapis"},
    ["gold"]={"main:goldore"},
    ["diamond"]={"main:diamond"},
    ["emerald"]={"main:emerald"},
    ["sapphire"]={"main:sapphire"},
    ["ruby"]={"main:ruby"},
}

local levels = {
    ["coal"]=1,
    ["iron"]=2,
    ["lapis"]=3,
    ["gold"]=3,
    ["diamond"]=4,
    ["emerald"]=5,
    ["sapphire"]=6,
    ["ruby"]=7,
}


local level = 0
local experience
for ore,tool_required in pairs(ores) do
    level = levels[ore]

    if ore == "iron" or ore == "gold" then
        experience = 0
    else
        experience = level
    end

    register_node("main:"..ore.."block", {
        description = ore:gsub("^%l", string.upper).." Block",
        tiles = {ore.."block.png"},
        groups = {stone = level, pathable = 1},
        sounds = main.stoneSound(),
        --light_source = 14,--debugging ore spawn
        drop = {
            max_items = 1,
            items= {
                {
                    rarity = 0,
                    tools = tool_required,
                    items = {"main:"..ore.."block"},
                },
                },
            },
        })

    register_node("main:"..ore.."ore", {
        description = ore:gsub("^%l", string.upper).." Ore",
        tiles = {"stone.png^"..ore.."ore.png"},
        groups = {stone = level, pathable = 1,experience=experience},
        sounds = main.stoneSound(),
        --light_source = 14,--debugging ore spawn
        drop = {
            max_items = 1,
            items= {
                {
                    rarity = 0,
                    tools = tool_required,
                    items = drops[ore],
                },
                },
            },
        })
    register_node(":nether:"..ore.."ore", {
        description = "Nether "..ore:gsub("^%l", string.upper).." Ore",
        tiles = {"netherrack.png^"..ore.."ore.png"},
        groups = {netherrack = level, pathable = 1, experience = experience},
        sounds = main.stoneSound(),
        light_source = 7,
        drop = {
            max_items = 1,
            items= {
                {
                    rarity = 0,
                    tools = tool_required,
                    items = drops[ore],
                },
                },
            },
        after_destruct = function(pos, oldnode)
            if math_random() > 0.95 then
                sound_play("tnt_ignite",{pos=pos,max_hear_distance=64})
                after(1.5, function(pos)
                    tnt(pos,5)
                end,pos)
            end
        end,
    })
end

register_node("main:stone", {
    description = "Stone",
    tiles = {"stone.png"},
    groups = {stone = 1, hand = 1,pathable = 1},
    sounds = main.stoneSound(),
    drop = {
        max_items = 1,
        items= {
            {
                rarity = 0,
                tools = tool,
                items = {"main:cobble"},
            },
        },
    },
})

local function is_number_whole(input)
    return math_floor(input) == input
end
local function is_vec_whole(input)
    return is_number_whole(input.x) and is_number_whole(input.y) and is_number_whole(input.z)
end
register_node("main:cobble", {
    description = "Cobblestone",
    tiles = {"cobble.png"},
    groups = {stone = 1, pathable = 1},
    sounds = main.stoneSound(),
    drop = {
        max_items = 1,
        items= {
            {
                rarity = 0,
                tools = tool,
                items = {"main:cobble"},
            },
        },
    },
    -- Makes cobblestone generators able to be continuously mined
    on_destruct = function(pos)
        local meta = get_meta(pos)
        if meta:get_int("lava_cooled") == 1 then
            local lava = find_node_near(pos, 1, {"main:lavaflow", "main:lava"})
            local water = find_node_near(pos, 1, {"main:waterflow", "main:water"})

            if lava and water then
                local dir1 = is_vec_whole(vec_direction(pos, lava))
                local dir2 = is_vec_whole(vec_direction(pos, water))

                -- Brute force override the abm
                if dir1 and dir2 then
                    after(0.15, function()
                        set_node(pos, {name="main:cobble"})
                        get_meta(pos):set_int("lava_cooled", 1)
                    end)

                    -- Moves the item out of the way of the lava to avoid annoying item destruction
                    for _,object in ipairs(get_objects_inside_radius(pos, 0.25)) do
                        if not object:is_player() then
                            local lua_entity = object:get_luaentity()
                            if lua_entity and lua_entity.itemstring and lua_entity.itemstring == "main:cobble" then
                                local new_pos = vec_new(pos)
                                new_pos.y = new_pos.y + 0.55
                                object:set_pos(new_pos)
                            end
                        end
                    end
                end
            end
        end
    end
})

register_node("main:mossy_cobble", {
    description = "Mossy Cobblestone",
    tiles = {"mossy_cobble.png"},
    groups = {stone = 1, pathable = 1},
    sounds = main.stoneSound(),
    drop = {
        max_items = 1,
        items= {
            {
                rarity = 0,
                tools = tool,
                items = {"main:mossy_cobble"},
            },
            },
        },
})

register_node("main:glass", {
    description = "Glass",
    tiles = {"glass.png"},
    drawtype = "glasslike",
    paramtype = "light",
    sunlight_propagates = true,
    is_ground_content = false,
    groups = {glass = 1, pathable = 1},
    sounds = main.stoneSound({
        footstep = {name = "glass_footstep", gain = 0.4},
        dug =  {name = "break_glass", gain = 0.4},
    }),
    drop = "",
})
    
register_node("main:ice", {
    description = "Ice",
    tiles = {"ice.png"},
    drawtype = "normal",
    paramtype = "light",
    sunlight_propagates = true,
    is_ground_content = false,
    groups = {glass = 1, pathable = 1,slippery=3},
    sounds = main.stoneSound({
        footstep = {name = "glass_footstep", gain = 0.4},
        dug =  {name = "break_glass", gain = 0.4},
    }),
    --use_texture_alpha = false,
    --alpha = 100,
    drop = "",
    after_destruct = function(pos, oldnode)
       set_node(pos, {name="main:water"})
    end
})
register_node("main:ice_mapgen", {
    description = "Ice",
    tiles = {"ice.png"},
    drawtype = "normal",
    sunlight_propagates = true,
    is_ground_content = false,
    groups = {glass = 1, pathable = 1,slippery=3},
    sounds = main.stoneSound({
        footstep = {name = "glass_footstep", gain = 0.4},
        dug =  {name = "break_glass", gain = 0.4},
    }),
    use_texture_alpha = false,
    drop = "",
})

local grass_react_min = 10
local grass_react_max = 120
local function get_grass_spread_timer()
    return math_random(grass_react_min,grass_react_max) + math_random()
end
local function found_grass(pos)
    return find_node_near(pos, 1, {"main:grass"}) ~= nil
end
local function dispatch_timers(pos)
    for _,new_position in ipairs(find_nodes_in_area_under_air(vec_add(pos, -1), vec_add(pos, 1), {"main:dirt"})) do
        local timer = get_node_timer(new_position)
        if timer:is_started() then goto continue end
        timer:start(get_grass_spread_timer())
        ::continue::
    end
end
register_node("main:dirt", {
    description = "Dirt",
    tiles = {"dirt.png"},
    groups = {dirt = 1, soil=1,pathable = 1, farm_tillable=1},
    sounds = main.dirtSound(),
    paramtype = "light",
    on_construct = function(pos)
        get_node_timer(pos):start(get_grass_spread_timer())
    end,
    after_destruct = function(pos)
        dispatch_timers(pos)
    end,
    on_timer = function(pos)
        if not found_grass(pos) then return end
        if registered_nodes[get_node(vec_new(pos.x, pos.y+1,pos.z)).name].drawtype == "normal" then return end
        set_node(pos, {name="main:grass"})
    end
})

register_node("main:grass", {
    description = "Grass",
    tiles = {"grass.png"},
    groups = {grass = 1, soil=1,pathable = 1, farm_tillable=1},
    sounds = main.dirtSound(),
    drop="main:dirt",
    after_destruct = function(pos)
        dispatch_timers(pos)
    end,
    on_timer = function(pos)
        -- Grass dies when covered
        if registered_nodes[get_node(vec_new(pos.x, pos.y+1,pos.z)).name].drawtype ~= "normal" then return end
        set_node(pos, {name = "main:dirt"})
    end
})
-- Turns grass back into dirt when covered
register_on_placenode(function(pos,newnode)
    if not registered_nodes[newnode.name].drawtype == "normal" then return end
    pos.y = pos.y - 1
    if get_node(pos).name ~= "main:grass" then return end
    local timer = get_node_timer(pos)
    if timer:is_started() then return end
    timer:start(get_grass_spread_timer() / 2)
end)

register_chatcommand("dirt", {
    params = "<mob>",
    description = "Debug for pushing falling entities to the extreme",
    privs = {server = true},
    func = function(name)
        local player = get_player_by_name(name)
        local pos = player:get_pos()
        local queue = {}
        for x = -120,120 do
        for z = -120,120 do
            table.insert(queue, vec_add(pos, vec_new(x,0,z)))
        end
        end
        bulk_set_node(queue, {name = "main:dirt"})
    end,
})


register_node("main:sand", {
    description = "Sand",
    tiles = {"sand.png"},
    groups = {sand = 1, falling_node = 1,pathable = 1,soil=1},
    sounds = main.sandSound(),
})

register_node("main:gravel", {
    description = "Gravel",
    tiles = {"gravel.png"},
    groups = {sand = 1, falling_node = 1,pathable = 1},
    sounds = main.dirtSound(),
    drop = {
        max_items = 1,
        items= {
         {
            rarity = 10,
            items = {"main:flint"},
        },
        {
            rarity = 0,
            items = {"main:gravel"},
        },
    }},
})

local acceptable_soil = {
    ["main:dirt"] = true,
    ["main:grass"] = true,
    ["aether:dirt"] = true,
    ["aether:grass"] = true,
}
register_node("main:tree", {
    description = "Tree",
    tiles = {"treeCore.png","treeCore.png","treeOut.png","treeOut.png","treeOut.png","treeOut.png"},
    groups = {wood = 1, tree = 1, pathable = 1, flammable=1},
    sounds = main.woodSound(),
    --set metadata so treecapitator doesn't destroy houses
    on_place = function(itemstack, placer, pointed_thing)
        if not pointed_thing.type == "node" then
            return
        end

        local sneak = placer:get_player_control().sneak
        local noddef = registered_nodes[get_node(pointed_thing.under).name]
        if not sneak and noddef.on_rightclick then
            item_place(itemstack, placer, pointed_thing)
            return
        end

        local pos = pointed_thing.above
        item_place_node(itemstack, placer, pointed_thing)
        local meta = get_meta(pos)
        meta:set_string("placed", "true")
        return(itemstack)
    end,
    --treecapitator - move treecapitator into own file using override
    on_dig = function(pos, node, digger)
        --bvav_create_vessel(pos,facedir_to_dir(dir_to_facedir(yaw_to_dir(digger:get_look_horizontal()+(math_pi/2)))))
        --check if wielding axe?
        --turn treecapitator into an enchantment?
        local meta = get_meta(pos)
        --local tool_meta = digger:get_wielded_item():get_meta()
        --if tool_meta:get_int("treecapitator") > 0 then
        if not meta:contains("placed") and string.match(digger:get_wielded_item():get_name(), "axe") then
            local tool_capabilities = digger:get_wielded_item():get_tool_capabilities()

            local wear = get_dig_params({wood=1}, tool_capabilities).wear

            local wield_stack = digger:get_wielded_item()

            --remove tree
            for y = -6,6 do
                local name = get_node(vec_new(pos.x,pos.y+y,pos.z)).name

                if name == "main:tree" or name == "redstone:node_activated_tree" then
                    wield_stack:add_wear(wear)
                    node_dig(vec_new(pos.x,pos.y+y,pos.z), node, digger)
                    add_particlespawner({
                        amount = 30,
                        time = 0.0001,
                        minpos = {x=pos.x-0.5, y=pos.y-0.5+y, z=pos.z-0.5},
                        maxpos = {x=pos.x+0.5, y=pos.y+0.5+y, z=pos.z+0.5},
                        minvel = vec_new(-1,0,-1),
                        maxvel = vec_new(1,0,1),
                        minacc = {x=0, y=-9.81, z=0},
                        maxacc = {x=0, y=-9.81, z=0},
                        minexptime = 0.5,
                        maxexptime = 1.5,
                        minsize = 0,
                        maxsize = 0,
                        collisiondetection = true,
                        vertical = false,
                        node = {name= name},
                    })

                    local name2 = get_node(vec_new(pos.x,pos.y+y-1,pos.z)).name
                    if acceptable_soil[name2] then
                        set_node(vec_new(pos.x,pos.y+y,pos.z),{name="main:sapling"})
                    end
                end
            end
            digger:set_wielded_item(wield_stack)
        else
            node_dig(pos, node, digger)
        end
    end
})

register_node("main:wood", {
    description = "Wood",
    tiles = {"wood.png"},
    groups = {wood = 1, pathable = 1,flammable=1},
    sounds = main.woodSound(),
})

register_node("main:leaves", {
    description = "Leaves",
    drawtype = "allfaces_optional",
    waving = 1,
    walkable = true,
    paramtype = "light",
    is_ground_content = false,
    tiles = {"leaves.png"},
    groups = {leaves = 1, leafdecay = 1,flammable=1},
    sounds = main.grassSound(),
    drop = {
        max_items = 1,
        items= {
        {
            tools = {"main:shears"},
            items = {"main:dropped_leaves"},
        },
        {
            rarity = 25,
            items = {"main:apple"},
        },
        {
            rarity = 20,
            items = {"main:sapling"},
        },
        },
    },
})


register_node("main:dropped_leaves", {
    description = "Leaves",
    drawtype = "allfaces_optional",
    waving = 0,
    walkable = false,
    climbable = false,
    paramtype = "light",
    is_ground_content = false,
    tiles = {"leaves.png"},
    groups = {leaves = 1, flammable=1},
    sounds = main.grassSound(),
    drop = {
        max_items = 1,
        items= {
        {
            tools = {"main:shears"},
            items = {"main:dropped_leaves"},
        },
    },
    },
})


register_node("main:water", {
    description = "Water Source",
    drawtype = "liquid",
    waving = 3,
    tiles = {
        {
            name = "water_source.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 1,
            },
        },
        {
            name = "water_source.png",
            backface_culling = true,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 1,
            },
        },
    },
    alpha = 191,
    paramtype = "light",
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    is_ground_content = false,
    drop = "",
    liquidtype = "source",
    liquid_alternative_flowing = "main:waterflow",
    liquid_alternative_source = "main:water",
    move_resistance = 1,
    liquid_viscosity = 0,
    post_effect_color = {a = 103, r = 30, g = 60, b = 90},
    groups = {water = 1, liquid = 1, cools_lava = 1, bucket = 1, source = 1,pathable = 1,drowning=1,disable_fall_damage=1,extinguish=1},
    on_construct = function(pos)
        local under = get_node(vec_new(pos.x,pos.y-1,pos.z)).name
        if under == "nether:glowstone" then
            remove_node(pos)
            create_aether_portal(pos)
        end
    end,
})

register_node("main:waterflow", {
    description = "Water Flow",
    drawtype = "flowingliquid",
    waving = 3,
    tiles = {"water_static.png"},
    special_tiles = {
        {
            name = "water_flow.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 0.5,
            },
        },
        {
            name = "water_flow.png",
            backface_culling = true,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 0.5,
            },
        },
    },
    selection_box = {
            type = "fixed",
            fixed = {
                {0, 0, 0, 0, 0, 0},
            },
        },
    alpha = 191,
    paramtype = "light",
    paramtype2 = "flowingliquid",
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    is_ground_content = false,
    drop = "",
    liquidtype = "flowing",
    liquid_alternative_flowing = "main:waterflow",
    liquid_alternative_source = "main:water",
    move_resistance = 1,
    liquid_viscosity = 0,
    post_effect_color = {a = 103, r = 30, g = 60, b = 90},
    groups = {water = 1, liquid = 1, notInCreative = 1, cools_lava = 1,pathable = 1,drowning=1,disable_fall_damage=1,extinguish=1},
})

register_node("main:lava", {
    description = "Lava",
    drawtype = "liquid",
    tiles = {
        {
            name = "lava_source.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 2.0,
            },
        },
        {
            name = "lava_source.png",
            backface_culling = true,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 2.0,
            },
        },
    },
    paramtype = "light",
    light_source = 13,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    is_ground_content = false,
    drop = "",
    drowning = 1,
    liquidtype = "source",
    liquid_alternative_flowing = "main:lavaflow",
    liquid_alternative_source = "main:lava",
    move_resistance = 5,
    liquid_viscosity = 7,
    liquid_renewable = false,
    post_effect_color = {a = 191, r = 255, g = 64, b = 0},
    groups = {lava = 3, liquid = 2, igniter = 1, fire=1,hurt_inside=1},
})

register_node("main:lavaflow", {
    description = "Flowing Lava",
    drawtype = "flowingliquid",
    tiles = {"lava_flow.png"},
    special_tiles = {
        {
            name = "lava_flow.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 3.3,
            },
        },
        {
            name = "lava_flow.png",
            backface_culling = true,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 3.3,
            },
        },
    },
    selection_box = {
            type = "fixed",
            fixed = {
                {0, 0, 0, 0, 0, 0},
            },
        },
    paramtype = "light",
    paramtype2 = "flowingliquid",
    light_source = 13,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    is_ground_content = false,
    drop = "",
    drowning = 1,
    liquidtype = "flowing",
    liquid_alternative_flowing = "main:lavaflow",
    liquid_alternative_source = "main:lava",
    move_resistance = 5,
    liquid_viscosity = 7,
    liquid_renewable = false,
    liquid_range = 3,
    post_effect_color = {a = 191, r = 255, g = 64, b = 0},
    groups = {lava = 3, liquid = 2, igniter = 1, fire=1,hurt_inside=1},
})

register_node("main:ladder", {
    description = "Ladder",
    drawtype = "signlike",
    tiles = {"ladder.png"},
    inventory_image = "ladder.png",
    wield_image = "ladder.png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    climbable = true,
    is_ground_content = false,
    node_placement_prediction = "",
    selection_box = {
        type = "wallmounted",
    },
    groups = {wood = 1, flammable = 1, attached_node=1},
    sounds = main.woodSound(),
    on_place = function(itemstack, placer, pointed_thing)
        --copy from torch
        if pointed_thing.type ~= "node" then
            return itemstack
        end

        local wdir = dir_to_wallmounted(vec_subtract(pointed_thing.under,pointed_thing.above))

        local fakestack = itemstack
        local retval = false
        if wdir > 1 then
            retval = fakestack:set_name("main:ladder")
        else
            return itemstack
        end

        if not retval then
            return itemstack
        end

        itemstack, retval = item_place(fakestack, placer, pointed_thing, wdir)

        if retval then
            sound_play("wood", {pos=pointed_thing.above, gain = 1.0})
        end

        print(itemstack, retval)
        itemstack:set_name("main:ladder")

        return itemstack
    end,
})
