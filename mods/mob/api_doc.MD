# Mobs API

Welcome to my mobs api documentation. This will teach you how to create a mob for Crafter.

There are a few requirements that you will need.

1. A model
2. An animation for the model (if you want)
3. Some sounds (if you want)
4. Some patience

---
## Step 1
---

We must create the mob for your mod. So you're going to need to depend on mob. Just add in this line into your ``mod.conf`` file:

```
depends = mob
```
Fantastic, you've conquered the first step. Now we must actually create the mob. So let's do that. In your ``init.lua``, or wherever this is running, add this:

```lua
minetest.register_mob({
    name = "my_cool_mob"
})
```

So this allows you to create a definition for my_cool_mob! Remember: your mob will be called ``mob:my_cool_mob``, or whatever you call it, in game. That's quite alright though. You can use ``/spawn my_cool_mob`` so you don't have to worry about the mod namespace.

Okay so what is this empty table? ``{}`` Well the empty table is where you're going to put all the definitions for your cool mob! Now let's get into the basics of the definition table.

---
# API

The name of the mob.
```lua
name = "a_flying_pig"
```
If your mob collides with the terrain. False could be used for things like ghosts.
```lua
physical = true
```
The collisionbox of the mob. Remember, this is -xyz, +xyz. Set -y to 0 so your mob works correctly.
```lua
collisionbox = {-0.37, 0, -0.37, 0.37, 0.85, 0.37},
```
Sets the draw type of your mob. This is using a normal mesh type in this specific example.
```lua
visual = "mesh",
visual_size = { x = 1, y = 1 },
mesh = "my_cool_mob.b3d",
textures = {"my_cool_mob.png"}
```