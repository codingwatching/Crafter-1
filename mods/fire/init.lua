local get_node_timer = minetest.get_node_timer
local get_node = minetest.get_node
local set_node = minetest.set_node
local find_node_near = minetest.find_node_near
local sound_play = minetest.sound_play
local registered_nodes = minetest.registered_nodes
local item_place = minetest.item_place
local mod_channel_join = minetest.mod_channel_join
local remove_node = minetest.remove_node
local add_entity = minetest.add_entity
local after = minetest.after
local log = minetest.log
local vec_new = vector.new
local math_random = math.random
local getmetatable = getmetatable

local function start_fire_timer(pos)
    get_node_timer(pos):start(math_random(1,7))
end

minetest.register_node("fire:fire", {
    description = "Fire",
    drawtype = "firelike",
    tiles = {
        {
            name = "fire.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 0.6
            },
        },
    },
    groups = { dig_immediate = 1, fire = 1 },
    sounds = main.stoneSound(),
    floodable = true,
    drop = "",
    walkable = false,
    is_ground_content = false,
    light_source = 11,
    on_construct = function(pos)

        local under = get_node( vec_new( pos.x, pos.y - 1, pos.z ) ).name
        -- Creates a nether portal
        if under == "nether:obsidian" then
            remove_node(pos)
            create_nether_portal(pos)
        -- Fire lasts forever on netherrack, as a side effect, you can also make fire art with this :)
        elseif under ~= "nether:netherrack" then
            start_fire_timer(pos)
        end
    end,
    on_timer = function(pos)

        local fire_spread_position = find_node_near( pos, 1, { "group:flammable" } )

        -- Reduce the amount of serverwide fires that can happen from stagnant fire nodes in air
        if not fire_spread_position then
            remove_node(pos)
            return
        end

        if fire_spread_position then
            -- This encourages players to use their flint and steel more, along with reducing the amount of
            -- huge server wide fires that can happen
            if math_random() > 0.25 then

                set_node( fire_spread_position, { name = "fire:fire" } )
                start_fire_timer(fire_spread_position)
            end
        end

        start_fire_timer(pos)
    end,
})

-- Flint and steel
minetest.register_tool("fire:flint_and_steel", {
    description = "Flint and Steel",
    inventory_image = "flint_and_steel.png",
    on_place = function(itemstack, placer, pointed_thing)

        if pointed_thing.type ~= "node" then
            return
        end

        local sneak = placer:get_player_control().sneak

        local nodedef = registered_nodes[get_node(pointed_thing.under).name]

        if not sneak and nodedef.on_rightclick then return item_place(itemstack, placer, pointed_thing) end

        -- Can't make fire in the aether
        if pointed_thing.above.y >= 20000 then
            sound_play( "flint_failed", {
                pos = pointed_thing.above,
                pitch = math_random( 75, 95 ) / 100
            })
            return
        end

        if get_node(pointed_thing.above).name ~= "air" then
            sound_play( "flint_failed", {
                pos = pointed_thing.above
            })
            return
        end

        set_node( pointed_thing.above, { name = "fire:fire" } )
        sound_play( "flint_and_steel", {
            pos = pointed_thing.above
        })

        itemstack:add_wear(100)
        return(itemstack)
    end,
    tool_capabilities = {
        groupcaps={
            _namespace_reserved = { times = { [ 1 ] = 5555 }, uses = 0, maxlevel = 1},
        }
    },
    groups = { flint = 1},
    sound = {
        breaks = {
            name = "tool_break",
            gain = 0.4
        }
    },
})

minetest.register_craft({
    type = "shapeless",
    output = "fire:flint_and_steel",
    recipe = {"main:flint","main:iron"},
})

-- Fire entity, attaches to players, items, and mobs

-- Fire class
local fire = {}

-- Fire fields
fire.initial_properties = {
    hp_max = 1,
    physical = false,
    collide_with_objects = false,
    collisionbox = {0, 0, 0, 0, 0, 0},
    visual = "cube",
    textures = {"nothing.png","nothing.png","fire.png","fire.png","fire.png","fire.png"},
    visual_size = {x = 1, y = 1, z = 1},
    --textures = {"nothing.png","nothing.png","fire.png","fire.png","fire.png","fire.png"},--, animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=8.0}},
    is_visible = true,
    pointable = false,
}

fire.frame = 0
fire.frame_timer = 0
fire.glow = -1
fire.damage_timer = 0
fire.life = 0

-- Fire methods
function fire:on_activate()
    local texture_list = {
        "nothing.png",
        "nothing.png",
        "fire.png^[opacity:180^[verticalframe:8:0",
        "fire.png^[opacity:180^[verticalframe:8:0",
        "fire.png^[opacity:180^[verticalframe:8:0",
        "fire.png^[opacity:180^[verticalframe:8:0",
    }
    self.object:set_properties( { textures = texture_list } )
end

-- Pushes the fire texture to the next frame or overflows to first
fire.frame_update = function(self)

    self.frame = self.frame + 1

    if self.frame > 7 then
        self.frame = 0
    end

    local texture_list = {
        "nothing.png",
        "nothing.png",
        "fire.png^[opacity:180^[verticalframe:8:" .. self.frame,
        "fire.png^[opacity:180^[verticalframe:8:" .. self.frame,
        "fire.png^[opacity:180^[verticalframe:8:" .. self.frame,
        "fire.png^[opacity:180^[verticalframe:8:" .. self.frame,
    }
    self.object:set_properties( { textures = texture_list } )
end

function fire:on_step(dtime)

    if not self.owner then
        self.object:remove()
        return
    end

    if not self.owner:is_player() and not self.owner:get_luaentity() then
        self.object:remove()
        return
    end

    -- The owner died :(
    if self.owner:get_hp() <= 0 then
        self.owner:set_fire_state(false)
        return
    end

    self.damage_timer = self.damage_timer + dtime
    self.life = self.life + dtime

    -- The flame died out, 8 second flame lifetime
    if self.life >= 8 then
        self.owner:set_fire_state(false)
        return
    end

    -- Punching whatever it's attached to
    if self.damage_timer >= 1 then

        self.damage_timer = 0

        if self.owner:is_player() then

            self.owner:set_hp( self.owner:get_hp() - 1 )

        elseif self.owner:get_luaentity() then

            self.owner:punch( self.object, 2, {
                full_punch_interval = 0,
                damage_groups = { damage = 2 },
            })

        end
    end

    -- Animation handling
    self.frame_timer = self.frame_timer + dtime

    if self.frame_timer >= 0.015 then
        self.frame_timer = 0
        self.frame_update(self)
    end
end

minetest.register_entity( "fire:fire", fire )


local fire_channels = {}

-- Injects fire methods into the player object when they join the server
minetest.register_on_joinplayer(function(player)

    local player_name = player:get_player_name()
    fire_channels[player_name] = mod_channel_join(player_name..":fire_state")

    local metatable = getmetatable(player)

    -- Intake boolean, store as integer, return as boolean
    function metatable:set_fire_state(state, silent_extinguish)

        local current_state = player:get_fire_state()

        if current_state == state then return end

        local name = player:get_player_name()
        local meta = player:get_meta()

        -- Player is being lit on fire by a mod
        if state then

            local fire_entity = add_entity( player:get_pos(), "fire:fire" )

            -- A serious glitch has occured, log and keep the server running
            if not fire_entity then
                log("action", "A serious error has occurred attaching an entity to " .. name .. "!")
                return
            end

            fire_entity:get_luaentity().owner = player
            fire_entity:set_attach(player, "", vec_new( 0, 11, 0 ), vec_new( 0, 0, 0 ) )
            fire_entity:set_properties( { visual_size = vec_new( 1, 2, 1 ) } )
            fire_channels[name]:send_all("1")

            metatable.fire_entity = fire_entity

        -- Player is being extinguished by a mod
        else

            local fire_entity = metatable.fire_entity

            if fire_entity and fire_entity:get_luaentity() then
                fire_entity:remove()
            end
            fire_channels[name]:send_all("0")

            if not silent_extinguish then
                sound_play( "fire_extinguish", {
                    object = player,
                    gain = 0.3,
                    pitch = math_random( 80, 100 ) / 100
                })
            end
        end

        meta:set_int("fire_state", state and 1 or 0)
    end

    function metatable:get_fire_state()
        return player:get_meta():get_int("fire_state") == 1
    end

    local old_state = player:get_fire_state()

    if not old_state then return end

    player:set_fire_state(false, true)

    after(2.1, function()
        player:set_fire_state(true)
    end)

end)

--[[

function is_entity_on_fire(object)
    return false
end

local fire_obj

function start_fire(object)

    if object:is_player() then
        object:set_fire_state(true)

    elseif object and object:get_luaentity() then

        if not object:get_luaentity().fire_entity or object:get_luaentity().fire_entity and not object:get_luaentity().fire_entity:get_luaentity() then

            object:get_luaentity().on_fire = true

            fire_obj = minetest.add_entity(object:get_pos(),"fire:fire")

            fire_obj:get_luaentity().owner = object

            local entity_fire_def = object:get_luaentity().fire_table

            fire_obj:set_attach(object, "", entity_fire_def.position,vec_new(0,0,0))

            fire_obj:set_properties({visual_size=entity_fire_def.visual_size})

            object:get_luaentity().fire_entity = fire_obj

        else

            object:get_luaentity().fire_entity:get_luaentity().life = 0

        end

    end
end

function put_fire_out(object)

    if object:is_player() then
        object:set_fire_state(false)

    elseif object and object:get_luaentity() then

        if object:get_luaentity().fire_entity and object:get_luaentity().fire_entity:get_luaentity() then

            object:get_luaentity().fire_entity:remove()

        end

        object:get_luaentity().on_fire = false

        object:get_luaentity().fire_entity = nil
        
        minetest.sound_play( "fire_extinguish", {
            object = object,
            gain = 0.3,
            pitch = math_random( 80, 100 ) / 100
        })

    end

end
]]--