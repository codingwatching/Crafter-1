local ipairs = ipairs
local get_player_by_name = minetest.get_player_by_name
local check_player_privs = minetest.check_player_privs
local log = minetest.log
local chat_send_player = minetest.chat_send_player

local inventory_list = {
    "main",
    "craft",
    "craftpreview",
    "armor_head",
    "armor_torso",
    "armor_legs",
    "armor_feet"
}

-- Clearinv allows the player to clear their own inventory in case they did something dumb
-- This also allows admins to clear other player's inventory in case they are cheating
minetest.register_chatcommand("clearinv", {
    params = "[<name>]",
    description = "Clear the inventory of yourself or another player",
    privs = {},
    func = function(name, target_name)
        local player
        if target_name and target_name ~= "" and target_name ~= name then
            if not check_player_privs(name, {server=true}) then
                return false, "You don't have permission to clear another player's inventory! (missing privilege: server)"
            end
            player = get_player_by_name(target_name)
            chat_send_player(target_name, name.." cleared your inventory.")
        else
            player = get_player_by_name(name)
        end

        if not player then return end

        if player then
            local inventory = player:get_inventory()
            for _,inventory_name in ipairs(inventory_list) do
                inventory:set_list(inventory_name, {})
            end
            
            if name == target_name then
                log("action", name .. " cleared their own inventory.")
                return true, "Cleared "..player:get_player_name().."'s inventory."
            else
                log("action", name.." cleared "..player:get_player_name().."'s inventory.")
                return true, "Cleared "..player:get_player_name().."'s inventory."
            end
        else
            return false, "Player must be online to clear inventory!"
        end
    end,
})

-- Allows player to instantly die
minetest.register_chatcommand("suicide", {
    params = "",
    description = "Kill yourself instantly",
    privs = {},
    func = function(name)
        local player = get_player_by_name(name)
        if not player then return end
        player:set_hp(-1)
    end
})

-- Allows player to instantly die
-- Allows server admins to kill players that are misbehaving
minetest.register_chatcommand("kill", {
    params = "[<name>]",
    description = "Kill yourself instantly",
    -- Don't need the privs to kill themself but they need to have the privs to kill another player
    privs = {},
    func = function(name, target_name)

        local player

        if target_name and target_name ~= "" and target_name ~= name then
            if not check_player_privs(name, {server=true}) then
                return false, "You don't have permission to kill another player! (missing privilege: server)"
            end
            player = get_player_by_name(target_name)
            chat_send_player(target_name, name.." cleared your inventory.")
        else
            player = get_player_by_name(name)
        end

        if not player then return end
    end
})