local mod_path = minetest.get_modpath( minetest.get_current_modname() )

local formspec_bg = "background[-0.19,-0.25;9.41,9.49;gui_hb_bg.png]"


local neighbors = {}
local groups = {}
local containers = {}

-- global function to add new containers
local function add_container(list)
    for _, entry in pairs(list) do
        local target_node = entry[2]
        local neighbor_node
        if string.sub(target_node, 1, 6) == "group:" then

            local group_identifier, group_number
            local equals_index = string.find(target_node, "=")

            if equals_index ~= nil then
                group_identifier = string.sub(target_node, 7, equals_index-1)
                -- it's possible that the string was of the form "group:blah = 1", in which case we want to trim spaces off the end of the group identifier
                local space_index = string.find(group_identifier, " ")
                if space_index ~= nil then
                    group_identifier = string.sub(group_identifier, 1, space_index-1)
                end
                group_number = tonumber(string.sub(target_node, equals_index+1, -1))
            else
                group_identifier = string.sub(target_node, 7, -1)
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
            -- result is a table of the form groups[group_identifier][group_number][relative_position][inventory_name]
        else
            local node_info = containers[target_node]
            if node_info == nil then
                node_info = {}
            end
            node_info[entry[1]] = entry[3]
            containers[target_node] = node_info
            neighbor_node = target_node
            -- result is a table of the form containers[target_node_name][relative_position][inventory_name]
        end
        
        local already_in_neighbors = false
        for _, value in pairs(neighbors) do
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
-- "bottom" indicates what inventory the hopper will put items into if this node is located at the hopper's narrow end and either above or below the hopper.
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
    local output = hopper.containers[target_node_name]
    if output ~= nil then return output end

    local target_def = minetest.registered_nodes[target_node_name]
    if target_def == nil or target_def.groups == nil then return nil end

    for group, value in pairs(target_def.groups) do
        local registered_group = hopper.groups[group]
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
    if minetest.get_meta(pos):get_string("eject") == "true" then
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
        return minetest.get_player_by_name(player_name) or {
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
    local target_def = minetest.registered_nodes[target_node.name]
    if not target_def then
        return
    end

    --hopper inventory
    local hopper_meta = minetest.get_meta(hopper_pos);
    local hopper_inv = hopper_meta:get_inventory()
    local placer = get_placer(hopper_meta:get_string("placer"))

    --source inventory
    local target_inv = minetest.get_meta(target_pos):get_inventory()
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
    local hopper_meta = minetest.get_meta(hopper_pos)
    local target_def = minetest.registered_nodes[target_node.name]
    if not target_def then
        return false
    end

    local eject_item = hopper_meta:get_string("eject") == "true" and target_def.buildable_to

    if not eject_item and not target_inventory_name then
        return false
    end

    --hopper inventory
    local hopper_meta = minetest.get_meta(hopper_pos);
    local hopper_inv = hopper_meta:get_inventory()
    if hopper_inv:is_empty("main") == true then
        return false
    end
    local hopper_inv_size = hopper_inv:get_size("main")
    local placer = get_placer(hopper_meta:get_string("placer"))

    --target inventory
    local target_inv = minetest.get_meta(target_pos):get_inventory()

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
                minetest.add_item(target_pos, stack_to_put)
                hopper_inv:set_stack("main", i, stack)
                return true
            end
        end
    end
    return false
end

dofile( mod_path .. "/nodes/hoppers.lua" )
dofile( mod_path .. "/nodes/chute.lua" )
dofile( mod_path .. "/nodes/sorter.lua" )
dofile( mod_path .. "/crafts.lua" )
dofile( mod_path .. "/abms.lua" )


-------------------------------------------------------------------------------------------
-- Formspec handling

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if "hopper_formspec:" == string.sub(formname, 1, 16) then
        local pos = minetest.string_to_pos(string.sub(formname, 17, -1))
        local meta = minetest.get_meta(pos)
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
