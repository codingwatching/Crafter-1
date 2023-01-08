local ipairs = ipairs

local pool = {}

local c_flow
local acceleration
local newvel
local flow_dir
local name
minetest.register_globalstep(function()

    for _,player in ipairs( minetest.get_connected_players() ) do

        flow_dir = flow( player:get_pos() )

        name = player:get_player_name()

        if not flow_dir then
            pool[name] = nil
            return
        end

        -- Buffer continuation
        if pool[name] then
            c_flow = pool[name]
            acceleration = nil
            if c_flow.x ~= 0 then
                acceleration = vector.new(c_flow.x,0,0)
            elseif c_flow.z ~= 0 then
                acceleration = vector.new(0,0,c_flow.z)
            end
            acceleration = vector.multiply(acceleration, 0.075)
            player:add_velocity(acceleration)

            newvel = player:get_velocity()

            if newvel.x ~= 0 or newvel.z ~= 0 then
                return
            else
                pool[name] = nil
            end
        else
            flow_dir = vector.multiply(flow_dir,10)
            acceleration = nil
            if flow_dir.x ~= 0 then
                acceleration = vector.new(flow_dir.x,0,0)
            elseif flow_dir.z ~= 0 then
                acceleration = vector.new(0,0,flow_dir.z)
            end
            acceleration = vector.multiply(acceleration, 0.075)
            player:add_velocity(acceleration)
            pool[name] = flow_dir
        end
    end
end)


--coal armor stops fire from hurting you