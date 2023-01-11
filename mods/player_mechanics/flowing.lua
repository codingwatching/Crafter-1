local ipairs                = ipairs
local vec_new               = vector.new
local vec_multiply          = vector.multiply
local get_connected_players = minetest.get_connected_players

local pool = {}
local c_flow
local acceleration
local newvel
local flow_dir
local name

-- TODO: try to force the player smoothly to move in the direction
minetest.register_globalstep(function()

    for _,player in ipairs( get_connected_players() ) do

        flow_dir = get_liquid_flow_direction( player:get_pos() )

        name = player:get_player_name()

        if not flow_dir then
            pool[name] = nil
            goto continue
        end

        -- Buffer continuation
        if not pool[name] then
            acceleration = vec_multiply( flow_dir, 0.2 )
            player:add_velocity(acceleration)
            pool[name] = flow_dir
            goto continue
        end

        c_flow = pool[name]
        acceleration = vec_multiply( c_flow, 0.2 )
        player:add_velocity( acceleration )

        newvel = player:get_velocity()

        if newvel.x ~= 0 or newvel.z ~= 0 then goto continue end

        pool[name] = nil

        ::continue::
    end
end)