local type = type
local pairs = pairs
local get_node_or_nil    = minetest.get_node_or_nil
local get_time           = minetest.get_us_time
local get_player_by_name = minetest.get_player_by_name
local yaw_to_dir         = minetest.yaw_to_dir
local dir_to_yaw         = minetest.dir_to_yaw
local get_item_group     = minetest.get_item_group
local play_sound         = minetest.sound_play
local mod_storage        = minetest.get_mod_storage()
local throw_experience   = minetest.throw_experience
local new_vec       = vector.new
local vec_distance  = vector.distance
local add_vec       = vector.add
local multiply_vec  = vector.multiply
local vec_direction = vector.direction
local add_hud = hud_manager.add_hud
local change_hud = hud_manager.change_hud

local math_pi     = math.pi
local math_random = math.random
local math_abs    = math.abs
local HALF_PI     = math_pi / 2
local registered_nodes
minetest.register_on_mods_loaded(function()
    registered_nodes = minetest.registered_nodes
end)


local pool = {}
local name
local temp_pool
local xp_amount
local collector
local pos
local pos2
local distance
local player_velocity
local goal
local currentvel
local velocity
local node
local vel
local def
local is_moving
local is_slippery
local slippery
local slip_factor
local size


-- TODO: precalculate and hold use the result of these weirdly calculated values instead of calculating it every time

local load_data = function(player)
    name = player:get_player_name()
    pool[name] = {}
    temp_pool = pool[name]
    if mod_storage:get_int(name.."xp_save") > 0 then
        temp_pool.xp_level = mod_storage:get_int(name.."xp_level")
        temp_pool.xp_bar   = mod_storage:get_int(name.."xp_bar"  )
        temp_pool.buffer   = 0
        temp_pool.last_time= get_time()/1000000
    else
        temp_pool.xp_level = 0
        temp_pool.xp_bar   = 0
        temp_pool.buffer   = 0
        temp_pool.last_time= get_time()/1000000
    end
end

-- Save data to be utilized on next login
local save_data = function(player_name)

    temp_pool = pool[ player_name ]

    mod_storage:set_int( player_name .. "xp_level", temp_pool.xp_level )
    mod_storage:set_int( player_name .. "xp_bar", temp_pool.xp_bar )

    mod_storage:set_int( player_name .. "xp_save", 1 )

    pool[player_name] = nil
end

-- Saves data for players when they relog
minetest.register_on_leaveplayer(function(player)
    name = player:get_player_name()
    save_data(name)
end)

-- is used for shutdowns to save all data
local save_all = function()
    for player_name,_ in pairs(pool) do
        save_data(player_name)
    end
end

-- save all data to mod storage on shutdown
minetest.register_on_shutdown(function()
    save_all()
end)


function get_player_xp_level(player)
    name = player:get_player_name()
    return(pool[name].xp_level)
end

function set_player_xp_level( player, level )
    name = player:get_player_name()
    pool[name].xp_level = level
    change_hud({
        player   = player,
        hud_name = "xp_level_fg",
        element  = "text",
        data     = tostring(level)
    })
    change_hud({
        player   = player,
        hud_name = "xp_level_bg",
        element  = "text",
        data     = tostring(level)
    })
end

minetest.hud_replace_builtin("health",{
    hud_elem_type = "statbar",
    position = {x = 0.5, y = 1},
    text = "heart.png",
    number = minetest.PLAYER_MAX_HP_DEFAULT,
    direction = 0,
    size = { x = 24, y = 24 },
    offset = {x = ( -10 * 24 ) - 25, y = - ( 48 + 24 + 38 ) },
})

minetest.register_on_joinplayer(function(player)

    load_data(player)

    name = player:get_player_name()
    temp_pool = pool[name]

    add_hud(player,"heart_bar_bg",{
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "heart_bg.png",
        number = minetest.PLAYER_MAX_HP_DEFAULT,
        direction = 0,
        size = { x = 24, y = 24 },
        offset = { x = ( -10 * 24 ) - 25, y = - ( 48 + 24 + 38 ) },
    })

    add_hud(player,"experience_bar_background",{
        hud_elem_type = "statbar",
        position = { x = 0.5, y = 1 },
        name = "experience bar background",
        text = "experience_bar_background.png",
        number = 36,
        direction = 0,
        offset = { x = ( -8 * 28 ) - 29, y = -( 48 + 24 + 16 ) },
        size = { x = 28, y = 28 },
        z_index = 0,
    })

    add_hud(player,"experience_bar",{
        hud_elem_type = "statbar",
        position = { x = 0.5, y = 1 },
        name = "experience bar",
        text = "experience_bar.png",
        number = temp_pool.xp_bar,
        direction = 0,
        offset = {x = (-8 * 28) - 29, y = -(48 + 24 + 16)},
        size = { x = 28, y = 28 },
        z_index = 0,
    })

    add_hud(player,"xp_level_bg",{
        hud_elem_type = "text",
        position = { x = 0.5, y = 1 },
        name = "xp_level_bg",
        text = tostring(temp_pool.xp_level),
        number = 0x000000,
        offset = { x = 0, y = - ( 48 + 24 + 24 ) },
        z_index = 0,
    })
    add_hud(player,"xp_level_fg",{
        hud_elem_type = "text",
        position = { x = 0.5, y = 1 },
        name = "xp_level_fg",
        text = tostring(temp_pool.xp_level),
        number = 0xFFFFFF,
        offset = { x = -1, y = - ( 48 + 24 + 25 ) },
        z_index = 0,
    })
end)

local function level_up_experience(player)
    name = player:get_player_name()
    temp_pool = pool[name]

    temp_pool.xp_level = temp_pool.xp_level + 1

    change_hud({
        player   = player,
        hud_name = "xp_level_fg",
        element  = "text",
        data     = tostring(temp_pool.xp_level)
    })
    change_hud({
        player   = player,
        hud_name = "xp_level_bg",
        element  = "text",
        data     = tostring(temp_pool.xp_level)
    })
end

local function add_experience(player,experience)
    name = player:get_player_name()
    temp_pool = pool[name]

    temp_pool.xp_bar = temp_pool.xp_bar + experience

    if temp_pool.xp_bar > 36 then
        if get_time()/1000000 - temp_pool.last_time > 0.04 then
            play_sound("level_up",{gain=0.2,to_player = name})
            temp_pool.last_time = get_time()/1000000
        end
        temp_pool.xp_bar = temp_pool.xp_bar - 36
        level_up_experience(player)
    else
        if get_time()/1000000 - temp_pool.last_time > 0.01 then
            temp_pool.last_time = get_time()/1000000
            play_sound("experience",{gain=0.1,to_player = name,pitch=math_random(75,99)/100})
        end
    end
    change_hud({
        player   = player,
        hud_name = "experience_bar",
        element  = "number",
        data     = temp_pool.xp_bar
    })
end

--reset player level
minetest.register_on_dieplayer(function(player)
    name = player:get_player_name()
    temp_pool = pool[name]
    xp_amount = temp_pool.xp_level

    temp_pool.xp_bar   = 0
    temp_pool.xp_level = 0


    change_hud({
        player   = player,
        hud_name = "xp_level_fg",
        element  = "text",
        data     = tostring(temp_pool.xp_level)
    })
    change_hud({
        player   = player,
        hud_name = "xp_level_bg",
        element  = "text",
        data     = tostring(temp_pool.xp_level)
    })

    change_hud({
        player   = player,
        hud_name = "experience_bar",
        element  = "number",
        data     = temp_pool.xp_bar
    })

    throw_experience(player:get_pos(), xp_amount)
end)


-- Experience orb class
local xp_orb = {}

-- Experience orb fields
xp_orb.initial_properties = {
    hp_max = 1,
    physical = true,
    collide_with_objects = false,
    collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
    visual = "sprite",
    visual_size = {x = 0.4, y = 0.4},
    textures = {name="experience_orb.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}},
    spritediv = {x = 1, y = 14},
    initial_sprite_basepos = {x = 0, y = 0},
    is_visible = true,
    pointable = false,
    static_save = false,
}

xp_orb.moving_state = true
xp_orb.slippery_state = false
xp_orb.physical_state = true
-- Item expiry
xp_orb.age = 0
-- Pushing item out of solid nodes
xp_orb.force_out = nil
xp_orb.force_out_start = nil
--Collection Variables
xp_orb.collectable = false
xp_orb.try_timer = 0
xp_orb.collected = false
xp_orb.delete_timer = 0
xp_orb.radius = 4


function xp_orb:on_activate(staticdata, dtime_s)
    self.object:set_velocity(new_vec(
        math_random(-2,2)*math_random(),
        math_random(2,5),
        math_random(-2,2)*math_random()
    ))
    self.object:set_armor_groups({immortal = 1})
    self.object:set_velocity({x = 0, y = 2, z = 0})
    self.object:set_acceleration({x = 0, y = -9.81, z = 0})
    size = math_random(20,36)/100
    self.object:set_properties({
        visual_size = {x = size, y = size},
        glow = 14,
    })
    self.object:set_sprite( { x = 1, y = math_random( 1, 14 ) }, 14, 0.05, false )
end

function xp_orb:enable_physics()
    if self.physical_state then return end

    self.physical_state = true
    self.object:set_properties({physical = true})
    self.object:set_velocity({x=0, y=0, z=0})
    self.object:set_acceleration({x=0, y=-9.81, z=0})
end

function xp_orb:disable_physics()
    if not self.physical_state then return end

    self.physical_state = false
    self.object:set_properties({physical = false})
    self.object:set_velocity({x=0, y=0, z=0})
    self.object:set_acceleration({x=0, y=0, z=0})

end

-- Returns boolean
function xp_orb:execute_collection(dtime)

    if not self.collected then return false end

    if not self.collector then
        self.collected = false
        return false
    end

    collector = get_player_by_name(self.collector)

    if collector and collector:get_hp() > 0 and vec_distance(self.object:get_pos(),collector:get_pos()) < 5 then

        temp_pool = pool[self.collector]

        self.disable_physics(self)

        player_velocity = collector:get_velocity()

        pos = self.object:get_pos()

        pos2 = collector:get_pos()

        pos2.y = pos2.y + 0.8

        distance = vec_distance(pos2,pos)

        currentvel = self.object:get_velocity()

        if distance > 1 then

            goal = multiply_vec( vec_direction( pos, pos2 ) , 20 - distance )

            velocity = add_vec( new_vec( goal.x - currentvel.x, goal.y - currentvel.y, goal.z - currentvel.z ), player_velocity )

            self.object:add_velocity(velocity)

        elseif distance > 0.9 and temp_pool.buffer > 0 then

            temp_pool.buffer = temp_pool.buffer - dtime

            goal = add_vec( player_velocity, multiply_vec( yaw_to_dir( dir_to_yaw( vec_direction( new_vec( pos.x, 0, pos.z ), new_vec( pos2.x, 0, pos2.z ) ) ) + HALF_PI ), 10 ) )

            velocity = new_vec( goal.x - currentvel.x, goal.y - currentvel.y, goal.z - currentvel.z )

            self.object:add_velocity( velocity )
        end

        -- Collected successfully
        if distance < 0.4 and temp_pool.buffer <= 0 then
            temp_pool.buffer = 0.04
            add_experience( collector, 2 )
            self.object:remove()
            return false
        end

        return true
    end

    self.collector = nil
    self.enable_physics(self)
    return false
end

function xp_orb:on_step(dtime)

    if self:execute_collection(dtime) then return end

    self.age = self.age + dtime

    if self.age > 300 then
        self.object:remove()
        return
    end

    pos = self.object:get_pos()

    if pos then
        node = get_node_or_nil({
            x = pos.x,
            y = pos.y -0.25,
            z = pos.z
        })
    else
        return
    end

    -- Remove nodes in 'ignore'
    if node and node.name == "ignore" then
        self.object:remove()
        return
    end

    if not self.physical_state then
        return -- Don't do anything
    end

    -- Slide on slippery nodes
    vel = self.object:get_velocity()
    def = node and registered_nodes[node.name]
    is_moving = (def and not def.walkable) or vel.x ~= 0 or vel.y ~= 0 or vel.z ~= 0
    is_slippery = false

    if def and def.walkable then

        slippery = get_item_group(node.name, "slippery")

        is_slippery = slippery ~= 0

        if is_slippery and (math_abs(vel.x) > 0.2 or math_abs(vel.z) > 0.2) then
            -- Horizontal deceleration
            slip_factor = 4.0 / ( slippery + 4 )
            self.object:set_acceleration({
                x = -vel.x * slip_factor,
                y = 0,
                z = -vel.z * slip_factor
            })
        elseif vel.y == 0 then
            is_moving = false
        end
    end

    -- Do not update anything until the moving state changes
    if self.moving_state == is_moving and self.slippery_state == is_slippery then return end

    self.moving_state = is_moving
    self.slippery_state = is_slippery

    if is_moving then
        self.object:set_acceleration({x = 0, y = -9.81, z = 0})
    else
        self.object:set_acceleration({x = 0, y = 0, z = 0})
        self.object:set_velocity({x = 0, y = 0, z = 0})
    end
end

minetest.register_entity("experience:orb", xp_orb)


minetest.register_chatcommand("xp", {
    params = "nil",
    description = "Admin command to spawn particles",
    privs = { server = true },
    func = function(player_name)
        local player = get_player_by_name(player_name)
        pos = player:get_pos()
        pos.y = pos.y + 1.2
        pos.x = pos.x + 3
        throw_experience(pos, 1000)
    end,
})