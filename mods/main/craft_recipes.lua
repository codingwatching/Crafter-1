local ipairs = ipairs
local register_craft = minetest.register_craft

--cooking
register_craft({
    type = "cooking",
    output = "main:diamond",
    recipe = "main:diamondore",
    cooktime = 12,
})
register_craft({
    type = "cooking",
    output = "main:coal 4",
    recipe = "main:coalore",
    cooktime = 3,
})
register_craft({
    type = "cooking",
    output = "main:charcoal",
    recipe = "main:tree",
    cooktime = 2,
})
register_craft({
    type = "cooking",
    output = "main:gold",
    recipe = "main:goldore",
    cooktime = 9,
})
register_craft({
    type = "cooking",
    output = "main:iron",
    recipe = "main:ironore",
    cooktime = 6,
})
register_craft({
    type = "cooking",
    output = "main:stone",
    recipe = "main:cobble",
    cooktime = 2,
})

register_craft({
    type = "cooking",
    output = "main:glass",
    recipe = "main:sand",
    cooktime = 1,
})


--fuel fuel fuel
register_craft({
    type = "fuel",
    recipe = "main:stick",
    burntime = 1,
})
register_craft({
    type = "fuel",
    recipe = "main:sapling",
    burntime = 1,
})
register_craft({
    type = "fuel",
    recipe = "main:paper",
    burntime = 1,
})
register_craft({
    type = "fuel",
    recipe = "main:tree",
    burntime = 24,
})
register_craft({
    type = "fuel",
    recipe = "main:wood",
    burntime = 12,
})
register_craft({
    type = "fuel",
    recipe = "main:leaves",
    burntime = 3,
})
register_craft({
    type = "fuel",
    recipe = "main:coal",
    burntime = 20,
})

register_craft({
    type = "fuel",
    recipe = "main:charcoal",
    burntime = 7,
})
---crafting
register_craft({
    type = "shapeless",
    output = "main:wood 4",
    recipe = {"main:tree"},
})
register_craft({
    type = "shapeless",
    output = "main:sugar 3",
    recipe = {"farming:sugarcane"},
})

register_craft({
    output = "main:stick 4",
    recipe = {
        {"main:wood"},
        {"main:wood"}
    }
})

register_craft({
    output = "main:paper",
    recipe = {
        {"farming:sugarcane","farming:sugarcane","farming:sugarcane"},
    }
})

local tool =     {"coal","wood","stone" ,"lapis","iron","gold","diamond","emerald","sapphire","ruby"}--the tool name
local material = {"coal","wood","cobble","lapis","iron","gold","diamond","emerald","sapphire","ruby"}--material to craft

for id,tool in pairs(tool) do

    
    register_craft({
        output = "main:"..tool.."pick",
        recipe = {
            {"main:"..material[id], "main:"..material[id], "main:"..material[id]},
            {"", "main:stick", ""},
            {"", "main:stick", ""}
        }
    })
    
    register_craft({
        output = "main:"..tool.."shovel",
        recipe = {
            {"","main:"..material[id], ""},
            {"", "main:stick", ""},
            {"", "main:stick", ""}
        }
    })
    
    register_craft({
        output = "main:"..tool.."axe",
        recipe = {
            {"main:"..material[id], "main:"..material[id], ""},
            {"main:"..material[id], "main:stick", ""},
            {"", "main:stick", ""}
        }
    })
    register_craft({
        output = "main:"..tool.."axe",
        recipe = {
            {"", "main:"..material[id], "main:"..material[id]},
            {"", "main:stick", "main:"..material[id]},
            {"", "main:stick", ""}
        }
    })
    
    register_craft({
        output = "main:"..tool.."sword",
        recipe = {
            {"","main:"..material[id], ""},
            {"","main:"..material[id], ""},
            {"", "main:stick", ""}
        }
    })
end

register_craft({
    output = "main:ladder 16",
    recipe = {
        {"main:stick","", "main:stick"},
        {"main:stick","main:stick", "main:stick"},
        {"main:stick", "", "main:stick"}
    }
})

register_craft({
    output = "main:shears",
    recipe = {
        {"","main:iron"},
        {"main:iron",""},
    }
})

register_craft({
    output = "main:bucket",
    recipe = {
        {"main:iron","","main:iron"},
        {"","main:iron",""},
    }
})

--tool repair
register_craft({
    type = "toolrepair",
    additional_wear = -0.02,
})



local raw_material = {"coal","lapis","iron","gold","diamond","emerald","sapphire","ruby"}
for _,name in ipairs(raw_material) do
    register_craft({
        output = "main:"..name.."block",
        recipe = {
            {"main:"..name, "main:"..name, "main:"..name},
            {"main:"..name, "main:"..name, "main:"..name},
            {"main:"..name, "main:"..name, "main:"..name},
        }
    })
    register_craft({
        type = "shapeless",
        output = "main:"..name.." 9",
        recipe = {"main:"..name.."block"},
    })
end