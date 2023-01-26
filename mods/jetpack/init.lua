

minetest.register_tool("jetpack:jetpack",{
    description = "Jetpack",

    groups = {chestplate = 1,},
    inventory_image = "jetpack_item.png",
    stack_max = 1,
    wearing_texture = "jetpack.png",
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

local sound_handling_loop = {}

local player_name
local inv
local stack
local name
local controls
local additive_height_velocity = vector.new(0,1,0)
local currentvel
local goal
local acceleration

minetest.register_globalstep(function()

    for _,player in ipairs(minetest.get_connected_players()) do

        if player:get_hp() <= 0 then goto continue end

        player_name = player:get_player_name()

        controls = player:get_player_control()

        -- Player is jetpacking, wooo
        if controls.jump or controls.sneak then

            inv = player:get_inventory()
            stack = inv:get_stack("armor_torso",1)
            name = stack:get_name()

            if name ~= "jetpack:jetpack" then goto continue end

            -- Boost upwards
            if player:get_player_control().jump and player:get_velocity().y < 20 then

                player:add_velocity(additive_height_velocity)
                player:set_physics_override( { gravity = 1.25 } )

            -- Hover at current height
            elseif player:get_player_control().sneak then

                currentvel = player:get_velocity()
                acceleration = vector.new(0,-currentvel.y,0)

                acceleration = vector.multiply(acceleration, 0.05)
                player:add_velocity(acceleration)
                player:set_physics_override( { gravity = 0 } )
            end

            --[[ TODO: replace this with attached particle spawner
            local particle_pos = player:get_pos()
            local yaw = player:get_look_horizontal()
            local p_dir = vector.divide(minetest.yaw_to_dir(yaw + math.pi),8)
            particle_pos.y = particle_pos.y + 0.7
            particle_pos = vector.add(particle_pos,p_dir)


            minetest.add_particle({
                pos = particle_pos,
                velocity = {x=0, y=-20+player:get_velocity().y , z=0},
                acceleration = {x=math.random(-1,1), y=0, z=math.random(-1,1)},
                expirationtime = 1+math.random(),
                size = 1+math.random(),
                texture = "smoke.png",
            })

            ]]

            stack:add_wear(4)
            inv:set_stack("armor_torso", 1, stack)

            if not sound_handling_loop[player_name] then
                sound_handling_loop[player_name] = minetest.sound_play( "jetpack", { object = player, loop = true, gain = 0.3 } )
            end

            if stack:get_name() == "" then
                update_armor_visual(player)
                set_armor_gui(player)
                player:set_physics_override({gravity=1.25})
                if sound_handling_loop[player_name] then
                    minetest.sound_play( "armor_break", { object = player, gain = 1, pitch = math.random( 80, 100 ) / 100 } )
                    minetest.sound_fade(sound_handling_loop[player_name], -1, 0)
                    sound_handling_loop[player_name] = nil
                end
            end
        -- Turn off the jetpack sound and restore gravity
        elseif sound_handling_loop[player_name] then
            player:set_physics_override( { gravity = 1.25 } )
            minetest.sound_stop(sound_handling_loop[player_name])
            sound_handling_loop[player_name] = nil
        end

        ::continue::
    end
end)

minetest.register_craft({
    output = "jetpack:jetpack",
    recipe = {
        {"main:iron" , "main:gold" , "main:iron" },
        {"main:iron" , "main:diamond" , "main:iron" },
        {"redstone:piston_off" , "redstone:dust", "redstone:piston_off" }
    }
})