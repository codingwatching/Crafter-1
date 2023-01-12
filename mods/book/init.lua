
--[[
    TODO:
    1. give books multiple pages
    2. make books placable on the ground
    2.a make a nice looking node that represents a book
]]

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
-- Checks the fields of a formspec easily
local function field_check(intake, ...)
    local gotten_arguments = {...}
    local check_length = #gotten_arguments
    for _,key in ipairs(gotten_arguments) do
        if not intake[key] then return false end
        check_length = check_length - 1
    end
    return check_length <= 0
end

--this is the gui for un-inked books

-- TODO: replace user with author as a variable name
local function open_book_item_gui(itemstack, user)

    play_book_open_sound_to_player( user )

    local meta = itemstack:get_meta()

    local book_text = meta:get_string("book.book_text")
    

    if book_text == "" then

        book_text = "Text here"

    end

    local book_title = meta:get_string("book.book_title")

    if book_title == "" then
        book_title = "Title here"
    end

    local book_writing_formspec = "size[9,8.75]"..
        "background[-0.19,-0.25;9.41,9.49;gui_hb_bg.png]"..
        "style[book.book_text,book.book_title;textcolor=black;border=false;noclip=false]"..
        "textarea[0.3,0;9,0.5;book.book_title;;"..book_title.."]"..
        "textarea[0.3,0.3;9,9;book.book_text;;"..book_text.."]"..
        "button[-0.2,8.3;1,1;book.book_write;write]"..
        "button[8.25,8.3;1,1;book.book_ink;ink  ]"
    minetest.show_formspec(user:get_player_name(), "book.book_gui", book_writing_formspec)
end

-- TODO: replace user with author as a variable name
-- The gui for permenantly written books

local function open_book_item_written_gui(itemstack, user)

    play_book_open_sound_to_player( user )

    local meta = itemstack:get_meta()
    local book_text = meta:get_string("book.book_text")
    local book_title = meta:get_string("book.book_title")
    local book_writing_formspec = "size[9,8.75]"..
        "background[-0.19,-0.25;9.41,9.49;gui_hb_bg.png]"..
        "style_type[textarea;textcolor=black;border=false;noclip=false]"..
        "textarea[0.3,0;9,0.5;;;"..book_title.."]"..
        "textarea[0.3,0.3;9,9;;;"..book_text.."]"..
        "button_exit[4,8.3;1,1;book.book_close;close]"
    minetest.show_formspec(user:get_player_name(), "book.book_gui", book_writing_formspec)
end


-- Handes the book gui
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not formname == "book.book_gui" then return end
    
    if fields["book.book_write"] and fields["book.book_text"] and fields["book.book_text"] then
        local itemstack = ItemStack("book:book")
        local meta = itemstack:get_meta()
        meta:set_string("book.book_text", fields["book.book_text"])
        meta:set_string("book.book_title", fields["book.book_title"])    
        meta:set_string("description", fields["book.book_title"])minetest.sound_play("book_write", {to_player=player:get_player_name()})
        
        player:set_wielded_item(itemstack)
        minetest.close_formspec(player:get_player_name(), "book.book_gui")
        play_book_write_to_player(player)

    elseif fields["book.book_ink"] and fields["book.book_text"] and fields["book.book_text"] then

        local itemstack = ItemStack("book:book_written")
        local meta = itemstack:get_meta()
        meta:set_string("book.book_text", fields["book.book_text"])
        meta:set_string("book.book_title", fields["book.book_title"])    
        meta:set_string("description", fields["book.book_title"])
        player:set_wielded_item(itemstack)
        minetest.close_formspec(player:get_player_name(), "book.book_gui")

        play_book_closed_to_player( player )

    elseif fields["book.book_close"] then

        play_book_closed_to_player( player )

    end
end)


--this is the book item
minetest.register_craftitem("book:book",{
    description = "Book",
    groups = {book = 1, written = 0},
    stack_max = 1,
    inventory_image = "book.png",
    
    on_place = function(itemstack, user, pointed_thing)
        if not pointed_thing.type == "node" then
            return
        end

        local sneak = user:get_player_control().sneak

        local noddef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]

        if not sneak and noddef.on_rightclick then
            minetest.item_place(itemstack, user, pointed_thing)
            return
        end
        --print("make books placable on the ground")
        open_book_item_gui(itemstack, user)
    end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        open_book_item_gui(itemstack, user)
    end,
})

--permenantly written books
minetest.register_craftitem("book:book_written",{
    description = "Book",
    groups = {book = 1, written = 1},
    stack_max = 1,
    inventory_image = "book_written.png",
    
    on_place = function(itemstack, user, pointed_thing)

        if not pointed_thing.type == "node" then
            return
        end

        local sneak = user:get_player_control().sneak

        local noddef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]

        -- Ignore for rightclicking things
        if noddef.on_rightclick then return end

        -- If a player is sneaking then they can place the book on the ground
        if sneak then
            print("placing a thing on the ground")
            minetest.item_place(itemstack, user, pointed_thing.above)
            return
        end

        open_book_item_written_gui(itemstack, user)
    end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        open_book_item_written_gui(itemstack, user)
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
