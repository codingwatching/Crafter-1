--this is from https://github.com/HybridDog/builtin_item/blob/e6dfd9dce86503b3cbd1474257eca5f6f6ca71c2/init.lua#L50

local ipairs = ipairs

local tab
local index
local new_pos
local data
local param2
local nd
local par2
local name
local tmp
local c_node


-- Position instructions to step through
local position_instructions = {
    vector.new(-1, 0, 0 ),
    vector.new( 1, 0, 0 ),
    vector.new( 0, 0,-1 ),
    vector.new( 0, 0, 1 )
}


local function get_nodes(pos)
    tab = {}
    index = 1
    for _,checking_position in ipairs(position_instructions) do
        new_pos = vector.add(pos, checking_position)
        tab[index] = {new_pos, minetest.get_node(new_pos)}
        index = index + 1
    end
    return tab
end


local function get_flowing_dir(pos)
    c_node = minetest.get_node(pos).name
    if c_node ~= "main:waterflow" and c_node ~= "main:water" then
        return nil
    end
    param2 = minetest.get_node(pos).param2
    if param2 > 7 then
        return nil
    end
    data = get_nodes(pos)
    if c_node == "main:water" then
        for _,i in pairs(data) do
            nd = i[2]
            name = nd.name
            par2 = nd.param2
            if name == "main:waterflow" and par2 == 7 then
                return(vector.subtract(i[1],pos))
            end
        end
    end
    for _,i in pairs(data) do
        nd = i[2]
        name = nd.name
        par2 = nd.param2
        if name == "main:waterflow" and par2 < param2 then
            return(vector.subtract(i[1],pos))
        end
    end
    for _,i in pairs(data) do
        nd = i[2]
        name = nd.name
        par2 = nd.param2
        if name == "main:waterflow" and par2 >= 11 then
            return(vector.subtract(i[1],pos))
        end
    end
    for _,i in pairs(data) do
        nd = i[2]
        name = nd.name
        par2 = nd.param2
        tmp = minetest.registered_nodes[name]
        if tmp and not tmp.walkable and name ~= "main:waterflow" and name ~= "main:water" then
            return(vector.subtract(i[1],pos))
        end
    end

    return nil
end

function flow(pos)
    return(get_flowing_dir(pos))
end