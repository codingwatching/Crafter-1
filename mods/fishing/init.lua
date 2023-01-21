minetest.register_on_joinplayer(function(player)
    local metatable = getmetatable(player)

    -- Boolean in, store as integer, boolean out    
    function metatable:set_fishing_state(state, silent_line_snap)
        local meta = player:get_meta()

        local current_state = player:get_fishing_state()

        if state == current_state then return end

        if state then

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
                bobber:get_luaentity():reel_in_action()
            end

            metatable.fishing_bobber_entity = nil
            meta:set_int("fishing_state", 0)
        end

    end
    function metatable:get_fishing_state()
        return player:get_meta():get_int("fishing_state") == 1
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
    mesh = "fishing_bobber.obj",
    textures = {"fishing_bobber.png"},
    is_visible = true,
    pointable = false,
    -- Bobber glows in the dark, how nice
    glow = 6
}
bobber.in_water = false
bobber.catch_timer = 0
bobber.fish_on_the_line = false
bobber.first_water_touch = false
bobber.particle_spawner = nil

-- Bobber methods
function bobber:on_activate()
    self.object:set_acceleration( vector.new( 0, -9.81, 0 ) )
end

function bobber:reel_in_action()

    self:delete_particle_spawner()

    local pos = self.object:get_pos()

    -- Only do splash and sound if the thing hit the water
    if self.origin_height then
        -- Have the particles spawn on the surface of the water
        pos.y = math.ceil(self.origin_height) - 0.5

        local amount = 10

        if self.fish_on_the_line then
            amount = 40
        end

        minetest.add_particlespawner({
            time = 0.0001,
            pos = {
                min = vector.subtract(pos, vector.new(0.5,0,0.5)),
                max = vector.add(pos, vector.new(0.5,0,0.5))
            },
            acc = vector.new(0,-9.81, 0),
            vel = {
                min = vector.new(0, 7, 0),
                max = vector.new(0, 8, 0),
            },
            attract = {
                kind = "point",
                strength = {
                    min = -2,
                    max = -2
                },
                origin = pos
            },
            drag = 1.5,
            amount = amount,
            exptime = {
                min = 0.8,
                max = 1.2
            },
            collisiondetection = false,
            collision_removal = false,
            object_collision = false,
            texture = {
                name = "bubble.png",
                alpha_tween = {0.6,0},
                scale_tween = {
                    {x = 1, y = 1},
                    {x = 0, y = 0}
                }
            }
        })
        minetest.sound_play( "splash", {
            pos = pos,
            gain = 1
        })
    else
        minetest.sound_play( "line_break", {
            pos = pos,
            gain = 1
        })
    end
    self.object:remove()
end


function bobber:delete_particle_spawner()
    if self.particle_spawner then
        minetest.delete_particlespawner(self.particle_spawner)
    end
end

function bobber:splash_effect(heavy, extreme)

    self:delete_particle_spawner()

    local pos = self.object:get_pos()

    -- Have the particles spawn on the surface of the water
    pos.y = math.ceil(self.origin_height) - 0.5

    local amount = 5
    local vel = 2
    if heavy and not extreme then
        amount = 30
        vel = 5
    end

    self.particle_spawner = minetest.add_particlespawner({
        pos = {
            min = vector.subtract(pos, vector.new(0.5,0,0.5)),
            max = vector.add(pos, vector.new(0.5,0,0.5))
        },
        acc = vector.new(0,-9.81, 0),
        vel = {
            min = vector.new(0, vel, 0),
            max = vector.new(0, vel + 2, 0),
        },
        attract = {
            kind = "point",
            strength = {
                min = -2,
                max = -2
            },
            origin = pos
        },
        drag = 1.5,
        amount = amount,
        exptime = {
            min = 0.8,
            max = 1.2
        },
        time = 0,
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        texture = {
            name = "bubble.png",
            alpha_tween = {0.6,0},
            scale_tween = {
                {x = 1, y = 1},
                {x = 0, y = 0}
            }
        }
    })
end

function bobber:on_step(dtime, move_result)

    -- Something is glitchy
    if not self.player or not self.player:is_player() then
        self.object:remove()
        return
    end

    local pos = self.object:get_pos()
    local node = minetest.get_node(pos).name
    local in_water = false
    local position_locked = self.position_locked

    if not position_locked and node == "main:water" and not self.fish_on_the_line then
        in_water = true
        local vel = self.object:get_velocity()
        vel = vector.subtract( vector.new( 0, 1, 0 ), vel )
        self.object:set_acceleration(vel)
        if not self.touched_water then
            self.touched_water = true
            self.object:set_velocity(vector.new(0,0,0))
            self.origin_height = pos.y
        end
    end

    -- Make the bobber appear to bob up and down
    if not position_locked and ((not in_water and self.touched_water) or self.fish_on_the_line) then
        local vel = self.object:get_velocity()
        if self.fish_on_the_line then
            vel = vector.subtract( vector.new( 0, -3, 0 ), vel )
        else
            vel = vector.subtract( vector.new( 0, -1, 0 ), vel )
        end
        
        self.object:set_acceleration(vel)
        if not self.first_water_touch then
            self.first_water_touch = true
            self:splash_effect(false)
        end
    end

    -- Handle sinking state of bobber when fish on the line. Overrides two procedures above
    if not position_locked and self.fish_on_the_line and self.origin_height - 0.5 >  pos.y then
        self.object:set_acceleration(vector.new(0,0,0))
        self.object:set_velocity(vector.new(0,0,0))
        self.position_locked = true
    end

    -- Bobber has hit something, this function is automatically inferred because the player
    -- function automatically tells it to call self:reel_in_action()
    if not self.fish_on_the_line and move_result and move_result.collides then
        self.player:set_fishing_state(false)
        return
    end

    -- Bobber is in water and is doing fish biting calculations
    if not self.touched_water then return end

    -- Fish calculation check every 1.5 second
    if self.catch_timer < 1.5 then
        self.catch_timer = self.catch_timer + dtime
        return
    else
        self.catch_timer = 0
    end

    -- Player has a fish on the line
    if not self.fish_on_the_line and math.random() > 0.65 then
        self.fish_on_the_line = true
        self:splash_effect(true)
        minetest.sound_play( "splash", {
            pos = pos,
            gain = 0.6
        })
    -- Fish has escaped!
    elseif self.fish_on_the_line and math.random() > 0.6 then
        self.fish_on_the_line = false
        self:splash_effect(false)
        minetest.sound_play( "fishing_bloop", {
            pos = pos,
            gain = 1
        })
        self.position_locked = false
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