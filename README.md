![](https://raw.githubusercontent.com/jordan4ibanez/Crafter/master/menu/header.png)

---
Designed for Minetest 5.7.0-DEV

---

Built using textures from [MineClone 2](https://forum.minetest.net/viewtopic.php?t=16407)

---

Be sure to install the clientside mod for this game mode: [Download here](https://github.com/jordan4ibanez/crafter_client)

---

Discord: https://discord.gg/dRPyvubfyg

---

Nodebox creator: https://lunasqu.ee/apps/3d/nodebox/

---

Formspec creator: https://luk3yx.gitlab.io/minetest-formspec-editor/

---

If you want to run this on a server you might want to add this to your server minetest.conf:
Don't be afraid to experiment with it!

```
enable_client_modding = true
csm_restriction_flags = 0
enable_mod_channels = true
secure.http_mods = skins
max_objects_per_block = 4096
max_packets_per_iteration = 10096
```
---


**This game is in early alpha and is being updated from like 2 years of api changes!**

---

# ALPHA STATE CHANGELOG

**This is probably extremely outdated maybe?**

> [Old Version Changelogs](https://github.com/jordan4ibanez/Crafter/blob/master/old_changelog.md)

## Alpha 0.07
> RailRoad Tech

- Added in better minecart algorithm
- Added in ability to link minecarts
- Added in train wrench
- Added in prototype of Engine by using a furnace on a minecart
- Added in SolarShrine's vignette


---
IDEAS:
---
---


## REDSTONE:
- breaker (mines whatever is in front of it)
- dispenser (shoots out first item in inventory, or shoots item into pipe)
- piston in general (if node is falling and piston is pointing up then FLING IT, if detects falling node entity FLING IT)
- redstone bugs which spawn and try to kill you if a stack overflow detection occurs

---



## BUILDTEST:
- quarry
- filter
- siv
- mining lazer
- trains



---


## MOBS:

> #1 idea: weakness items, items that damage the mob more than diamond swords

## redstone bugs
- spawn when a stack overflow detection occurs and is very hostile

## zombies
- zombies drop limbs randomly and a player can use them as a very low durability weapon and place them in the world

## spider
- spider eyes randomly drop as an object and players can wear them and place them

### snowman
- you can put a pumpkin on it's head to make it survive when it's not snowing out
- drops snowballs, coal, or carrot

### sheep
- sheep can be punched to drop wool without damage
- you can dye a sheep with colored dye and it will change color, then will drop the color you dyed it


### pig
- disable pig aggression
- make porkchop look nicer


### ghosts
- make the default player model whited out
- ghosts can pass through any nodes
- ghosts fly around
- will follow you groaning about "diamonds", "need food", and "join us"
- they will fling you up in the air or punch you
- ghosts can drag you down into nodes and suffocate you
- spawn with cave sounds
- drop soul


### node monster
- gets built out of nodes in the area
- will probabaly destroy you
- drops all nodes that it's made of when killed



---


## Game Mechanics:
- brewing
- enchanting/upgrading
- magic (wands, spells, etc)
- better combat ( sweep hit enemies, falling while hitting deals more damage )
- Enchanting food - gives buffs
- LATE effects https://forum.minetest.net/viewtopic.php?t=20724


---


## New Themes

### mechanics (mechanical tools and machines)
- compressor (compresses nodes down)
- auto miner (digs whatever is in front of it)
- decompressor (opposite of compressor


### automation 
- pipes
- pumps
- fluid  transfer
- fluid storage
- pipes should be able to move objects quickly


### HALLOWEEN!
- Jack O'Lanterns
- corn and corn stalks
- decorations
- cobwebs
- costumes (somehow?)
- candy
- make grass and leaves orange during the month of October
- (Use a simple date check and override nodes)
- Gravestones
- Graveyards
- Candles
- candy apples
- Soul cake, make with cake and soul


### Farming
- add fertilizer (pig drops bone randomly) 
- fertilizer is made out of bone - 
- fertilizer can make tall grass grow on regular grass
- bread - 3 bread in a row
- make sandwich with bread and cooked porkchop
- fertilizer used on saplings randomly make tree grow (make sapling growth a function)


### Fishing
- enchanted fish
- player casts out a better lure if on a boat


---


## New Items

> These don't seem to fit into any theme so list them all here

- rope and tnt arrows
- vehicles (car, powered minecarts, trains)
- hitscan flintlocks


---


## Ideas

> These ideas are all over the place but are good for future updates
- make pistons able to push and pull any node that does not use meta or inv
- make pistons able to push and pull deactivated pistons
- upgrade minecart physics even more 
- rewrite minecart
- fix tool rightclick torch placement to replace buildable to nodes
- if placed last node put another stack into hand
- have falling node hurt player?
- add a function to set a velocity goal to entities and then implement it with all entities
- ^make a value if below then stop?
- create a function to check if a node or group is below
- ^ set meta for player so that all mods can use it without calculating it
- ^ over and over again (saves cpu cycles)
- cars buildable in crafting table
- require gas pumps refine oil
- drive next to gas pump and car will fill with gas
- maybe have pump be rightclickable and then manually fill with gass using nozel
- minecart car train? - off rail use
- automatic step height for off rail use
- make cars follow each other
- oil which spawns underground in pools
- powered minecart car (engine car)
- chest minecart car
- player controls engine car

