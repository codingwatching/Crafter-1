minetest.register_on_joinplayer(function(player)
    local metatable = getmetatable(player)

    -- Boolean in, store as integer, boolean out    
    function metatable:set_fishing_state(state, silent_line_snap)
        local meta = player:get_meta()

        local current_state = player:get_fishing_state()

        if state == current_state then return end

        if state then
            -- Generate a player's casting thing here

            local pos = player:get_pos()
            -- TODO: Get camera offset
            pos.y = pos.y + 1.625

            local dir = player:get_look_dir()
            local force = vector.multiply(dir,20)
            local bobber = minetest.add_entity(pos,"fishing:bobber")

            if bobber then
                minetest.sound_play( "woosh", {
                    pos = pos
                })
                bobber:get_luaentity().player = player
                bobber:set_velocity(force)
            else
                minetest.log("action", "WARNING: Failed to spawn a fishing bobber for " .. player:get_player_name())
                return
            end

            metatable.fishing_bobber_entity = bobber
            meta:set_int("fishing_state", 1)

        else
            -- Remove the player's lure and disable casting here
            local bobber = metatable.fishing_bobber_entity

            if bobber and bobber:get_luaentity() then
                bobber:reel_in_action()
                bobber:remove()
            end

            metatable.fishing_bobber_entity = nil
            meta:set_int("fishing_state", 0)
        end

    end
    function metatable:get_fishing_state()
        return player:get_meta():get_int("currently_fishing") == 1
    end
    -- Easy method for one lining the fishing state
    function metatable:toggle_fishing_state()
        local current_state = player:get_fishing_state()
        player:set_fishing_state(not current_state)

    end

    -- Remove the lure when a player joins
    player:set_fishing_state(false, true)
end)

minetest.register_on_dieplayer(function(player)
    -- Remove the lure when a player dies while fishing
    player:set_fishing_state(false, true)
end)

minetest.register_node("fishing:pole", {
    description = "Fishing Pole",
    drawtype = "mesh",
    mesh = "fishing_pole.obj",
    tiles = {
        "fishing_pole.png"
    },
    node_placement_prediction = "",
    stack_max = 1,
    on_place = function(_, player)
        player:toggle_fishing_state()
    end,
    on_secondary_use = function(_, player)
        player:toggle_fishing_state()
    end,
})

minetest.register_craft({
    output = "fishing:pole",
    recipe = {
        {"", "", "main:stick"},
        {"", "main:stick", "mob:string"},
        {"main:stick", "", "mob:string"},
    }
})

-- Bobber class
local bobber = {}

-- Bobber fields
bobber.initial_properties = {
    physical = true,
    collide_with_objects = false,
    collisionbox = {-0.1, 0, -0.1, 0.1, 0.2, 0.1},
    visual = "mesh",
    visual_size = {x = 0.25, y = 0.25},
    mesh = "fishing_bobber.obj",
    textures = {"fishing_bobber.png"},
    is_visible = true,
    pointable = false,
    -- Bobber glows in the dark, how nice
    glow = 6
}
bobber.in_water = false
bobber.interplayer = nil
bobber.catch_timer = 0

-- Bobber methods
function bobber:on_activate()
    self.object:set_acceleration( vector.new( 0, -9.81, 0 ) )
end

function bobber:on_step(dtime, move_result)

    local pos = self.object:get_pos()
    local node = minetest.get_node(pos).name
    local in_water = false

    -- Waterflow to allow people to fish in rivers
    if node == "main:water" or node == "main:waterflow" then
        in_water = true
        local vel = self.object:get_velocity()
        self.object:add_velocity(vector.subtract(vel, vector.new(0,10,0)))
    else
        pos.y = pos.y - 0.5
        node = minetest.get_node(pos).name
        if node == "main:water" or node == "main:waterflow" then
            in_water = true
        end
    end

    --[[
        local newp = table.copy(pos)

        newp.y = newp.y - 0.1

        local node = minetest.get_node(newp).name

        if node ~= "air" and node ~= "main:water" and node ~= "main:waterflow" then

            if self.player then

                players_fishing[self.player] = nil

            end
            
            minetest.sound_play("line_break",{pos=pos,gain=0.3})
            self.object:remove()
        end
    end
    ]]

    if self.in_water == true then
        do return end
        if self.player then
            local p = minetest.get_player_by_name(self.player)
            if p:get_player_control().RMB then
                local pos2 = p:get_pos()
                local vel = vector.direction(vector.new(pos.x,0,pos.z),vector.new(pos2.x,0,pos2.z))
                self.object:set_velocity(vector.multiply(vel,2))


                self.catch_timer = self.catch_timer + dtime

                if self.catch_timer >= 0.5 then
                    self.catch_timer = 0
                    if math.random() > 0.94 then
                        local obj = minetest.add_item(pos, "fishing:fish")
                        if obj then
                            local distance = vector.distance(pos,pos2)
                            local dir = vector.direction(pos,pos2)
                            local force = vector.multiply(dir,distance)
                            force.y = 6
                            obj:set_velocity(force)
                            minetest.sound_play("splash",{pos=obj:get_pos(),gain=0.25})
                        end
                        players_fishing[self.player] = nil
                        self.object:remove()
                    end
                end
            else
                self.object:set_velocity(vector.new(0,0,0))
            end
            if p then
                local pos2 = p:get_pos()
                if vector.distance(vector.new(pos.x,0,pos.z),vector.new(pos2.x,0,pos2.z)) < 1 then
                    players_fishing[self.player] = nil
                    minetest.sound_play("line_break",{pos=pos,gain=0.3,pitch=0.5})
                    self.object:remove()
                end
            end
        end
    end
    if self.player == nil then
        self.object:remove()
    end
end
minetest.register_entity("fishing:bobber", bobber)

minetest.register_craft({
    type = "cooking",
    output = "fishing:fish_cooked",
    recipe = "fishing:fish",
})

minetest.register_food("fishing:fish",{
    description = "Raw Fish",
    texture = "fish.png",
    satiation=6,
    hunger=3,
})

minetest.register_food("fishing:fish_cooked",{
    description = "Cooked Fish",
    texture = "fish_cooked.png",
    satiation=22,
    hunger=5,
})