local lang = vRP.lang

-- this module define some police tools and functions
local Police = class("Police", vRP.Extension)

-- SUBCLASS

Police.User = class("User")

-- insert a police record for a specific user
--- record: text for one line (html)
function Police.User:insertPoliceRecord(record)
  table.insert(self.police_records, record)
  self:savePoliceRecords()
end

function Police.User:savePoliceRecords()
  -- save records
  vRP:setCData(self.cid, "vRP:police:records", msgpack.pack(self.police_records))
end

-- PRIVATE METHODS

-- menu: police pc
local function menu_police_pc(self)
  local m_police_pc_css = [[
.div_police_pc{ 
  background-color: rgba(0,0,0,0.75); 
  color: white; 
  font-weight: bold; 
  width: 500px; 
  padding: 10px; 
  margin: auto; 
  margin-top: 150px; 
}
  ]]

  local function e_pc_div_close(menu)
    if menu.pc_div then
      vRP.EXT.GUI.remote._removeDiv(menu.user.source,"police_pc")
      menu.pc_div = nil
    end
  end

  -- search identity by registration
  local function m_searchreg(menu)
    local user = menu.user


    local reg = user:prompt(lang.police.pc.searchreg.prompt(),"")
    local cid = vRP.EXT.Identity:getByRegistration(reg)
    if cid then
      local identity = vRP.EXT.Identity:getIdentity(cid)
      if identity then
        -- display identity and business
        local name = identity.name
        local firstname = identity.firstname
        local age = identity.age
        local phone = identity.phone
        local registration = identity.registration
        local bname = ""
        local bcapital = 0
        local home = ""
        local number = ""

        local business = vRP.EXT.Business:getBusiness(cid)
        if business then
          bname = business.name
          bcapital = business.capital
        end

        local address = vRP.EXT.Home:getAddress(cid)
        if address then
          home = address.home
          number = address.number
        end

        e_pc_div_close(menu)

        local content = lang.police.identity.info({name,firstname,age,registration,phone,bname,bcapital,home,number})
        vRP.EXT.GUI.remote._setDiv(user.source,"police_pc",m_police_pc_css,content)
      else
        vRP.EXT.Base.remote._notify(user.source,lang.common.not_found())
      end
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.not_found())
    end
  end

  -- show police records by registration
  local function m_show_police_records(menu)
    local user = menu.user

    local reg = user:prompt(lang.police.pc.searchreg.prompt(),"")
    local tuser
    local cid = vRP.EXT.Identity:getByRegistration(reg)
    if cid then tuser = vRP.users_by_cid[cid] end

    if tuser then
      e_pc_div_close(menu)

      local content = table.concat(tuser.police_records, "<br />")
      vRP.EXT.GUI.remote._setDiv(user.source,"police_pc",m_police_pc_css,content)
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.not_found())
    end
  end

  -- delete police records by registration
  local function m_delete_police_records(menu)
    local user = menu.user

    local reg = user:prompt(lang.police.pc.searchreg.prompt(),"")
    local tuser
    local cid = vRP.EXT.Identity:getByRegistration(reg)
    if cid then tuser = vRP.users_by_cid[cid] end

    if tuser then
      tuser.police_records = {}
      tuser:savePoliceRecords()

      vRP.EXT.Base.remote._notify(user.source,lang.police.pc.records.delete.deleted())
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.not_found())
    end
  end

  -- close business of an arrested owner
  local function m_closebusiness(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,5)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      local identity = nuser.identity

      local business = vRP.EXT.Business:getBusiness(nuser.cid)

      if identity and business then
        if user:request(lang.police.pc.closebusiness.request({identity.name,identity.firstname,business.name}),15) then
          vRP.EXT.Business:closeBusiness(nuser.cid)
          vRP.EXT.Base.remote._notify(user.source,lang.police.pc.closebusiness.closed())
        end
      else
        vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
      end
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  -- track vehicle
  local function m_trackveh(menu)
    local user = menu.user

    local reg = user:prompt(lang.police.pc.trackveh.prompt_reg(),"")

    local tuser
    local cid = vRP.EXT.Identity:getByRegistration(reg)
    if cid then tuser = vRP.users_by_cid[cid] end

    if tuser then
      local note = user:prompt(lang.police.pc.trackveh.prompt_note(),"")
      -- begin veh tracking
      vRP.EXT.Base.remote._notify(user.source,lang.police.pc.trackveh.tracking())
      local seconds = math.random(self.cfg.trackveh.min_time,self.cfg.trackveh.max_time)

      SetTimeout(seconds*1000,function()
        local ok,x,y,z = vRP.EXT.Garage.remote.getAnyOwnedVehiclePosition(nuser.source)
        if ok then -- track success
          vRP.EXT.Phone:sendServiceAlert(nil, self.cfg.trackveh.service,x,y,z,lang.police.pc.trackveh.tracked({reg,note}))
        else
          vRP.EXT.Base.remote._notify(user.source,lang.police.pc.trackveh.track_failed({reg,note})) -- failed
        end
      end)
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.not_found())
    end
  end

  vRP.EXT.GUI:registerMenuBuilder("police_pc", function(menu)
    menu.title = lang.police.pc.title()
    menu.css.header_color = "rgba(0,125,255,0.75)"

    menu:addOption(lang.police.pc.searchreg.title(), m_searchreg, lang.police.pc.searchreg.description())
    menu:addOption(lang.police.pc.trackveh.title(), m_trackveh, lang.police.pc.trackveh.description())
    menu:addOption(lang.police.pc.records.show.title(), m_show_police_records, lang.police.pc.records.show.description())
    menu:addOption(lang.police.pc.records.delete.title(), m_delete_police_records, lang.police.pc.records.delete.description())
    menu:addOption(lang.police.pc.closebusiness.title(), m_closebusiness, lang.police.pc.closebusiness.description())

    menu:listen("close", e_pc_div_close)
  end)
end

-- menu: police fine
local function menu_police_fine(self)
  local function m_fine(menu, name)
    local user = menu.user
    local tuser = menu.data.tuser

    local amount = self.cfg.fines[name]
    if amount then
      if tuser:tryFullPayment(amount) then
        tuser:insertPoliceRecord(lang.police.menu.fine.record({name,amount}))
        vRP.EXT.Base.remote._notify(user.source,lang.police.menu.fine.fined({name,amount}))
        vRP.EXT.Base.remote._notify(nuser.source,lang.police.menu.fine.notify_fined({name,amount}))

        user:closeMenu(menu)
      else
        vRP.EXT.Base.remote._notify(user.source,lang.money.not_enough())
      end
    end
  end

  vRP.EXT.GUI:registerMenuBuilder("police.fine", function(menu)
    menu.title = lang.police.menu.fine.title()
    menu.css.header_color = "rgba(0,125,255,0.75)"

    for name,amount in pairs(self.cfg.fines) do -- add fines in function of money available
      if amount <= money then
        menu:addOption(name, m_fine, amount, name)
      end
    end
  end)
end

-- menu: police
local function menu_police(self)
  local function m_handcuff(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,10)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      self.remote._toggleHandcuff(nuser.source)
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  local function m_drag(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,10)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      local followed = self.remote.getFollowedPlayer(nuser.source)
      if followed ~= user.source then -- drag
        self.remote._followPlayer(nuser.source, user.source)
      else -- stop follow
        self.remote._followPlayer(nuser.source)
      end
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  local function m_putinveh(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,10)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      if self.remote.isHandcuffed(nuser.source) then  -- check handcuffed
        self.remote._putInNearestVehicleAsPassenger(nuser.source, 5)
      else
        vRP.EXT.Base.remote._notify(user.source,lang.police.not_handcuffed())
      end
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  local function m_getoutveh(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,10)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      if self.remote.isHandcuffed(nuser.source) then  -- check handcuffed
        vRP.EXT.Garage.remote._ejectVehicle(nuser.source)
      else
        vRP.EXT.Base.remote._notify(user.source,lang.police.not_handcuffed())
      end
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  local m_askid_css = [[
div_police_identity{ 
  background-color: rgba(0,0,0,0.75); 
  color: white; 
  font-weight: bold; 
  width: 500px; 
  padding: 10px; 
  margin: auto; 
  margin-top: 150px; 
}
  ]]

  local function m_askid(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,10)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      vRP.EXT.Base.remote._notify(user.source,lang.police.menu.askid.asked())
      if nuser:request(lang.police.menu.askid.request(),15) then
        local identity = nuser.identity
        if identity then
          -- display identity and business
          local name = identity.name
          local firstname = identity.firstname
          local age = identity.age
          local phone = identity.phone
          local registration = identity.registration
          local bname = ""
          local bcapital = 0
          local home = ""
          local number = ""

          local business = vRP.EXT.Business:getBusiness(nuser.cid)
          if business then
            bname = business.name
            bcapital = business.capital
          end

          local address = nuser.address
          if address then
            home = address.home
            number = address.number
          end

          local content = lang.police.identity.info({name,firstname,age,registration,phone,bname,bcapital,home,number})
          vRP.EXT.GUI.remote._setDiv(user.source,"police_identity",m_askid_css,content)
          -- request to hide div
          user:request(lang.police.menu.askid.request_hide(), 1000)
          vRP.EXT.GUI.remote._removeDiv(user.source,"police_identity")
        end
      else
        vRP.EXT.Base.remote._notify(user.source,lang.common.request_refused())
      end
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  local m_check_css = [[
.div_police_check{ 
  background-color: 
  rgba(0,0,0,0.75); 
  color: white; 
  font-weight: bold; 
  width: 500px; 
  padding: 10px; 
  margin: auto; 
  margin-top: 150px; 
}
  ]]

  local function m_check(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,5)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      vRP.EXT.Base.remote._notify(nuser.source,lang.police.menu.check.checked())
      local weapons = vRP.EXT.PlayerState.remote.getWeapons(nuser.source)
      -- prepare display data (money, items, weapons)
      local money = nuser:getWallet()
      local items = ""
      for fullid,amount in pairs(nuser:getInventory()) do
        local citem = vRP.EXT.Inventory:computeItem(fullid)
        if citem then
          items = items.."<br />"..citem.name.." ("..amount..")"
        end
      end

      local weapons_info = ""
      for k,v in pairs(weapons) do
        weapons_info = weapons_info.."<br />"..k.." ("..v.ammo..")"
      end

      vRP.EXT.GUI.remote._setDiv(user.source,"police_check",m_check_css,lang.police.menu.check.info({money,items,weapons_info}))
      -- request to hide div
      user:request(lang.police.menu.check.request_hide(), 1000)
      vRP.EXT.GUI.remote._removeDiv(user.source,"police_check")
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  local function m_seize_weapons(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,5)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      if nuser:hasPermission("police.seizable") then
        if self.remote.isHandcuffed(nuser.source) then  -- check handcuffed
          local weapons = vRP.EXT.PlayerState.remote.replaceWeapons(nuser.source, {})

          for k,v in pairs(weapons) do -- display seized weapons
            -- vRPclient._notify(player,lang.police.menu.seize.seized({k,v.ammo}))
            -- convert weapons to parametric weapon items
            user:tryGiveItem("wbody|"..k, 1)
            if v.ammo > 0 then
              user:tryGiveItem("wammo|"..k, v.ammo)
            end
          end

          vRP.EXT.Base.remote._notify(nuser.source,lang.police.menu.seize.weapons.seized())
        else
          vRP.EXT.Base.remote._notify(user.source,lang.police.not_handcuffed())
        end
      end
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  local function m_seize_items(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,5)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      if nuser:hasPermission("police.seizable") then
        if self.remote.isHandcuffed(nuser.source) then  -- check handcuffed
          local inventory = nuser:getInventory()

          for key in pairs(self.cfg.seizable_items) do -- transfer seizable items
            local sub_items = {key} -- single item

            if string.sub(key,1,1) == "*" then -- seize all parametric items of this id
              local id = string.sub(key,2)
              sub_items = {}
              for fullid in pairs(inventory) do
                if splitString(fullid, "|")[1] == id then -- same parametric item
                  table.insert(sub_items, fullid) -- add full idname
                end
              end
            end

            for _,fullid in pairs(sub_items) do
              local amount = nuser:getItemAmount(fullid)
              if amount > 0 then
                local citem = vRP.EXT.Inventory:computeItem(fullid)
                if citem then -- do transfer
                  if nuser:tryTakeItem(fullid,amount) then
                    user:tryGiveItem(fullid,amount,nil,true)
                    vRP.EXT.Base.remote._notify(user.source,lang.police.menu.seize.seized({citem.name,amount}))
                  end
                end
              end
            end
          end

          vRP.EXT.Base.remote._notify(nuser.source,lang.police.menu.seize.items.seized())
        else
          vRP.EXT.Base.remote._notify(user.source,lang.police.not_handcuffed())
        end
      end
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  local function m_jail(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,5)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      if self.remote.isJailed(nuser.source) then
        self.remote._unjail(nuser.source)
        vRP.EXT.Base.remote._notify(nuser.source,lang.police.menu.jail.notify_unjailed())
        vRP.EXT.Base.remote._notify(user.source,lang.police.menu.jail.unjailed())
      else -- find the nearest jail
        local x,y,z = vRP.EXT.Base.remote.getPosition(nuser.source)
        local d_min = 1000
        local v_min = nil
        for k,v in pairs(self.cfg.jails) do
          local dx,dy,dz = x-v[1],y-v[2],z-v[3]
          local dist = math.sqrt(dx*dx+dy*dy+dz*dz)

          if dist <= d_min and dist <= 15 then -- limit the research to 15 meters
            d_min = dist
            v_min = v
          end

          -- jail
          if v_min then
            self.remote._jail(nuser.source,v_min[1],v_min[2],v_min[3],v_min[4])
            vRP.EXT.Base.remote._notify(nuser.source,lang.police.menu.jail.notify_jailed())
            vRP.EXT.Base.remote._notify(user.source,lang.police.menu.jail.jailed())
          else
            vRP.EXT.Base.remote._notify(user.source,lang.police.menu.jail.not_found())
          end
        end
      end
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  local function m_fine(menu)
    local user = menu.user

    local nuser
    local nplayer = vRP.EXT.Base.remote.getNearestPlayer(user.source,5)
    if nplayer then nuser = vRP.users_by_source[nplayer] end

    if nuser then
      local money = nuser:getWallet()+nuser:getBank()
      user:openMenu("police.fine", {tuser = nuser, money = money})
    else
      vRP.EXT.Base.remote._notify(user.source,lang.common.no_player_near())
    end
  end

  vRP.EXT.GUI:registerMenuBuilder("police", function(menu)
    local user = menu.user
    menu.title = lang.police.title()
    menu.css.header_color = "rgba(0,125,255,0.75)"

    if user:hasPermission("police.askid") then
      menu:addOption(lang.police.menu.askid.title(), m_askid, lang.police.menu.askid.description())
    end

    if user:hasPermission("police.handcuff") then
      menu:addOption(lang.police.menu.handcuff.title(), m_handcuff, lang.police.menu.handcuff.description())
    end

    if user:hasPermission("police.drag") then
      menu:addOption(lang.police.menu.drag.title(), m_drag, lang.police.menu.drag.description())
    end

    if user:hasPermission("police.putinveh") then
      menu:addOption(lang.police.menu.putinveh.title(), m_putinveh, lang.police.menu.putinveh.description())
    end

    if user:hasPermission("police.getoutveh") then
      menu:addOption(lang.police.menu.getoutveh.title(), m_getoutveh, lang.police.menu.getoutveh.description())
    end

    if user:hasPermission("police.check") then
      menu:addOption(lang.police.menu.check.title(), m_check, lang.police.menu.check.description())
    end

    if user:hasPermission("police.seize.weapons") then
      menu:addOption(lang.police.menu.seize.weapons.title(), m_seize_weapons, lang.police.menu.seize.weapons.description())
    end

    if user:hasPermission("police.seize.items") then
      menu:addOption(lang.police.menu.seize.items.title(), m_seize_items, lang.police.menu.seize.items.description())
    end

    if user:hasPermission("police.jail") then
      menu:addOption(lang.police.menu.jail.title(), m_jail, lang.police.menu.jail.description())
    end

    if user:hasPermission("police.fine") then
      menu:addOption(lang.police.menu.fine.title(), m_fine, lang.police.menu.fine.description())
    end
  end)
end

local function define_items(self)
  local function m_bulletproof_vest_wear(menu)
    local user = menu.user
    local fullid = menu.data.fullid

    if user:tryTakeItem(fullid, 1) then -- take vest
      vRP.EXT.PlayerState.remote._setArmour(user.source, 100)

      local namount = user:getItemAmount(fullid)
      if namount > 0 then
        user:actualizeMenu()
      else
        user:closeMenu(menu)
      end
    end
  end

  local function i_bulletproof_vest_menu(args, menu)
    menu:addOption(lang.item.bulletproof_vest.wear.title(), m_bulletproof_vest_wear)
  end

  vRP.EXT.Inventory:defineItem("bulletproof_vest", lang.item.bulletproof_vest.name(), lang.item.bulletproof_vest.description(), i_bulletproof_vest_menu, 1.5)
end

-- METHODS

function Police:__construct()
  vRP.Extension.__construct(self)

  self.cfg = module("cfg/police")
  self:log(#self.cfg.pcs.." PCs "..#self.cfg.jails.." jails")

  self.wantedlvl_users = {}

  -- items
  define_items(self)

  -- menu
  menu_police_pc(self)
  menu_police_fine(self)
  menu_police(self)

  -- main menu
  local function m_police(menu)
    menu.user:openMenu("police")
  end

  local function m_store_weapons(menu)
    local user = menu.user

    local weapons = vRP.EXT.PlayerState.remote.replaceWeapons(user.source, {})
    for k,v in pairs(weapons) do
      -- convert weapons to parametric weapon items
      user:tryGiveItem("wbody|"..k, 1)
      if v.ammo > 0 then
        user:tryGiveItem("wammo|"..k, v.ammo)
      end
    end
  end

  vRP.EXT.GUI:registerMenuBuilder("main", function(menu)
    if menu.user:hasPermission("police.menu") then
      menu:addOption(lang.police.title(), m_police)
    end

    if menu.user:hasPermission("player.store_weapons") then
      menu:addOption(lang.police.menu.store_weapons.title(), m_store_weapons, lang.police.menu.store_weapons.description())
    end
  end)

  -- task: display wanted positions
  local function task_wanted_positions()
    local listeners = vRP.EXT.Group:getUsersByPermission("police.wanted")

    for user, v in pairs(self.wantedlvl_users) do -- each wanted player
      if v > 0 then
        local x,y,z = vRP.EXT.Base.remote.getPosition(user.source)
        for _,listener in pairs(listeners) do -- each listening player
          vRP.EXT.Map.remote._setNamedBlip(listener.source, "vRP:police:wanted:"..user.id,x,y,z,self.cfg.wanted.blipid,self.cfg.wanted.blipcolor,lang.police.wanted({v}))
        end
      end
    end
    SetTimeout(5000, task_wanted_positions)
  end

  async(function()
    task_wanted_positions()
  end)
end

function Police:getUserWantedLevel(user)
  return self.wantedlvl_users[user] or 0
end

-- EVENT
Police.event = {}

function Police.event:characterLoad(user)
  -- load records
  local sdata = vRP:getCData(user.cid, "vRP:police:records")
  user.police_records = (sdata and string.len(sdata) > 0 and msgpack.unpack(sdata) or {})
end

function Police.event:playerSpawn(user, first_spawn)
  if first_spawn then
    local menu
    local function enter(user)
      if user:hasPermission("police.pc") then
        menu = user:openMenu("police_pc")
      end
    end

    local function leave(user)
      if menu then
        user:closeMenu(menu)
      end
    end

    -- build police PCs
    for k,v in pairs(self.cfg.pcs) do
      local x,y,z = table.unpack(v)
      vRP.EXT.Map.remote._addMarker(user.source,x,y,z-1,0.7,0.7,0.5,0,125,255,125,150)
      user:setArea("vRP:police:pc:"..k,x,y,z,1,1.5,enter,leave)
    end
  end
end

function Police.event:playerLeave(user)
  self.wantedlvl_users[user] = nil
  vRP.EXT.Map.remote._removeNamedBlip(-1, "vRP:police:wanted:"..user.id)  -- remove wanted blip (all to prevent phantom blip)
end

-- TUNNEL
Police.tunnel = {}

-- receive wanted level
function Police.tunnel:updateWantedLevel(level)
  local user = vRP.users_by_source[source]

  if user then
    local was_wanted = (self:getUserWantedLevel(user) > 0)
    self.wantedlvl_users[user] = level
    local is_wanted = (level > 0)

    -- send wanted to listening service
    if not was_wanted and is_wanted then
      local x,y,z = vRP.EXT.Base.remote.getPosition(user.source)
      vRP.EXT.Phone:sendServiceAlert(nil, self.cfg.wanted.service,x,y,z,lang.police.wanted({level}))
    end

    if was_wanted and not is_wanted then
      vRP.EXT.Map.remote._removeNamedBlip(-1, "vRP:police:wanted:"..user.id) -- remove wanted blip (all to prevent phantom blip)
    end
  end
end

vRP:registerExtension(Police)
