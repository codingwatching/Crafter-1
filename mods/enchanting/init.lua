local pairs = pairs
local after = minetest.after
local itemstring_with_color = minetest.itemstring_with_color
local registered_tools = minetest.registered_tools

--[[
swiftness - how fast you mine
hardness - allows the tool to go way above it's level
durable - makes the tool last longer
slippery - you drop the tool randomly
careful - "not silk touch"
fortune - drops extra items and experience
autorepair - tool will repair itself randomly
spiky - the tool will randomly hurt you when used
sharpness - the tool does more damage
]]--

-- TODO: Make a GUI for this

local enchantment_list = {
    "swiftness",
    "durable",
    "careful",
    "fortune",
    "autorepair",
    "sharpness"
}

local temp_names = {
    "Monster",
    "Behemoth",
    "Ultra",
    "Wow!",
    "Oh Em Gee",
    "The Ultimatum",
    "Holy Moly!",
    "Infinity"
}

local hexer = {"a","b","c","d","e","f","1","2","3","4","5","6","7","8","9","0"}

minetest.register_node("enchanting:table", {
    description = "Enchanting Table",
    tiles = {"bedrock.png"},
    groups = { wood = 1, pathable = 1 },
    sounds = main.stoneSound(),
    is_ground_content = false,

    on_rightclick = function(_, _, clicker, itemstack)

        after(0,function()

            local stack = clicker:get_wielded_item()

            local meta = stack:get_meta()

            if meta:get_int("enchanted") > 0 then return end

            local tool_definition = registered_tools[itemstack:get_name()]

            if tool_definition then return end

            local tool_caps = itemstack:get_tool_capabilities()

            local groupcaps = tool_caps.groupcaps

            if not groupcaps then return end

            local player_level = get_player_xp_level(clicker)

            local enchants_available = math.floor( player_level / 5 )

            local max_enchant_level = math.floor( player_level / 5 )

            if enchants_available <= 0 then return end

            if enchants_available > 3 then enchants_available = 3 end

            local description = tool_definition.description

            for _ = 1,enchants_available do

                local new_enchant = enchantment_list[ math.random( 1, #enchantment_list ) ]

                local level = math.random( 1, max_enchant_level )

                if meta:get_int(new_enchant) == 0 then

                    player_level = player_level - 5

                    meta:set_int( new_enchant, level )

                    description = description .. "\n" .. new_enchant:gsub("^%l", string.upper) .. ": " .. tostring(level)

                    if new_enchant == "swiftness" then
                        for index,current_cap in pairs(groupcaps) do
                            for index2,time in pairs(current_cap.times) do
                                tool_caps["groupcaps"][index]["times"][index2] = time / ( level + 1 )
                            end
                        end
                    end

                    if new_enchant == "durable" then
                        for index,current_cap in pairs(groupcaps) do
                            tool_caps["groupcaps"][index]["uses"] = current_cap.uses * ( level + 1 )
                        end
                    end

                    if new_enchant == "sharpness" then
                        for index,data in pairs(tool_caps.damage_groups) do
                            tool_caps.damage_groups[index] = data*(level+1)
                        end
                    end

                end

            end

            meta:set_string( "description", "Enchanted " .. description )
            meta:set_int( "enchanted", 1 )
            meta:set_tool_capabilities(tool_caps)

            set_player_xp_level(clicker,player_level)

            -- Create random colorstring
            local colorstring = "#"
            for _ = 1,6 do
                colorstring = colorstring .. hexer[ math.random( 1, 16 ) ]
            end

            stack = itemstring_with_color(stack, colorstring)
            clicker:set_wielded_item(stack)
        end)
    end
})

minetest.register_craft({
    output = "enchanting:table",
    recipe = {
        { "nether:obsidian", "nether:obsidian", "nether:obsidian" },
        { "nether:obsidian", "main:diamond", "nether:obsidian" },
        { "nether:obsidian", "nether:obsidian", "nether:obsidian" },
    },
})
