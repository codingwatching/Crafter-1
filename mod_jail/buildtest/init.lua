minetest.register_node("buildtest:glass_pipe", {
    description = "Glass Pipe",
    tiles = {"glass_pipe.png"},
    groups = {glass = 1},
    sounds = main.stoneSound(),
    drawtype = "nodebox",
    paramtype = "light",
    sunlight_propagates = true,
    connects_to = {"buildtest:glass_pipe","hopper:hopper"},
    node_box = {
        type = "connected",
        -- {x1, y1, z1, x2, y2, z2}
        disconnected  = {
            {-3/16,-3/16,-3/16,3/16,3/16,3/16}
            },
        connect_top = {
            {-3/16,-3/16,-3/16,3/16,8/16,3/16}
            },
        connect_bottom = {
            {-3/16,-8/16,-3/16,3/16,3/16,3/16}
            },
            
            
        connect_left = {
            {-8/16,-3/16,-3/16,3/16,3/16,3/16}
            },
        connect_right = {
            {-3/16,-3/16,-3/16,8/16,3/16,3/16}
            },    
        connect_front = {
            {-3/16,-3/16,-8/16,3/16,3/16,3/16}
            },
        
        connect_back = {
            {-3/16,-3/16,-3/16,3/16,3/16,8/16}
            },
    },
})

minetest.register_craft({
    output = "buildtest:glass_pipe 20",
    recipe = {
        {"main:glass","","main:glass"},
        {"main:glass","","main:glass"},
        {"main:glass","","main:glass"},
    }
})
