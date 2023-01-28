
minetest.register_entity("test:snowman", {initial_properties = {
    visual = "mesh",
    mesh = "snow_man.gltf",
    textures = {"snow_man.png"}
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