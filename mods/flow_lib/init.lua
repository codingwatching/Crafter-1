--this is from https://github.com/HybridDog/builtin_item/blob/e6dfd9dce86503b3cbd1474257eca5f6f6ca71c2/init.lua#L50

local ipairs = ipairs

local index
local new_pos
local data
local param2
local nd
local par2
local name
local tmp
local node_name
local gotten_node


-- Position instructions to step through
local position_instructions = {
    vector.new(-1, 0, 0 ),
    vector.new( 1, 0, 0 ),
    vector.new( 0, 0,-1 ),
    vector.new( 0, 0, 1 )
}


local function get_nodes(pos)
    data = {}
    index = 1
    for _,checking_position in ipairs(position_instructions) do
        new_pos = vector.add(pos, checking_position)
        data[index] = {new_pos, minetest.get_node(new_pos)}
        index = index + 1
    end
end


local function get_flowing_dir(pos)

    gotten_node = minetest.get_node(pos)

    node_name = gotten_node.name

    if node_name ~= "main:waterflow" and node_name ~= "main:water" then return nil end

    param2 = gotten_node.param2

    if param2 > 7 then
        return nil
    end

    get_nodes(pos)

    if node_name ~= "main:water" then goto skip end

    for _,i in ipairs(data) do
        nd = i[2]
        name = nd.name
        par2 = nd.param2
        if name == "main:waterflow" and par2 == 7 then
            return(vector.subtract(i[1],pos))
        end
    end

    ::skip::

    for _,i in ipairs(data) do
        nd = i[2]
        name = nd.name
        par2 = nd.param2
        if name == "main:waterflow" and par2 < param2 then
            return(vector.subtract(i[1],pos))
        end
    end

    for _,i in ipairs(data) do
        nd = i[2]
        name = nd.name
        par2 = nd.param2
        if name == "main:waterflow" and par2 >= 11 then
            return(vector.subtract(i[1],pos))
        end
    end

    for _,i in ipairs(data) do
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