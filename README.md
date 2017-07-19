`/!\ THIS IS THE FXSERVER VERSION /!\`
```
Lot of things change in this version, moving to FXServer and MySQL full async requests.
Many functions based on MySQL queries are now async too.
A lot of those changes are not yet documented.
```

# vRP
FiveM RP addon/framework

The project aim to create a generic and simple RP framework to prevent everyone from reinventing the wheel.

Contributions are welcomed.

If you want to try the framework somewhere, here is a list of servers using vRP, without whitelist and managed by me.

vRP test server availables:
* 93.115.96.185 (FR) [(config)](http://93.115.96.185/fivem/servers/FR_cfg.zip) [(discord)](https://discord.gg/ZAdE3eu)

Support me on Patreon to keep this project alive:

[![Support me and the project on Patreon](http://i.imgur.com/dyePK6Q.png)](https://www.patreon.com/ImagicTheCat)

[(old pledgie, thank you to the donors)](https://pledgie.com/campaigns/34016)


See also (and use it as a basis to understand how to develop extensions for vRP) : 
* https://github.com/ImagicTheCat/vRP-basic-mission (repair/delivery missions extension)

## Features
* basic admin tools (kick,ban,whitelist)
* groups/permissions 
* language config file
* player state auto saved to database (hunger,thirst,weapons,player apparence,position)
* player identity
* business system
* aptitudes (education/exp)
* homes (experimental, if a visitor leave in any other way than using the green circle, like crashing, flying or disconnecting, it will require an eject all)
* phone
* cloakrooms (uniform for jobs)
* basic police (PC, check, I.D., handcuff, jails, seize weapons/items)
* basic emergency (coma, reanimate)
* emotes
* money (wallet/bank)
* inventory (with custom item definition, parametric items), chests (vehicle trunks)
* basic implementations: ATM, market, gunshop, skinshop, garage
* item transformer (harvest, process, produce) (illegal informer)
* identification system (persistant user id for database storage)
* user custom data key/value
* gui (dynamic menu, progress bars, prompt) API
* blip, markers (colored circles), areas (enter/leave callbacks) API
* MySQL lua bindings (prepared statements)
* proxy for easy server-side inter-resource developement
* tunnel for easy server/clients communication

## TODO LIST
* home stuff (home garage,etc)
* vehicle customization
* static chests
* drop weapon/save weapon components
* police pc: add custom police records 
* admin: tp to marker
* police research per veh type
* display some permission/group count

## NOTES
### Homes

The home system is experimental, don't expect too much from it at this point. But it's a good basis for some RP interactions, and further developments.

#### How it works

Homes are closed interiors allocated to players when they want to go inside their home, it means that if no slots are availables, you can't enter to your home. Slots are freed when everyone moves out, however if a player dies, crashes or disconnects inside, the slot will not close itself, only "eject all" will close the slot. So it's possible that all slots are locked after a while, restarting the server will fix the issue. 

Also, player addresses are bound to the home cluster name, it means that if you change the cluster configuration name, players will not be able to enter/sell their home anymore. So choose the name well and don't change it, if you don't want to deal with this.

## Tutorials

* [Deployment](#deployment)
  * [Installation](#installation)
  * [Configuration](#configuration)
  * [Update](#update)
  * [Issues / Features / Help](#issues--features--help)
* [Events](#events)
  * [Base](#base)
* [API](#api)
  * [Base](#base-1)
  * [Group/permission](#grouppermission)
  * [Survival](#survival)
  * [Police](#police)
  * [Player state](#player-state)
  * [Identity](#identity)
  * [Money](#money)
  * [Inventory](#inventory)
  * [Item transformer](#item-transformer)
  * [Home](#home)
  * [Mission](#mission)
  * [GUI](#gui)
     * [Registering choices to the main menu](#registering-choices-to-the-main-menu)
  * [Map](#map)
* [Libs](#libs)
  * [Proxy](#proxy)
  * [Tunnel](#tunnel)
  * [MySQL](#mysql)

[(gh-md-toc)](https://github.com/ekalinin/github-markdown-toc)

### Deployment
#### Installation

vRP has been tested under Windows and GNU/Linux with Mono 4.8.

First, make sure you don't have other resources loaded (especially resources using MySQL, add them later and see if they break vRP).
vRP use a new version of MySql.Data.dll, the 4.5, since only one version can be loaded at a time, if another resource load an older version, things will get crazy.

Then clone the repository or download the master [archive](https://github.com/ImagicTheCat/vRP/archive/master.zip) and copy the `vrp/` directory to your resource folder. Add `vrp_mysql` then `vrp` to the loading resource list (first after the basic FiveM resources is better).

#### Configuration

Only the files in the `cfg/` directory should be modified. Modifying the vRP core files is highly discouraged (don't open an issue if it's about modified core files).

There is only one required file to configure before launching the server, `cfg/base.lua`, to setup the MySQL database credentials.

There is a lot to configure in vRP, nothing comes preconfigured so everyone can make his unique server. 
Everything you need to know is in the configuration files, but if you have troubles configuring, look at the configuration of the vRP LaTest servers above.

#### Update

vRP will warn you at server launch if a new version is available. You can also update while I commit things, but do that only if you like to beta test, because you will need to update a lot.

A way to update:
* save your `cfg/` folder somewhere
* copy all new files in `vrp/`
* compare your old `cfg/` folder with the new one, fill the gaps (one mistake will break everything, take your time)
* replace the new `cfg/` folder with the old modified `cfg/` folder

#### Issues / Features / Help

The issue section is only for bug reports and feature requests. I will close (and ban) issues not related to the core of vRP, to keep the github clean.
Don't submit issues about your own modifications, I will close them without warning.

When submitting an issue, add any information you can find, with all details. Saying that something doesn't work is useless and will not solve the issue. 
If you have errors in your console BEFORE the issue happen, everything could be corrupted, so the issue is irrelevant, you should solve all unrelated errors before submitting issues.

For questions, help, discussions around the project, please go instead on the vRP thread of the FiveM forum here: https://forum.fivem.net/t/release-vrp-framework/22894

### Events
#### Base

```lua

-- (server) called after identification 
AddEventHandler("vRP:playerJoin",function(user_id,source,name,last_login) end)

-- (server) called when the player join again without triggering the vRP:playerLeave event before
-- (used after a client crash for example)
AddEventHandler("vRP:playerRejoin",function(user_id,source,name) end)

-- (server) called when a logged player spawn
AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn) end)

-- (server) called when a player leave
AddEventHandler("vRP:playerLeave",function(user_id, source) end)

-- (server) called when a player join a group
-- gtype can be nil
AddEventHandler("vRP:playerJoinGroup", function(user_id, group, gtype) end)

-- (server) called when a player leave a group
-- gtype can be nil
AddEventHandler("vRP:playerLeaveGroup", function(user_id, group, gtype) end)

```

### API

To call the server-side API functions, get the vRP interface.

```lua
local Proxy = require("resources/vRP/lib/Proxy")

vRP = Proxy.getInterface("vRP")

-- ex:
vRP.getUserId({source},function(user_id)
  print("user_id = "..user_id)
end)
```

You can also do it client-side, the API is the same as the TUNNEL CLIENT APIs (copy and add the `vrp/client/Proxy.lua` to your resources, first).

```lua
vRP = Proxy.getInterface("vRP")

-- ex:
vRP.notify({"A notification."}) -- notify the player
```

For the client/server tunnel API, the interface is also "vRP", see the Tunnel library below.

In the config files callbacks, you can use directly vRP and vRPclient (the tunnel to the clients).

#### Base

```lua
-- PROXY API

-- return map of user_id -> player source
vRP.getUsers()

-- return user id or nil if the source is invalid
vRP.getUserId(source)

-- return source of the user or nil if not connected
vRP.getUserSource(user_id)

-- set user data (textual data)
vRP.setUData(user_id,key,value)

-- get user data (textual data)
-- return nil if data not found
vRP.getUData(user_id,key)

-- set server data (textual data)
vRP.setSData(key,value)

-- get server data (textual data)
-- return nil if data not found
vRP.getSData(key)

-- TUNNEL SERVER API

-- TUNNEL CLIENT API

-- teleport the player to the specified coordinates
vRP.teleport(x,y,z)

-- get the player position
-- return x,y,z
vRP.getPosition()

-- get the player speed
-- return speed 
vRP.getSpeed()

-- return false if in exterior, true if inside a building
vRP.isInside()

-- notify the player
vRP.notify(message)

-- play a screen effect
-- name, see https://wiki.fivem.net/wiki/Screen_Effects
-- duration: in seconds, if -1, will play until stopScreenEffect is called
vRP.playScreenEffect(name, duration)

-- stop a screen effect
-- name, see https://wiki.fivem.net/wiki/Screen_Effects
vRP.stopScreenEffect(name)



-- FUNCTIONS BELOW ARE EXPERIMENTALS

-- get nearest players (inside the radius)
-- return map of player => distance in meters
vRP.getNearestPlayers(radius)

-- get nearest player (inside the radius)
-- return player or nil
vRP.getNearestPlayer(radius)


-- animations dict/name: see http://docs.ragepluginhook.net/html/62951c37-a440-478c-b389-c471230ddfc5.htm

-- play animation (new version)
-- upper: true, only upper body, false, full animation
-- seq: list of animations as {dict,anim_name,loops} (loops is the number of loops, default 1)
-- looping: if true, will infinitely loop the first element of the sequence until stopAnim is called
vRP.playAnim(upper, seq, looping)

-- stop animation (new version)
-- upper: true, stop the upper animation, false, stop full animations
vRP.stopAnim(upper)

-- SOUND
-- some lists: 
-- pastebin.com/A8Ny8AHZ
-- https://wiki.gtanet.work/index.php?title=FrontEndSoundlist

-- play sound at a specific position
vRP.playSpatializedSound(dict,name,x,y,z,range)

-- play sound
vRP.playSound(dict,name)
```

#### Group/permission

Group and permissions are a way to limit features to specific players.
Each group have a set of permissions defined in `cfg/groups.lua`.
Permissions can be used with most of the vRP modules, giving the ability to create specific garages, item transformers, etc.

##### Regular permissions

Regular permissions are plain text permissions, they can be added to groups. You can add a `-` before the permission to negate (even if other groups add the permission, they will be ignored).

##### Special item permission

You can use a special permission to check for items.
Form: `#idname.operator`, operators to check the amount are greater `>`, less `<`, equal ` `. Ex:
* `#tacos.>0` -> one or more tacos
* `#weed.1` -> exactly one weed

##### Special aptitude permission

You can use a special permission to check for aptitudes.
Form: `@group.aptitude.operator`, operators to check the level are greater `>`, less `<`, equal ` `. Ex:
* `@physical.strength.3` -> strength level equal to 3
* `@science.chemicals.>4` -> chemicals science level greater or equal to 5

##### API

```lua
-- PROXY API

-- add a group to a connected user
vRP.addUserGroup(user_id,group)

-- remove a group from a connected user
vRP.removeUserGroup(user_id,group)

-- check if the user has a specific group
vRP.hasGroup(user_id,group)

-- check if the user has a specific permission
vRP.hasPermission(user_id, perm)

-- check if the user has a specific list of permissions (all of them)
vRP.hasPermissions(user_id, perms)

-- get user group by group type
-- return group name or an empty string
vRP.getUserGroupByType(user_id,gtype)

-- return list of connected users by group
vRP.getUsersByGroup(group)

-- return list of connected users by permission
vRP.getUsersByPermission(perm)
```

#### Survival

Running, walking, being hurt/injured, and just living add hunger and thirst. When the hunger and the thirst are at their maximum level (100%), next hunger/thirst overflow will damage the character by the same amount (ex: when thirsty, don't run, take a car).
This module disable the basic health regen.

The survival module implement also a coma system, if the health of the player is below the coma threshold, the player is in coma for a specific duration before dying. The health (thus coma) is recorded in the player state.
If a player disconnect and reconnect while in coma, he will fall in coma again and die in a few seconds.

```lua
-- PROXY API

-- return hunger (0-100)
vRP.getHunger(user_id)

-- return thirst (0-100)
vRP.getThirst(user_id)

vRP.setHunger(user_id,value)

vRP.setThirst(user_id,value)

-- vary hunger value by variation amount (+ to add hunger, - to remove hunger)
vRP.varyHunger(user_id,variation)

-- same as vary hunger
vRP.varyThirst(user_id,variation)

-- TUNNEL SERVER API

-- TUNNEL CLIENT API

-- player health variation (+ to heal, - to deal damage)
vRP.varyHealth(variation)

-- get player health
vRP.getHealth()

-- set player health
vRP.setHealth(health)

-- check if the player is in coma
vRP.isInComa()

-- enable/disable spawned player ability to hurt friendly
-- flag: boolean
vRP.setFriendlyFire(flag)

-- enable/disable spawned player ability to be chased/arrested by cops
-- flag: boolean
vRP.setPolice(flag)
```

#### Police

```lua
-- PROXY API

-- insert a police record for a specific user
--- line: text for one line (can be html)
vRP.insertPoliceRecord(user_id, line)

-- TUNNEL SERVER API

-- TUNNEL CLIENT API

-- apply wanted level
-- stars 1-5
vRP.applyWantedLevel(stars)

-- true to enable, false to disable
-- if enabled, will prevent NPC cops to fire at the player
vRP.setCop(flag)
```

#### Player state
```lua
-- PROXY API

-- TUNNEL SERVER API

-- TUNNEL CLIENT API

-- get player weapons data
-- return table with weapons data, use print(json.encode(result)) to understand the structure
vRP.getWeapons()

-- give weapons
-- weapons: same structure as returned by getWeapons()
-- (optional) clear_before: if true, will remove all the weapons before adding the new ones
vRP.giveWeapons(weapons,clear_before)

-- get player apparence customization data
-- return table with customization data, use print(json.encode(result)) to understand the structure
-- .model or .modelhash define the player model, the indexes define each component as [drawable_id,texture_id,palette_id] array
-- props are referenced using the prefix "p" for the key (p0,p1,p2,p...), -1 = no prop
vRP.getCustomization()

-- set player apparence
-- customization_data: same structure as returned by getCustomization()
vRP.setCustomization(customization_data)
```

#### Identity 

The identity module add identity cards with a car registration number (one per identity, all vehicles will have the same registration number).

```lua
-- PROXY API

-- get user identity
-- return nil if not found
-- identity keys are the database fields: user_id, name, firstname, age, registration
vRP.getUserIdentity(user_id)
```

#### Money

The money is managed with direct SQL queries to prevent most potential value corruptions.
The wallet empties itself when respawning (after death).

```lua
-- PROXY API

-- get money in wallet
vRP.getMoney(user_id)

-- set money in wallet
vRP.setMoney(user_id,value)

-- try a payment (wallet only)
-- return true or false (debited if true)
vRP.tryPayment(user_id,amount)

-- try full payment (wallet + bank to complete payment)
-- return true or false (debited if true)
vRP.tryFullPayment(user_id,amount)

-- give money to wallet
vRP.giveMoney(user_id,amount)

-- get bank money
vRP.getBankMoney(user_id)

-- set bank money
vRP.setBankMoney(user_id,value)

-- try a withdraw
-- return true or false (withdrawn if true)
vRP.tryWithdraw(user_id,amount)

-- try a deposit
-- return true or false (deposited if true)
vRP.tryDeposit(user_id,amount)

-- TUNNEL SERVER API

-- TUNNEL CLIENT API
```

#### Inventory

The inventory is autosaved and, as the wallet, gets empty upon death.

##### Items

Items are simple identifiers associated with a quantity in an inventory. But they can also be parametrics.

Parametrics items are identified like other items in the inventory but also have arguments as: `weapon|pistol` instead of just an ID. Parametric items don't contain any data, they are generic item definitions that will be specialized by the arguments.

```lua
-- PROXY API

-- define an inventory item (call this at server start) (parametric or plain text data)
-- idname: unique item name
-- name: display name or genfunction
-- description: item description (html) or genfunction
-- choices: menudata choices (see gui api) only as genfunction or nil
-- weight: weight or genfunction
--
-- genfunction are functions returning a correct value as: function(args) return value end
-- where args is a list of {base_idname,arg,arg,arg,...}

vRP.defInventoryItem(idname,name,description,choices,weight)

-- return name, description, weight
vRP.getItemDefinition(idname)

vRP.getItemName(idname)

vRP.getItemDescription(idname)

vRP.getItemChoices(idname)

vRP.getItemWeight(idname)

-- add item to a connected user inventory
vRP.giveInventoryItem(user_id,idname,amount,notify)

-- try to get item from a connected user inventory
-- return true if the item has been found and the quantity removed
vRP.tryGetInventoryItem(user_id,idname,amount,notify)

-- clear connected user inventory
vRP.clearInventory(user_id)

-- compute weight of a list of items (in inventory/chest format)
vRP.computeItemsWeight(items)

-- return user inventory total weight
vRP.getInventoryWeight(user_id)

-- return user inventory max weight
vRP.getInventoryMaxWeight(user_id)

-- open a chest by name
-- cb_close(): called when the chest is closed
vRP.openChest(source, name, max_weight, cb_close)

-- TUNNEL SERVER API

-- TUNNEL CLIENT API
```

Full example of a resource defining a water bottle item.
Once defined, items can be used by any resources (ex: they can be added to shops).

```lua
local Proxy = require("resources/vRP/lib/Proxy")
local Tunnel = require("resources/vRP/lib/Tunnel")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","vrp_waterbottle")

-- create Water bottle item (the callback hell begins) 
local wb_choices = {}  -- (see gui API for menudata choices structure)

wb_choices["Drink"] = {function(player,choice) -- add drink action
  local user_id = vRP.getUserId({player}) -- get user_id
  if user_id ~= nil then
    if vRP.tryGetInventoryItem({user_id,"water_bottle",1}) -- try to remove one bottle
      vRP.varyThirst({user_id,-35}) -- decrease thirst
      vRPclient.notify(player,{"~b~ Drinking."}) -- notify
      vRP.closeMenu({player}) -- the water bottle is consumed by the action, close the menu
    end
end
end,"Do it."}

-- add item definition
vRP.defInventoryItem({"water_bottle","Water bottle","Drink this my friend.",function() return wb_choices end,0.5})

-- (at any time later) give 2 water bottles to a connected user
vRP.giveInventoryItem({user_id,"water_bottle",2})

```

#### Item transformer

The item transformer is a very generic way to create harvest and processing areas.
The concept is simple: 
* you can use the action of the item transformer when entering the area
* the item transformer has a number of work units, regenerated at a specific rate
* the item transformer takes reagents (money, items or none) to produce products (money or items) and it consumes a work unit

This way, processing and harvesting are limited by the work units.
Item transformers can be dynamically set and removed, if you want to build random harvest points.

```lua
-- add an item transformer
-- name: transformer id name
-- itemtr: item transformer definition table
--- name
--- permissions (optional)
--- max_units
--- units_per_minute
--- x,y,z,radius,height (area properties)
--- r,g,b (color)
--- recipes, map of action =>
---- description
---- in_money
---- out_money
---- reagents: items as idname => amount
---- products: items as idname => amount
---- aptitudes: list as "group.aptitude" => exp amount generated
--- onstart(player,recipe): optional callback
--- onstep(player,recipe): optional callback
--- onstop(player,recipe): optional callback
vRP.setItemTransformer(name,itemtr)

-- remove an item transformer
vRP.removeItemTransformer(name)


-- Example from another resource using proxy

local itemtr = {
  name="Water bottles tree", -- menu name
  r=0,g=125,b=255, -- color
  max_units=10,
  units_per_minute=5,
  x=1858,y=3687.5,z=34.26, -- pos
  radius=5, height=1.5, -- area
  recipes = {
    ["Harvest"] = { -- action name
      description="Harvest some water bottles.", -- action description
      in_money=0, -- money taken per unit
      out_money=0, -- money earned per unit
      reagents={}, -- items taken per unit
      products={ -- items given per unit
        ["water_bottle"] = 1
      }
    }
  }
}

vRP.setItemTransformer({"my_unique_transformer",itemtr})
```

For static areas, configure the file `cfg/item_transformers.lua`, the transformers will be automatically added.

#### Home

```lua
-- PROXY API

-- define home component
-- name: unique component id
-- oncreate(owner_id, slot_type, slot_id, cid, config, x, y, z, player)
-- ondestroy(owner_id, slot_type, slot_id, cid, config, x, y, z, player)
vRP.defHomeComponent(name, oncreate, ondestroy)

-- user access a home by address (without asking)
-- return true on success
vRP.accessHome(user_id, home, number)
```

##### Basic components

###### Chest

`chest`
A home chest.

```lua
_config = {
  weight = 200
}
```

###### Wardrobe

`wardrobe`
Save your character customization in the wardrobe, so you don't need to customize/pay clothes in skinshop again.

###### Game table

`gametable`
* Bet with other peoples.

###### Item transformer

`itemtr`
Set the config as any item transformer structure configuration.


#### Mission

```lua
-- PROXY API

-- start a mission for a player
--- mission_data: 
---- name: Mission name
---- steps: ordered list of
----- text
----- position: {x,y,z}
----- onenter(player,area)
----- onleave(player,area) (optional)
----- blipid, blipcolor (optional)
vRP.startMission(player, mission_data)

-- end the current player mission step
vRP.nextMissionStep(player)

-- stop the player mission
vRP.stopMission(player)

-- check if the player has a mission 
vRP.hasMission(player)
```

#### GUI

Controls for the menu generated by the API are the cellphone controls (LEFT,RIGHT,UP,DOWN,CANCEL,SELECT and OPEN to open the main menu).
Don't forget to change the key to open the phone for something different than UP. You can also use the middle mouse button by default.

You can customize the GUI css in `cfg/gui.lua`.


```lua
-- PROXY API

-- HOW TO: building a dynamic menu
local menudata = {}
menudata.name = "My Menu"

-- shift menu from the top by 75px and set the menu header to green
menudata.css = {top = "75px", header_color = "rgba(0,255,0,0.75)"} -- exhaustive list

menudata.onclose = function(player)
  print("menu closed")
end

local onchoose = function(player,choice,mod)
  -- mod will be input modulation -1,0,1 (left,(c)enter,right)
  print("player choose "..choice)
  vRP.closeMenu({source}) -- ({} because proxy call) close the menu after the first choice (an action menu for example)
end

-- add options and callbacks
menudata["Option1"] = {onchoose, "this <b>option</b> is amazing"} -- callaback and description
menudata["Option two"] = {onchoose} -- no description
menudata["Another option"] = {function(choice) print("another option choice") end,"this<br />one<br />is<br />better"}
-- END HOW TO

-- open a dynamic menu to the client (will close previously opened menus)
vRP.openMenu(source, menudata)

-- close client active menu
vRP.closeMenu(source)

-- prompt textual (and multiline) information from player
-- cb_result: function(player,result)
vRP.prompt(source,title,default_text,cb_result)

-- ask something to a player with a limited amount of time to answer (yes|no request)
-- time: request duration in seconds
-- cb_ok: function(player,ok)
vRP.request(source,text,time,cb_ok)

-- STATIC MENUS

-- define choices to a static menu by name (needs to be called like inventory item definition, at initialization)
vRP.addStaticMenuChoices(name, choices)

-- TUNNEL SERVER API

-- TUNNEL CLIENT API


-- progress bar


-- create/update a progress bar 
-- anchor: the anchor string type (multiple progress bars can be set for the same anchor)
---- "minimap" => above minimap (will divide that horizontal space)
---- "center" => center of the screen, at the bottom
---- "botright" => bottom right of the screen
vRP.setProgressBar(name,anchor,text,r,g,b,value)

-- set progress bar value in percent
vRP.setProgressBarValue(name,value)

-- set progress bar text
vRP.setProgressBarText(name,text)

-- remove progress bar
vRP.removeProgressBar(name)


-- div

-- dynamic div are used to display formatted data
-- if only some part of the div changes, use JS pre-defined functions to hide/show the div and change the data

-- set a div
-- css: plain global css, the div class is ".div_nameofthediv"
-- content: html content of the div
vRP.setDiv(name,css,content)

-- set the div css
vRP.setDivCss(name,css)

-- set the div content
vRP.setDivContent(name,content)

-- execute js for the div in a simple sandbox 
-- you can attach objects or functions to the div element for later calls
-- use div.querySelector to find the div children elements
-- js context: div (the div element)
vRP.divExecuteJS(name,js)

-- remove the div
vRP.removeDiv(name)

-- announce

-- add an announce to the queue
-- background: image url (800x150)
-- content: announce html content
vRP.announce(background,content)

```

##### Registering choices to the main menu

The main menu is generated using an event, this is useful to add special choices if needed.

```lua
-- in another resource using the proxy interface

AddEventHandler("vRP:buildMainMenu",function(player) 
  local choices = {}
  
  local fchoice = function(player,choice)
    print("player "..player.." choose "..choice)
  end

  choices["My Choice"] = {fchoice,"My choice description."}
  choices["My Choice 2"] = {fchoice,"My choice 2 description."}

  vRP.buildMainMenu({player,choices}) -- add choices to the player main menu
end)
```

#### Map

```lua
-- PROXY API

-- create/update a player area (will trigger enter and leave callbacks)
-- cb_enter, cb_leave: function(player,area_name)
vRP.setArea(source,name,x,y,z,radius,height,cb_enter,cb_leave)

-- remove a player area 
vRP.removeArea(source,name)

-- TUNNEL SERVER API

-- TUNNEL CLIENT API

-- set the GPS destination marker coordinates
vRP.setGPS(x,y)

-- set route to native blip id
vRP.setBlipRoute(id)

-- create new blip, return native id
vRP.addBlip(x,y,z,idtype,idcolor,text)

-- remove blip by native id
vRP.removeBlip(id)

-- set a named blip (same as addBlip but for a unique name, add or update)
-- return native id
vRP.setNamedBlip(name,x,y,z,idtype,idcolor,text)

-- remove a named blip
vRP.removeNamedBlip(name)

-- add a circular marker to the game map
-- return marker id
vRP.addMarker(x,y,z,sx,sy,sz,r,g,b,a,visible_distance)

-- remove marker
vRP.removeMarker(id)

-- set a named marker (same as addMarker but for a unique name, add or update)
-- return id
vRP.setNamedMarker(name,x,y,z,sx,sy,sz,r,g,b,a,visible_distance)

-- remove a named marker
vRP.removeNamedMarker(name)

```

### Libs

#### Proxy

The proxy lib is used to call other resources functions through a proxy event.

Ex:

resource1.lua
```lua
local Proxy = require("resources/vRP/lib/Proxy")

Resource1 = {}
Proxy.addInterface("resource1",Resource1) -- add functions to resource1 interface (can be called multiple times if multiple files declare different functions for the same interface)

function Resource1.test(a,b)
  print("resource1 TEST "..a..","..b)
  return a+b,a*b -- return two values
end
```
resource2.lua
```lua
local Proxy = require("resources/vRP/lib/Proxy")

Resource1 = Proxy.getInterface("resource1")

local rvalue1, rvalue2 = Resource1.test({13,42})
print("resource2 TEST rvalues = "..rvalue1..","..rvalue2)
```

The notation is **Interface.function({arguments})**.

#### Tunnel

The idea behind tunnels is to easily access any declared server function from any client resource, and to access any declared client function from any server resource.

Example of two-way resource communication:

Server-side myrsc
```lua
local Tunnel = require("resources/vRP/lib/Tunnel")

-- build the server-side interface
serverdef = {} -- you can add function to serverdef later in other server scripts
Tunnel.bindInterface("myrsc",serverdef)

function serverdef.test(msg)
  print("msg "..msg.." received from "..source)
  return 42
end

-- get the client-side access
clientaccess = Tunnel.getInterface("myrsc","myrsc") -- the second argument is a unique id for this tunnel access, the current resource name is a good choice

-- (later, in a player spawn event) teleport the player to 0,0,0
clientaccess.teleport(source,{0,0,0})
```

Client-side myrsc (copy the resources/vRP/client/Tunnel.lua and add it first to the client scripts of your resource)
```lua

-- build the client-side interface
clientdef = {} -- you can add function to clientdef later in other client scripts
Tunnel.bindInterface("myrsc",clientdef)

function clientdef.teleport(x,y,z)
  SetEntityCoords(GetPlayerPed(-1), x, y, z, 1,0,0,0) 
end

-- sometimes, you would want to return the tunnel call asynchronously
-- ex:
function clientdef.setModel(hash)
  local exit = TUNNEL_DELAYED() -- get the delayed return function

  Citizen.CreateThread(function()
    -- do the asynchronous model loading
    Citizen.Wait(1000)

    exit({true}) -- return a boolean to confirm loading (calling exit will not really exit the function, but just send back the array as the tunnel call return values, so call it wisely)
  end)
end

-- get the server-side access
serveraccess = Tunnel.getInterface("myrsc","myrsc") -- the second argument is a unique id for this tunnel access, the current resource name is a good choice

-- call test on server and print the returned value
serveraccess.test({"my client message"},function(r)
  print(r)
end)

```

Now if we want to use the same teleport function in another resource:

```lua
local Tunnel = require("resources/vRP/lib/Tunnel")

-- get the client-side access of myrsc
myrsc_access = Tunnel.getInterface("myrsc","myotherrsc")

-- (later, in a player spawn event) teleport the player to 0,0,0
myrsc_access.teleport(source,{0,0,0})
```

This way resources can easily use other resources client/server API.

A magic trick with the tunnel system (which is based on the TriggerEvent), imagine we want to teleport all players to the same position:

```lua
clientaccess.teleport(-1,{0,0,0},function()
  print("player "..source.." teleported") -- will be displayed for each teleported player
end)
```

#### MySQL

```lua
local MySQL = require("resources/vRP/lib/MySQL/MySQL")

-- host can be "host" or "host:port"
local sql = MySQL.open("127.0.0.1","user","password","database") -- add ,true) to enable debug for the connection
local q_init = sql:prepare([[
CREATE IF NOT EXISTS list(
  name VARCHAR(255),
  value INTEGER,
  CONSTRAINT pk_list PRIMARY KEY(name)
);
]])
q_init:execute()

local q_insert = sql:prepare("INSERT INTO list(name,value) VALUES(@name,@value)")

for i=0,100 do
  q_insert:bind("@name","entry"..i)
  q_insert:bind("@value",i*5)
  q_insert:execute()
  
  print("inserted id = "..q_insert:last_insert_id())
end

local q_select = sql:prepare("SELECT * FROM list")
local r = q_select:query() 
print("NAME VALUE")
while r:fetch() do
  print(r:getValue("name").." "..r:getValue("value"))
  -- or print(r:getValue(0).." "..r:getValue(1))
  -- or local row = r:getRow()
end

r:close() -- don't forget to close the result

-- or
local r = q_select:query() 
local list = r:toTable() -- result is autoclosed
```

