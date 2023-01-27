local register_food = minetest.register_food
local register_craftitem = minetest.register_craftitem

register_food("main:apple",{
    description = "Apple",
    texture = "apple.png",
    satiation=1,
    hunger=2,
})

register_food("main:sugar",{
    description = "Sugar",
    texture = "sugar.png",
    satiation=1,
    hunger=1,
})

register_craftitem("main:stick", {
    description = "Stick",
    inventory_image = "stick.png",
    groups = {stick = 1}
})
register_craftitem("main:paper", {
    description = "Paper",
    inventory_image = "paper.png",
    groups = {paper = 1}
})

register_craftitem("main:coal", {
    description = "Coal",
    inventory_image = "coal.png",
    groups = {coal = 1}
})

register_craftitem("main:charcoal", {
    description = "Charcoal",
    inventory_image = "charcoal.png",
    groups = {coal = 1}
})

register_craftitem("main:iron", {
    description = "Iron",
    inventory_image = "iron.png",
})

register_craftitem("main:gold", {
    description = "Gold",
    inventory_image = "gold.png",
})

register_craftitem("main:diamond", {
    description = "Diamond",
    inventory_image = "diamond.png",
})
register_craftitem("main:flint", {
    description = "Flint",
    inventory_image = "flint.png",
})

register_craftitem("main:lapis", {
    description = "Lapis Lazuli",
    inventory_image = "lapis.png",
})

register_craftitem("main:emerald", {
    description = "Emerald",
    inventory_image = "emerald.png",
})
register_craftitem("main:sapphire", {
    description = "Sapphire",
    inventory_image = "sapphire.png",
})
register_craftitem("main:ruby", {
    description = "Ruby",
    inventory_image = "ruby.png",
})