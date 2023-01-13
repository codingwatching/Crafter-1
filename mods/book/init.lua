
--[[
    TODO:
    1. give books multiple pages

    2. make an auto page creation lockout in case the user wants to keep the amount of pages

    2. make a page saving function and check if there's nothing in the page

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
local function open_book_item_gui(itemstack, user, editable )

    play_book_open_sound_to_player( user )

    local meta = itemstack:get_meta()

    print("on loading I am on page " .. meta:get_int("page"))

    local max_page = meta:get_int("max_pages")

    if max_page == 0 then
        max_page = 1
        meta:set_int("max_pages", 1)
    end

    local page = meta:get_int("page")

    -- Page underflow catch
    if page == 0 then
        page = max_page
        meta:set_int("page", max_page)
        -- Player has reached the max number of pages allowed
    elseif page > MAX_BOOK_PAGES then
        page = 1
        meta:set_int("page", 1)
    elseif editable and page > max_page then
        max_page = max_page + 1
        meta:set_int("max_pages", max_page)
    elseif page > max_page then
        page = 1
        meta:set_int("page", 1)
    end

    print("I'm on page " .. page)

    local book_title = meta:get_string("book.book_title")

    local book_text = meta:get_string("book.book_text_" .. page)
    if book_text == "" then
        book_text = "NO DATA"
    end

    print("THE NEW DATA: " .. book_text)

    -- These are defaults for an inked book
    local close_button = "Close"
    local close_button_width = 1
    local close_button_offset = 4
    local close_button_id = "book.book_close"

    if editable then
        close_button = "Write & close"
        close_button_width = 2
        close_button_offset = -0.2
        close_button_id = "book.book_write"
    end

    local book_formspec = "size[9,8.75]" ..
        "background[-0.19,-0.25;9.41,9.49;gui_hb_bg.png]" ..
        "style[book.book_text,book.book_title;textcolor=black;border=true;noclip=false]" ..
        "textarea[1.75,0;6,1;book.book_title;;" .. book_title .."]" ..
        "textarea[0.3,1;9,8.5;book.book_text;;" .. book_text .."]"  ..
        "button[" .. close_button_offset .. ",8.3;" .. close_button_width .. ",1;" .. close_button_id .. ";" .. close_button .. "]" ..
        "button[0,-0.025;1,1;book.button_prev;Prev]" ..
        "button[8,-0.025;1,1;book.button_next;Next]"

    if editable then
        book_formspec = book_formspec .. "button[8.25,8.3;1,1;book.book_ink;ink]"
    else
        book_formspec = book_formspec .. "field[0,0;0,0;book.book_locked;book.locked;]"
    end

    print(page .. "'s text data is: " .. book_text)
        
    minetest.show_formspec( user:get_player_name(), "book.book_gui", book_formspec )

    return itemstack
end

-- TODO: replace user with author as a variable name
-- The gui for permenantly written books

-- Handes the book gui
minetest.register_on_player_receive_fields(function(player, formname, fields)

    if formname ~= "book.book_gui" then return end

    -- This is the save text logic gate
    if not fields["book.button_next"] and not fields["book.button_prev"] and not fields["book.book_locked"] and not fields["book.book_ink"] and fields["book.book_text"] and fields["book.book_title"] then
        
        print("ERROR 1")
        local itemstack = player:get_wielded_item()
        local meta = itemstack:get_meta()
        local current_page = meta:get_int("page")

        meta:set_string( "book.book_title", fields[ "book.book_title" ] )
        meta:set_string( "description", fields[ "book.book_title" ] )
        meta:set_string( "book.book_text_" .. current_page, fields[ "book.book_text" ] )

        player:set_wielded_item(itemstack)
        minetest.close_formspec( player:get_player_name(), "book.book_gui" )
        play_book_write_to_player(player)

    -- This is the lock book (ink it permenantly) logic gate
    elseif not fields["book.button_next"] and not fields["book.button_prev"] and not fields["book.book_locked"] and fields["book.book_ink"] and fields["book.book_text"] and fields["book.book_title"] then
        print("ERROR 2")
        
        local itemstack = ItemStack( "book:book_written" )
        local old_stack = player:get_wielded_item()

        local meta = itemstack:get_meta()
        local old_meta = old_stack:get_meta()

        for key,value in pairs(old_meta:to_table()) do
            meta[key] = value
        end

        player:set_wielded_item( itemstack )
        
        minetest.close_formspec( player:get_player_name(), "book.book_gui" )
        play_book_closed_to_player( player )
        
        
        -- Turn the page
    elseif fields["book.button_next"] then

        print("I'm turning the page")
        
        local itemstack = player:get_wielded_item()
        local meta = itemstack:get_meta()
        local current_page = meta:get_int("page")

        meta:set_string( "book.book_title", fields[ "book.book_title" ] )
        meta:set_string( "description", fields[ "book.book_title" ] )
        meta:set_string( "book.book_text_" .. current_page, fields[ "book.book_text" ] )

        print("saving page " .. current_page)

        meta:set_int("page", current_page + 1)

        player:set_wielded_item(itemstack)

        itemstack = open_book_item_gui(itemstack, player, true)

        player:set_wielded_item(itemstack)

        -- Turn back the page
    elseif fields["book.button_prev"] then

        local itemstack = player:get_wielded_item()
        local meta = itemstack:get_meta()
        local current_page = meta:get_int("page")
        meta:set_int("page", current_page - 1)

        player:set_wielded_item(itemstack)

        itemstack = open_book_item_gui(itemstack, player, true)

        player:set_wielded_item(itemstack)

        -- This is the fallthrough locked book closing
    elseif fields["book.book_locked"] then
        print("closing formspec")
        minetest.close_formspec( player:get_player_name(), "book.book_gui" )
        -- Player hit escape or close and the gui is now closed
        play_book_closed_to_player( player )
    end
end)


-- Book that is able to be edited
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
        itemstack = open_book_item_gui(itemstack, user, true)
        user:set_wielded_item(itemstack)
    end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        itemstack = open_book_item_gui(itemstack, user, true)
        user:set_wielded_item(itemstack)
    end,
})

-- Permenantly written books
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

        itemstack = open_book_item_gui(itemstack, user, false)
        user:set_wielded_item(itemstack)
    end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        itemstack = open_book_item_gui(itemstack, user, false)
        user:set_wielded_item(itemstack)
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

