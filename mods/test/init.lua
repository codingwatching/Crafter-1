
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

minetest.register_entity("test:tri", {initial_properties = {
    visual = "mesh",
    mesh = "minimal_triangle.gltf",
    textures = {"snow_man.png"}
}})

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
    on_step = function(self,dtime)
        if self.triggered then return end
        self.timer = self.timer + dtime
        if self.timer > 2 then
            print("triggered")
            self.triggered = true
            self.object:set_animation({x=168,y=188}, 10, 0, true)
        end
    end
})
