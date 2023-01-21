local ipairs = ipairs
local ItemStack = ItemStack
local registered_nodes = minetest.registered_nodes
local get_meta = minetest.get_meta
local get_player_by_name = minetest.get_player_by_name
local item_place_node = minetest.item_place_node
local get_node = minetest.get_node
local get_node_timer = minetest.get_node_timer
local settings = minetest.settings
local get_objects_inside_radius = minetest.get_objects_inside_radius
local is_protected = minetest.is_protected
local check_player_privs = minetest.check_player_privs
local show_formspec = minetest.show_formspec
local pos_to_string = minetest.pos_to_string
local string_to_pos = minetest.string_to_pos
local add_item = minetest.add_item
local register_node = minetest.register_node
local facedir_to_dir = minetest.facedir_to_dir
local get_inventory = minetest.get_inventory
local register_craft = minetest.register_craft
local register_on_player_receive_fields = minetest.register_on_player_receive_fields
local string_sub = string.sub
local string_find = string.find
local vec_add = vector.add
local vec_subtract = vector.subtract

local formspec_bg = "background[-0.19,-0.25;9.41,9.49;gui_hb_bg.png]"

local neighbors = {}
local groups = {}
local containers = {}

-- Local function to add new containers
local function add_container(list)
    for _, entry in ipairs(list) do
        local target_node = entry[2]
        local neighbor_node
        if string_sub(target_node, 1, 6) == "group:" then

            local group_identifier, group_number
            local equals_index = string_find(target_node, "=")

            if equals_index ~= nil then
                group_identifier = string_sub(target_node, 7, equals_index-1)
                -- it's possible that the string was of the form "group:blah = 1", in which case we want to trim spaces off the end of the group identifier
                local space_index = string_find(group_identifier, " ")
                if space_index ~= nil then
                    group_identifier = string_sub(group_identifier, 1, space_index-1)
                end
                group_number = tonumber(string_sub(target_node, equals_index+1, -1))
            else
                group_identifier = string_sub(target_node, 7, -1)
                group_number = "all" -- special value to indicate no number was provided
            end
            local group_info = groups[group_identifier]

            if group_info == nil then
                group_info = {}
            end
            if group_number and group_info[group_number] == nil then
                group_info[group_number] = {}
            end
            group_info[group_number][entry[1]] = entry[3]
            groups[group_identifier] = group_info
            neighbor_node = "group:"..group_identifier
            -- Result is a table of the form groups[group_identifier][group_number][relative_position][inventory_name]
        else
            local node_info = containers[target_node]
            if node_info == nil then
                node_info = {}
            end
            node_info[entry[1]] = entry[3]
            containers[target_node] = node_info
            neighbor_node = target_node
            -- Result is a table of the form containers[target_node_name][relative_position][inventory_name]
        end

        local already_in_neighbors = false
        for _, value in ipairs(neighbors) do
            if value == neighbor_node then
                already_in_neighbors = true
                break
            end
        end
        if not already_in_neighbors then
            table.insert(neighbors, neighbor_node)
        end
    end
end

-- "top" indicates what inventory the hopper will take items from if this node is located at the hopper's wide end
-- "side" indicates what inventory the hopper will put items into if this node is located at the hopper's narrow end and at the same height as the hopper
-- "bottom" indicates what inventory the hopper will put items into if this node is located at the hopper's narrow end and either above or below the 
add_container({
    {"top", "hopper:hopper", "main"},
    {"bottom", "hopper:hopper", "main"},
    {"side", "hopper:hopper", "main"},
    {"side", "hopper:hopper_side", "main"},

    {"bottom", "hopper:chute", "main"},
    {"side", "hopper:chute", "main"},

    {"bottom", "hopper:sorter", "main"},
    {"side", "hopper:sorter", "main"},

    {"top", "utility:chest", "main"},
    {"bottom", "utility:chest", "main"},
    {"side", "utility:chest", "main"},

    {"top", "utility:chest_open", "main"},
    {"bottom", "utility:chest_open", "main"},
    {"side", "utility:chest_open", "main"},

    {"top", "utility:furnace", "dst"},
    {"bottom", "utility:furnace", "src"},
    {"side", "utility:furnace", "fuel"},

    {"top", "utility:furnace_active", "dst"},
    {"bottom", "utility:furnace_active", "src"},
    {"side", "utility:furnace_active", "fuel"},
})

-- Target inventory retrieval

-- looks first for a registration matching the specific node name, then for a registration
-- matching group and value, then for a registration matching a group and *any* value
local get_registered_inventories_for = function(target_node_name)
    local output = containers[target_node_name]
    if output ~= nil then return output end

    local target_def = registered_nodes[target_node_name]
    if target_def == nil or target_def.groups == nil then return nil end

    for group, value in pairs(target_def.groups) do
        local registered_group = groups[group]
        if registered_group ~= nil then
            output = registered_group[value]
            if output ~= nil then return output end
            output = registered_group["all"]
            if output ~= nil then return output end
        end
    end

    return nil
end

local get_eject_button_texts = function(pos, loc_X, loc_Y)

    local eject_button_text, eject_button_tooltip
    if get_meta(pos):get_string("eject") == "true" then
        eject_button_text = "Don't\nEject"
        eject_button_tooltip = "This hopper is currently set to eject items from its output\neven if there isn't a compatible block positioned to receive it.\nClick this button to disable this feature."
    else
        eject_button_text = "Eject\nItems"
        eject_button_tooltip = "This hopper is currently set to hold on to item if there\nisn't a compatible block positioned to receive it.\nClick this button to have it eject items instead."
    end
    return "button_exit["..loc_X..","..loc_Y..";1,1;eject;"..eject_button_text.."]tooltip[eject;"..eject_button_tooltip.."]"
end

 local get_string_pos = function(pos)
    return pos.x .. "," .. pos.y .. "," ..pos.z
end

-- Apparently node_sound_metal_defaults is a newer thing, I ran into games using an older version of the default mod without it.
local metal_sounds = main.stoneSound()


-- Inventory transfer functions

local delay = function(x)
    return (function() return x end)
end

local get_placer = function(player_name)
    if player_name ~= "" then
        return get_player_by_name(player_name) or {
            is_player = delay(true),
            get_player_name = delay(player_name),
            is_fake_player = ":hopper",
            get_wielded_item = delay(ItemStack(nil))
        }
    end
    return nil
end

-- Used to remove items from the target block and put it into the hopper's inventory
local take_item_from = function(hopper_pos, target_pos, target_node, target_inventory_name)
    if target_inventory_name == nil then
        return
    end
    local target_def = registered_nodes[target_node.name]
    if not target_def then
        return
    end

    --hopper inventory
    local hopper_meta = get_meta(hopper_pos);
    local hopper_inv = hopper_meta:get_inventory()
    local placer = get_placer(hopper_meta:get_string("placer"))

    --source inventory
    local target_inv = get_meta(target_pos):get_inventory()
    local target_inv_size = target_inv:get_size(target_inventory_name)
    if target_inv:is_empty(target_inventory_name) == false then
        for i = 1,target_inv_size do
            local stack = target_inv:get_stack(target_inventory_name, i)
            local item = stack:get_name()
            if item ~= "" then
                if hopper_inv:room_for_item("main", item) then
                    local stack_to_take = stack:take_item(1)
                    if target_def.allow_metadata_inventory_take == nil
                      or placer == nil -- backwards compatibility, older versions of this mod didn't record who placed the hopper
                      or target_def.allow_metadata_inventory_take(target_pos, target_inventory_name, i, stack_to_take, placer) > 0 then
                        target_inv:set_stack(target_inventory_name, i, stack)
                        --add to hopper
                        hopper_inv:add_item("main", stack_to_take)
                        if target_def.on_metadata_inventory_take ~= nil and placer ~= nil then
                            target_def.on_metadata_inventory_take(target_pos, target_inventory_name, i, stack_to_take, placer)
                        end
                        break
                    end
                end
            end
        end
    end
end

-- Used to put items from the hopper inventory into the target block
local send_item_to = function(hopper_pos, target_pos, target_node, target_inventory_name, filtered_items)
    local hopper_meta = get_meta(hopper_pos)
    local target_def = registered_nodes[target_node.name]
    if not target_def then
        return false
    end

    local eject_item = hopper_meta:get_string("eject") == "true" and target_def.buildable_to

    if not eject_item and not target_inventory_name then
        return false
    end

    --hopper inventory
    hopper_meta = get_meta(hopper_pos);
    local hopper_inv = hopper_meta:get_inventory()
    if hopper_inv:is_empty("main") == true then
        return false
    end
    local hopper_inv_size = hopper_inv:get_size("main")
    local placer = get_placer(hopper_meta:get_string("placer"))

    --target inventory
    local target_inv = get_meta(target_pos):get_inventory()

    for i = 1,hopper_inv_size do
        local stack = hopper_inv:get_stack("main", i)
        local item = stack:get_name()
        if item ~= "" and (filtered_items == nil or filtered_items[item]) then
            if target_inventory_name then
                if target_inv:room_for_item(target_inventory_name, item) then
                    local stack_to_put = stack:take_item(1)
                    if target_def.allow_metadata_inventory_put == nil
                    or placer == nil -- backwards compatibility, older versions of this mod didn't record who placed the hopper
                    or target_def.allow_metadata_inventory_put(target_pos, target_inventory_name, i, stack_to_put, placer) > 0 then
                        hopper_inv:set_stack("main", i, stack)
                        --add to target node
                        target_inv:add_item(target_inventory_name, stack_to_put)
                        if target_def.on_metadata_inventory_put ~= nil and placer ~= nil then
                            target_def.on_metadata_inventory_put(target_pos, target_inventory_name, i, stack_to_put, placer)
                        end
                        return true
                    end
                end
            elseif eject_item then
                local stack_to_put = stack:take_item(1)
                add_item(target_pos, stack_to_put)
                hopper_inv:set_stack("main", i, stack)
                return true
            end
        end
    end
    return false
end

-- Hopper node

-- formspec
local function get_hopper_formspec(pos)
    local spos = get_string_pos(pos)
    local formspec =
        "size[8,9]"
        .. formspec_bg
        .. "list[nodemeta:" .. spos .. ";main;2,0.3;4,4;]"
        .. get_eject_button_texts(pos, 7, 2)
        .. "list[current_player;main;0,4.85;8,1;]"
        .. "list[current_player;main;0,6.08;8,3;8]"
        .. "listring[nodemeta:" .. spos .. ";main]"
        .. "listring[current_player;main]"
    return formspec
end

local hopper_on_place = function(itemstack, placer, pointed_thing, node_name)
    local pos  = pointed_thing.under
    local pos2 = pointed_thing.above
    local x = pos.x - pos2.x
    local z = pos.z - pos2.z

    local returned_stack, success
    -- unfortunately param2 overrides are needed for side hoppers even in the non-single-craftable-item case
    -- because they are literally *side* hoppers - their spouts point to the side rather than to the front, so
    -- the default item_place_node orientation code will not orient them pointing toward the selected surface.
    if x == -1 then
        returned_stack, success = item_place_node(ItemStack("hopper:hopper_side"), placer, pointed_thing, 0)
    elseif x == 1 then
        returned_stack, success = item_place_node(ItemStack("hopper:hopper_side"), placer, pointed_thing, 2)
    elseif z == -1  then
        returned_stack, success = item_place_node(ItemStack("hopper:hopper_side"), placer, pointed_thing, 3)
    elseif z == 1 then
        returned_stack, success = item_place_node(ItemStack("hopper:hopper_side"), placer, pointed_thing, 1)
    else
        node_name = "hopper:hopper" -- For cases where single_craftable_item was set on an existing world and there are still side hoppers in player inventories 
        returned_stack, success = item_place_node(ItemStack(node_name), placer, pointed_thing)
    end

    if success then
        local meta = get_meta(pos2)
        meta:set_string("placer", placer:get_player_name())
        if not settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
    end
    return itemstack
end

-- Hopper timer procedure

-- Used to convert side hopper facing into source and destination relative coordinates
-- This was tedious to populate and test, I'm not going to turn this into a linear list just yet, easier to read
local directions = {
    [0] = { ["src"] = { x = 0, y = 1, z = 0 }, ["dst"] = { x = -1, y = 0, z = 0 } },
    [1] = { ["src"] = { x = 0, y = 1, z = 0 }, ["dst"] = { x = 0, y = 0, z = 1 } },
    [2] = { ["src"] = { x = 0, y = 1, z = 0 }, ["dst"] = { x = 1, y = 0, z = 0 } },
    [3] = { ["src"] = { x = 0, y = 1, z = 0 }, ["dst"] = { x = 0, y = 0, z = -1 } },
    [4] = { ["src"] = { x = 0, y = 0, z = 1 }, ["dst"] = { x = -1, y = 0, z = 0 } },
    [5] = { ["src"] = { x = 0, y = 0, z = 1 }, ["dst"] = { x = 0, y = -1, z = 0 } },
    [6] = { ["src"] = { x = 0, y = 0, z = 1 }, ["dst"] = { x = 1, y = 0, z = 0 } },
    [7] = { ["src"] = { x = 0, y = 0, z = 1 }, ["dst"] = { x = 0, y = 1, z = 0 } },
    [8] = { ["src"] = { x = 0, y = 0, z = -1 }, ["dst"] = { x = -1, y = 0, z = 0 } },
    [9] = { ["src"] = { x = 0, y = 0, z = -1 }, ["dst"] = { x = 0, y = 1, z = 0 } },
    [10] = { ["src"] = { x = 0, y = 0, z = -1 }, ["dst"] = { x = 1, y = 0, z = 0 } },
    [11] = { ["src"] = { x = 0, y = 0, z = -1 }, ["dst"] = { x = 0, y = -1, z = 0 } },
    [12] = { ["src"] = { x = 1, y = 0, z = 0 }, ["dst"] = { x = 0, y = 1, z = 0 } },
    [13] = { ["src"] = { x = 1, y = 0, z = 0 }, ["dst"] = { x = 0, y = 0, z = 1 } },
    [14] = { ["src"] = { x = 1, y = 0, z = 0 }, ["dst"] = { x = 0, y = -1, z = 0 } },
    [15] = { ["src"] = { x = 1, y = 0, z = 0 }, ["dst"] = { x = 0, y = 0, z = -1 } },
    [16] = { ["src"] = { x = -1, y = 0, z = 0 }, ["dst"] = { x = 0, y = -1, z = 0 } },
    [17] = { ["src"] = { x = -1, y = 0, z = 0 }, ["dst"] = { x = 0, y = 0, z = 1 } },
    [18] = { ["src"] = { x = -1, y = 0, z = 0 }, ["dst"] = { x = 0, y = 1, z = 0 } },
    [19] = { ["src"] = { x = -1, y = 0, z = 0 }, ["dst"] = { x = 0, y = 0, z = -1 } },
    [20] = { ["src"] = { x = 0, y = -1, z = 0 }, ["dst"] = { x = 1, y = 0, z = 0 } },
    [21] = { ["src"] = { x = 0, y = -1, z = 0 }, ["dst"] = { x = 0, y = 0, z = 1 } },
    [22] = { ["src"] = { x = 0, y = -1, z = 0 }, ["dst"] = { x = -1, y = 0, z = 0 } },
    [23] = { ["src"] = { x = 0, y = -1, z = 0 }, ["dst"] = { x = 0, y = 0, z = -1 } },
}

local bottomdir = function(facedir)
    return (
    { [0] =
        { x = 0, y = -1, z = 0 },
        { x = 0, y = 0, z = -1 },
        { x = 0, y = 0, z = 1 },
        { x = -1, y = 0, z = 0 },
        { x = 1, y = 0, z = 0 },
        { x = 0, y = 1, z = 0 }
    })[ math.floor( facedir / 4 ) ]
end

local function do_hopper_function(pos)

    -- Top of hopper item vacuum

    local gotten_object = get_objects_inside_radius(pos, 1)
    if #gotten_object == 0 then goto moving end

    do

        local inv = get_meta(pos):get_inventory()
        local posob

        for _,object in ipairs(gotten_object) do
            if not object:is_player()
            and object:get_luaentity()
            and object:get_luaentity().name == "__builtin:item"
            and inv
            and inv:room_for_item("main", ItemStack( object:get_luaentity().itemstring ) ) then

                posob = object:get_pos()

                if math.abs(posob.x - pos.x) <= 0.5 and posob.y - pos.y <= 0.85 and posob.y - pos.y >= 0.3 then
                    inv:add_item("main", ItemStack(object:get_luaentity().itemstring))

                    object:get_luaentity().itemstring = ""
                    object:remove()
                end
            end
        end

    end
    -- Procedure to move items

    ::moving::

    local node = get_node(pos)

    local source_pos, destination_pos, destination_dir
    if node.name == "hopper:hopper_side" then
        source_pos = vec_add(pos, directions[node.param2].src)
        destination_dir = directions[node.param2].dst
        destination_pos = vec_add(pos, destination_dir)
    else
        destination_dir = bottomdir(node.param2)
        source_pos = vec_subtract(pos, destination_dir)
        destination_pos = vec_add(pos, destination_dir)
    end

    local output_direction
    if destination_dir.y == 0 then
        output_direction = "horizontal"
    end

    local source_node = get_node(source_pos)
    local destination_node = get_node(destination_pos)

    local registered_source_inventories = get_registered_inventories_for(source_node.name)
    if registered_source_inventories ~= nil then
        take_item_from(pos, source_pos, source_node, registered_source_inventories["top"])
    end

    local registered_destination_inventories = get_registered_inventories_for(destination_node.name)
    if registered_destination_inventories ~= nil then
        if output_direction == "horizontal" then
            send_item_to(pos, destination_pos, destination_node, registered_destination_inventories["side"])
        else
            send_item_to(pos, destination_pos, destination_node, registered_destination_inventories["bottom"])
        end
    else
        send_item_to(pos, destination_pos, destination_node)
    end

    get_node_timer(pos):start(0.1)
end

-- Hoppers - I would have never guessed

register_node("hopper:hopper", {
    drop = "hopper:hopper",
    description = "Hopper",
    groups = {stone = 1, hard = 1, pickaxe = 1, hand = 4,pathable = 1},
    sounds = metal_sounds,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
        "hopper_top_16.png",
        "hopper_top_16.png",
        "hopper_front_16.png"
    },
    node_box = {
        type = "fixed",
        fixed = {
            --funnel walls
            {-0.5, 0.0, 0.4, 0.5, 0.5, 0.5},
            {0.4, 0.0, -0.5, 0.5, 0.5, 0.5},
            {-0.5, 0.0, -0.5, -0.4, 0.5, 0.5},
            {-0.5, 0.0, -0.5, 0.5, 0.5, -0.4},
            --funnel base
            {-0.5, 0.0, -0.5, 0.5, 0.1, 0.5},
            --spout
            {-0.3, -0.3, -0.3, 0.3, 0.0, 0.3},
            {-0.15, -0.3, -0.15, 0.15, -0.7, 0.15},
        },
    },
    selection_box = {
        type = "fixed",
        fixed = {
            --funnel
            {-0.5, 0.0, -0.5, 0.5, 0.5, 0.5},
            --spout
            {-0.3, -0.3, -0.3, 0.3, 0.0, 0.3},
            {-0.15, -0.3, -0.15, 0.15, -0.7, 0.15},
        },
    },

    on_construct = function(pos)
        local inv = get_meta(pos):get_inventory()
        inv:set_size("main", 4*4)
        get_node_timer(pos):start(0.1)
    end,

    on_timer = do_hopper_function,

    on_place = function(itemstack, placer, pointed_thing)
        return hopper_on_place(itemstack, placer, pointed_thing, "hopper:hopper")
    end,

    can_dig = function(pos)
        local inv = get_meta(pos):get_inventory()
        return inv:is_empty("main")
    end,
    on_rightclick = function(pos, _, clicker)
        if is_protected(pos, clicker:get_player_name()) and not check_player_privs(clicker, "protection_bypass") then
            return
        end
        show_formspec(clicker:get_player_name(),
            "hopper_formspec:"..pos_to_string(pos), get_hopper_formspec(pos))
    end,
})

local hopper_side_drop = "hopper:hopper"

register_node("hopper:hopper_side", {
    description = "Side Hopper",
    drop = hopper_side_drop,
    groups = {stone = 1, hard = 1, pickaxe = 1, hand = 4,pathable = 1},
    sounds = metal_sounds,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
        "hopper_top_16.png",
        "hopper_bottom_16.png",
        "hopper_back_16.png",
        "hopper_side_16.png",
        "hopper_back_16.png",
        "hopper_back_16.png"
    },
    node_box = {
        type = "fixed",
        fixed = {
            --funnel walls
            {-0.5, 0.0, 0.4, 0.5, 0.5, 0.5},
            {0.4, 0.0, -0.5, 0.5, 0.5, 0.5},
            {-0.5, 0.0, -0.5, -0.4, 0.5, 0.5},
            {-0.5, 0.0, -0.5, 0.5, 0.5, -0.4},
            --funnel base
            {-0.5, 0.0, -0.5, 0.5, 0.1, 0.5},
            --spout
            {-0.3, -0.3, -0.3, 0.3, 0.0, 0.3},
            {-0.7, -0.3, -0.15, 0.15, 0.0, 0.15},
        },
    },
    selection_box = {
        type = "fixed",
        fixed = {
            --funnel
            {-0.5, 0.0, -0.5, 0.5, 0.5, 0.5},
            --spout
            {-0.3, -0.3, -0.3, 0.3, 0.0, 0.3},
            {-0.7, -0.3, -0.15, 0.15, 0.0, 0.15},
        },
    },

    on_construct = function(pos)
        local inv = get_meta(pos):get_inventory()
        inv:set_size("main", 4*4)
        get_node_timer(pos):start(0.1)
    end,

    on_timer = do_hopper_function,

    on_place = function(itemstack, placer, pointed_thing)
        return hopper_on_place(itemstack, placer, pointed_thing, "hopper:hopper_side")
    end,

    can_dig = function(pos)
        local inv = get_meta(pos):get_inventory()
        return inv:is_empty("main")
    end,

    on_rightclick = function(pos, _, clicker)
        if is_protected(pos, clicker:get_player_name()) and not check_player_privs(clicker, "protection_bypass") then
            return
        end
        show_formspec(clicker:get_player_name(),
            "hopper_formspec:"..pos_to_string(pos), get_hopper_formspec(pos))
    end,
})


-- The chute node


local function get_chute_formspec(pos)
    local spos = get_string_pos(pos)
    local formspec =
        "size[8,7]"
        .. formspec_bg
        .. "list[nodemeta:" .. spos .. ";main;3,0.3;2,2;]"
        .. get_eject_button_texts(pos, 7, 0.8)
        .. "list[current_player;main;0,2.85;8,1;]"
        .. "list[current_player;main;0,4.08;8,3;8]"
        .. "listring[nodemeta:" .. spos .. ";main]"
        .. "listring[current_player;main]"
    return formspec
end

register_node("hopper:chute", {
    description = "Hopper Chute",
    drop = "hopper:chute",
    groups = {stone = 1, hard = 1, pickaxe = 1, hand = 4,pathable = 1},
    sounds = metal_sounds,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
        "hopper_bottom_16.png^hopper_chute_arrow_16.png",
        "hopper_bottom_16.png^(hopper_chute_arrow_16.png^[transformR180)",
        "hopper_bottom_16.png^(hopper_chute_arrow_16.png^[transformR270)",
        "hopper_bottom_16.png^(hopper_chute_arrow_16.png^[transformR90)",
        "hopper_top_16.png",
        "hopper_bottom_16.png"
    },
    node_box = {
        type = "fixed",
        fixed = {
            {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
            {-0.2, -0.2, 0.3, 0.2, 0.2, 0.7},
        },
    },

    on_construct = function(pos)
        local inv = get_meta(pos):get_inventory()
        inv:set_size("main", 2*2)
    end,

    on_place = function(itemstack, placer, pointed_thing)
        local pos  = pointed_thing.under
        local pos2 = pointed_thing.above
        local x = pos.x - pos2.x
        local z = pos.z - pos2.z

        local returned_stack, success = item_place_node(itemstack, placer, pointed_thing)
        if success then
            local meta = get_meta(pos2)
            meta:set_string("placer", placer:get_player_name())
        end
        return returned_stack
    end,

    can_dig = function(pos)
        local inv = get_meta(pos):get_inventory()
        return inv:is_empty("main")
    end,

    on_rightclick = function(pos, _, clicker)
        if is_protected(pos, clicker:get_player_name()) and not check_player_privs(clicker, "protection_bypass") then
            return
        end
        show_formspec(clicker:get_player_name(),
            "hopper_formspec:"..pos_to_string(pos), get_chute_formspec(pos))
    end,

    on_metadata_inventory_put = function(pos)
        local timer = get_node_timer(pos)
        if not timer:is_started() then
            timer:start(0.1)
        end
    end,

    on_timer = function(pos)
        local meta = get_meta(pos);
        local inv = meta:get_inventory()

        local node = get_node(pos)
        local dir = facedir_to_dir(node.param2)
        local destination_pos = vec_add(pos, dir)
        local output_direction
        if dir.y == 0 then
            output_direction = "horizontal"
        end

        local destination_node = get_node(destination_pos)
        local registered_inventories = get_registered_inventories_for(destination_node.name)
        if registered_inventories ~= nil then
            if output_direction == "horizontal" then
                send_item_to(pos, destination_pos, destination_node, registered_inventories["side"])
            else
                send_item_to(pos, destination_pos, destination_node, registered_inventories["bottom"])
            end
        else
            send_item_to(pos, destination_pos, destination_node)
        end

        if not inv:is_empty("main") then
            get_node_timer(pos):start(1)
        end
    end,
})


-- The sorter node

local facedir_to_bottomdir = {
    [0]={x=0, y=-1, z=0},
    {x=0, y=0, z=-1},
    {x=0, y=0, z=1},
    {x=-1, y=0, z=0},
    {x=1, y=0, z=0},
    {x=0, y=1, z=0},
}

local get_bottomdir = function(facedir)
    return facedir_to_bottomdir[math.floor(facedir/4)]
end

local function get_sorter_formspec(pos)
    local spos = get_string_pos(pos)

    local filter_all = get_meta(pos):get_string("filter_all") == "true"
    local y_displace = 0
    local filter_button_text, filter_button_tooltip, filter_body
    if filter_all then
        filter_body = ""
        filter_button_text = "Selective\nFilter"
        filter_button_tooltip = "This sorter is currently set to try sending all items\nin the direction of the arrow. Click this button\nto enable an item-type-specific filter."
    else
        filter_body = "label[3.7,0;Filter]list[nodemeta:" .. spos .. ";filter;0,0.5;8,1;]"
        filter_button_text = "Filter\nAll"
        filter_button_tooltip = "This sorter is currently set to only send items listed\nin the filter list in the direction of the arrow.\nClick this button to set it to try sending all\nitems that way first."
        y_displace = 1.6
    end

    local formspec =
        "size[8," .. 7 + y_displace .. "]"
        .. formspec_bg
        .. filter_body        
        .. "list[nodemeta:" .. spos .. ";main;3,".. tostring(0.3 + y_displace) .. ";2,2;]"
        .. "button_exit[7,".. tostring(0.8 + y_displace) .. ";1,1;filter_all;".. filter_button_text .. "]tooltip[filter_all;" .. filter_button_tooltip.. "]"
        .. get_eject_button_texts(pos, 6, 0.8 + y_displace)
        .. "list[current_player;main;0,".. tostring(2.85 + y_displace) .. ";8,1;]"
        .. "list[current_player;main;0,".. tostring(4.08 + y_displace) .. ";8,3;8]"
        .. "listring[nodemeta:" .. spos .. ";main]"
        .. "listring[current_player;main]"
    return formspec
end


register_node("hopper:sorter", {
    description = "Sorter",
    groups = {stone = 1, hard = 1, pickaxe = 1, hand = 4,pathable = 1},
    sounds = metal_sounds,
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
            "hopper_bottom_16.png",
            "hopper_top_16.png",
            "hopper_bottom_16.png^hopper_sorter_arrow_16.png^[transformFX^hopper_sorter_sub_arrow_16.png^[transformFX",
            "hopper_bottom_16.png^hopper_sorter_arrow_16.png^hopper_sorter_sub_arrow_16.png",
            "hopper_top_16.png",
            "hopper_bottom_16.png^hopper_sorter_arrow_16.png",
        },
    node_box = {
        type = "fixed",
        fixed = {
            {-0.3, -0.3, -0.4, 0.3, 0.4, 0.4},
            {-0.2, -0.2, 0.4, 0.2, 0.2, 0.7},
            {-0.2, -0.3, -0.2, 0.2, -0.7, 0.2},
        },
    },

    on_construct = function(pos)
        local meta = get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("main", 2*2)
        inv:set_size("filter", 8)
    end,

    on_place = function(itemstack, placer, pointed_thing)
        local pos  = pointed_thing.under
        local pos2 = pointed_thing.above
        local x = pos.x - pos2.x
        local z = pos.z - pos2.z

        local returned_stack, success = item_place_node(itemstack, placer, pointed_thing)
        if success then
            local meta = get_meta(pos2)
            meta:set_string("placer", placer:get_player_name())
        end
        return returned_stack
    end,

    can_dig = function(pos)
        local meta = get_meta(pos);
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,

    on_rightclick = function(pos, _, clicker)
        if is_protected(pos, clicker:get_player_name()) and not check_player_privs(clicker, "protection_bypass") then
            return
        end
        show_formspec(clicker:get_player_name(),
            "hopper_formspec:"..pos_to_string(pos), get_sorter_formspec(pos))
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack)
        if listname == "filter" then
            local inv = get_inventory({type="node", pos=pos})
            inv:set_stack(listname, index, stack:take_item(1))
            return 0
        end
        return stack:get_count()
    end,

    allow_metadata_inventory_take = function(pos, listname, index, stack)
        if listname == "filter" then
            local inv = get_inventory({type="node", pos=pos})
            inv:set_stack(listname, index, ItemStack(""))
            return 0
        end
        return stack:get_count()
    end,

    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count)
        if to_list == "filter" then
            local inv = get_inventory({type="node", pos=pos})
            local stack_moved = inv:get_stack(from_list, from_index)
            inv:set_stack(to_list, to_index, stack_moved:take_item(1))
            return 0
        elseif from_list == "filter" then
            local inv = get_inventory({type="node", pos=pos})
            inv:set_stack(from_list, from_index, ItemStack(""))
            return 0
        end
        return count
    end,

    on_metadata_inventory_put = function(pos)
        local timer = get_node_timer(pos)
        if not timer:is_started() then
            timer:start(0.1)
        end
    end,

    on_timer = function(pos)
        local meta = get_meta(pos);
        local inv = meta:get_inventory()

        -- build a filter list
        local filter_items = nil
        if meta:get_string("filter_all") ~= "true" then
            filter_items = {}
            local filter_inv_size = inv:get_size("filter")
            for i = 1, filter_inv_size do
                local stack = inv:get_stack("filter", i)
                local item = stack:get_name()
                if item ~= "" then
                    filter_items[item] = true
                end
            end
        end

        local node = get_node(pos)
        local dir = facedir_to_dir(node.param2)
        local default_destination_pos = vec_add(pos, dir)
        local default_output_direction
        if dir.y == 0 then
            default_output_direction = "horizontal"
        end

        dir = get_bottomdir(node.param2)
        local filter_destination_pos = vec_add(pos, dir)
        local filter_output_direction
        if dir.y == 0 then
            filter_output_direction = "horizontal"
        end

        local success = false

        local filter_destination_node = get_node(filter_destination_pos)
        local registered_inventories = get_registered_inventories_for(filter_destination_node.name)
        if registered_inventories ~= nil then
            if filter_output_direction == "horizontal" then
                success = send_item_to(pos, filter_destination_pos, filter_destination_node, registered_inventories["side"], filter_items)
            else
                success = send_item_to(pos, filter_destination_pos, filter_destination_node, registered_inventories["bottom"], filter_items)
            end
        else
            success = send_item_to(pos, filter_destination_pos, filter_destination_node, nil, filter_items)
        end

        -- Weren't able to put something in the filter destination, for whatever reason. Now we can start moving stuff forward to the default
        if not success then
            local default_destination_node = get_node(default_destination_pos)
            local registered_inventories = get_registered_inventories_for(default_destination_node.name)
            if registered_inventories ~= nil then
                if default_output_direction == "horizontal" then
                    send_item_to(pos, default_destination_pos, default_destination_node, registered_inventories["side"])
                else
                    send_item_to(pos, default_destination_pos, default_destination_node, registered_inventories["bottom"])
                end
            else
                send_item_to(pos, default_destination_pos, default_destination_node)
            end
        end

        if not inv:is_empty("main") then
            get_node_timer(pos):start(1)
        end
    end,
})


-- Craft recipes

register_craft({
    output = "hopper:hopper",
    recipe = {
        {"main:iron","utility:chest","main:iron"},
        {"","main:iron",""},
    }
})

register_craft({
    output = "hopper:chute",
    recipe = {
        {"main:iron","utility:chest","main:iron"},
    }
})

register_craft({
    output = "hopper:sorter",
    recipe = {
        {"","main:gold",""},
        {"main:iron","utility:chest","main:iron"},
        {"","main:iron",""},
    }
})



-- Formspec handling

register_on_player_receive_fields(function(_, formname, fields)
    if "hopper_formspec:" == string_sub(formname, 1, 16) then
        local pos = string_to_pos(string_sub(formname, 17, -1))
        local meta = get_meta(pos)
        local eject_setting = meta:get_string("eject") == "true"
        local filter_all_setting = meta:get_string("filter_all") == "true"
        if fields.eject then
            if eject_setting then
                meta:set_string("eject", nil)
            else
                meta:set_string("eject", "true")
            end
        end
        if fields.filter_all then
            if filter_all_setting then
                meta:set_string("filter_all", nil)
            else
                meta:set_string("filter_all", "true")
            end
        end
    end
end)
