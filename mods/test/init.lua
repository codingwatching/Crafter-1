
minetest.register_entity("test:snowman", {initial_properties = {
    visual = "mesh",
    mesh = "snow_man.gltf",
    textures = {"test_snow_man.png"}
}})

minetest.register_entity("test:cube", {initial_properties = {
    visual = "mesh",
    mesh = "blender_cube.gltf",
    textures = {"snow_man.png"}
}})

minetest.register_entity("test:error", {initial_properties = {
    visual = "mesh",
    mesh = "json_missing_brace.gltf",
    textures = {"snow_man.png"}
}})

minetest.register_entity("test:tri", {
	initial_properties = {
        visual = "mesh",
        mesh = "animated_triangle.gltf",
        textures = {"dirt.png"}
    },
    on_activate = function(self)
        print("LUA: TRIGGERED MESH ANIMATION")
        self.object:set_animation({x=0,y=5}, 1, 0, true)
    end,
    time = 0,
    rot = 0,
    on_step = function(self, dtime)
        if self.time > 2 then

            --self.rot = self.rot + (dtime * 500)
            -- self.object:set_bone_position("debug", vector.new(0,0,0), vector.new(0,0,self.rot))
            return
        end
        self.time = self.time + dtime

        if self.time >= 2 then
            -- print("BOOM BABY")
            --minetest.chat_send_all("LET'S PARTY!")
        end
    end
})

--[[
minetest.register_entity("test:spider", {
    initial_properties = {
        visual = "mesh",
        mesh = "spider_animated.gltf",
        textures = {"debug_spider.png"}
    },
    on_activate = function(self)
        print("I am a spider")
        self.object:set_animation({x=0,y=1}, 1, 0, true)
    end,
})
]]

minetest.register_entity("test:spider", {
    initial_properties = {
        visual = "mesh",
        mesh = "spider_animated.gltf",
        textures = {"dirt.png"}
    },
    on_activate = function(self)
        self.object:set_animation({x=0,y=120}, 24, 0, true)
    end,
})

minetest.register_entity("test:simp", {
    initial_properties = {
        visual = "mesh",
        mesh = "ultra_simple.gltf",
        textures = {"dirt.png"}
    },
    on_activate = function(self)
        self.object:set_animation({x=0,y=50}, 24, 0, true)
    end,
})

minetest.register_entity("test:bendy", {
    initial_properties = {
        visual = "mesh",
        mesh = "magical_bendy_boi.gltf",
        textures = {"dirt.png"}
    },
    on_activate = function(self)
        self.object:set_animation({x=0,y=7}, 1, 0, true)
    end,
})

minetest.register_entity("test:sb", {
    initial_properties = {
        visual = "mesh",
        mesh = "simple_bendy_boi.gltf",
        textures = {"dirt.png"}
    },
    on_activate = function(self)
        self.object:set_animation({x=0,y=7}, 1, 0, true)
    end,
})

minetest.register_entity("test:archy", {
    initial_properties = {
        visual = "mesh",
        mesh = "archfan_bendy.gltf",
        textures = {"dirt.png"}
    },
    on_activate = function(self)
        self.object:set_animation({x=0,y=40}, 24, 0, true)
    end,
})

minetest.register_entity("test:simple", {
    initial_properties = {
        visual = "mesh",
        mesh = "simple_animated.gltf",
        textures = {"dirt.png"}
    },
    on_activate = function(self)
        self.object:set_animation({x=0,y=132}, 24, 0, true)
    end,
})


minetest.register_entity("test:debug_cube", {initial_properties = {
    visual = "mesh",
    mesh = "debug_cube.gltf",
    textures = {"debug_cube.png"}
}})




minetest.register_entity("test:c", {
    initial_properties = {
        visual = "mesh",
        mesh = "debug_character.gltf",
        textures = {"debug_character.png"}
    },
    triggered = false,
    timer = 0,
    on_activate = function(self)
        -- self.object:set_animation({x=168,y=188}, 10, 0, true)
        -- self.object:set_animation({x=0,y=0}, 10, 0, true)
    end
})
