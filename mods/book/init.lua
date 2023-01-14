-- An important note: This does not reuse heap objects because strings can be very HUGE and it's not high performance. Does not need to be

--[[
    TODO:
    1. consolidate the function logic into separate functions because this is a lot of code
        
    2. Make the sounds play either attached to the player or at the node's position so it's more interactive in multiplayer

    3. update the item's description to match the title of the book

    3. make books placable on the ground
    3.a make a nice looking node that represents a book
    4.Maybe make a book animation for when it's opening?
    5.Maybe dye books?
]]

-- Cause why not
local MAX_BOOK_PAGES = 64

-- These are functions to clarify the state of the function's procedure
local function play_book_open_sound_to_player( author )
    minetest.sound_play( "book_open", {
        to_player = author:get_player_name()
    })
end

local function play_book_closed_to_player( author )
    minetest.sound_play( "book_close", {
        to_player = author:get_player_name()
    })
end

local function play_book_write_to_player( author )
    minetest.sound_play( "book_write", {
        to_player = author:get_player_name()
    })
end


-- Important note: The meta argument is an object pointer
local function creat_book_formspec( meta, editable, page_modification, previous_data, book_name, setting_max_page, toggle_auto_page )

    local max_page = meta:get_int("max_pages")

    if max_page == 0 then
        max_page = 1
        meta:set_int("max_pages", 1)
    end

    local page = meta:get_int("page")

    if previous_data then
        -- Save the old page's data
        meta:set_string("book_text_" .. page, previous_data)
    end

    -- Auto generate new pages makes it create a new page when you click to the right
    local auto_page = meta:get_int("auto_page")

    if toggle_auto_page or not meta:contains("auto_page") then
        if auto_page == 0 then
            auto_page = 1
        else
            auto_page = 0
        end
        meta:set_int("auto_page", auto_page)
    end

    local book_title = book_name or meta:get_string("book_title")
    if book_title then
        meta:set_string("book_name", book_title)
    end

    page = page + page_modification

    -- Page underflow & overflow catches
    if page == 0 then
        page = max_page
        -- Player has reached the max number of pages allowed
    elseif page > MAX_BOOK_PAGES then
        page = 1
    elseif editable and auto_page == 1 and page > max_page then
        max_page = max_page + 1
    elseif page > max_page then
        page = 1
    end
    meta:set_int("max_pages", max_page)
    meta:set_int("page", page)

    -- Allows the author to cut off the books length to the current page
    if editable and setting_max_page then

        local old_max = max_page
        meta:set_string("max_pages", page)
        max_page = page

        -- Remove old data
        for i = page + 1, old_max do
            meta:set_string("book_text_" .. i , "")
        end
    end

    local book_text = meta:get_string("book_text_" .. page)

    -- These are defaults for an inked book
    local close_button = "Close"
    local close_button_width = 1
    local close_button_offset = 4
    local close_button_id = "book_close"
    local page_offset = 5
    local title_area_name = ""
    local text_area_name = ""

    if editable then
        close_button = "Write & close"
        close_button_width = 2
        close_button_offset = -0.19
        close_button_id = "book_write"
        page_offset = 1.675
        title_area_name = "book_title"
        text_area_name = "book_text"
    end

    local book_formspec = "size[9,8.75]" ..
        "background[-0.19,-0.25;9.41,9.49;gui_hb_bg.png]" ..
        "style[" .. text_area_name .. "," .. title_area_name .. ";textcolor=black;border=true;noclip=false]" ..
        "textarea[1.75,0;6,1;" .. title_area_name .. ";;" .. book_title .."]" ..
        "textarea[0.3,1;9,8.5;" .. text_area_name .. ";;" .. book_text .."]"  ..
        "button[" .. close_button_offset .. ",8.25;" .. close_button_width .. ",1;" .. close_button_id .. ";" .. close_button .. "]" ..
        "button[0,-0.025;1,1;book_button_prev;Prev]" ..
        "button[8,-0.025;1,1;book_button_next;Next]" ..
        "button[" .. page_offset .. ",8.25;2,1;current_page;Page: " .. page .. "/" .. max_page .. "]"

    if editable then

        local auto_page_display = tostring(auto_page == 1):gsub("^%l", string.upper)

        book_formspec = book_formspec ..
        "button[7.25,8.25;2,1;book_ink;Ink]" ..
        "button[5.375,8.25;2,1;book_max_page;Set Max Page]" ..
        "button[3.525,8.25;2,1;toggle_auto_page;AutoPage: " .. auto_page_display .. "]"

    else
        -- Invisible helper label
        book_formspec = book_formspec .. "field[0,0;0,0;book_locked;book_locked;]"
    end

    return book_formspec
end

-- Opening the book guis are not only the entry points into this, they're also the logic loop!
local function open_book_item_gui( author, editable, page_modification, previous_data, book_name, setting_max_page, toggle_auto_page )

    play_book_open_sound_to_player( author )

    local itemstack = author:get_wielded_item()

    local meta = itemstack:get_meta()

    local book_formspec = creat_book_formspec( meta, editable, page_modification, previous_data, book_name, setting_max_page, toggle_auto_page )

    minetest.show_formspec( author:get_player_name(), "book_gui", book_formspec )

    author:set_wielded_item(itemstack)
end

local function open_book_node_gui( pos, author, editable, page_modification, previous_data, book_name, setting_max_page, toggle_auto_page )

    play_book_open_sound_to_player( author )

    -- Needed for the entry point
    local meta = minetest.get_meta(pos)

    local book_formspec = creat_book_formspec( meta, editable, page_modification, previous_data, book_name, setting_max_page, toggle_auto_page )

    -- Reuse this over and over
    -- Invisible helper label
    book_formspec = book_formspec .. "field[0,0;0,0;book_pos;book_pos;" .. minetest.serialize(pos) .. "]"

    minetest.show_formspec( author:get_player_name(), "book_node_gui", book_formspec )
end

local function save_current_page(player, fields)
    local itemstack = player:get_wielded_item()
    local meta = itemstack:get_meta()
    local current_page = meta:get_int("page")
    meta:set_string("book_title", fields["book_title"])
    meta:set_string("book_text_" .. current_page, fields["book_text"])
    player:set_wielded_item(itemstack)
end

local function save_current_node_page(pos, fields)
    local meta = minetest.get_meta(pos)
    local current_page = meta:get_int("page")
    meta:set_string("book_title", fields["book_title"])
    meta:set_string("book_text_" .. current_page, fields["book_text"])
end

-- Handes the book gui
minetest.register_on_player_receive_fields(function(player, formname, fields)

    -- Wait, this isn't a book
    if formname ~= "book_gui" and formname ~= "book_node_gui" then return end

    -- Player accidentally clicked the page button
    if fields["current_page"] then return end

    local editable = fields["book_locked"] == nil

    -- It's a book node
    if formname == "book_node_gui" then goto book_node end

    -- This is the save text logic gate
    if editable and fields["book_write"] then
        minetest.close_formspec( player:get_player_name(), "book_gui" )
        play_book_write_to_player(player)
        save_current_page(player, fields)

    -- This is the lock book (ink it permenantly) logic gate
    elseif editable and fields["book_ink"] then

        save_current_page(player, fields)

        local itemstack = ItemStack( "book:book_written" )
        local old_stack = player:get_wielded_item()

        local meta = itemstack:get_meta()
        local old_meta = old_stack:get_meta()

        local max_pages = old_meta:get_int("max_pages")

        for i = 1,max_pages do
            meta:set_string("book_text_" .. i, old_meta:get_string( "book_text_" .. i ) )
        end

        local name = old_meta:get_string("book_title")
        if name == "" then
            name = "Uknown"
        end
        name = name .. " by " .. player:get_player_name()
        meta:set_string("book_title", name)
        meta:set_int("page", meta:get_int("page"))
        meta:set_int("max_pages", max_pages)

        player:set_wielded_item( itemstack )

        play_book_write_to_player(player)
        open_book_item_gui(player, false, 0)

        -- Turn the page
    elseif fields["book_button_next"] then

        if editable then
            local old_data = fields["book_text"] or ""
            local book_name = fields["book_title"] or ""

            open_book_item_gui(player, editable, 1, old_data, book_name)
        else
            open_book_item_gui(player, editable, 1)
        end

        -- Turn back the page
    elseif fields["book_button_prev"] then

        if editable then
            local old_data = fields["book_text"] or ""
            local book_name = fields["book_title"] or ""

            open_book_item_gui(player, editable, -1, old_data, book_name)
        else
            open_book_item_gui(player, editable, -1)
        end

        -- Basically cuts the book off at the current page
    elseif fields["book_max_page"] then

        local old_data = fields["book_text"] or ""
        local book_name = fields["book_title"] or ""

        open_book_item_gui(player, editable, 0, old_data, book_name, true)

        -- AutoPage toggle
    elseif fields["toggle_auto_page"] then

        local old_data = fields["book_text"] or ""
        local book_name = fields["book_title"] or ""

        open_book_item_gui(player, true, 0, old_data, book_name, false, true)

        -- This is the fallthrough locked book closing and players hitting escape or close and the gui is now closed in an editable book
    elseif fields["book_locked"]  or fields["quit"] then

        -- If editable book, then all changes to the current page are lost :(
        minetest.close_formspec( player:get_player_name(), "book_gui" )
        play_book_closed_to_player( player )
    end

    do return end


    ::book_node::

    -- book_node_gui

    -- An important note: When the book is opened, pages turned, anything, the formspec will have the position as a serialized value!

    local pos = minetest.deserialize(fields["book_pos"])

    -- This is the save text logic gate
    if editable and fields["book_write"] then

        minetest.close_formspec( player:get_player_name(), "book_node_gui" )
        play_book_write_to_player(player)

        -- TODO: this is used so many times this might as well be created above
        save_current_node_page(pos, fields)

    -- This is the lock book (ink it permenantly) logic gate
    elseif editable and fields["book_ink"] then
        
        save_current_node_page(pos, fields)
        local meta = minetest.get_meta(pos)
        local name = meta:get_string("book_title")
        if name == "" then
            name = "Uknown"
        end
        name = name .. " by " .. player:get_player_name()
        meta:set_string("book_title", name)

        local old_node = minetest.get_node(pos)
        local param1 = old_node.param1
        local param2 = old_node.param2        

        minetest.swap_node( pos, { name = "book:inked_book_node", param1 = param1, param2 = param2} )

        play_book_write_to_player(player)
        open_book_node_gui(pos, player, false, 0)

        -- Turn the page
    elseif fields["book_button_next"] then

        if editable then
            local old_data = fields["book_text"] or ""
            local book_name = fields["book_title"] or ""

            open_book_node_gui(pos, player, editable, 1, old_data, book_name)
        else
            open_book_node_gui(pos, player, editable, 1)
        end

        -- Turn back the page
    elseif fields["book_button_prev"] then

        if editable then
            local old_data = fields["book_text"] or ""
            local book_name = fields["book_title"] or ""

            open_book_node_gui(pos, player, editable, -1, old_data, book_name)
        else
            open_book_node_gui(pos, player, editable, -1)
        end

        -- Basically cuts the book off at the current page
    elseif fields["book_max_page"] then

        local old_data = fields["book_text"] or ""
        local book_name = fields["book_title"] or ""

        open_book_node_gui(pos, player, editable, 0, old_data, book_name, true)

        -- AutoPage toggle
    elseif fields["toggle_auto_page"] then

        local old_data = fields["book_text"] or ""
        local book_name = fields["book_title"] or ""

        open_book_node_gui(pos, player, true, 0, old_data, book_name, false, true)

        -- This is the fallthrough locked book closing and players hitting escape or close and the gui is now closed in an editable book
    elseif fields["book_locked"]  or fields["quit"] then

        -- If editable book, then all changes to the current page are lost :(
        minetest.close_formspec( player:get_player_name(), "book_node_gui" )
        play_book_closed_to_player( player )
    end
    

end)

local function place_item_as_node(pos, param2, old_stack, new_node)
    local old_meta = old_stack:get_meta()

    minetest.set_node(pos, {name = new_node, param2 = param2})

    local new_meta = minetest.get_meta(pos)

    local max_page = old_meta:get_int("max_pages")
    for i = 1,max_page do
        new_meta:set_string( "book_text_" .. i, old_meta:get_string( "book_text_" .. i ) )
    end

    local page = old_meta:get_int("page")
    local title = old_meta:get_string("book_title")

    new_meta:set_string("book_title", title)
    new_meta:set_int("max_pages", max_page)
    new_meta:set_int("page", page)
end

local function get_param2(dir)
    local param2 = minetest.dir_to_fourdir(dir)

    return param2
end

-- Book that is able to be edited
minetest.register_craftitem("book:book",{
    description = "Book",
    groups = {book = 1, written = 0},
    stack_max = 1,
    inventory_image = "book.png",

    on_place = function(itemstack, author, pointed_thing)
        if not pointed_thing.type == "node" then
            return
        end

        local sneak = author:get_player_control().sneak

        local nodedef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]

        -- If a player is sneaking then they can place the book as a node
        if sneak then
            if nodedef.buildable_to then
                local param2 = get_param2(author:get_look_dir())
                place_item_as_node(pointed_thing.under, param2, itemstack, "book:book_node")
                itemstack:take_item(1)
                return itemstack
            end
            if vector.equals(vector.direction(pointed_thing.under,pointed_thing.above), vector.new(0,1,0)) then
                local param2 = get_param2(author:get_look_dir())
                place_item_as_node(pointed_thing.above, param2, itemstack, "book:book_node")
                itemstack:take_item(1)
                return itemstack
            end
        end
        -- Ignore for rightclicking things
        if nodedef.on_rightclick then return minetest.item_place(itemstack, author, pointed_thing) end
        
        open_book_item_gui( author, true, 0)
    end,

    on_secondary_use = function(itemstack, author, pointed_thing)
        open_book_item_gui( author, true, 0)
    end,
})

-- Permenantly written books
minetest.register_craftitem("book:book_written",{
    description = "Book",
    groups = {book = 1, written = 1},
    stack_max = 1,
    inventory_image = "book_written.png",

    on_place = function(itemstack, author, pointed_thing)

        if not pointed_thing.type == "node" then
            return
        end

        local sneak = author:get_player_control().sneak

        local nodedef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]

        -- If a player is sneaking then they can place the book as a node
        if sneak then
            if nodedef.buildable_to then
                local param2 = get_param2(author:get_look_dir())
                place_item_as_node(pointed_thing.under, param2, itemstack, "book:inked_book_node")
                itemstack:take_item(1)
                return itemstack
            end

            if vector.equals(vector.direction(pointed_thing.under,pointed_thing.above), vector.new(0,1,0)) then
                local param2 = get_param2(author:get_look_dir())
                place_item_as_node(pointed_thing.above, param2, itemstack, "book:inked_book_node")
                itemstack:take_item(1)
                return itemstack
            end
        end
        
        -- Ignore for rightclicking things
        if nodedef.on_rightclick then return minetest.item_place(itemstack, author, pointed_thing) end

        open_book_item_gui(author, false, 0)
    end,

    on_secondary_use = function(itemstack, author, pointed_thing)
        open_book_item_gui(author, false, 0)
    end,
})

--change this to paper
minetest.register_craft({
    output = "book:book",
    recipe = {
        {"main:wood","main:wood","main:wood"},
        {"main:paper","main:paper","main:paper"},
        {"main:wood","main:wood","main:wood"},
    }
})

local node_box = {
    type = "fixed",
    fixed = {
        {-0.4375, -0.5000, -0.3750, 0.4375, -0.4375, 0.3750},
        {-0.3750, -0.4375, -0.3750, 0.3750, -0.3750, 0.3750}
    }
}

local function destroy_node_function( pos, dropping_item )
    local old_meta = minetest.get_meta( pos )

    local new_item = ItemStack( dropping_item )
    local new_meta = new_item:get_meta()

    local max_page = old_meta:get_int("max_pages")
    for i = 1,max_page do
        new_meta:set_string( "book_text_" .. i, old_meta:get_string( "book_text_" .. i ) )
    end

    local page = old_meta:get_int("page")
    local title = old_meta:get_string("book_title")

    new_meta:set_string("book_title", title)
    new_meta:set_int("max_pages", max_page)
    new_meta:set_int("page", page)

    minetest.item_drop(new_item, nil, pos)
end



minetest.register_node("book:book_node", {
    description = "Book",
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "4dir",
    sunlight_propagates = true,
    groups = { wool = 1, attached_node = 3 },
    tiles = {"book_top.png","book_bottom.png","book_side.png","book_side.png","book_side.png","book_side.png"},
    node_box = node_box,
    drop = "",
    on_rightclick = function( pos, _, clicker )
        open_book_node_gui( pos, clicker, true, 0)
    end,
    on_destruct = function(pos)
        destroy_node_function( pos, "book:book" )
    end,
    on_punch = function(pos, node, puncher)
        if not puncher:get_player_control().sneak then return end
        minetest.sound_play("book_close", {
            pos = pos,
            max_hear_distance = 20,
        })
        minetest.swap_node(pos, { name = "book:book_node_closed", param1 = node.param1, param2 = node.param2 } )
    end
})

minetest.register_node("book:inked_book_node", {
    description = "Inked Book",
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "4dir",
    sunlight_propagates = true,
    groups = { wool = 1, attached_node = 3 },
    tiles = {"inked_book_top.png","inked_book_bottom.png","inked_book_side.png","inked_book_side.png","inked_book_side.png","inked_book_side.png"},
    node_box = node_box,
    drop = "",
    on_rightclick = function( pos, _, clicker )
        open_book_node_gui( pos, clicker, false, 0)
    end,
    on_destruct = function(pos)
        destroy_node_function( pos, "book:book_written" )
    end,
    on_punch = function(pos, node, puncher)
        if not puncher:get_player_control().sneak then return end
        minetest.sound_play("book_close", {
            pos = pos,
            max_hear_distance = 20,
        })
        minetest.swap_node(pos, { name = "book:inked_book_node_closed", param1 = node.param1, param2 = node.param2 } )
    end
})

-- These are closed books, there's literally no reason to have this but I thought it would be neat for players to be able to close the book :)

local nodebox_closed = {
	type = "fixed",
	fixed = {
		{-0.2500, -0.5000, -0.3750, 0.2500, -0.2500, 0.3750}
	}
}

minetest.register_node("book:book_node_closed", {
    description = "Book",
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "4dir",
    sounds = main.woolSound(),
    sunlight_propagates = true,
    groups = { wool = 1, attached_node = 3 },
    tiles = {
        "book_closed_top.png",
        "book_closed_top.png",
        "book_closed_right.png",
        "book_closed_left.png",
        "book_closed_front.png",
        "book_closed_back.png"
    },
    node_box = nodebox_closed,
    drop = "",
    on_destruct = function(pos)
        destroy_node_function( pos, "book:book" )
    end,
    on_punch = function(pos, node, puncher)
        if not puncher:get_player_control().sneak then return end
        minetest.sound_play("book_open", {
            pos = pos,
            max_hear_distance = 20,
        })
        minetest.swap_node(pos, { name = "book:book_node", param1 = node.param1, param2 = node.param2 } )
    end
})

minetest.register_node("book:inked_book_node_closed", {
    description = "Inked Book",
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "4dir",
    sounds = main.woolSound(),
    sunlight_propagates = true,
    groups = { wool = 1, attached_node = 3 },
    tiles = {
        "inked_book_closed_top.png",
        "inked_book_closed_top.png",
        "inked_book_closed_right.png",
        "inked_book_closed_left.png",
        "inked_book_closed_front.png",
        "inked_book_closed_back.png"
    },
    node_box = nodebox_closed,
    drop = "",
    on_destruct = function(pos)
        destroy_node_function( pos, "book:book_written" )
    end,
    on_punch = function(pos, node, puncher)
        if not puncher:get_player_control().sneak then return end
        minetest.sound_play("book_open", {
            pos = pos,
            max_hear_distance = 20,
        })
        minetest.swap_node(pos, { name = "book:inked_book_node", param1 = node.param1, param2 = node.param2 } )
    end
})