local colors = {
    "red",
    "white",
    "blue"
}

local colors_halloween = {
    "orange",
    "black"
}

--[[
--TODO: internal API to make firework 3d models

ideas:

spiral fireworks

wavey fireworks

colored fireworks smoke on launch

extra smokey fireworks

3d fireworks model :D

]]


local fireworks_alphabet = {
    a = {
        scale = 1,
        vertices = {
            {
                color = "blue",
                time = { min = 3, max = 3},
                expansion = { min = -3, max = -3 },
                expands = true,
                coords = {
                    vector.new( -1, 0, -1 ),
                    vector.new( -1, 0,  1 ),
                    vector.new(  1, 0,  1 ),
                    vector.new(  1, 0, -1 ),

                }
            },
            {
                color = "blue",
                time = { min = 3, max = 3},
                expansion = { min = -3, max = -3 },
                expands = true,
                coords = {
                    vector.new( -1, 0, 0 ),
                    vector.new(  1, 0, 0 ),
                }
            }
        }
    }
}

-- This is laid out like an opengl vertices buffer slightly tweaked so it's more readable
local test_box = {
    scale = 1,
    vertices = {
        {
            color = "blue",
            -- Allow things to fade at different rates
            time = { min = 3, max = 3},
            expands = false,
            coords = {
                vector.new( -1, 0, -1 ),
                vector.new( -1, 0, 1 ), -- left |
                vector.new( 1, 0, 1 ), -- top -
                vector.new( 1, 0, -1 ), -- right |
                vector.new( -1, 0, -1 ), -- Loops over to bottom -
                -- This includes a duplicate so things like text are possible
            }
        }
    }
}

local function fireworks_debug_pop(pos, mesh)
    local scale = mesh.scale
    local vertices = mesh.vertices

    for _,data_container in ipairs(vertices) do
        local coords = data_container.coords
        local color = data_container.color
        local time = data_container.time
        local expansion = data_container.expansion
        local expands = data_container.expands

        for i = 1,#coords - 1 do

            local min_pos = vector.add(vector.multiply(coords[i], scale), pos)
            local max_pos = vector.add(vector.multiply(coords[i + 1], scale), pos)

            local definition = {}

            
            definition.amount = 30
            definition.time = 0.01
            definition.pos = {
                min = min_pos,
                max = max_pos
            }

            definition.exptime = { min = 1, max = 3 }

            -- Smoke expands and fades out
            definition.texture = {
                scale_tween = {
                    {x = 1, y = 1},
                    {x = 5, y = 5},
                },
                alpha_tween = { 1, 0 },
                name = "smoke.png^[colorize:" .. color .. ":255",
                glow = 14,
            }
            -- Smoke explodes away from the center
            if expands then
                definition.attract = {
                    kind = "point",
                    strength = { min = -5, max = -5 },
                    origin = pos,
                    direction = vector.new(0,1,0),
                    die_on_contact = false
                }
            end
            minetest.add_particlespawner(definition)
        end
    end
end




local function fireworks_pop(pos)
    for _,color in ipairs(colors) do
        minetest.add_particlespawner({
            amount = 30,
            time = 0.01,
            pos = pos,
            exptime = { min = 1, max = 3 },

            radius = 1,

            -- Smoke expands and fades out
            texture = {
                scale_tween = {
                    {x = 1, y = 1},
                    {x = 5, y = 5},
                },
                alpha_tween = { 1, 0 },
                name = "smoke.png^[colorize:"..color..":255",
                glow = 14,
            },
            -- Smoke explodes away from the center
            attract = {
                kind = "point",
                strength = { min = -5, max = -5 },
                origin = pos
            }
        })
    end
    minetest.sound_play("fireworks_pop",{pos=pos,pitch=math.random(80,100)/100,gain=6.0,max_hear_distance = 128})
end


minetest.register_entity("fireworks:rocket", {
    initial_properties = {
        hp_max = 1,
        physical = true,
        collide_with_objects = false,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        visual = "sprite",
        visual_size = {x = 1, y = 1},
        textures = {"fireworks.png"},
        is_visible = true,
        pointable = true,
    },

    timer = 0,
    
    on_activate = function(self, staticdata, dtime_s)
        self.object:set_acceleration(vector.new(0,50,0))
        local pos = self.object:get_pos()
        minetest.add_particlespawner({
            amount = 30,
            time = 1,
            minpos = pos,
            maxpos = pos,
            minvel = vector.new(0,-20,0),
            maxvel = vector.new(0,-20,0),
            minacc = {x=0, y=0, z=0},
            maxacc = {x=0, y=0, z=0},
            minexptime = 1.1,
            maxexptime = 1.5,
            minsize = 1,
            maxsize = 2,
            collisiondetection = false,
            collision_removal = false,
            vertical = false,
            attached = self.object,
            texture = "smoke.png",
        })
        minetest.sound_play("fireworks_launch",{object=self.object,pitch=math.random(80,100)/100})
    end,

    sound_played = false,
    on_step = function(self, dtime)    
        self.timer = self.timer + dtime
        if self.timer >= 1 then
            fireworks_debug_pop(self.object:get_pos(), fireworks_alphabet.a)
            -- fireworks_pop(self.object:get_pos())
            self.object:remove()
        end
    end,
})

minetest.register_craftitem("fireworks:rocket", {
    description = "Fireworks",
    inventory_image = "fireworks.png",
    wield_image = "fireworks.png",
    on_place = function(itemstack, placer, pointed_thing)
        if not pointed_thing.type == "node" then
            return
        end
        
        minetest.add_entity(pointed_thing.above, "fireworks:rocket")

        itemstack:take_item()

        return itemstack
    end,
})

minetest.register_craft({
    type = "shapeless",
    output = "fireworks:rocket",
    recipe = {"main:paper","mob:gunpowder"},
})
