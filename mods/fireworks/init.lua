local colors = {
    "red",
    "white",
    "blue"
}

local colors_halloween = {
    "orange",
    "black"
}

--TODO: internal API to make firework 3d models

local function fireworks_pop(pos)
    for _,color in ipairs(colors) do
        minetest.add_particlespawner({
            amount = 30,
            time = 0.01,
            pos = pos,
            -- exptime = { x = 500, y = 1000 },
            --[[
            vel = {
                min = vector.new(0,0,0),
                max = vector.new(0,0,0)
            },
            attract = {
                kind = "point",
                strength = {-0.1, -0.5},
                origin = pos,
                die_on_contact = false
            },
            ]]
            radius = 1,
            texture = {
                scale_tween = {
                    {x = 20, y = 20},
                    {x = 0, y = 0},
                },
                name = "smoke.png^[colorize:"..color..":255",
                glow = 14,
            },
            --collisiondetection = false,
            --collision_removal = false,
            --vertical = false,
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
            fireworks_pop(self.object:get_pos())
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
