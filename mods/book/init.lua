
--[[
    TODO:
    1. give books multiple pages

    2. make an auto page creation lockout in case the user wants to keep the amount of pages

    2. make a page saving function and check if there's nothing in the page

    3. make books placable on the ground
    3.a make a nice looking node that represents a book
    4.Maybe make a book animation for when it's opening?
    5.Maybe dye books?

    -- TODO: replace user with author as a variable name
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



-- TODO: replace user with author as a variable name
local function open_book_item_gui( user, editable, page_modification, previous_data, book_name, setting_max_page, toggle_auto_page)

    play_book_open_sound_to_player( user )

    local itemstack = user:get_wielded_item()

    local meta = itemstack:get_meta()

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

    if toggle_auto_page then
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

    -- TODO: REMOVE THIS WORKAROUND FOR THE NOT UPDATING GLITCH WHEN IT IS FIXED
    if book_text == "" then
        book_text = tostring(math.random())
    end

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
        "style[book_text,book_title;textcolor=black;border=true;noclip=false]" ..
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
 
    minetest.show_formspec( user:get_player_name(), "book_gui", book_formspec )

    user:set_wielded_item(itemstack)
end

local function save_current_page(player, fields)

    local itemstack = player:get_wielded_item()
    local meta = itemstack:get_meta()
    local current_page = meta:get_int("page")

    meta:set_string("book_title", fields["book_title"])
    meta:set_string("book_text_" .. current_page, fields["book_text"])

    player:set_wielded_item(itemstack)
end

-- Handes the book gui
minetest.register_on_player_receive_fields(function(player, formname, fields)

    if formname ~= "book_gui" then return end

    -- Player accidentally clicked the page button
    if fields["current_page"] then return end

    local editable = fields["book_locked"] == nil

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
        open_book_item_gui( user, true, 0)
    end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        open_book_item_gui( user, true, 0)
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

        open_book_item_gui(user, false, 0)
    end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        open_book_item_gui(user, false, 0)
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

