local get_item_group = minetest.get_item_group
local get_itemdef    = minetest.get_itemdef

local math_ceil  = math.ceil
local math_random = math.random
local ipairs = ipairs
local change_hud
local add_hud
local register_on_player_inventory_action = minetest.register_on_player_inventory_action
local register_allow_player_inventory_action = minetest.register_allow_player_inventory_action
local after = minetest.after
local sound_play = minetest.sound_play
local register_on_joinplayer = minetest.register_on_joinplayer
local register_on_dieplayer = minetest.register_on_dieplayer
local register_node = minetest.register_node
local remove_node = minetest.remove_node
local register_craft = minetest.register_craft
local register_tool = minetest.register_tool
local register_on_mods_loaded = minetest.register_on_mods_loaded

register_on_mods_loaded(function()
    after(0,function()
        change_hud = hud_manager.change_hud
        add_hud = hud_manager.add_hud
    end)
end)

-- These three lists are synchronized to use ipairs
local armor_inventories = {
    "armor_head",
    "armor_torso",
    "armor_legs",
    "armor_feet"
}
local calculation_list = {
    8,
    4,
    6,
    8
}
local group_check = {
    "helmet",
    "chestplate",
    "leggings",
    "boots"
}

local inv
local player_skin
local armor_skin
local skin_element
local armor_absorbtion
local level
local defense
local recalc
local stack
local name
local wear_level
local new_stack
local item


function update_armor_visual(player)
    if not player or (player and not player:is_player()) then return end
    inv = player:get_inventory()

    player_skin = get_skin(player)
    armor_skin = "blank_skin.png"

    for index,inventory_name in ipairs(armor_inventories) do
        stack = inv:get_stack( inventory_name, 1 ):get_name()
        if stack == "" or get_item_group( stack, group_check[ index ] ) <= 0 then goto continue end
        skin_element = get_itemdef(stack, "wearing_texture")
        -- This is a workaround due to the fact that applying a helmet to the player's armor is broken for some reason
        if inventory_name == "armor_head" then
            player_skin = player_skin .. "^" .. skin_element
        else
            armor_skin = armor_skin .. "^" .. skin_element
        end

        ::continue::
    end

    player:set_properties({textures = {player_skin,armor_skin}})
end

function calculate_armor_absorbtion(player)

    if not player or (player and not player:is_player()) then return end

    inv = player:get_inventory()
    armor_absorbtion = 0

    for _,inventory_name in ipairs(armor_inventories) do
        stack = inv:get_stack(inventory_name,1):get_name()
        if stack == "" then goto continue end
        level = get_item_group(stack,"armor_level")
        defense = get_item_group(stack,"armor_defense")
        armor_absorbtion = armor_absorbtion + ( level * defense )
        ::continue::
    end

    if armor_absorbtion > 0 then
        armor_absorbtion = math_ceil(armor_absorbtion/4)
    end
    return(armor_absorbtion)
end

function set_armor_gui(player)
    if not player or (player and not player:is_player()) then return end
    level = calculate_armor_absorbtion(player)
    change_hud({
        player    =  player ,
        hud_name  = "armor_fg",
        element   = "number",
        data      =  level
    })
end

local update_the_armor_visual = update_armor_visual

function damage_armor(player,damage)

    if not player or (player and not player:is_player()) then return end

    inv = player:get_inventory()

    recalc = false

    -- Scan all armor slots
    for index,inventory_name in ipairs(armor_inventories) do
        stack = inv:get_stack(inventory_name,1)
        name = stack:get_name()

        -- 9 is the base armor level, 5 is the level of protection it gives, then subtracted from it's level and type
        -- 9 is the max level + 1 so that the calculation does not multiply into 0
        -- 5 is the max level for different types of armor + 1 so the calculation does not multiply into 0
        wear_level = ( ( 9 - get_item_group( name, "armor_level" ) ) * calculation_list[index] ) * ( 5 - get_item_group( name, "armor_type" ) ) * damage
        stack:add_wear(wear_level)
        inv:set_stack(inventory_name, 1, stack)
        new_stack = inv:get_stack(inventory_name,1):get_name()
        -- If the armor breaks, the armor level needs to be recalculated
        recalc = recalc or new_stack == ""
    end

    if not recalc then return end

    sound_play( "armor_break", {
        to_player = player:get_player_name(),
        gain = 1,
        pitch = math_random( 80, 100 ) / 100 
    })
    update_the_armor_visual(player)
    set_armor_gui(player)
end

register_on_joinplayer(function(player)
    add_hud(player,"armor_bg",{
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "armor_icon_bg.png",
        number = 20,
        size = {x = 24, y = 24},
        offset = {x = (-10 * 24) - 25, y = -(48 + 50 + 39)},
    })
    add_hud(player,"armor_fg",{
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "armor_icon.png",
        number = calculate_armor_absorbtion(player),
        size = {x = 24, y = 24},
        offset = {x = (-10 * 24) - 25, y = -(48 + 50 + 39)},
    })

    inv = player:get_inventory()
    for _,inventory_name in ipairs(armor_inventories) do
        inv:set_size(inventory_name,1)
    end
end)

register_on_dieplayer(function(player)
    set_armor_gui(player)
end)

-- Acceptable list is basically disallowing you to move random items into your armor slots
local acceptable = {
    ["armor_head"]  = true,
    ["armor_torso"] = true,
    ["armor_legs"]  = true,
    ["armor_feet"]  = true,
}
register_on_player_inventory_action(function(player, _, _, inventory_info)
    if not ( acceptable[ inventory_info.from_list ] or acceptable[ inventory_info.to_list ] ) then return end
    after(0,function()
        update_the_armor_visual(player)
        set_armor_gui(player)
    end)
end)

-- Only allow players to put armor in the right slots to stop exploiting chestplates
register_allow_player_inventory_action( function( _, _, inventory, inventory_info )
    for index,inventory_name in ipairs(armor_inventories) do
        if inventory_info.to_list ~= inventory_name then goto continue end
        stack = inventory:get_stack(inventory_info.from_list,inventory_info.from_index)
        item = stack:get_name()
        if get_item_group(item, group_check[index]) == 0 then
            return(0)
        end
        ::continue::
    end
end)

local materials = {
    ["coal"] = 1,
    ["lapis"] = 2,
    ["iron"] = 3,
    ["chain"] = 4,
    ["gold"] = 2,
    ["diamond"] = 5,
    ["emerald"] = 6,
    ["sapphire"] = 7,
    ["ruby"] = 8} --max 8
local armor_type = {
    ["helmet"]=2,
    ["chestplate"]=4,
    ["leggings"]=3,
    ["boots"]=1
} --max 4

local function bool_int(state)
    if state == true then return 1 end
    return 0
end

for material_id,material_level in pairs(materials) do
    for armor_id,armor in pairs(armor_type) do
        register_tool("armor:"..material_id.."_"..armor_id,{
            description = material_id:gsub("^%l", string.upper).." "..armor_id:gsub("^%l", string.upper),
            groups = {
                armor         = 1,
                armor_level   = material_level,
                armor_defense = armor,
                helmet        = bool_int(armor_id == "helmet"),
                chestplate    = bool_int(armor_id == "chestplate"),
                leggings      = bool_int(armor_id == "leggings"),
                boots         = bool_int(armor_id == "boots"),
            },
            inventory_image = material_id.."_"..armor_id.."_item.png",
            stack_max = 1,
            wearing_texture = material_id.."_"..armor_id..".png",
            tool_capabilities = {
                full_punch_interval = 0,
                max_drop_level = 0,
                groupcaps = {
                },
                damage_groups = {

                },
                punch_attack_uses = 0,
            }
        })

        if armor_id == "helmet" then
            register_craft({
                output = "armor:"..material_id.."_"..armor_id,
                recipe = {
                    {"main:"..material_id, "main:"..material_id, "main:"..material_id},
                    {"main:"..material_id, ""                  , "main:"..material_id},
                    {""                  , ""                  , ""                  }
                }
            })
        elseif armor_id == "chestplate" then
            register_craft({
                output = "armor:"..material_id.."_"..armor_id,
                recipe = {
                    {"main:"..material_id, ""                  , "main:"..material_id},
                    {"main:"..material_id, "main:"..material_id, "main:"..material_id},
                    {"main:"..material_id, "main:"..material_id, "main:"..material_id}
                }
            })
        elseif armor_id == "leggings" then
            register_craft({
                output = "armor:"..material_id.."_"..armor_id,
                recipe = {
                    {"main:"..material_id, "main:"..material_id, "main:"..material_id},
                    {"main:"..material_id, ""                  , "main:"..material_id},
                    {"main:"..material_id, ""                  , "main:"..material_id}
                }
            })
        elseif armor_id == "boots" then
            register_craft({
                output = "armor:"..material_id.."_"..armor_id,
                recipe = {
                    {""                  , "", ""                  },
                    {"main:"..material_id, "", "main:"..material_id},
                    {"main:"..material_id, "", "main:"..material_id}
                }
            })
            register_node("armor:"..material_id.."_"..armor_id.."particletexture", {
                description = "NIL",
                tiles = {material_id.."_"..armor_id.."_item.png"},
                groups = {},
                drop = "",
                drawtype = "allfaces",
                on_construct = function(pos)
                    remove_node(pos)
                end,
            })
        end
        
    end
end