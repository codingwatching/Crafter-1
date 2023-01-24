local getmetatable = getmetatable

local player_huds = {}

-- Set up initial data container
minetest.register_on_joinplayer(function(player)
    local metatable = getmetatable(player)
    local name = player:get_player_name()
    player_huds[name] = {}
    -- Heap pointer object becomes bound to this player's methods
    local data_container = player_huds[name]

    function metatable:add_hud( hud_name, def )
        local gotten_id = data_container[hud_name]
        if gotten_id ~= nil then return end
        -- The value gets stored as so: table["key"] = 1 -- or whatever the number is
        data_container[hud_name] = player:hud_add({
            hud_elem_type = def.hud_elem_type,
            position      = def.position,
            text          = def.text,
            number        = def.number,
            direction     = def.direction,
            size          = def.size,
            offset        = def.offset,
        })
    end

    function metatable:remove_hud(hud_name)
        local gotten_id = data_container[hud_name]
        if not gotten_id then return end
        player:hud_remove(gotten_id)
        data_container[hud_name] = nil
    end

    function metatable:change_hud(hud_name, data)
        local gotten_id = data_container[hud_name]
        if not gotten_id then return end
        player:hud_change( data_container[hud_name], data.element, data.data )
    end

    function metatable:hud_exists(hud_name)
        return data_container[hud_name] ~= nil
    end

    function metatable:delete_hud_data_container()
        player_huds[name] = nil
    end
end)

-- Remove the player's data container
minetest.register_on_leaveplayer(function(player)
    player:delete_hud_data_container()
end)
