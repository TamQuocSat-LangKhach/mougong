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
    local max_limit = table.contains({"aaa_role_mode", "aab_role_mode"}, Fk:currentRoom().room_settings.gameMode) and 4 or 2
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < max_limit
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
          break
        end
      end
    end
    if not player.dead then
      player:drawCards(1, self.name)
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

    AimGroup:cancelTarget(data, player.id)
    AimGroup:addTargets(room, data, to)

    if Fk:getCardById(self.cost_data[2]).suit == Card.Heart and player:getMark("mou__liuli-turn") == 0 then
      local targets = {}
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
    return true
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
  ["#mou__daqiao"] = "矜持之花",
  ["mou__guose"] = "国色",
  [":mou__guose"] = "出牌阶段限四次（若不为身份模式改为限两次），你可以选择一项：1.将一张<font color='red'>♦</font>牌当【乐不思蜀】使用；"..
  "2.弃置一张<font color='red'>♦</font>牌并弃置场上的一张【乐不思蜀】。选择完成后，你摸一张牌。",
  ["mou__guose_use"] = "使用乐不思蜀",
  ["mou__guose_throw"] = "弃置乐不思蜀",
  ["mou__liuli"] = "流离",
  ["#mou__liuli_dangxian"] = "流离",
  [":mou__liuli"] = "每当你成为【杀】的目标时，你可以弃置一张牌并选择你攻击范围内为此【杀】合法目标（无距离限制）的一名角色：若如此做，"..
  "该角色代替你成为此【杀】的目标。若你以此法弃置了<font color='red'>♥️</font>牌，则你可以令一名不为此【杀】使用者的其他角色获得“流离”标记，"..
  "且移去场上所有其他的“流离”（每回合限一次）。有“流离”的角色回合开始时，其移去其“流离”并执行一个额外的出牌阶段。",
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
    if target == player and player:hasSkill(self) then
      return (data.card and U.hasFullRealCard(player.room, data.card)) or player:getMark("@mou__jianxiong") < 2
    end
  end,
  on_use = function(self, event, target, player, data)
    if data.card and U.hasFullRealCard(player.room, data.card) then
      player.room:moveCardTo(data.card, Player.Hand, player, fk.ReasonPrey, self.name)
      if player.dead then return end
    end
    local num = 2 - player:getMark("@mou__jianxiong")
    if num > 0 then
      player:drawCards(num, self.name)
    end
    if player:getMark("@mou__jianxiong") > 0 then
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
    player:broadcastSkillInvoke("mou__jianxiong")
    local choice = room:askForChoice(player, {"0", "1", "2"}, "mou__jianxiong", "#mou__jianxiong-choice")
    room:addPlayerMark(player,  "@mou__jianxiong", tonumber(choice))
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
      return not player:isKongcheng() and #suits >= num
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
      "#mou__qingzheng-choose:::"..(3 - player:getMark("@mou__jianxiong")), self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(self.cost_data)
    local num = 3 - player:getMark("@mou__jianxiong")
    local suits = {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      local suit = Fk:getCardById(id):getSuitString(true)
      if suit ~= "log_nosuit" then
        table.insertIfNeed(suits, suit)
      end
    end
    local choices = room:askForChoices(player, suits, num, num, self.name, "#mou__qingzheng-discard:::".. num, false)
    local cards = table.filter(player.player_cards[Player.Hand], function (id)
      return not player:prohibitDiscard(Fk:getCardById(id)) and table.contains(choices, Fk:getCardById(id):getSuitString(true))
    end)
    if #cards > 0 then
      room:throwCard(cards, self.name, player, player)
    end
    if player.dead then return end
    local cids = to.player_cards[Player.Hand]
    local cards1 = {}
    if #cids > 0 then
      local id1 = room:askForCardChosen(player, to, { card_data = { { "$Hand", cids }  } }, self.name, "#mou__qingzheng-throw")
      cards1 = table.filter(cids, function(id) return Fk:getCardById(id).suit == Fk:getCardById(id1).suit end)
      room:throwCard(cards1, self.name, to, player)
    end
    if #cards > #cards1 and not to.dead then
      room:damage{ from = player, to = to, damage = 1, skillName = self.name }
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
    local targets = table.filter(player.room:getOtherPlayers(player), function(p) return p.kingdom == "wei" end)
    if #targets > 0 then
      local to = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#mou__hujia-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:damage{
      from = data.from,
      to = to,
      damage = data.damage,
      damageType = data.damageType,
      skillName = data.skillName,
      chain = data.chain,
      card = data.card,
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
  ["#mou__caocao"] = "魏武大帝",
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
  ["#mou__jianxiong-dismark"] = "奸雄：是否弃置一枚“治世”标记？",
  ["#mou__jianxiong-choice"] = "奸雄：请选择要获得的“治世”标记数量。",
  ["#mou__qingzheng-addmark"] = "清正：是否获得一个“治世”标记？",
  ["#mou__qingzheng-choose"] = "清正：可以弃置 %arg 种花色的所有手牌，观看一名角色手牌并弃置其中一种花色",
  ["#mou__qingzheng-discard"] = "清正：请选择 %arg 种花色的所有手牌弃置",
  ["#mou__qingzheng-throw"] = "清正：弃置其一种花色的所有手牌",
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
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
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
  ["#mou__sunquan"] = "江东大帝",
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
  ["#mou__zhouyu"] = "江淮之杰",
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
          if not p:prohibitDiscard(card) then
            room:throwCard(cards, self.name, p, p)
          end
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
  ["#mou__zhenji"] = "薄幸幽兰",
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
local peace_spell = {{"js__peace_spell", Card.Heart, 3}}
local mou__huangtian = fk.CreateTriggerSkill{
  name = "mou__huangtian$",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart , fk.Damage},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      return player:hasSkill(self) and target == player and player.room:getTag("RoundCount") == 1
      and player:hasEmptyEquipSlot(Card.SubtypeTreasure)
      and room:getCardArea(U.prepareDeriveCards(room, peace_spell, "huangtian_spell")[1]) == Card.Void
    else
      return player:hasSkill(self) and target and target ~= player and target.kingdom == "qun" and player:hasSkill("mou__guidao", true) and
      player:getMark("@daobing") < 8 and player:getMark("mou__huangtian-round") < 4
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local spell = U.prepareDeriveCards(room, peace_spell, "huangtian_spell")[1]
      U.moveCardIntoEquip(room, player, spell, self.name, true, player)
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
  ["#mou__zhangjiao"] = "驱雷掣电",
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

local mou__liubiao = General(extension, "mou__liubiao", "qun", 3)
local mou__zishou = fk.CreateTriggerSkill{
  name = "mou__zishou",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player ~= target and target.phase == Player.Finish and not target:isNude() then
      return #U.getActualDamageEvents(player.room, 1, function(e)
        local damage = e.data[1]
        return (damage.from == player and damage.to == target) or (damage.from == target and damage.to == player)
      end, Player.HistoryGame) == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCard(target, 1, 1, true, self.name, false, ".", "#mou__zishou-give::"..player.id)
    room:obtainCard(player, cards[1], false, fk.ReasonGive)
  end,
}
mou__liubiao:addSkill(mou__zishou)
local mou__zongshi = fk.CreateTriggerSkill{
  name = "mou__zongshi",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player == target and data.from and not data.from:isKongcheng() then
      local mark = U.getMark(player, self.name)
      return not table.contains(mark, data.from.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, self.name)
    table.insert(mark, data.from.id)
    room:setPlayerMark(player, self.name, mark)
    data.from:throwAllCards("h")
  end,
}
mou__liubiao:addSkill(mou__zongshi)
Fk:loadTranslationTable{
  ["mou__liubiao"] = "谋刘表",
  ["#mou__liubiao"] = "跨蹈汉南",
  ["mou__zishou"] = "自守",
  [":mou__zishou"] = "锁定技，其他角色的结束阶段，若本局游戏你与其均未对另一方造成过伤害，其交给你一张牌。",
  ["mou__zongshi"] = "宗室",
  [":mou__zongshi"] = "锁定技，当你受到伤害后，伤害来源弃置所有手牌（每名角色限一次）。",
  ["#mou__zishou-give"] = "自守：你须交给 %dest 一张牌 ",
  
  ["$mou__zishou1"] = "荆襄通连天下，我有何惧？",
  ["$mou__zishou2"] = "据此人杰地灵之地，何必再行征战？",
  ["$mou__zongshi1"] = "是时候讨伐悖逆之人了。",
  ["$mou__zongshi2"] = "强汉之威，贼寇岂有不败之理？",
  ["~mou__liubiao"] = "我死之后，只望荆州仍然安定。",
}

local mou__liubei = General(extension, "mou__liubei", "shu", 4)
local mou__rende = fk.CreateActiveSkill{
  name = "mou__rende",
  prompt = "#mou__rende-promot",
  interaction = function()
    local choices = {"mou__rende"}
    if Self:getMark("@mou__renwang") > 1 and Self:getMark("mou__rende_vs-turn") == 0 then
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeBasic and not card.is_derived and Self:canUse(card) and not Self:prohibitUse(card) then
          table.insertIfNeed(choices, card.name)
        end
      end
    end
    return UI.ComboBox {choices = choices}
  end,
  card_filter = function(self, to_select, selected)
    return self.interaction.data == "mou__rende"
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if self.interaction.data == "mou__rende" then
      return #selected == 0 and to_select ~= Self.id 
      and Fk:currentRoom():getPlayerById(to_select):getMark("mou__rende_target-phase") == 0
    else
      local to_use = Fk:cloneCard(self.interaction.data)
      to_use.skillName = self.name
      if (#selected == 0 or to_use.multiple_targets) and
      Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), to_use) then return false end
      return to_use.skill:targetFilter(to_select, selected, selected_cards, to_use)
    end
  end,
  feasible = function(self, selected, selected_cards)
    if self.interaction.data == "mou__rende" then
      return #selected_cards > 0 and #selected == 1
    else
      local to_use = Fk:cloneCard(self.interaction.data)
      to_use.skillName = self.name
      return to_use.skill:feasible(selected, selected_cards, Self, to_use)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "mou__rende" then
      local target = room:getPlayerById(effect.tos[1])
      room:setPlayerMark(target, "mou__rende_target-phase", 1)
      room:setPlayerMark(target, "mou__rende_target", 1)
      room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
      room:setPlayerMark(player, "@mou__renwang", math.min(8, player:getMark("@mou__renwang") + #effect.cards))
    else
      room:removePlayerMark(player, "@mou__renwang", 2)
      room:setPlayerMark(player, "mou__rende_vs-turn", 1)
      local use = {
        from = player.id,
        tos = table.map(effect.tos, function (id) return {id} end),
        card = Fk:cloneCard(self.interaction.data),
      }
      use.card.skillName = self.name
      room:useCard(use)
    end
  end,
}
local mou__rende_trigger = fk.CreateTriggerSkill{
  name = "#mou__rende_trigger",
  mute = true,
  main_skill = mou__rende,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mou__rende) and target == player and player.phase == Player.Play and player:getMark("@mou__renwang") < 8
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("mou__rende")
    room:setPlayerMark(player, "@mou__renwang", math.min(8, player:getMark("@mou__renwang") + 2))
  end,
}
mou__rende:addRelatedSkill(mou__rende_trigger)
local mou__rende_response = fk.CreateTriggerSkill{
  name = "#mou__rende_response",
  mute = true,
  main_skill = mou__rende,
  events = {fk.AskForCardUse, fk.AskForCardResponse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mou__rende)
    and player:getMark("@mou__renwang") > 1 and player:getMark("mou__rende_vs-turn") == 0 and
      ((data.cardName and Fk:cloneCard(data.cardName).type == Card.TypeBasic) or
      (data.pattern and Exppattern:Parse(data.pattern):matchExp(".|.|.|.|.|basic")))
  end,
  on_cost = function (self, event, target, player, data)
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not card.is_derived and Exppattern:Parse(data.pattern):match(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names > 0 then
      local name = names[1]
      if #names > 1 then
        name = table.every(names, function(str) return string.sub(str, -5) == "slash" end) and "slash" or "basic"
      end
      if player.room:askForSkillInvoke(player, self.name, nil, "#mou__rende-invoke:::"..name) then
        self.cost_data = names
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = self.cost_data
    if event == fk.AskForCardUse then
      local extra_data = data.extraData
      local isAvailableTarget = function(card, p)
        if extra_data then
          if type(extra_data.must_targets) == "table" and #extra_data.must_targets > 0 and
              not table.contains(extra_data.must_targets, p.id) then
            return false
          end
          if type(extra_data.exclusive_targets) == "table" and #extra_data.exclusive_targets > 0 and
              not table.contains(extra_data.exclusive_targets, p.id) then
            return false
          end
        end
        return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player.id, card, true)
      end
      local findCardTarget = function(card)
        local tos = {}
        for _, p in ipairs(room.alive_players) do
          if isAvailableTarget(card, p) then
            table.insert(tos, p.id)
          end
        end
        return tos
      end
      names = table.filter(names, function (c_name)
        local card = Fk:cloneCard(c_name)
        return not player:prohibitUse(card) and (card.skill:getMinTargetNum() == 0 or #findCardTarget(card) > 0)
      end)
      if #names == 0 then return false end
      local name = room:askForChoice(player, names, self.name, "#mou__rende-name")
      player:broadcastSkillInvoke("mou__rende")
      room:removePlayerMark(player, "@mou__renwang", 2)
      room:setPlayerMark(player, "mou__rende_vs-turn", 1)
      local card = Fk:cloneCard(name)
      card.skillName = mou__rende.name
      data.result = {
        from = player.id,
        card = card,
      }
      if card.skill:getMinTargetNum() == 1 then
        local tos = findCardTarget(card)
        if #tos == 1 then
          data.result.tos = {{tos[1]}}
        elseif #tos > 1 then
          data.result.tos = {room:askForChoosePlayers(player, tos, 1, 1, "#mou__rende-target:::" .. name, self.name, false, true)}
        else
          return false
        end
      end
      if data.eventData then
        data.result.toCard = data.eventData.toCard
        data.result.responseToEvent = data.eventData.responseToEvent
      end
      return true
    else
      names = table.filter(names, function (c_name)
        return not player:prohibitResponse(Fk:cloneCard(c_name))
      end)
      if #names == 0 then return false end
      local name = room:askForChoice(player, names, self.name, "#mou__rende-name")
      player:broadcastSkillInvoke("mou__rende")
      room:removePlayerMark(player, "@mou__renwang", 2)
      room:setPlayerMark(player, "mou__rende_vs-turn", 1)
      local card = Fk:cloneCard(name)
      card.skillName = mou__rende.name
      data.result = card
      return true
    end
  end
}
mou__rende:addRelatedSkill(mou__rende_response)
mou__liubei:addSkill(mou__rende)
local mou__zhangwu = fk.CreateActiveSkill{
  name = "mou__zhangwu",
  anim_type = "control",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  card_filter = function() return false end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local x = math.min(3, (room:getTag("RoundCount") - 1))
    if x > 0 then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if player.dead then break end
        if not p.dead and p:getMark("mou__rende_target") > 0 and not p:isNude() then
          local cards = (#p:getCardIds("he") < x) and p:getCardIds("he") or
          room:askForCard(p, x, x, true, self.name, false, ".", "#mou__zhangwu-give::"..player.id..":"..x)
          if #cards > 0 then
            local dummy = Fk:cloneCard("dilu")
            dummy:addSubcards(cards)
            room:obtainCard(player, dummy, false, fk.ReasonGive)
          end
        end
      end
    end
    if not player.dead and player:isWounded() then
      room:recover { num = 3, skillName = self.name, who = player, recoverBy = player}
    end
    room:handleAddLoseSkills(player, "-mou__rende")
  end,
}
mou__liubei:addSkill(mou__zhangwu)
local mou__jijiang = fk.CreateTriggerSkill{
  name = "mou__jijiang$",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local players = player.room.alive_players
      return #players > 2 and table.find(players, function(p) return p ~= player and p.kingdom == "shu" and p.hp >= player.hp end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "mou__jijiang_choose", "#mou__jijiang-promot", true, nil, true)
    if success and dat then
      self.cost_data = dat.targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local victim = room:getPlayerById(self.cost_data[1])
    local bro = room:getPlayerById(self.cost_data[2])
    room:doIndicate(player.id, {bro.id})
    local choices = {"mou__jijiang_skip"}
    if not bro:prohibitUse(Fk:cloneCard("slash")) and not bro:isProhibited(victim, Fk:cloneCard("slash")) then
      table.insert(choices, 1, "mou__jijiang_slash:"..victim.id)
    end
    if room:askForChoice(bro, choices, self.name) == "mou__jijiang_skip" then
      room:setPlayerMark(bro, "@@mou__jijiang_skip", 1)
    else
      room:useVirtualCard("slash", nil, bro, victim, self.name, true)
    end
  end,
}
local mou__jijiang_choose = fk.CreateActiveSkill{
  name = "mou__jijiang_choose",
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if  #selected > 1 or to_select == Self.id then return false end
    if #selected == 0 then
      return true
    else
      local victim = Fk:currentRoom():getPlayerById(selected[1])
      local bro = Fk:currentRoom():getPlayerById(to_select)
      return bro.kingdom == "shu" and bro.hp >= Self.hp and bro:inMyAttackRange(victim)
    end
  end,
}
Fk:addSkill(mou__jijiang_choose)
local mou__jijiang_delay = fk.CreateTriggerSkill{
  name = "#mou__jijiang_delay",
  events = {fk.EventPhaseChanging},
  priority = 10,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@mou__jijiang_skip") > 0 and data.to == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@mou__jijiang_skip", 0)
    target:skip(Player.Play)
    return true
  end,
}
mou__jijiang:addRelatedSkill(mou__jijiang_delay)
mou__liubei:addSkill(mou__jijiang)
Fk:loadTranslationTable{
  ["mou__liubei"] = "谋刘备",
  ["#mou__liubei"] = "雄才盖世",
  ["mou__rende"] = "仁德",
  [":mou__rende"] = "①出牌阶段开始时，你获得2枚“仁望”标记（至多拥有8枚）；"..
  "<br>②出牌阶段，你可以选择一名本阶段未选择过的其他角色，交给其任意张牌，然后你获得等量枚“仁望”标记；"..
  "<br>③每回合限一次，当你需要使用或打出基本牌时，你可以移去2枚“仁望”标记，视为使用或打出之。",
  ["@mou__renwang"] = "仁望",
  ["#mou__rende-invoke"] = "仁德：可以移去2枚“仁望”标记，视为使用或打出 %arg",
  ["#mou__rende-name"] = "仁德：选择视为使用或打出的所需的基本牌的牌名",
  ["#mou__rende-target"] = "仁德：选择使用【%arg】的目标角色",
  ["#mou__rende_response"] = "仁望",
  ["#mou__rende-promot"] = "仁望：将牌交给其他角色获得“仁望”标记，或移去标记视为使用基本牌",
  ["mou__zhangwu"] = "章武",
  [":mou__zhangwu"] = "限定技，出牌阶段，你可以令〖仁德〗选择过的所有角色依次交给你X张牌（X为游戏轮数-1，至多为3），然后你回复3点体力，失去技能〖仁德〗。",
  ["#mou__zhangwu-give"] = "章武：请交给 %dest %arg 张牌",
  ["mou__jijiang"] = "激将",
  [":mou__jijiang"] = "主公技，出牌阶段结束时，你可以选择一名其他角色，令一名攻击范围内含有其且体力值不小于你的其他蜀势力角色选择一项："..
  "1.视为对其使用一张【杀】；2.跳过下一个出牌阶段。",
  ["@@mou__jijiang_skip"] = "激将",
  ["#mou__jijiang-promot"] = "激将：先选择【杀】的目标，再选需要响应“激将”的蜀势力角色",
  ["mou__jijiang_slash"] = "视为对 %src 使用一张【杀】",
  ["mou__jijiang_skip"] = "跳过下一个出牌阶段",
  ["mou__jijiang_choose"] = "激将",
  ["$mou__rende1"] = "仁德为政，自得民心！",
  ["$mou__rende2"] = "民心所望，乃吾政所向！",
  ["$mou__zhangwu1"] = "众将皆言君恩，今当献身以报！",
  ["$mou__zhangwu2"] = "汉贼不两立，王业不偏安！",
  ["$mou__jijiang1"] = "匡扶汉室，岂能无诸将之助！",
  ["$mou__jijiang2"] = "大汉将士，何人敢战？",
  ["~mou__liubei"] = "汉室之兴，皆仰望丞相了……",
}

local mou__wolong = General(extension, "mou__wolong", "shu", 3)
local mou__huoji = fk.CreateActiveSkill{
  name = "mou__huoji",
  anim_type = "offensive",
  prompt = "#mou__huoji",
  frequency = Skill.Quest,
  card_num = 0,
  target_num = 1,
  mute = true,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:getQuestSkillState(self.name)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name, math.random(2))
    local kingdom = target.kingdom
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == kingdom then
        table.insert(targets, p)
      end
    end
    for _, p in ipairs(targets) do
      if not p.dead then
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
    if target == player and player:hasSkill(mou__huoji) and not player:getQuestSkillState("mou__huoji") then
      if event == fk.EventPhaseStart then
        if player.phase == Player.Start then
          local room = player.room
          local n = 0
          U.getActualDamageEvents(room, 1, function(e)
            local damage = e.data[1]
            if damage and damage.from == player and damage.damageType == fk.FireDamage then
              n = n + damage.damage
            end
          end, Player.HistoryGame)
          return n >= #room.players
        end
      else
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:broadcastSkillInvoke("mou__huoji", math.random(2))
      room:notifySkillInvoked(player, "mou__huoji", "special")
      room:updateQuestSkillState(player, "mou__huoji", false)
      room:handleAddLoseSkills(player, "-mou__huoji|-mou__kanpo|mou__guanxing|mou__kongcheng", nil, true, false)
      if player.general == "mou__wolong" then
        player.general = "mou__zhugeliang"
        room:broadcastProperty(player, "general")
      else
        player.deputyGeneral = "mou__zhugeliang"
        room:broadcastProperty(player, "deputyGeneral")
      end
    else
      player:broadcastSkillInvoke("mou__huoji", 3)
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
        if player:getMark("@[private]$mou__kanpo") ~= 0 then return true end
        local max_limit = table.contains({"m_1v2_mode", "m_2v2_mode"}, player.room.settings.gameMode) and 2 or 4
        return player:getMark("mou__kanpo_times") < max_limit
      else
        return target ~= player and table.contains(U.getPrivateMark(player, "$mou__kanpo"), data.card.trueName)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.RoundStart then
      return true
    else
      local room = player.room
      if room:askForSkillInvoke(player, self.name, nil,
      "#mou__kanpo-invoke::"..target.id..":"..data.card:toLogString()) then
        room:doIndicate(player.id, {target.id})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      local all_names = player:getMark("mou__kanpo")
      if all_names == 0 then
        all_names = U.getAllCardNames("btd", true)
        room:setPlayerMark(player, "mou__kanpo", all_names)
      end
      table.insert(all_names, "Cancel")
      local names = table.simpleClone(all_names)

      if player:getMark("@[private]$mou__kanpo") ~= 0 then
        for _, name in ipairs(U.getPrivateMark(player, "$mou__kanpo")) do
          table.removeOne(names, name)
        end
        room:setPlayerMark(player, "@[private]$mou__kanpo", 0)
      end

      local max_limit = table.contains({"m_1v2_mode", "m_2v2_mode"}, room.settings.gameMode) and 2 or 4
      max_limit = max_limit - player:getMark("mou__kanpo_times")

      local mark = {}
      for i = max_limit, 1, -1 do
        local choice = room:askForChoice(player, names, self.name,
          "#mou__kanpo-choice:::"..i..":"..table.concat(table.map(mark, function(name)
            return "【"..Fk:translate(name).."】" end), "、"), nil, all_names)
        if choice == "Cancel" then
          break
        else
          table.insert(mark, choice)
        end
      end
      if #mark > 0 then
        room:addPlayerMark(player, "mou__kanpo_times", #mark)
        U.setPrivateMark(player, "$mou__kanpo", mark)
      end
    else
      local mark = U.getPrivateMark(player, "$mou__kanpo")
      table.removeOne(mark, data.card.trueName)
      if #mark > 0 then
        U.setPrivateMark(player, "$mou__kanpo", mark)
      else
        room:setPlayerMark(player, "@[private]$mou__kanpo", 0)
      end
      data.toCard = nil
      data.tos = {}
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@[private]$mou__kanpo", 0)
    room:setPlayerMark(player, "mou__kanpo_times", 0)
  end,
}
mou__huoji:addRelatedSkill(mou__huoji_trigger)
mou__wolong:addSkill(mou__huoji)
mou__wolong:addSkill(mou__kanpo)
Fk:loadTranslationTable{
  ["mou__wolong"] = "谋卧龙诸葛亮",
  ["mou__huoji"] = "火计",
  [":mou__huoji"] = "使命技，出牌阶段限一次，你可以选择一名其他角色，对其及其同势力的其他角色各造成1点火焰伤害。<br>\
  <strong>成功</strong>：准备阶段，若你本局游戏对其他角色造成过至少X点火焰伤害（X为本局游戏人数），你失去〖火计〗〖看破〗，获得〖观星〗〖空城〗。<br>\
  <strong>失败</strong>：当你进入濒死状态时，使命失败。",
  ["mou__kanpo"] = "看破",
  [":mou__kanpo"] = "每轮开始时，你清除〖看破〗记录的牌名，然后你可以选择并记录任意个数与本轮清除牌名均不相同的"..
  "非装备牌的牌名（每局游戏至多记录四个牌名，若为斗地主或2V2模式则改为两个牌名）。"..
  "当其他角色使用与你记录牌名相同的牌时，你可以移除一个对应牌名的记录，然后令此牌无效并摸一张牌。",
  ["#mou__huoji"] = "发动 火计，选择一名角色，对所有与其势力相同的其他角色造成1点火焰伤害",
  ["#mou__kanpo-choice"] = "看破：你可以选择至多%arg个牌名，其他角色使用同名牌时，你可令其无效<br>已记录：%arg2",
  ["#mou__kanpo-invoke"] = "看破：是否令 %dest 使用的%arg无效？",
  ["@[private]$mou__kanpo"] = "看破",

  ["$mou__huoji1"] = "区区汉贼，怎挡天火之威？",
  ["$mou__huoji2"] = "就让此火，再兴炎汉国祚。",
  ["$mou__huoji3"] = "吾虽有功，然终逆天命啊。",
  ["$mou__kanpo1"] = "知汝欲行此计，故已待之久矣。",
  ["$mou__kanpo2"] = "静思敌谋，以出应对之策。",
  ["~mou__wolong"] = "纵具地利，不得天时亦难胜也……",
}

local mou__zhugeliang = General(extension, "mou__zhugeliang", "shu", 3)
mou__zhugeliang.hidden = true
local mou__guanxing = fk.CreateTriggerSkill{
  name = "mou__guanxing",
  derived_piles = "mou__guanxing&",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player.phase == Player.Start then
        return #player:getPile("mou__guanxing&") > 0 or player:getMark("mou__guanxing_times") < 3
      elseif player.phase == Player.Finish then
        return #player:getPile("mou__guanxing&") > 0 and player:getMark("mou__guanxing-turn") > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Start then
      if #player:getPile("mou__guanxing&") > 0 then
        room:moveCards({
          from = player.id,
          ids = player:getPile("mou__guanxing&"),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
          fromSpecialName = "mou__guanxing&",
        })
        if player.dead then return false end
      end
      local n = 7 - 3*player:getMark("mou__guanxing_times")
      if n < 1 then return false end
      room:addPlayerMark(player, "mou__guanxing_times")
      player:addToPile("mou__guanxing&", room:getNCards(n), false, self.name)
      if player.dead or #player:getPile("mou__guanxing&") == 0 then return false end
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

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "mou__guanxing_times", 0)
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
mou__zhugeliang:addSkill(mou__guanxing)
mou__zhugeliang:addSkill(mou__kongcheng)
Fk:loadTranslationTable{
  ["mou__zhugeliang"] = "谋诸葛亮",
  ["mou__guanxing"] = "观星",
  [":mou__guanxing"] = "准备阶段，你移去所有的“星”，并将牌堆顶的X张牌置于武将牌上"..
  "（X为7-此前此技能准备阶段发动次数的三倍），称为“星”，然后你可以将任意张“星”置于牌堆顶。"..
  "结束阶段，若你未于准备阶段将“星”置于牌堆顶，则你可以将任意张“星”置于牌堆顶。你可以如手牌般使用或打出“星”。",
  ["mou__kongcheng"] = "空城",
  [":mou__kongcheng"] = "锁定技，当你受到伤害时，若你拥有技能〖观星〗且你的武将牌上："..
  "有“星”，你判定，若结果点数不大于“星”数，则此伤害-1；没有“星”，此伤害+1。",
  ["mou__guanxing&"] = "星",

  ["$mou__guanxing1"] = "明星皓月，前路通达。",
  ["$mou__guanxing2"] = "冷夜孤星，正如时局啊。",
  ["$mou__kongcheng1"] = "城下千军万马，我亦谈笑自若。",
  ["$mou__kongcheng2"] = "仲达可愿与我城中一叙？",
  ["~mou__zhugeliang"] = "琴焚身陨，功败垂成啊……",
}

return extension
