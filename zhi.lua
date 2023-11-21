local extension = Package("mou_zhi")
extension.extensionName = "mougong"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["mou_zhi"] = "谋攻篇-知包",
}

local daqiao = General(extension, "mou__daqiao", "wu", 3, 3, General.Female)
local mou__guose = fk.CreateActiveSkill{
  name = "mou__guose",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 4 and not player:isNude()
  end,
  interaction = function()
    return UI.ComboBox {choices = {"mou__guose_use" , "mou__guose_throw"}}
  end,
  card_filter = function(self, to_select, selected)
    if #selected > 0 or not self.interaction.data or Fk:getCardById(to_select).suit ~= Card.Diamond then return false end
    if self.interaction.data == "mou__guose_use" then
      local card = Fk:cloneCard("indulgence")
      card:addSubcard(to_select)
      return Self:canUse(card) and not Self:prohibitUse(card)
    else
      return not Self:prohibitDiscard(Fk:getCardById(to_select))
    end
  end,
  target_filter = function(self, to_select, selected, cards)
    if #cards ~= 1 or #selected > 0 or not self.interaction.data then return false end
    local target = Fk:currentRoom():getPlayerById(to_select)
    if self.interaction.data == "mou__guose_use" then
      local card = Fk:cloneCard("indulgence")
      card:addSubcard(cards[1])
      return to_select ~= Self.id and not Self:isProhibited(target, card)
    else
      return target:hasDelayedTrick("indulgence")
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if self.interaction.data == "mou__guose_use" then
      room:useVirtualCard("indulgence", effect.cards, player, target, self.name)
    else
      room:throwCard(effect.cards, self.name, player, player)
      for _, id in ipairs(target.player_cards[Player.Judge]) do
        local card = target:getVirualEquip(id)
        if not card then card = Fk:getCardById(id) end
        if card.name == "indulgence" then
          room:throwCard({id}, self.name, target, player)
        end
      end
    end
    if not player.dead then
      player:drawCards(2, self.name)
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
}
local mou__liuli = fk.CreateTriggerSkill{
  name = "mou__liuli",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    local ret = target == player and player:hasSkill(self) and
      data.card.trueName == "slash"
    if ret then
      local room = player.room
      local from = room:getPlayerById(data.from)
      for _, p in ipairs(room.alive_players) do
        if p ~= player and p.id ~= data.from and player:inMyAttackRange(p) and not from:isProhibited(p, data.card) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#mou__liuli-target"
    local targets = {}
    local from = room:getPlayerById(data.from)
    for _, p in ipairs(room.alive_players) do
      if p ~= player and p.id ~= data.from and player:inMyAttackRange(p) and not from:isProhibited(p, data.card) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return false end
    local plist, cid = room:askForChooseCardAndPlayers(player, targets, 1, 1, nil, prompt, self.name, true)
    if #plist > 0 then
      self.cost_data = {plist[1], cid}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = self.cost_data[1]
    room:doIndicate(player.id, { to })
    room:throwCard(self.cost_data[2], self.name, player, player)
    TargetGroup:removeTarget(data.targetGroup, player.id)
    TargetGroup:pushTargets(data.targetGroup, to)
    
    if Fk:getCardById(self.cost_data[2]).suit == Card.Heart and player:getMark("mou__liuli-turn") == 0 then
        local targets = {}
      local from = room:getPlayerById(data.from)
      for _, p in ipairs(room.alive_players) do
        if p ~= player and p.id ~= data.from and p:getMark("@@liuli_dangxian") == 0 then
           table.insert(targets, p.id)
        end
      end
     local tar = room:askForChoosePlayers(player, targets, 1, 1, "#mou__liuli-choose", self.name, true)
      if #tar > 0 then
         room:removePlayerMark(player, "mou__liuli-turn", 1)
          for _, p in ipairs(room.alive_players) do
            if p:getMark("@@liuli_dangxian") ~= 0 then
                room:removePlayerMark(p, "@@liuli_dangxian", 1)
            end
          end
         room:addPlayerMark(room:getPlayerById(tar[1]), "@@liuli_dangxian", 1)
      end
    end
  end,
}

local mou__liuli_dangxian = fk.CreateTriggerSkill{
  name = "#mou__liuli_dangxian",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@liuli_dangxian") ~=0 and data.to == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@@liuli_dangxian", 1)
    player:gainAnExtraPhase(Player.Play)
  end,
}
mou__liuli:addRelatedSkill(mou__liuli_dangxian)
daqiao:addSkill(mou__guose)
daqiao:addSkill(mou__liuli)
Fk:loadTranslationTable{
  ["mou__daqiao"] = "谋大乔",
  ["mou__guose"] = "国色",
  [":mou__guose"] = "出牌阶段限四次，你可以选择一项：1.将一张<font color='red'>♦</font>牌当【乐不思蜀】使用；"..
  "2.弃置一张<font color='red'>♦</font>牌并弃置场上的一张【乐不思蜀】。选择完成后，你摸两张牌，然后弃置一张牌。",
  ["mou__guose_use"] = "使用乐不思蜀",
  ["mou__guose_throw"] = "弃置乐不思蜀",
  ["mou__liuli"] = "流离",
  ["#mou__liuli_dangxian"] = "流离",
  [":mou__liuli"] = "每当你成为【杀】的目标时，你可以弃置一张牌并选择你攻击范围内为此【杀】合法目标（无距离限制）的一名角色：若如此做，该角色代替你成为此【杀】的目标。若你以此法弃置了<font color='red'>♥️</font>牌，则你可以令一名不为此【杀】使用者的其他角色获得“流离”标记，且移去场上所有其他的“流离”（每回合限一次）。有“流离”的角色回合开始时，其移去其“流离”并执行一个额外的出牌阶段。",
  ["#mou__liuli-target"] = "流离：你可以弃置一张牌，将【杀】的目标转移给一名其他角色",
  ["#mou__liuli-choose"] = "流离：你可以令一名除此【杀】使用者的其他角色获得“流离”标记并清除场上的其他流离标记。",
  ["@@liuli_dangxian"] = "流离",

  ["$mou__guose1"] = "还望将军，稍等片刻。",
  ["$mou__guose2"] = "将军，请留步。",
  ["$mou__liuli1"] = "无论何时何地，我都在你身边。",
  ["$mou__liuli2"] = "辗转流离，只为此刻与君相遇。",
  ["~mou__daqiao"] = "此心无可依，惟有泣别离……",
}

local caocao = General(extension, "mou__caocao", "wei", 4)
local mou__jianxiong = fk.CreateTriggerSkill{
  name = "mou__jianxiong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
     return target == player and player:hasSkill(self) and ((data.card and target.room:getCardArea(data.card) == Card.Processing) or 2 - player:getMark("@mou__jianxiong") > 0)
  end,
  on_use = function(self, event, target, player, data)
    if data.card and target.room:getCardArea(data.card) == Card.Processing then
      player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    end
     local num = 2 - player:getMark("@mou__jianxiong")
     if num > 0 then
       player:drawCards(num, self.name)
     end
     if player:getMark("@mou__jianxiong") ~= 0 then
       if player.room:askForSkillInvoke(player, self.name, nil, "#mou__jianxiong-dismark") then
           player.room:removePlayerMark(player, "@mou__jianxiong", 1)
       end
     end
  end,
}
local mou__jianxiong_gamestart = fk.CreateTriggerSkill{
  name = "#mou__jianxiong_gamestart",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("mou__jianxiong")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
     local choices = {}
      for i = 1, 2, 1 do
        table.insert(choices, tostring(i))
      end
      local choice = room:askForChoice(player, choices, self.name, "#mou__jianxiong-choice")
      if choice == "1" then 
         room:setPlayerMark(player,  "@mou__jianxiong", 1)
      else
        room:setPlayerMark(player,  "@mou__jianxiong", 2)
      end
  end,
}

local mou__qingzheng = fk.CreateTriggerSkill{
  name = "mou__qingzheng",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
       local num = 3 - player:getMark("@mou__jianxiong")
       local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
           table.insertIfNeed(suits, suit)
        end
      end
       return  not player:isKongcheng() and #suits >= num
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isKongcheng() end), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#mou__qingzheng-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(self.cost_data)
    local num = 3 - player:getMark("@mou__jianxiong")
     local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        local suit = Fk:getCardById(id):getSuitString()
        if suit ~= Card.NoSuit then
           table.insertIfNeed(suits, suit)
        end
      end
      local cards ={}
      local cards1 ={}
      for i = 1, num, 1 do
        local choice = room:askForChoice(player, suits, self.name, "#mou__qingzheng-discard:::".. num ..":" ..i)
        table.removeOne(suits, choice)
         for _, c in ipairs(player.player_cards[Player.Hand]) do
           local suit = Fk:getCardById(c):getSuitString()
           if suit == choice then
             table.insertIfNeed(cards, c)
           end
         end
      end

      if #cards > 0 then
        room:throwCard(cards, self.name, player)
      end
      if player.dead then return end
      local cids = to.player_cards[Player.Hand]
      room:fillAG(player, cids)
    local id1 = room:askForAG(player, cids, false, self.name)
    room:closeAG(player)
    for _, y in ipairs(cids) do
       local suit = Fk:getCardById(y).suit
       local suit1 = Fk:getCardById(id1).suit
      if suit == suit1 then
         table.insertIfNeed(cards1, y)
      end
    end
     room:throwCard(cards1, self.name, to, player)

     if #cards > # cards1 and not player.dead and not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
      if player:hasSkill("mou__jianxiong") and player:getMark("@mou__jianxiong") < 2 then
        if room:askForSkillInvoke(player, self.name, nil, "#mou__qingzheng-addmark") then
            room:addPlayerMark(player, "@mou__jianxiong", 1)
        end
      end
    end
  end,
}

local mou__hujia = fk.CreateTriggerSkill{
  name = "mou__hujia$",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room:getOtherPlayers(player), function(p) return p.kingdom == "wei" end), function(p) return p.id end)
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#mou__hujia-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    
    room:damage{
      from = data.from,
      to = to,
      damage = data.damage,
      damageType = data.type,
      skillName = self.name,
    }
   
    return true
  end,
}
mou__jianxiong:addRelatedSkill(mou__jianxiong_gamestart)
caocao:addSkill(mou__jianxiong)
caocao:addSkill(mou__qingzheng)
caocao:addSkill(mou__hujia)

Fk:loadTranslationTable{
  ["mou__caocao"] = "谋曹操",
  ["mou__jianxiong"] = "奸雄",
  ["#mou__jianxiong_gamestart"] = "奸雄",
  [":mou__jianxiong"] = "游戏开始时，你可以获得至多两枚“治世”标记。当你受到伤害后，你可以获得对你造成伤害的牌并摸2-X张牌，然后你可以移除1枚“治世”。"..
  "（X为“治世”的数量且至多为2）。",
  ["mou__qingzheng"] = "清正",
  [":mou__qingzheng"] = "出牌阶段开始时，你可以选择一名有手牌的其他角色，你弃置3-X（X为你的“治世”标记数）种花色的所有手牌，然后观看其手牌并选择一种"..
  "花色的牌，其弃置所有该花色的手牌。若如此做且你以此法弃置的牌数大于其弃置的手牌，你对其造成1点伤害，然后若你拥有〖奸雄〗且“治世”标记小于2，你可以"..
  "获得一枚“治世”。",
  ["mou__hujia"] = "护驾",
  [":mou__hujia"] = "主公技，每轮限一次，当你即将受到伤害时，你可以将此伤害转移给一名其他魏势力角色。",
  ["#mou__jianxiong-dismark"] = "奸雄：是否弃置一枚“治世”标记？。",
  ["#mou__jianxiong-choice"] = "奸雄：请选择要获得的“治世”标记数量。",
  ["#mou__qingzheng-addmark"] = "清正：是否获得一个“治世”标记？",
  ["#mou__qingzheng-choose"] = "清正：你可以发动“清正”选择一名有手牌的其他角色",
  ["#mou__qingzheng-discard"] = "清正：请选择一种花色的所有牌弃置，总共%arg 次 现在是第%arg2 次",
  ["#mou__hujia-choose"] = "护驾：你可以将伤害转移给一名魏势力角色",
  ["@mou__jianxiong"] = "治世",

  ["$mou__jianxiong1"] = "古今英雄盛世，尽赴沧海东流。",
  ["$mou__jianxiong2"] = "骖六龙行御九州，行四海路下八邦！",
  ["$mou__qingzheng1"] = "立威行严法，肃佞正国纲！",
  ["$mou__qingzheng2"] = "悬杖分五色，治法扬清名。",
  ["$mou__hujia1"] = "虎贲三千，堪当敌万余！",
  ["$mou__hujia2"] = "壮士八百，足护卫吾身！",
  ["~mou__caocao"] = "狐死归首丘，故乡安可忘……",
}
local sunquan = General(extension, "mou__sunquan", "wu", 4)
local mou__zhiheng = fk.CreateActiveSkill{
  name = "mou__zhiheng",
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local hand = from:getCardIds(Player.Hand)
    local more = #hand > 0
    for _, id in ipairs(hand) do
      if not table.contains(effect.cards, id) then
        more = false
        break
      end
    end
    local num1 = from:getMark("@tongye")
    room:throwCard(effect.cards, self.name, from, from)
    room:drawCards(from, #effect.cards + (more and 1 + num1 or 0), self.name)
    if more and num1 > 0 then
      room:removePlayerMark(from, "@tongye", 1)
    end
  end
}
local mou__tongye = fk.CreateTriggerSkill{
  name = "mou__tongye",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player.phase == Player.Finish then 
        return true
      elseif player.phase == Player.Start then
        return player:getMark("@@tongye1") > 0 or player:getMark("@@tongye2") >0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
     local n = 0
    for _, p in ipairs(room:getAlivePlayers()) do
      for _, id in ipairs(p:getCardIds{Player.Equip}) do
         n = n+1
      end
    end
    if player.phase == Player.Start then
      if player:getMark("@@tongye1") ~= 0 then
        if player:getMark("tongye_num") ~=n then
          if player:getMark("@tongye") < 2 then
            room:addPlayerMark(player, "@tongye", 1)
          end
        else
          room:removePlayerMark(player, "@tongye", 1)
        end
        room:setPlayerMark(player, "@@tongye1", 0)
      end
      if player:getMark("@@tongye2") ~= 0 then
        if player:getMark("tongye_num") == n then
          if player:getMark("@tongye") < 2 then
            room:addPlayerMark(player, "@tongye", 1)
          end
        else
          room:removePlayerMark(player, "@tongye", 1)
        end
        room:setPlayerMark(player, "@@tongye2", 0)
      end
       room:setPlayerMark(player, "tongye_num", 0)
    else
      room:addPlayerMark(player, "tongye_num", n)
      local choice = room:askForChoice(player, { "tongye1", "tongye2"}, self.name)
      if choice == "tongye1" then
        room:addPlayerMark(player, "@@tongye1")
      end
      if choice == "tongye2" then
        room:addPlayerMark(player, "@@tongye2")
      end
    end
  end,
}
local mou__jiuyuan = fk.CreateTriggerSkill{
  name = "mou__jiuyuan$",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.PreHpRecover, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PreHpRecover then
      return
        target == player and
        player:hasSkill(self) and
        data.card and
        data.card.trueName == "peach" and
        data.recoverBy and
        data.recoverBy.kingdom == "wu" and
        data.recoverBy ~= player
    elseif event == fk.CardUsing then
      return player:hasSkill(self) and target ~= player and target.kingdom == "wu" and data.card.trueName == "peach"
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.PreHpRecover then
      data.num = data.num + 1
    elseif event == fk.CardUsing then
      player:drawCards(1, self.name)
    end
  end,
}
sunquan:addSkill(mou__zhiheng)
sunquan:addSkill(mou__tongye)
sunquan:addSkill(mou__jiuyuan)
Fk:loadTranslationTable{
  ["mou__sunquan"] = "谋孙权",
  ["mou__zhiheng"] = "制衡",
  [":mou__zhiheng"] = "出牌阶段限一次，你可以弃置任意张牌并摸等量的牌。若你以此法弃置了所有的手牌，你多摸1+X张牌（X为你的“业”数），然后你弃置一枚“业”。",
  ["mou__tongye"] = "统业",
  [":mou__tongye"] = "锁定技，结束阶段，你可以猜测场上的装备数量于你的下个准备阶段开始时有无变化。若你猜对，你获得一枚“业”，猜错，你弃置一枚“业”。",
  ["mou__jiuyuan"] = "救援",
  [":mou__jiuyuan"] = "主公技，锁定技，其他吴势力角色使用【桃】时，你摸一张牌。其他吴势力角色对你使用【桃】回复的体力+1。",

  ["tongye1"] = "统业猜测:有变化",
  ["tongye2"] = "统业猜测:无变化",
  ["@tongye"] = "业",
  ["@@tongye1"] = "统业猜测:有变化",
  ["@@tongye2"] = "统业猜测:无变化",

  ["$mou__zhiheng1"] = "稳坐山河，但观世变。",
  ["$mou__zhiheng2"] = "身处惊涛，尤可弄潮。",
  ["$mou__tongye1"] = "上下一心，君臣同志。",
  ["$mou__tongye2"] = "胸有天下者，必可得其国。",
  ["$mou__jiuyuan1"] = "汝救护有功，吾必当厚赐。",
  ["$mou__jiuyuan2"] = "诸位将军，快快拦住贼军！",
  ["~mou__sunquan"] = "风急举发，命不久矣……",
}

local mouzhouyu = General(extension, "mou__zhouyu", "wu", 3)
local mou__yingzi = fk.CreateTriggerSkill{
  name = "mou__yingzi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
     return target == player and player:hasSkill(self) and (player:getHandcardNum() > 1 or #player:getCardIds("e") > 0 or player.hp > 1)
  end,
  on_use = function(self, event, target, player, data)
     if player.hp > 1 then
       player.room:addPlayerMark(player, "mou__yingzi-turn", 1)
     end
     if player:getHandcardNum() > 1 then
       player.room:addPlayerMark(player, "mou__yingzi-turn", 1)
     end
     if #player:getCardIds("e") > 0 then
       player.room:addPlayerMark(player, "mou__yingzi-turn", 1)
     end
     data.n = data.n+player:getMark("mou__yingzi-turn")
  end,
}
local mou__yingzi_maxcards = fk.CreateMaxCardsSkill{
  name = "#mou__yingzi_maxcards",
  correct_func = function(self, player)
    if player:hasSkill("mou__yingzi") then
      return player:getMark("mou__yingzi-turn")
    else
      return 0
    end
  end,
}
mou__yingzi:addRelatedSkill(mou__yingzi_maxcards)

local mou__fanjian = fk.CreateActiveSkill{
  name = "mou__fanjian",
  anim_type = "control",
  interaction = function(self)
    local choiceList = {"spade", "heart", "club", "diamond"}
    return UI.ComboBox { choices = choiceList }
  end,
  card_num = 1,
  target_num = 1,
   can_use = function(self, player)
     return player:getMark("mou__fanjian-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    if Self:getMark("moufanjianRecord-turn") ~= 0 then
      local suitsx = Self:getMark("moufanjianRecord-turn")
      suitsx = suitsx:split("+")
     return not table.contains(suitsx, Fk:getCardById(to_select):getSuitString())
    else return true end
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
      local player = room:getPlayerById(effect.from)
      local target = room:getPlayerById(effect.tos[1])
      room:sendLog{
        type = "#fanjian_log",
        from = player.id,
        arg = self.interaction.data,
        arg2 = self.name
      }
      local choiceList = { "mou__fanjian_true","mou__fanjian_false", "mou__fanjian_fanmian" }
    local choice = room:askForChoice( target, choiceList , self.name,"#mou__fanjian-active:::"..self.interaction.data)
    if choice == "mou__fanjian_fanmian" then
      target:turnOver()
    elseif choice == "mou__fanjian_true" then
      if self.interaction.data == Fk:getCardById(effect.cards[1]):getSuitString() then 
        room:setPlayerMark(player, "mou__fanjian-turn", 1)
      else 
        room:loseHp(target, 1, self.name)
      end
    elseif choice == "mou__fanjian_false" then
      if self.interaction.data ~= Fk:getCardById(effect.cards[1]):getSuitString() then 
        room:setPlayerMark(player, "mou__fanjian-turn", 1)
      else 
        room:loseHp(target, 1, self.name)
      end
    end
     if not target.dead then
        room:obtainCard(target.id, effect.cards[1], false, fk.ReasonGive)
     end
      local suit = Fk:getCardById(effect.cards[1]):getSuitString()
      if table.contains({ "spade", "heart", "club", "diamond" }, suit) then
        local m = player:getMark("moufanjianRecord-turn")
        if m == 0 then
          m = suit
        elseif type(m) == "string" then
          local suits = m:split("+")
          table.insertIfNeed(suits, suit)
          m = table.concat(suits, "+")
        end
        room:setPlayerMark(player, "moufanjianRecord-turn", m)
        local card_suits_table = {
          spade = "♠",
          club = "♣",
          heart = "♥",
          diamond = "♦",
        }
        room:setPlayerMark(player, "@moufanjianRecord-turn", table.concat(
          table.map(m:split("+"), function(s) return card_suits_table[s] end)
          , ""))
      end
  end,
}
mouzhouyu:addSkill(mou__yingzi)
mouzhouyu:addSkill(mou__fanjian)
Fk:loadTranslationTable{
  ["mou__zhouyu"] = "谋周瑜",
  ["mou__yingzi"] = "英姿",
  ["#mou__yingzi_maxcards"] = "英姿",
  [":mou__yingzi"] = "锁定技，摸牌阶段开始时，你每满足以下一项条件此摸牌阶段摸牌基数和本回合手牌上限便+1，你的手牌数不少于2，你的装备区内牌数不少于1，你的体力值不少于2。",
  ["mou__fanjian"] = "反间",
  [":mou__fanjian"] = "出牌阶段，你可以选择一名其他角色和一张牌（每种花色每回合限一次）并声明一个花色，其须选择一项：1.猜测此牌花色是否与你声明的"..
  "花色相同；2.翻面。然后其正面向上获得此牌。若其选择猜测且猜测错误，其失去1点体力，否则其令你〖反间〗于本回合失效。",
  ["mou__fanjian_true"] = "花色相同",
  ["mou__fanjian_false"] = "花色不相同",
  ["mou__fanjian_fanmian"] = "你翻面",
  
  ["#mou__fanjian-active"] = "反间:请猜测选择的牌花色是否与%arg 相同或者选择翻面。",
  ["#fanjian_log"] = "%from 发动了“%arg2”，声明的花色为 【%arg】。",
  ["@moufanjianRecord-turn"] = "反间",
  
  ["$mou__yingzi1"] = "交之总角，付之九州！",
  ["$mou__yingzi2"] = "定策分两治，纵马饮三江！",
  ["$mou__fanjian1"] = "若不念汝三世之功，今日定斩不赦！",
  ["$mou__fanjian2"] = "比之自内，不自失也！",
  ["~mou__zhouyu"] = "瑜虽不惧曹军，但惧白驹过隙……",
}

local mouzhenji = General(extension, "mou__zhenji", "wei", 3, 3, General.Female)
local mou__luoshen = fk.CreateTriggerSkill{
  name = "mou__luoshen",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      1, 1, "#mou__luoshen-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = (#room.alive_players + 1) // 2
    local to = room:getPlayerById(self.cost_data)
    local targets = {to}
    for _ = 2, x do
      to = to:getNextAlive(true)
      if to == player then
        to = to:getNextAlive(true)
      end
      table.insertIfNeed(targets, to)
    end
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    for _, p in ipairs(targets) do
      if player.dead then break end
      if not (p.dead or p:isKongcheng()) then
        local cards = room:askForCard(p, 1, 1, false, self.name, false, nil, "#mou__luoshen-show:"..player.id)
        p:showCards(cards)
        local card = Fk:getCardById(cards[1])
        if card.color == Card.Red then
          room:throwCard(cards, self.name, p, p)
        elseif card.color == Card.Black then
          room:moveCards({
            ids = cards,
            from = p.id,
            to = player.id,
            toArea = Player.Hand,
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = "mou__luoshen_prey",
          })
        end
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "mou__luoshen_prey" then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              room:setCardMark(Fk:getCardById(id), "@@mou__luoshen-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.AfterTurnEnd then
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "@@mou__luoshen-inhand", 0)
      end
    end
  end,
}
local mou__luoshen_maxcards = fk.CreateMaxCardsSkill{
  name = "#mou__luoshen_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@mou__luoshen-inhand") > 0
  end,
}
mou__luoshen:addRelatedSkill(mou__luoshen_maxcards)
mouzhenji:addSkill(mou__luoshen)
mouzhenji:addSkill("qingguo")
Fk:loadTranslationTable{
  ["mou__zhenji"] = "谋甄姬",
  ["mou__luoshen"] = "洛神",
  [":mou__luoshen"] = "准备阶段，你可以选择一名角色，自其开始的X名其他角色依次展示一张手牌（X为场上存活角色数的一半，向上取整）："..
  "若为黑色，你获得之（这些牌不计入你本回合的手牌上限）；若为红色，其弃置之。",

  ["#mou__luoshen-choose"] = "发动洛神，选择一名其他角色作为起始角色",
  ["#mou__luoshen-show"] = "洛神：展示一张手牌，若为黑色则%src获得之，若为红色则弃置之",

  ["@@mou__luoshen-inhand"] = "洛神",

  ["$mou__luoshen1"] = "商灵缤兮恭迎，伞盖纷兮若云。",
  ["$mou__luoshen2"] = "晨张兮细帷，夕茸兮兰櫋。",
  ["$qingguo_mou__zhenji1"] = "凌波荡兮微步，香罗袜兮生尘。",
  ["$qingguo_mou__zhenji2"] = "辛夷展兮修裙，紫藤舒兮绣裳。",
  ["~mou__zhenji"] = "秀目回兮难得，徒逍遥兮莫离……",
}
local mou__zhangjiao = General(extension, "mou__zhangjiao", "qun", 3)
local mou__leiji = fk.CreateActiveSkill{
  name = "mou__leiji",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:getMark("@daobing") >= 4
  end,
  card_num = 0,
  card_filter = function() return false end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:removePlayerMark(player, "@daobing", 4)
    room:damage { from = player, to = to, damage = 1, skillName = self.name, damageType = fk.ThunderDamage }
  end,
}
mou__zhangjiao:addSkill(mou__leiji)
local mou__guidao = fk.CreateTriggerSkill{
  name = "mou__guidao",
  anim_type = "special",
  events = {fk.GameStart , fk.Damaged, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self) and player:getMark("@daobing") < 8
    elseif event == fk.Damaged then
      return player:hasSkill(self) and data.damageType ~= fk.NormalDamage and player:getMark("@daobing") < 8 and player:getMark("mou__guidao_invalidity") == 0
    else
      return player:hasSkill(self) and target == player and player:getMark("@daobing") >= 2
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.DamageInflicted then
      local prompt = player.phase == Player.NotActive and "#mou__guidao_invalidity-invoke" or "#mou__guidao-invoke"
      return player.room:askForSkillInvoke(player, self.name, nil, prompt)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setPlayerMark(player, "@daobing", math.min(8, player:getMark("@daobing")+4))
    elseif event == fk.Damaged then
      room:setPlayerMark(player, "@daobing", math.min(8, player:getMark("@daobing")+2))
    else
      room:removePlayerMark(player, "@daobing", 2)
      if player.phase == Player.NotActive then room:addPlayerMark(player, "mou__guidao_invalidity") end
      return true
    end
  end,
  refresh_events = {fk.TurnStart},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("mou__guidao_invalidity") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "mou__guidao_invalidity", 0)
  end,
}
mou__zhangjiao:addSkill(mou__guidao)
local mou__huangtian = fk.CreateTriggerSkill{
  name = "mou__huangtian$",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart , fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return player:hasSkill(self) and target == player and player.room:getTag("RoundCount") == 1 and  #player:getAvailableEquipSlots(Card.SubtypeTreasure) > 0 and table.find(player.room.void, function(id) return Fk:getCardById(id).name == "mougong__peace_spell" end)
    else
      return player:hasSkill(self) and target and target ~= player and target.kingdom == "qun" and player:hasSkill("mou__guidao",true) and player:getMark("@daobing") < 8 and player:getMark("mou__huangtian-round") < 4
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local spell = table.find(room.void, function(id) return Fk:getCardById(id).name == "mougong__peace_spell" end)
      if not spell then return end
      local existingEquip = player:getEquipments(Card.SubtypeTreasure)
      if #existingEquip > 0 then
        room:moveCards({ ids = existingEquip, toArea = Card.DiscardPile, moveReason = fk.ReasonPutIntoDiscardPile, },
        {ids = {spell}, to = player.id, toArea = Card.PlayerEquip, moveReason = fk.ReasonPut, })
      else
        room:moveCards({ids = {spell}, to = player.id, toArea = Card.PlayerEquip, moveReason = fk.ReasonPut, })
      end
    else
      local n = math.min(2, 8-player:getMark("@daobing"), 4-player:getMark("mou__huangtian-round"))
      room:addPlayerMark(player, "@daobing", n)
      room:addPlayerMark(player, "mou__huangtian-round", n)
    end
  end,
}
mou__zhangjiao:addSkill(mou__huangtian)
Fk:loadTranslationTable{
  ["mou__zhangjiao"] = "谋张角",
  ["mou__leiji"] = "雷击",
  [":mou__leiji"] = "出牌阶段，你可以移去4个“道兵”标记，对一名其他角色造成1点雷电伤害。",
  ["@daobing"] = "道兵",
  ["mou__guidao"] = "鬼道",
  [":mou__guidao"] = "①游戏开始时，你获得4个“道兵”标记（你至多拥有8个“道兵”标记）；<br>"..
  "②当一名角色受到属性伤害后，你获得2个“道兵”标记；<br>"..
  "③当你受到伤害时，你可以移去2个“道兵”标记，防止此伤害，若此时为你回合外，〖鬼道〗②失效直到你下回合开始。",
  ["#mou__guidao-invoke"] = "鬼道:你可以移去2个“道兵”标记，防止此次受到的伤害",
  ["#mou__guidao_invalidity-invoke"] = "鬼道:可移去2个“道兵”标记，防止此伤害，且〖鬼道〗②失效直到你下回合开始",
  ["mou__huangtian"] = "黄天",
  [":mou__huangtian"] = "主公技，锁定技，①第一轮的你的回合开始时，你将游戏外的【太平要术】置入装备区；<br>②当其他群势力角色造成伤害后，"..
  "若你拥有技能〖鬼道〗，你获得2个“道兵”标记（每轮你至多以此法获得4个标记）。",

  ["$mou__leiji1"] = "云涌风起，雷电聚集！",
  ["$mou__leiji2"] = "乾坤无极，风雷受命！",
  ["$mou__guidao1"] = "世间万法，殊途同归！",
  ["$mou__guidao2"] = "从无邪恶之法，唯有作恶之人！",
  ["$mou__huangtian1"] = "汝等既顺黄天，当应天公之命！",
  ["$mou__huangtian2"] = "黄天佑我，道兵显威！",
  ["~mou__zhangjiao"] = "只叹未能覆汉，徒失天时。",
}

local mou__zhugeliang = General(extension, "mou__zhugeliang", "shu", 3)
local mou__huoji = fk.CreateActiveSkill{
  name = "mou__huoji",
  anim_type = "offensive",
  prompt = "#mou__huoji",
  frequency = Skill.Quest,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local kingdom = target.kingdom
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == kingdom and not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
local mou__huoji_trigger = fk.CreateTriggerSkill{
  name = "#mou__huoji_trigger",
  main_skill = mou__huoji,
  mute = true,
  events = {fk.EventPhaseStart, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("mou__huoji", true) and not player:getQuestSkillState("mou__huoji") then
      if event == fk.EventPhaseStart then
        if player.phase == Player.Start then
          local n = 0
          player.room.logic:getEventsOfScope(GameEvent.Damage, 999, function(e)
            local damage = e.data[1]
            if damage and damage.from and damage.from == player and damage.damageType == fk.FireDamage then
              n = n + damage.damage
            end
          end, Player.HistoryGame)
          return n >= #player.room.players
        end
      else
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("mou__huoji")
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, "mou__huoji", "special")
      room:handleAddLoseSkills(player, "-mou__huoji|-mou__kanpo|mou__guanxing|mou__kongcheng", nil, true, false)
      room:updateQuestSkillState(player, "mou__huoji", false)
    else
      room:notifySkillInvoked(player, "mou__huoji", "negative")
      room:updateQuestSkillState(player, "mou__huoji", true)
    end
  end,
}
local mou__kanpo = fk.CreateTriggerSkill{
  name = "mou__kanpo",
  anim_type = "control",
  events ={fk.RoundStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.RoundStart then
        return true
      else
        return target ~= player and player:getMark(self.name) ~= 0 and table.contains(player:getMark(self.name), data.card.trueName)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.RoundStart then
      return true
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#mou__kanpo-invoke::"..target.id..":"..data.card:toLogString())
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      local mark = player:getMark(self.name)
      if mark == 0 then mark = {} end
      local all_choices = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card.type ~= Card.TypeEquip and not card.is_derived then
          table.insertIfNeed(all_choices, card.trueName)
        end
      end
      table.insert(all_choices, "Cancel")
      local choices = table.simpleClone(all_choices)
      if #mark > 0 then
        for _, name in ipairs(mark) do
          table.removeOne(choices, name)
        end
      end
      mark = {}
      for i = 1, 3, 1 do
        local choice = room:askForChoice(player, choices, self.name,
          "#mou__kanpo-choice:::"..(4-i)..":"..table.concat(table.map(mark, function(name)
            return "【"..Fk:translate(name).."】" end), "、"), nil, all_choices)
        if choice == "Cancel" then
          room:setPlayerMark(player, self.name, {})
          return
        else
          table.insert(mark, choice)
        end
      end
      room:setPlayerMark(player, self.name, mark)
    else
      room:doIndicate(player.id, {target.id})
      local mark = player:getMark(self.name)
      table.removeOne(mark, data.card.trueName)
      room:setPlayerMark(player, self.name, mark)
      room.logic:getCurrentEvent().parent:shutdown()
    end
  end,
}
local mou__guanxing = fk.CreateTriggerSkill{
  name = "mou__guanxing",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      return player.phase == Player.Start or
        (player.phase == Player.Finish and #player:getPile("mou__guanxing&") > 0 and player:getMark("mou__guanxing-turn") > 0)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Start then
      return true
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#mou__guanxing-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      local n = player:usedSkillTimes(self.name, Player.HistoryGame) > 1 and (#player:getPile("mou__guanxing&") + 1) or 7
      if #player:getPile("mou__guanxing&") > 0 then
        room:moveCards({
          from = player.id,
          ids = player:getPile("mou__guanxing&"),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
          fromSpecialName = "mou__guanxing&",
        })
      end
      if player.dead then return end
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(room:getNCards(n))
      player:addToPile("mou__guanxing&", dummy, false, self.name)
      if player.dead or #player:getPile("mou__guanxing&") == 0 then return end
    end
    local result = room:askForGuanxing(player, player:getPile("mou__guanxing&"), nil, nil, self.name, true, {"mou__guanxing&", "Top"})
    if #result.bottom > 0 then
      room:moveCards({
        ids = table.reverse(result.bottom),
        from = player.id,
        fromArea = Card.PlayerSpecial,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        fromSpecialName = "mou__guanxing&",
      })
      room:sendLog{
        type = "#GuanxingResult",
        from = player.id,
        arg = #result.bottom,
        arg2 = 0,
      }
    elseif player.phase == Player.Start then
      room:setPlayerMark(player, "mou__guanxing-turn", 1)
    end
  end,
}
local mou__kongcheng = fk.CreateTriggerSkill{
  name = "mou__kongcheng",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:hasSkill("mou__guanxing", true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if #player:getPile("mou__guanxing&") > 0 then
      room:notifySkillInvoked(player, self.name, "defensive")
      local pattern = ".|1~"..(#player:getPile("mou__guanxing&") - 1)
      if #player:getPile("mou__guanxing&") < 2 then
        pattern = "FuckYoka"
      end
      local judge = {
        who = player,
        reason = self.name,
        pattern = pattern,
      }
      room:judge(judge)
      if judge.card.number < #player:getPile("mou__guanxing&") then
        data.damage = data.damage - 1
      end
    else
      room:notifySkillInvoked(player, self.name, "negative")
      data.damage = data.damage + 1
    end
  end,
}
mou__huoji:addRelatedSkill(mou__huoji_trigger)
mou__zhugeliang:addSkill(mou__huoji)
mou__zhugeliang:addSkill(mou__kanpo)
mou__zhugeliang:addRelatedSkill(mou__guanxing)
mou__zhugeliang:addRelatedSkill(mou__kongcheng)
Fk:loadTranslationTable{
  ["mou__zhugeliang"] = "谋诸葛亮",
  ["mou__huoji"] = "火计",
  [":mou__huoji"] = "使命技，出牌阶段限一次，你可以选择一名其他角色，对其及其同势力的其他角色各造成1点火焰伤害。<br>\
  <strong>成功</strong>：准备阶段，若你本局游戏对其他角色造成过至少X点火焰伤害（X为本局游戏人数），你失去〖火计〗〖看破〗，获得〖观星〗〖空城〗。<br>\
  <strong>失败</strong>：当你进入濒死状态时，使命失败。",
  ["mou__kanpo"] = "看破",
  [":mou__kanpo"] = "每轮开始时，你可以记录三次与本轮清除牌名均不相同的牌名。其他角色使用你记录牌名的牌时，你可以移除一个对应记录，令此牌无效。",
  ["mou__guanxing"] = "观星",
  [":mou__guanxing"] = "准备阶段，你移去所有“星”，将牌堆顶X张牌置为“星”（X为移去“星”数+1，至多为7；首次发动时X为7），然后你可以将任意张“星”"..
  "置于牌堆顶。结束阶段，若你本回合准备阶段未将“星”置于牌堆顶，则你可以将任意张“星”置于牌堆顶。你可以将“星”如手牌般使用或打出。",
  ["mou__kongcheng"] = "空城",
  [":mou__kongcheng"] = "锁定技，当你受到伤害时，若你有〖观星〗且：有“星”，你进行一次判定，若判定结果点数小于“星”数，则此伤害-1；没有“星”，"..
  "你受到的伤害+1。",
  ["#mou__huoji"] = "火计：选择一名角色，对所有与其势力相同的其他角色造成1点火焰伤害",
  ["#mou__kanpo-choice"] = "看破：你可以选择3次牌名（还剩%arg次），其他角色使用同名牌时，你可令其无效<br>已记录：%arg2",
  ["#mou__kanpo-invoke"] = "看破：是否令 %dest 使用的%arg无效？",
  ["mou__guanxing&"] = "星",
  ["#mou__guanxing-invoke"] = "观星：你可以将任意张“星”置于牌堆顶",

  ["$mou__huoji1"] = "风起之日，火攻之时！",
  ["$mou__huoji2"] = "发火有时，起火有日！",
  ["$mou__kanpo1"] = "呵！不过尔尔。",
  ["$mou__kanpo2"] = "哼！班门弄斧。",
  ["$mou__guanxing1"] = "冷夜孤星，正如时局啊。",
  ["$mou__guanxing2"] = "明星皓月，前路通达。",
  ["$mou__kongcheng1"] = "仲达可愿与我城中一叙？",
  ["$mou__kongcheng2"] = "城下千军万马，我亦谈笑自若。",
  ["~mou__zhugeliang"] = "纵具地利，不得天时亦难胜也……",
}

Fk:loadTranslationTable{
  ["mou__huangyueying"] = "谋黄月英",
  ["mou__qicai"] = "奇才",
  [":mou__qicai"] = "你使用锦囊牌无距离限制。出牌阶段限一次，你可以选择一名其他角色，将手牌或弃牌堆中一张防具牌置入其装备区（每局游戏每种牌名限一次），"..
  "然后其获得“奇”标记。有“奇”标记的角色接下来获得的三张普通锦囊牌须交给你。",
  ["mou__jizhi"] = "集智",
  [":mou__jizhi"] = "锁定技，当你使用普通锦囊牌时，你摸一张牌，以此法获得的牌本回合不计入手牌上限。",
}

return extension
