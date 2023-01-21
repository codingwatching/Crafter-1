minetest.register_craft({
    output = "hopper:hopper",
    recipe = {
        {"main:iron","utility:chest","main:iron"},
        {"","main:iron",""},
    }
})

minetest.register_craft({
    output = "hopper:chute",
    recipe = {
        {"main:iron","utility:chest","main:iron"},
    }
})

minetest.register_craft({
    output = "hopper:sorter",
    recipe = {
        {"","main:gold",""},
        {"main:iron","utility:chest","main:iron"},
        {"","main:iron",""},
    }
})