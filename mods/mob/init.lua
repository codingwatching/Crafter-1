local minetest,math,vector = minetest,math,vector
--this is where mobs are defined

local path = minetest.get_modpath(minetest.get_current_modname())

dofile(path.."/spawning.lua")
dofile(path.."/api/api_hook.lua")
dofile(path.."/items.lua")
dofile(path.."/chatcommands.lua")


mobs.register_mob(
    {
     mobname = "pig",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.37, 0, -0.37, 0.37, 0.85, 0.37},
     visual = "mesh",
     visual_size = {x = 3, y = 3},
     mesh = "pig.b3d",
     textures = {
         --blank out the first two to create adult pig
        "pig.png"
     },
     
     --these are used to anchor a point to the head position


     -----
     head_bone = "head",
     debug_head_pos = false,
     head_directional_offset = 0.5, --used in vector.multiply(minetest.yaw_to_dir(body_yaw),head_offset)
     head_height_offset = 0.8, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,3,-0.5),
     --this is used to tell the game the orientation of the bone (swaps x to and y, then z and y)
     head_coord = "horizontal",
     -----
     
     is_visible = true,
     pointable = true,
     automatic_face_movement_dir = 0,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 10,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 5,
     state = 0,
     view_distance = 15,
     
     item_drop = "mob:raw_porkchop", 
     standing_frame = {x=0,y=0},
     moving_frame = {x=0,y=40},
     animation_multiplier = 20,
     ----
     ----
     death_rotation = "x",
     
     hurt_sound = "pig",
     die_sound = "pig_die",
     
     
     hostile = false,
     attacked_hostile = false,
     attack_type = "punch",
     group_attack = true,

     
     --explosion_radius = 4, -- how far away the mob has to be to initialize the explosion
     --explosion_power = 7, -- how big the explosion has to be
     --explosion_time = 3, -- how long it takes for a mob to explode
     fire_table = {
        visual_size = vector.new(1/3,2/3,1/3),
        position = vector.new(0,3,0),
    }
    }
)

mobs.register_mob(
    {
     mobname = "sheep",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.37, 0, -0.37, 0.37, 0.85, 0.37},
     visual = "mesh",
     visual_size = {x = 3, y = 3},
     mesh = "sheep.b3d",
     textures = {
        "sheep_head_wool.png","sheep_wool.png","sheep.png"
        --"sheep_head_shaved.png","nothing.png","sheep.png"
     },
     
     --these are used to anchor a point to the head position


     -----
     head_bone = "head",
     debug_head_pos = false,
     head_directional_offset = 0.571, --used in vector.multiply(minetest.yaw_to_dir(body_yaw),head_offset)
     head_height_offset = 1.15, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,4.1,-0.86),
     --this is used to tell the game the orientation of the bone (swaps x to and y, then z and y)
     head_coord = "horizontal",
     -----
     
     is_visible = true,
     pointable = true,
     automatic_face_movement_dir = 0,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 10,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 5,
     state = 0,
     view_distance = 15,
     
     item_drop = "mob:raw_porkchop", 
     standing_frame = {x=0,y=0},
     moving_frame = {x=0,y=40},
     animation_multiplier = 20,
     ----
     ----
     death_rotation = "x",
     
     hurt_sound = "sheep",
     die_sound = "sheep",
     
     
     hostile = false,
     attacked_hostile = false,
     attack_type = "punch",
     group_attack = true,

     c_mob_data = {sheared = false},

     custom_on_activate = function(self)
        --print(dump(self.c_mob_data))
        if self.c_mob_data.sheared == true then
            self.object:set_properties({textures = {"sheep_head_shaved.png","nothing.png","sheep.png"}})
        end
     end,

     custom_on_punch = function(self)
        if self.c_mob_data.sheared == false then
            self.object:set_properties({textures = {"sheep_head_shaved.png","nothing.png","sheep.png"}})
            self.c_mob_data = {sheared=true}
            local pos = self.object:get_pos()
            pos.y = pos.y + 0.5
            minetest.throw_item(pos,{name="weather:snow_block"})
        end
    end,
    fire_table = {
        visual_size = vector.new(1/3,2/3,1/3),
        position = vector.new(0,3,0),
    }
    }
    
)

mobs.register_mob(
    {
     mobname = "chicken",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.225, 0, -0.225, 0.225, 0.675, 0.225},
     visual = "mesh",
     visual_size = {x = 3, y = 3},
     mesh = "chicken.b3d",
     textures = {
         --blank out the first two to create adult pig
        "chicken.png"
     },
     
     --these are used to anchor a point to the head position


     -----
     head_bone = "head",
     debug_head_pos = false,
     rotational_correction = -math.pi/2,
     head_directional_offset = 0.2, --used in vector.multiply(minetest.yaw_to_dir(body_yaw),head_offset)
     head_height_offset = 0.82, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,1.8,-0.89),
     --this is used to tell the game the orientation of the bone (swaps x to and y, then z and y)
     head_coord = "vertical",
     flip_pitch = true,
     -----
     
     is_visible = true,
     pointable = true,
     automatic_face_movement_dir = 90,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 10,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 5,
     state = 0,
     view_distance = 15,
     
     item_drop = {"mob:egg","mob:feather"}, 
     standing_frame = {x=20,y=20},
     moving_frame = {x=0,y=20},
     animation_multiplier = 15,
     ----
     ----
     death_rotation = "z",
     
     hurt_sound = "chicken_hurt",
     die_sound = "chicken_die",
     
     
     hostile = false,
     attacked_hostile = false,
     attack_type = "punch",
     group_attack = true,
     --explosion_radius = 4, -- how far away the mob has to be to initialize the explosion
     --explosion_power = 7, -- how big the explosion has to be
     --explosion_time = 3, -- how long it takes for a mob to explode
     fire_table = {
        visual_size = vector.new(1/6,1/2.2,1/6),
        position = vector.new(0,2.3,0),
    }
    }
)


local acceptable_drawtypes = {
    ["normal"] = true,
    ["glasslike"] = true,
    ["glasslike_framed"] = true,
    ["glasslike_framed_optional"] = true,
    ["allfaces"] = true,
    ["allfaces_optional"] = true,
}
local node
local def
mobs.register_mob(
    {
     mobname = "snowman",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.37, 0, -0.37, 0.37, 1.75, 0.37},
     visual = "mesh",
     visual_size = {x = 9, y = 9},
     mesh = "snowman.b3d",
     textures = {
        "snowman.png","snowman.png","snowman.png","snowman.png","snowman.png","snowman.png",
     },
     
     --these are used to anchor a point to the head position


     -----
     head_bone = "head",
     debug_head_pos = false,
     rotational_correction = math.pi/2,
     head_directional_offset = 0.01, --used in vector.multiply(minetest.yaw_to_dir(body_yaw),head_offset)
     head_height_offset = 1.65, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,0.6,0),
     --this is used to tell the game the orientation of the bone (swaps x to and y, then z and y)
     head_coord = "vertical",
     flip_pitch = true,
     -----
     
     is_visible = true,
     pointable = true,
     automatic_face_movement_dir = -90,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 10,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 5,
     state = 0,
     view_distance = 15,
     
     item_drop = {"weather:snowball","main:coal","mob:carrot","main:stick"}, 
     standing_frame = {x=0,y=0},
     moving_frame = {x=0,y=0},
     animation_multiplier = 10,
     ----
     ----
     death_rotation = "z",
     
     hurt_sound = "wool",
     die_sound = "wool",
     
     
     hostile = false,
     attacked_hostile = true,
     attack_type = "projectile",
     projectile_type = "weather:snowball",
     projectile_timer_cooldown = 1,

     custom_function = function(self,dtime,moveresult)
        if moveresult and moveresult.touching_ground then
            local pos = vector.floor(vector.add(self.object:get_pos(),0.5))
            if self.custom_old_pos and not vector.equals(pos,self.custom_old_pos) then
                node = minetest.get_node(pos).name
                if node == "air" then
                    node = minetest.get_node(vector.new(pos.x,pos.y-1,pos.z)).name
                    def = minetest.registered_nodes[node]

                    if not def then return end
                    drawtype = acceptable_drawtypes[def.drawtype]
                    walkable = def.walkable
                    liquid = (def.liquidtype ~= "none")
                    if not liquid and walkable and drawtype and node ~= "main:ice" then
                        minetest.set_node(pos,{name="weather:snow"})
                    end
                end
            end
            self.custom_old_pos = pos
        end
     end,

     custom_timer = 0.75,
     custom_timer_function = function(self,dtime)
        if weather_type and weather_type ~= 1 then
            self.object:punch(self.object, 2, 
                {
                full_punch_interval=1.5,
                damage_groups = {damage=2},
                })
        end
     end,
     fire_table = {
        visual_size = vector.new(1/4,2/3,1/4),
        position = vector.new(0,3.3,0),
    }
    }
)

mobs.register_mob(
    {
     mobname = "phyg",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.37, 0, -0.37, 0.37, 0.85, 0.37},
     visual = "mesh",
     visual_size = {x = 3, y = 3},
     mesh = "phyg.b3d",
     textures = {
         --blank out the first two to create adult pig
        "phyg.png","wings.png"
     },
     
     --these are used to anchor a point to the head position


     -----
     head_bone = "head",
     debug_head_pos = false,
     head_directional_offset = 0.5, --used in vector.multiply(minetest.yaw_to_dir(body_yaw),head_offset)
     head_height_offset = 0.8, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,3,-0.5),
     --this is used to tell the game the orientation of the bone (swaps x to and y, then z and y)
     head_coord = "horizontal",
     -----
     
     is_visible = true,
     pointable = true,
     automatic_face_movement_dir = 0,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     takes_fall_damage = false,
     make_jump_noise = false,
     hp = 10,
     gravity = {x = 0, y = -1, z = 0},
     movement_type = "walk",
     max_speed = 5,
     state = 0,
     view_distance = 15,
     
     item_drop = "main:gold", 
     item_minimum = 4,
     item_max = 5,

     standing_frame = {x=0,y=0},
     moving_frame = {x=0,y=40},
     animation_multiplier = 20,
     ----
     ----
     death_rotation = "x",
     
     hurt_sound = "pig",
     die_sound = "pig_die",
     
     
     hostile = false,
     attacked_hostile = false,
     attack_type = "punch",
     group_attack = true,
     --explosion_radius = 4, -- how far away the mob has to be to initialize the explosion
     --explosion_power = 7, -- how big the explosion has to be
     --explosion_time = 3, -- how long it takes for a mob to explode
     fire_table = {
        visual_size = vector.new(1/3,2/3,1/3),
        position = vector.new(0,3,0),
    }
    }
)


mobs.register_mob(
    {
    mobname = "big_slime",
    physical = true,
     collide_with_objects = false,
     collisionbox = {-1.25, 0, -1.25, 1.25, 2.5, 1.25},
      visual = "mesh",
    visual_size = {x = 15, y = 15},
    mesh = "slime.b3d",
    textures = {
        "slime.png"
    },
    collision_boundary = 2.5,
    is_visible = true,
    pointable = true,
    automatic_face_movement_dir = 90,
    automatic_face_movement_max_rotation_per_sec = 300,
    makes_footstep_sound = false,
    hp = 32,
    gravity = {x = 0, y = -9.81, z = 0},
    movement_type = "jump",
    make_jump_noise = true,
    max_speed = 4,
    hostile = true,
    state = 0,
    view_distance = 20,
    death_rotation = "z",
    hurt_sound = "slime_die",
    die_sound = "slime_die",
    attack_type = "punch",
    attack_damage = 6,
    die_in_light = true,
    custom_on_death = function(self)
        local pos = self.object:get_pos()
        for i = 1,4 do
            local obj = minetest.add_entity(pos,"mob:medium_slime")
            if self.on_fire then
                start_fire(obj)
            end
        end
    end,
    --this is used to properly position fire when the mob catches on fire
    fire_table = {
        visual_size = vector.new(1/5.8,1/3.3,1/5.8),
        position = vector.new(0,1.5,0),
    }
    }
)

mobs.register_mob(
    {
    mobname = "medium_slime",
    physical = true,
     collide_with_objects = false,
     collisionbox = {-0.625, 0, -0.625, 0.625, 1.25, 0.625},
      visual = "mesh",
    visual_size = {x = 7.5, y = 7.5},
    mesh = "slime.b3d",
    textures = {
        "slime.png"
    },
    is_visible = true,
    pointable = true,
    automatic_face_movement_dir = 90,
    automatic_face_movement_max_rotation_per_sec = 300,
    makes_footstep_sound = false,
    hp = 10,
    gravity = {x = 0, y = -9.81, z = 0},
    movement_type = "jump",
    make_jump_noise = true,
    max_speed = 4,
    hostile = true,
    state = 0,
    view_distance = 20,
    death_rotation = "z",
    hurt_sound = "slime_die",
    die_sound = "slime_die",
    attack_damage = 2,
    attack_type = "punch",
    die_in_light = true,
    custom_on_death = function(self)
        local pos = self.object:get_pos()
        pos.y = pos.y + 0.2
        for i = 1,4 do
            local obj = minetest.add_entity(pos,"mob:small_slime")
            if self.on_fire then
                start_fire(obj)
            end
        end
    end,
    fire_table = {
        visual_size = vector.new(1/5.8,1/3.3,1/5.8),
        position = vector.new(0,1.5,0),
    }
    }
)

mobs.register_mob(
    {
    mobname = "small_slime",
    physical = true,
     collide_with_objects = false,
     collisionbox = {-0.3, 0, -0.3, 0.3, 0.6, 0.3},
      visual = "mesh",
    visual_size = {x = 3.7, y = 3.7},
    mesh = "slime.b3d",
    textures = {
        "slime.png"
    },
    is_visible = true,
    pointable = true,
    automatic_face_movement_dir = 90,
    automatic_face_movement_max_rotation_per_sec = 300,
    makes_footstep_sound = false,
    hp = 4,
    gravity = {x = 0, y = -9.81, z = 0},
    movement_type = "jump",
    make_jump_noise = true,
    max_speed = 4,
    hostile = true,
    state = 0,
    view_distance = 20,
    death_rotation = "z",
    hurt_sound = "slime_die",
    die_sound = "slime_die",
    attack_damage = 1,
    attack_type = "punch",
    item_drop = "mob:slimeball",
    die_in_light = true,
    fire_table = {
        visual_size = vector.new(1/5.8,1/3.3,1/5.8),
        position = vector.new(0,1.5,0),
    }
    }
)

--[[


mobs.register_mob(
    {
     mobname = "creepig",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.37, -0.4, -0.37, 0.37, 0.5, 0.37},
     visual = "mesh",
     visual_size = {x = 3, y = 3},
     mesh = "pig.x",
     textures = {
        "creepig_body.png","creepig_leg.png","creepig_leg.png","creepig_leg.png","creepig_leg.png"
    },
     is_visible = true,
     pointable = true,
     automatic_face_movement_dir = -90.0,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 10,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 4,
     hostile = true,
     state = 0,
     view_distance = 20,
     item_drop = "mob:cooked_porkchop",
      
     standing_frame = {x=0,y=0},
     moving_frame = {x=5,y=15},
     animation_multiplier = 5,
     ----
      
     has_head = true, --remove this when mesh based head rotation is implemented
     head_visual = "mesh",
     head_visual_size = {x = 1.1, y = 1.1},
     head_mesh = "pig_head.x",
     head_textures ={"creepig_head.png","creepig_nose.png"},
     head_mount = vector.new(0,1.2,1.9),
     
     death_rotation = "z",
     
     hurt_sound = "pig",
     die_sound = "pig_die",
     
     attack_type = "explode",
     --projectile_timer_cooldown = 5,
     --projectile_type = "tnt:tnt",
     
     explosion_radius = 2, -- how far away the mob has to be to initialize the explosion
     explosion_power = 7, -- how big the explosion has to be
     explosion_time = 5, -- how long it takes for a mob to explode
     
     die_in_light = true,
    }
)

]]--


mobs.register_mob(
    {
     mobname = "zombie",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.23,0, -0.23, 0.23, 1.7, 0.23},
     visual = "mesh",
     visual_size = {x = 3.2, y = 3.2},
     mesh = "zombie.b3d",
     textures = {
        "zombie.png"
    },
     is_visible = true,
     pointable = true,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 27,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 3,
     hostile = true,
     hostile_cooldown = false,
     state = 0,
     view_distance = 32,
     item_drop = "mob:cooked_porkchop",
      
     standing_frame = {x=0,y=0},
     moving_frame = {x=0,y=40},
     animation_multiplier = 20,
     ----
     pathfinds = true,
     
     --these are used to anchor a point to the head position
     -----
     automatic_face_movement_dir = 0,
     head_bone = "Head",
     debug_head_pos = false,
     --this always has to be slightly positive
     head_directional_offset = 0.01,
     head_height_offset = 1.55, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,2.4,0),
     head_coord = "vertical",
     -----
      
     
     death_rotation = "x",
     
     hurt_sound = "hurt",
     die_sound = "hurt",
     sound_pitch_mod_min = 60,
     sound_pitch_mod_max = 80,
     sound_pitch_mod_min_die = 50,
     sound_pitch_mod_max_die = 70,
     attack_type = "punch",
     attack_damage = 3,
     
     die_in_light = true,

     fire_table = {
        visual_size = vector.new(1/4,2/3,1/4),
        position = vector.new(0,3.3,0),
    }
    }
)


mobs.register_mob(
    {
     mobname = "creeper",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.37,0, -0.37, 0.37, 1.5, 0.37},
     visual = "mesh",
     visual_size = {x = 3.2, y = 3.2},
     mesh = "creeper.b3d",
     textures = {
        "creeper.png"
    },
     is_visible = true,
     pointable = true,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 27,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 4,
     hostile = true,
     hostile_cooldown = false,
     state = 0,
     view_distance = 32,
     item_drop = "mob:gunpowder",
      
     standing_frame = {x=0,y=0},
     moving_frame = {x=0,y=40},
     animation_multiplier = 20,
     ----
     pathfinds = true,
     
     --these are used to anchor a point to the head position
     -----
     automatic_face_movement_dir = 0,
     head_bone = "head",
     debug_head_pos = false,
     --this always has to be slightly positive
     head_directional_offset = 0.01,
     head_height_offset = 1.45, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,2.4,0),
     head_coord = "vertical",
     -----
      
     
     death_rotation = "x",
     
     hurt_sound = "creeper_hurt",
     die_sound = "creeper_hurt",
     
     attack_type = "explode",
     --projectile_timer_cooldown = 5,
     --projectile_type = "tnt:tnt",
     
     explosion_radius = 4, -- how far away the mob has to be to initialize the explosion
     explosion_power = 4, -- how big the explosion has to be
     explosion_time = 3, -- how long it takes for a mob to explode
     
     die_in_light = false,
     fire_table = {
        visual_size = vector.new(1/4,2/3,1/4),
        position = vector.new(0,3.3,0),
    }
    }
)

mobs.register_mob(
    {
     mobname = "sneeper",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.37,0, -0.37, 0.37, 1.5, 0.37},
     visual = "mesh",
     visual_size = {x = 3.2, y = 3.2},
     mesh = "creeper.b3d",
     textures = {
        "sneeper.png"
    },
     is_visible = true,
     pointable = true,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 27,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 4,
     hostile = true,
     hostile_cooldown = false,
     state = 0,
     view_distance = 32,
     item_drop = "mob:gunpowder",
      
     standing_frame = {x=0,y=0},
     moving_frame = {x=0,y=40},
     animation_multiplier = 20,
     ----
     pathfinds = true,
     
     --these are used to anchor a point to the head position
     -----
     automatic_face_movement_dir = 0,
     head_bone = "head",
     debug_head_pos = false,
     --this always has to be slightly positive
     head_directional_offset = 0.01,
     head_height_offset = 1.45, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,2.4,0),
     head_coord = "vertical",
     -----
     
     damage_color = "blue",
     
     death_rotation = "x",
     
     hurt_sound = "creeper_hurt",
     die_sound = "creeper_hurt",
     
     attack_type = "explode",
     explosion_type = "weather:snow_block",
     --projectile_timer_cooldown = 5,
     --projectile_type = "tnt:tnt",
     
     explosion_radius = 4, -- how far away the mob has to be to initialize the explosion
     explosion_power = 4, -- how big the explosion has to be
     explosion_time = 3, -- how long it takes for a mob to explode
     
     die_in_light = false,
     fire_table = {
        visual_size = vector.new(1/4,2/3,1/4),
        position = vector.new(0,3.3,0),
    }
    }
)


mobs.register_mob(
    {
     mobname = "nitro_creeper",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.37,0, -0.37, 0.37, 1.5, 0.37},
     visual = "mesh",
     visual_size = {x = 3.2, y = 3.2},
     mesh = "creeper.b3d",
     textures = {
        "nitro_creeper.png"
    },
     is_visible = true,
     pointable = true,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 40,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 6,
     hostile = true,
     hostile_cooldown = false,
     state = 0,
     view_distance = 40,
     item_drop = "mob:gunpowder",

     damage_color = "blue",
      
     standing_frame = {x=0,y=0},
     moving_frame = {x=0,y=40},
     animation_multiplier = 20,
     ----
     pathfinds = true,
     
     --these are used to anchor a point to the head position
     -----
     automatic_face_movement_dir = 0,
     head_bone = "head",
     debug_head_pos = false,
     --this always has to be slightly positive
     head_directional_offset = 0.01,
     head_height_offset = 1.45, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,2.4,0),
     head_coord = "vertical",
     -----
      
     
     death_rotation = "x",
     
     hurt_sound = "creeper_hurt",
     die_sound = "creeper_hurt",
     
     attack_type = "explode",
     --projectile_timer_cooldown = 5,
     --projectile_type = "tnt:tnt",
     
     explosion_radius = 6, -- how far away the mob has to be to initialize the explosion
     explosion_power = 6, -- how big the explosion is (radius)
     explosion_time = 3, -- how long it takes for a mob to explode
     explosion_blink_timer = 0.1, -- how fast the blinking happens
     
     die_in_light = false,
     fire_table = {
        visual_size = vector.new(1/4,2/3,1/4),
        position = vector.new(0,3.3,0),
    }
    }
)

local spider_eyes = {}

spider_eyes.initial_properties = {
    visual = "mesh",
    mesh = "spider_eyes.b3d",
    textures = {"spider_eyes.png"},
    pointable = false,
    collisionbox = {0, 0, 0, 0, 0, 0}
}
spider_eyes.glow = -1
spider_eyes.on_step = function(self)
    if not self.owner or not self.owner:get_luaentity() then
        self.object:remove()
    else
        local owner_head_bone = self.owner:get_luaentity().head_bone
        local position,rotation = self.owner:get_bone_position(owner_head_bone)
        self.object:set_attach(self.owner, owner_head_bone, vector.new(0,0,0), rotation)
    end
end
minetest.register_entity("mob:spider_eyes",spider_eyes)

mobs.register_mob(
    {
     mobname = "spider",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.37, 0, -0.37, 0.37, 0.85, 0.37},
     visual = "mesh",
     visual_size = {x = 3, y = 3},
     mesh = "spider.b3d",
     textures = {
        "spider.png"
     },
     
     --these are used to anchor a point to the head position
     -----
     head_bone = "body.head",
     debug_head_pos = false,
     rotational_correction = -math.pi/2,
     head_directional_offset = 0.3, --used in vector.multiply(minetest.yaw_to_dir(body_yaw),head_offset)
     head_height_offset = 0.63, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,1.24,0),
     --this is used to tell the game the orientation of the bone (swaps x to and y, then z and y)
     head_coord = "horizontal",
     -----
     
     is_visible = true,
     pointable = true,
     automatic_face_movement_dir = 90,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 30,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 4,
     state = 0,
     view_distance = 32,
     
     item_drop = "mob:string", 
     standing_frame = {x=21,y=21},
     moving_frame = {x=0,y=20},
     animation_multiplier = 20,
     ----
     ----
     death_rotation = "z",
     
     hurt_sound = "spider",
     die_sound = "spider_die",
     
     
     pathfinds = true,

     hostile = true,
     friendly_in_daylight = true,
     attacked_hostile = true,
     attack_damage = 3,
     attack_type = "punch",
     group_attack = true,

     custom_on_activate = function(self)
        local eyes = minetest.add_entity(self.object:get_pos(), "mob:spider_eyes")
        eyes:set_attach(self.object, "body.head", vector.new(0,0,0), vector.new(0,0,0))
        eyes:get_luaentity().owner = self.object
        if math.random() > 0.998 then
            local obj = minetest.add_entity(self.object:get_pos(),"mob:pig")
            local obj2 = minetest.add_entity(self.object:get_pos(),"tnt:tnt")
            local obj3 = minetest.add_entity(self.object:get_pos(),"boat:boat")

            obj2:get_luaentity().timer = 7
            obj2:get_luaentity().radius = 7

            obj:set_attach(self.object,"",vector.new(0,3,0),vector.new(0,90,0))
            obj2:set_attach(obj,"",vector.new(0,4.5,0),vector.new(0,90,0))
            obj3:set_attach(obj2,"",vector.new(0,6.5,0),vector.new(0,0,0))

            obj:set_properties({visual_size={x=1,y=1}})
            obj2:set_properties({visual_size={x=1/3,y=1/3}})
        end
     end,
     --explosion_radius = 4, -- how far away the mob has to be to initialize the explosion
     --explosion_power = 7, -- how big the explosion has to be
     --explosion_time = 3, -- how long it takes for a mob to explode
     --this is used to properly position fire when the mob catches on fire
    fire_table = {
        visual_size = vector.new(1.3/3,2/3,1.3/3),
        position = vector.new(0,4,0),
    }
    }
)

mobs.register_mob(
    {
     mobname = "snoider",
     physical = true,
     collide_with_objects = false,
     collisionbox = {-0.37, 0, -0.37, 0.37, 0.85, 0.37},
     visual = "mesh",
     visual_size = {x = 3, y = 3},
     mesh = "spider.b3d",
     textures = {
        "snoider.png"
     },
     
     --these are used to anchor a point to the head position
     -----
     head_bone = "body.head",
     debug_head_pos = false,
     rotational_correction = -math.pi/2,
     head_directional_offset = 0.3, --used in vector.multiply(minetest.yaw_to_dir(body_yaw),head_offset)
     head_height_offset = 0.63, --added to the base y position
     --use this to correct the head position initially because it becomes severly offset - look at your blender model to get this perfect
     head_position_correction = vector.new(0,1.24,0),
     --this is used to tell the game the orientation of the bone (swaps x to and y, then z and y)
     head_coord = "horizontal",
     -----
     
     is_visible = true,
     pointable = true,
     automatic_face_movement_dir = 90,
     automatic_face_movement_max_rotation_per_sec = 300,
     makes_footstep_sound = false,
     hp = 30,
     gravity = {x = 0, y = -9.81, z = 0},
     movement_type = "walk",
     max_speed = 4,
     state = 0,
     view_distance = 32,
     
     item_drop = "mob:string", 
     standing_frame = {x=21,y=21},
     moving_frame = {x=0,y=20},
     animation_multiplier = 20,
     ----
     ----
     death_rotation = "z",
     
     hurt_sound = "spider",
     die_sound = "spider_die",
     
     
     pathfinds = true,

     hostile = true,
     friendly_in_daylight = true,
     attacked_hostile = true,
     attack_damage = 3,
     attack_type = "punch",
     group_attack = true,

     --explosion_radius = 4, -- how far away the mob has to be to initialize the explosion
     --explosion_power = 7, -- how big the explosion has to be
     --explosion_time = 3, -- how long it takes for a mob to explode
     fire_table = {
        visual_size = vector.new(1.3/3,2/3,1.3/3),
        position = vector.new(0,4,0),
    }
    }
)
