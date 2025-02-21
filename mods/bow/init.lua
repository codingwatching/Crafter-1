local type   = type
local ipairs = ipairs
local get_player_by_name        = minetest.get_player_by_name
local get_objects_inside_radius = minetest.get_objects_inside_radius
local raycast                   = minetest.raycast
local dir_to_yaw                = minetest.dir_to_yaw
local deserialize               = minetest.deserialize
local serialize                 = minetest.serialize
local get_item_group            = minetest.get_item_group
local sound_play                = minetest.sound_play
local item_drop                 = minetest.item_drop
local add_entity                = minetest.add_entity
local string_sub    = string.sub
local string_length = string.len
local math_pi     = math.pi
local math_random = math.random
local HALF_PI     = math_pi / 2

local vec_new       = vector.new
local vec_distance  = vector.distance
local vec_normalize = vector.normalize
local vec_add       = vector.add
local vec_subtract  = vector.subtract
local vec_multiply  = vector.multiply
local vec_divide    = vector.divide
local vec_direction = vector.direction


-- data pool
local pool = {}

local temp_pool
local player
local new_index
local rightclick
local inv
local dir
local vel
local pos
local name
local is_player
local is_owner
local is_object
local is_mob
local new_velocity
local old_velocity
local node_pos
local owner
local pos2
local player_velocity
local direction
local distance
local multiplier
local velocity
local collision
local ray
local y
local x
local initial_velocity

local function arrow_check(player_name,dtime)

    temp_pool = pool[player_name]
    player = get_player_by_name(player_name)
    rightclick = player:get_player_control().RMB
    new_index = player:get_wield_index()

    -- if player changes selected item
    if new_index ~= temp_pool.index then
        inv:set_stack("main", temp_pool.index, ItemStack("bow:bow_empty"))
        pool[player_name] = nil
        return
    end

    -- if player lets go of rightclick
    if temp_pool.step ~= 5 and not rightclick then
        inv:set_stack("main", temp_pool.index, ItemStack("bow:bow_empty"))
        pool[player_name] = nil
        return
    end

    -- if player isn't holding a bow
    if get_item_group(player:get_wielded_item():get_name(), "bow") == 0 then
        pool[player_name] = nil
        return
    end

    inv = player:get_inventory()

    -- if player doesn't have any arrows
    if not inv:contains_item("main", ItemStack("bow:arrow")) then
        inv:set_stack("main", temp_pool.index, ItemStack("bow:bow_empty"))
        pool[player_name] = nil
        return
    end

    -- count steps using dtime
    if temp_pool.step < 5 then

    temp_pool.float = temp_pool.float + dtime

    if temp_pool.float > 0.05 then
        temp_pool.float = 0
        temp_pool.step  = temp_pool.step + 1
        player:set_wielded_item(ItemStack("bow:bow_"..temp_pool.step))
    end

    end

    if temp_pool.step == 5 and not rightclick then
        pos = player:get_pos()
        pos.y = pos.y + 1.5

        dir = player:get_look_dir()
        initial_velocity = vec_multiply( dir, 50)

        local arrow_object = add_entity( vec_add( pos, vec_divide( dir, 10 ) ), "bow:arrow" )

        -- A serious engine glitch has occured
        if not arrow_object then return end

        arrow_object:set_velocity(initial_velocity)
        arrow_object:get_luaentity().owner  = player_name
        arrow_object:get_luaentity().oldpos = pos
        
        sound_play( "bow", {
            object = player,
            gain = 1.0,
            max_hear_distance = 60,
            pitch = math_random( 80, 100 ) / 100
        })

        inv:remove_item( "main", ItemStack( "bow:arrow" ) )
        inv:set_stack( "main", temp_pool.index, ItemStack( "bow:bow_empty" ) )

        pool[player_name] = nil
    end
end

minetest.register_globalstep(function(dtime)
    for player_name in pairs(pool) do
        arrow_check(player_name,dtime)
    end
end)

-- Arrow class
local arrow = {}

-- Arrow fields
arrow.initial_properties = {
    physical = true,
    collide_with_objects = false,
    collisionbox = {-0.05, -0.05, -0.05, 0.05, 0.05, 0.05},
    visual = "mesh",
    visual_size = {x = 1 , y = 1},
    mesh = "basic_bow_arrow.b3d",
    textures = {
        "basic_bow_arrow_uv.png"
    },
    pointable = false
}

arrow.spin = 0
arrow.owner = ""
arrow.stuck = false
arrow.timer = 0
arrow.collecting = false
arrow.collection_height = 0.5
arrow.radius = 2

-- Arrow methods
arrow.on_activate = function(self, staticdata, dtime_s)

    vel = nil
    if string_sub(staticdata, 1, string_length("return")) == "return" then
        local data = deserialize(staticdata)
        if data and type(data) == "table" then
            self.spin       = data.spin
            self.owner      = data.owner
            self.stuck      = data.stuck
            self.timer      = data.timer
            self.collecting = data.collecting
            self.check_dir  = data.check_dir
            vel             = data.vel
        end
    end

    if self.stuck then return end

    self.object:set_acceleration( vec_new( 0, -9.81, 0 ) )
    if not vel then return end

    self.object:set_velocity(vel)

end

arrow.get_staticdata = function(self)
    return serialize({
        spin       = self.spin,
        owner      = self.owner,
        stuck      = self.stuck,
        timer      = self.timer,
        collecting = self.collecting,
        check_dir  = self.check_dir,
        vel        = self.object:get_velocity()
    })
end

function arrow:on_step( dtime, moveresult )

    self.timer = self.timer + dtime

    pos = self.object:get_pos()
    vel = self.object:get_velocity()

    -- The arrow entity is acting like an item entity being collected
    if self.collecting then

        -- Player logged off or a glitch occured
        if not self.owner then
            self.object:remove()
            return
        end

        owner = get_player_by_name(self.owner)

        if not owner then
            self.object:remove()
            return
        end

        -- Get the position vectors
        pos2 = owner:get_pos()
        player_velocity = owner:get_velocity()
        pos2.y = pos2.y + self.collection_height

        direction = vec_normalize(vec_subtract(pos2,pos))
        distance = vec_distance(pos2,pos)


        -- Set the distance to 0 in case the server lags and the player is able to walk away - Instant collection
        if distance > self.radius then
            distance = 0
        end

        multiplier = ( self.radius * 5 ) - distance
        velocity = vec_multiply(direction,multiplier)

        velocity = vec_add(player_velocity,velocity)

        self.object:set_velocity(velocity)

        if distance < 0.2 then
            self.object:remove()
        end

        return

    end


    -- Now the arrow entity is doing it's normal things

    -- The arrow is checking if there is a player or mob to hit, OR, if it's stuck (hit the ground) then try to be collected by a player
    -- This is what causes the arrow entity to fall and hurt you if you mine a node that another player shot at
    for _,object in ipairs(get_objects_inside_radius(pos, 2)) do

        if object == self.object then goto continue end

        is_player = object:is_player()
        is_owner = is_player and object:get_player_name() == self.owner
        is_object = not is_player and object:get_luaentity()
        is_mob = is_object and is_object.is_mob

        -- Something from another mod that isn't supposed to be hit by an arrow
        if not is_player and not is_owner and not is_object and not is_mob then goto continue end

        -- Searching for a player or mob to hurt while flying through the air
        if not self.stuck and ( (is_player and not is_owner and object:get_hp() > 0 ) or ( is_mob and object:get_hp() > 0 ) ) then

            object:punch(self.object, 2, {
                full_punch_interval = 1.5,
                damage_groups = { damage = 3 },
            })

            self.object:remove()

            return

        -- Searching for it's owner to do the collection, it's very lonely :(
        elseif self.timer > 3 and is_owner then

            inv = object:get_inventory()

            if inv and inv:room_for_item( "main", ItemStack( "bow:arrow" ) ) then

                inv:add_item("main",ItemStack("bow:arrow"))

                sound_play("pickup", {
                    to_player = object:get_player_name(),
                    gain = 0.4,
                    pitch = math_random(60,100)/100
                })

                self.collecting = true

                self.object:set_acceleration( vec_new( 0, 0, 0 ) )

            else

                item_drop("bow:arrow", nil, pos)

                self.object:remove()

            end

            return
        end

        ::continue::
    end

    if self.stuck and self.check_dir then
        pos2 = vec_add(pos,vec_multiply(self.check_dir,0.2))
        ray = raycast(pos, pos2, false, false)
        if not ray:next() then
            self.stuck = false
            self.object:set_acceleration(vec_new(0,-9.81,0))
        end
    end

    -- No point in continuing, the arrow is stuck in the ground
    if self.stuck then return end

    if  moveresult and
        moveresult.collides and
        moveresult.collisions and
        moveresult.collisions[1] and
        moveresult.collisions[1].new_velocity then

        collision = moveresult.collisions[1]
        new_velocity = collision.new_velocity
        old_velocity = collision.old_velocity
        node_pos = collision.node_pos

        if new_velocity.x == 0 and old_velocity.x ~= 0 then
            self.check_dir = vec_direction(vec_new(pos.x,0,0),vec_new(node_pos.x,0,0))
        elseif new_velocity.y == 0 and old_velocity.y ~= 0 then
            self.check_dir = vec_direction(vec_new(0,pos.y,0),vec_new(0,node_pos.y,0))
        elseif new_velocity.z == 0 and old_velocity.z ~= 0 then
            self.check_dir = vec_direction(vec_new(0,0,pos.z),vec_new(0,0,node_pos.z))
        end
        if collision.new_pos then
            self.object:set_pos(collision.new_pos)
        end
        --print(dump(collision.new_pos))
        sound_play( "arrow_hit",{
            object = self.object,
            gain = 1,
            pitch = math_random( 80, 100 ) / 100,
            max_hear_distance = 64
        })
        self.stuck = true
        self.object:set_velocity(vec_new(0,0,0))
        self.object:set_acceleration(vec_new(0,0,0))
    end

    -- Makes an arrow spin as it's flying through the air
    if pos and self.oldpos then

        self.spin = self.spin + ( dtime * 10 )

        if self.spin > math_pi then
            self.spin = -math_pi
        end

        dir = vec_normalize( vec_subtract( pos, self.oldpos ) )
        y = dir_to_yaw( dir )
        x = dir_to_yaw( vec_new( vec_distance( vec_new( pos.x, 0, pos.z ), vec_new( self.oldpos.x, 0, self.oldpos.z ) ), 0, pos.y - self.oldpos.y ) ) + HALF_PI
        self.object:set_rotation( vec_new( x, y, self.spin ) )
    end
    
    self.oldpos = pos
    self.oldvel = vel
end

minetest.register_entity("bow:arrow", arrow)


local function initialize_pullback(player)
    inv = player:get_inventory()
    if inv:contains_item("main", ItemStack("bow:arrow")) then
        name = player:get_player_name()
        pool[name] = {}
        pool[name].index = player:get_wield_index()
        pool[name].float = 0
        pool[name].step  = 0
        sound_play( "bow_pull_back", {
            object = player,
            gain = 1.0,
            max_hear_distance = 60,
            pitch = math_random( 70, 110 ) / 100
        })
    end
end


minetest.register_craftitem("bow:bow_empty", {
    description = "Bow",
    inventory_image = "bow.png",
    stack_max = 1,
    groups = { bow = 1 },
    range = 0,
    on_place = function( _, placer )
        initialize_pullback( placer )
    end,
    on_secondary_use = function( _, user )
        initialize_pullback( user )
    end
})

for i = 1,5 do
    minetest.register_craftitem("bow:bow_"..i, {
        description = "Bow",
        inventory_image = "bow_"..i..".png",
        stack_max = 1,
        groups = { bow = 1, bow_loaded = i },
        range = 0,
        on_drop = function( itemstack, dropper, position )
            itemstack = ItemStack("bow:bow_empty")
            item_drop(itemstack, dropper, position)
            return(itemstack)
        end,
    })
end

minetest.register_craftitem( "bow:arrow", {
    description = "Arrow",
    inventory_image = "arrow_item.png",
})


minetest.register_craft({
    output = "bow:bow_empty",
    recipe = {
        { "", "main:stick", "mob:string"},
        { "main:stick", "", "mob:string"},
        { "", "main:stick", "mob:string"},
    },
})

minetest.register_craft({
    output = "bow:arrow 16",
    recipe = {
        { "main:iron", "", "" },
        { "", "main:stick", "" },
        { "", "", "mob:feather" },
    },
})