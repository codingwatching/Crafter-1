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
minetest.register_chatcommand("clearinv", {
    params = "[<name>]",
    description = "Clear the inventory of yourself or another player",
    privs = {server = true},
    func = function(name, param)
        local player
        if param and param ~= "" and param ~= name then
            if not check_player_privs(name, {server=true}) then
                return false, "You don't have permission"
                        .. " to clear another player's inventory (missing privilege: server)"
            end
            player = get_player_by_name(param)
            chat_send_player(param, name.." cleared your inventory.")
        else
            player = get_player_by_name(name)
        end

        if player then
            local inventory = player:get_inventory()
            for _,inventory_name in ipairs(inventory_list) do
                inventory:set_list(inventory_name, {})
            end
            
            log("action", name.." clears "..player:get_player_name().."'s inventory")
            return true, "Cleared "..player:get_player_name().."'s inventory."
        else
            return false, "Player must be online to clear inventory!"
        end
    end,
})
