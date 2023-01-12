local ipairs                = ipairs
local vec_multiply          = vector.multiply
local get_connected_players = minetest.get_connected_players
local get_node              = minetest.get_node

local pool = {}
local c_flow
local acceleration
local newvel
local flow_dir
local name
local pos
local current_node

-- TODO: try to force the player smoothly to move in the direction
minetest.register_globalstep(function()

    for _,player in ipairs( get_connected_players() ) do

        pos = player:get_pos()
        current_node = get_node(pos).name
        name = player:get_player_name()

        if current_node ~= "main:water" and current_node ~= "main:waterflow" then
            pool[name] = nil
            goto continue
        end

        flow_dir = get_liquid_flow_direction( pos )

        if not flow_dir then
            pool[name] = nil
            goto continue
        end

        -- Buffer continuation
        if not pool[name] then
            acceleration = vec_multiply( flow_dir, 2 )
            player:add_velocity(acceleration)
            pool[name] = flow_dir
            goto continue
        end

        c_flow = pool[name]
        acceleration = vec_multiply( c_flow, 2 )
        player:add_velocity( acceleration )

        newvel = player:get_velocity()

        if newvel.x ~= 0 or newvel.z ~= 0 then goto continue end

        pool[name] = nil

        ::continue::
    end
end)