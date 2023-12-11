local extension = Package("mou_neng")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_neng"] = "谋攻篇-能包",
}
local U = require "packages/utility/utility"
local mousunshangxiang = General(extension, "mou__sunshangxiang", "shu", 4, 4, General.Female)

local mou__jieyin = fk.CreateTriggerSkill{
  name = "mou__jieyin",
  events = {fk.GameStart, fk.EventPhaseStart, fk.Deathed},
  frequency = Skill.Quest,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:getQuestSkillState(self.name) or not player:hasSkill(self) then
      return false
    end
    if event == fk.GameStart then
      return true
    elseif event == fk.EventPhaseStart then
      if player.phase ~= Player.Play then return false end
      local mark = player:getMark("mou__jieyin_target")
      if mark ~= 0 then
        return not player.room:getPlayerById(mark).dead
      end
    elseif event == fk.Deathed then
      return player:getMark("mou__jieyin_target") == target.id
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    if event == fk.GameStart then
      player:broadcastSkillInvoke(self.name, 1)
      local targets = table.map(room:getOtherPlayers(player, false), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#mou__jieyin-choose", self.name, false)
      if #tos > 0 then
        local to = room:getPlayerById(tos[1])
        room:setPlayerMark(to, "@@mou__jieyin", 1)
        room:setPlayerMark(player, "mou__jieyin_target", tos[1])
      end
      return false
    elseif event == fk.EventPhaseStart then
      player:broadcastSkillInvoke(self.name, 1)
      local mark = player:getMark("mou__jieyin_target")
      if mark ~= 0 then
        local to = room:getPlayerById(mark)
        local x = math.max(1,math.min(2, to:getHandcardNum()))
        local cards = room:askForCard(to, x, 2, false, self.name, true, ".", "#mou__jieyin-price:" .. player.id .. "::".. tostring(x))
        if #cards > 0 then
          room:moveCards({
            ids = cards,
            from = mark,
            to = player.id,
            toArea = Player.Hand,
            moveReason = fk.ReasonGive,
            proposer = mark,
            skillName = self.name,
            moveVisible = false
          })
          room:changeShield(to, 1)
          return false
        else
          local mark2 = type(player:getMark("mou__jieyin_break")) == "table" and player:getMark("mou__jieyin_break") or {}
          if not table.contains(mark2, mark) then
            table.insert(mark2, mark)
            room:setPlayerMark(player, "mou__jieyin_break", mark2)
            local targets = {}
            for _, p in ipairs(room.alive_players) do
              if p ~= player and p ~= to then
                table.insert(targets, p.id)
              end
            end
            if #targets > 0 then
              local tos = room:askForChoosePlayers(player, targets, 1, 1, "#mou__jieyin-transfer::" .. mark, self.name, true)
              if #tos > 0 then
                room:setPlayerMark(player, "mou__jieyin_target", tos[1])
                if table.every(room.alive_players, function (p)
                  return p:getMark("mou__jieyin_target") ~= mark
                end) then
                  room:setPlayerMark(to, "@@mou__jieyin", 0)
                end
                room:setPlayerMark(room:getPlayerById(tos[1]), "@@mou__jieyin", 1)
                return false
              end
            end
          end
        end
      end
    end
    player:broadcastSkillInvoke(self.name, 2)
    room:updateQuestSkillState(player, self.name, true)
    local mark = player:getMark("mou__jieyin_target")
    room:setPlayerMark(player, "mou__jieyin_target", 0)
    local to = room:getPlayerById(mark)
    if to:getMark("@@mou__jieyin") > 0 and table.every(room.alive_players, function (p)
      return p:getMark("mou__jieyin_target") ~= mark
    end) then
      room:setPlayerMark(to, "@@mou__jieyin", 0)
    end
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:changeKingdom(player, "wu", true)
    local dowry = player:getPile("mou__liangzhu_dowry")
    if #dowry > 0 then
      room:moveCards({
        ids = dowry,
        from = player.id,
        to = player.id,
        toArea = Player.Hand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
        moveVisible = true
      })
    end
    room:changeMaxHp(player, -1)
  end,

  refresh_events = {fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("mou__jieyin_target") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("mou__jieyin_target")
    room:setPlayerMark(player, "mou__jieyin_target", 0)
    local to = room:getPlayerById(mark)
    if to:getMark("@@mou__jieyin") > 0 and table.every(room.alive_players, function (p)
      return p:getMark("mou__jieyin_target") ~= mark
    end) then
      room:setPlayerMark(to, "@@mou__jieyin", 0)
    end
  end,
}

local mou__liangzhu = fk.CreateActiveSkill{
  name = "mou__liangzhu",
  anim_type = "control",
  prompt = "#mou__liangzhu-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and #Fk:currentRoom():getPlayerById(to_select):getCardIds(Player.Equip) > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if target.dead or player.dead or #target:getCardIds(Player.Equip) == 0 then return end
    local id = room:askForCardChosen(player, target, "e", self.name)
    player:addToPile("mou__liangzhu_dowry", id, true, self.name)
    local mark = player:getMark("mou__jieyin_target")
    if mark ~= 0 then
      local to = room:getPlayerById(mark)
      if to.dead then return false end
      local choices = {"draw2"}
      if to:isWounded() then
        table.insert(choices, "recover")
      end
      local choice = room:askForChoice(to, choices, self.name, "#mou__liangzhu-choice", false, {"draw2", "recover"})
      if choice == "draw2" then
        room:drawCards(to, 2, self.name)
      else
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
}
local mou__xiaoji = fk.CreateTriggerSkill{
  name = "mou__xiaoji",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local i = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            i = i + 1
          end
        end
      end
    end
    self.cancel_cost = false
    for _ = 1, i do
      if self.cancel_cost or not player:hasSkill(self) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:drawCards(player, 2, self.name)
    if player.dead then return false end
    local targets = table.map(table.filter(room.alive_players, function (p)
      return #p:getCardIds("ej") > 0
    end), Util.IdMapper)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#mou__xiaoji-discard", self.name, true)
    if #tos == 0 then return false end
    local to = room:getPlayerById(tos[1])
    local card = room:askForCardChosen(player, to, "ej", self.name)
    room:throwCard({card}, self.name, to, player)
  end,
}
mou__liangzhu:addAttachedKingdom("shu")
mou__xiaoji:addAttachedKingdom("wu")
mousunshangxiang:addSkill(mou__jieyin)
mousunshangxiang:addSkill(mou__liangzhu)
mousunshangxiang:addSkill(mou__xiaoji)

Fk:loadTranslationTable{
  ["mou__sunshangxiang"] = "谋孙尚香",
  ["mou__jieyin"] = "结姻",
  [":mou__jieyin"] = "游戏开始时，你选择一名其他角色令其获得“助”。"..
  "出牌阶段开始时，有“助”的角色须选择一项：1. 若其有手牌，交给你两张手牌（若其手牌不足两张则交给你所有手牌），然后其获得一点“护甲”；"..
  "2. 令你移动或移除助标记（若其不是第一次获得“助”标记，则你只能移除“助”标记）。<br>\
  <strong>失败</strong>：当“助”标记被移除时，你回复1点体力并获得你武将牌上所有“妆”牌，你将势力修改为“吴”，减1点体力上限。",
  ["mou__liangzhu"] = "良助",
  [":mou__liangzhu"] = "蜀势力技，出牌阶段限一次，你可以将其他角色装备区一张牌置于你的武将牌上，称为“妆”，然后有“助”的角色回复1点体力或摸两张牌。",
  ["mou__xiaoji"] = "枭姬",
  [":mou__xiaoji"] = "吴势力技，当你失去装备区里的一张牌后，你摸两张牌，然后你可以弃置场上的一张牌。",

  ["#mou__jieyin-choose"] = "结姻：选择一名角色，令其获得“助”标记",
  ["#mou__jieyin-price"] = "结姻：选择%arg张手牌交给%src，或点取消令其移动“助”标记",
  ["#mou__jieyin-transfer"] = "结姻：将%dest的“助”标记移动给一名角色，或点取消移除“助”标记",
  ["@@mou__jieyin"] = "助",
  ["#mou__liangzhu-active"] = "发动良助，选择一名角色，将其装备区里的一张牌作为“妆”",
  ["mou__liangzhu_dowry"] = "妆",
  ["#mou__liangzhu-choice"] = "良助：选择回复1点体力或者摸2张牌",
  ["#mou__xiaoji-discard"] = "枭姬：选择一名角色，弃置其装备区或判定区里的一张牌",

  ["$mou__jieyin1"] = "君若不负吾心，妾自随君千里。",
  ["$mou__jieyin2"] = "夫妻之情既断，何必再问归期！",
  ["$mou__liangzhu1"] = "助君得胜战，跃马提缨枪！",
  ["$mou__liangzhu2"] = "平贼成君业，何惜上沙场！",
  ["$mou__xiaoji1"] = "吾之所通，何止十八般兵刃！",
  ["$mou__xiaoji2"] = "既如此，就让尔等见识一番！",
  ["~mou__sunshangxiang"] = "此去一别，竟无再见之日……",
}

local mou__xueyi = fk.CreateTriggerSkill{
  name = "mou__xueyi$",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
     local room = player.room
     local to = room:getPlayerById(data.to)
     return target == player and player:hasSkill(self) and to.kingdom == "qun" and to ~= player
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local mou__xueyi_Max = fk.CreateMaxCardsSkill{
  name = "#mou__xueyi_Max",
  correct_func = function(self, player)
    if player:hasSkill(self) then
      local hmax = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p ~= player and p.kingdom == "qun" then 
          hmax = hmax + 1
        end
      end
      return hmax *2
    else
      return 0
    end
  end,
}
local mou__luanji_Draw = fk.CreateTriggerSkill{
  name = "#mou__luanji_Draw",
  anim_type = "offensive",
  events = {fk.CardUseFinished,fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card.name == "jink" then
      return data.responseToEvent and data.responseToEvent.from == player.id and data.responseToEvent.card.name =="archery_attack"
    end 
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
  }
local mou__luanji = fk.CreateViewAsSkill{
  name = "mou__luanji",
  anim_type = "offensive",
  pattern = "archery_attack",
  enabled_at_play = function(self, player)
        return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 1 then 
      return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip 
    elseif #selected == 2 then
      return false
    end

    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then
      return nil
    end

    local c = Fk:cloneCard("archery_attack")
    c:addSubcards(cards)
    return c
  end,
}
local mouyuanshao = General(extension, "mou__yuanshao", "qun", 4)
mou__xueyi:addRelatedSkill(mou__xueyi_Max)
mou__luanji:addRelatedSkill(mou__luanji_Draw)
mouyuanshao:addSkill(mou__luanji)
mouyuanshao:addSkill(mou__xueyi)
Fk:loadTranslationTable{
  ["mou__yuanshao"] = "谋袁绍",
  ["mou__luanji"] = "乱击",
  ["#mou__luanji_Draw"] = "乱击",
  [":mou__luanji"] = "①出牌阶段限一次，你可以将两张手牌当做【万箭齐发】使用。;②当有角色因响应你的【万箭齐发】打出【闪】时，你摸一张牌。",
  ["mou__xueyi"] = "血裔",
  [":mou__xueyi"] = "主公技，①锁定技，你的手牌上限+2X(X为场上现存其他群势力角色数)。;②当你使用牌指定其他群雄角色为目标时，你摸一张牌。",

  ["$mou__luanji1"] = "与我袁本初为敌，下场只有一个！",
  ["$mou__luanji2"] = "弓弩手，乱箭齐下，射杀此贼！",
  ["$mou__xueyi1"] = "四世三公之贵，岂是尔等寒门可及？",
  ["$mou__xueyi2"] = "吾袁门名冠天下，何须奉天子为傀？",
  ["~mou__yuanshao"] = "我不可能输给曹阿瞒，不可能！",
}
local mou__huaxiong = General:new(extension, "mou__huaxiong", "qun", 3, 4)
mou__huaxiong.shield = 1
local mou__yaowu = fk.CreateTriggerSkill{
  name = "mou__yaowu",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and (data.card.color ~= Card.Red or data.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if data.card.color ~= Card.Red then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    else
      room:notifySkillInvoked(player, self.name, "negative")
      local from = data.from
      local choices = {"draw1"}
      if from:isWounded() then
        table.insert(choices, "recover")
      end
      if room:askForChoice(from, choices, self.name) == "recover" then
        room:recover({ who = from, num = 1, recoverBy = from, skillName = self.name })
      else
        from:drawCards(1, self.name)
      end
    end
  end,
}
mou__huaxiong:addSkill(mou__yaowu)
local mou__yangwei = fk.CreateActiveSkill{
  name = "mou__yangwei",
  anim_type = "drawcard",
  target_num = 0,
  card_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getMark("mou__yangwei_used") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:drawCards(2, self.name)
    room:setPlayerMark(player, "@@mou__yangwei-phase", 1)
    room:setPlayerMark(player, "mou__yangwei_used", 1)
  end,
}
local mou__yangwei_targetmod = fk.CreateTargetModSkill{
  name = "#mou__yangwei_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@@mou__yangwei-phase") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return 1
    end
  end,
  bypass_distances = function(self, player, skill)
    return player:getMark("@@mou__yangwei-phase") > 0 and skill.trueName == "slash_skill"
  end,
}
mou__yangwei:addRelatedSkill(mou__yangwei_targetmod)
local mou__yangwei_trigger = fk.CreateTriggerSkill{
  name = "#mou__yangwei_trigger",
  mute = true,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@@mou__yangwei-phase") > 0
    and data.card and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("mou__yangwei")
    room:notifySkillInvoked(player, "mou__yangwei", "offensive")
    room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
    data.extra_data = data.extra_data or {}
    data.extra_data.mou__yangweiNullified = data.extra_data.mou__yangweiNullified or {}
    data.extra_data.mou__yangweiNullified[tostring(data.to)] = (data.extra_data.mou__yangweiNullified[tostring(data.to)] or 0) + 1
  end,

  refresh_events = {fk.CardUseFinished, fk.TurnStart, fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return data.extra_data and data.extra_data.mou__yangweiNullified
    elseif event == fk.TurnStart then
      return player == target and player:getMark("mou__yangwei_used") > 0
    else
      return player == target and player.phase == Player.Finish and player:getMark("mou__yangwei_removed-turn") > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      for key, num in pairs(data.extra_data.mou__yangweiNullified) do
        local p = room:getPlayerById(tonumber(key))
        if p:getMark(fk.MarkArmorNullified) > 0 then
          room:removePlayerMark(p, fk.MarkArmorNullified, num)
        end
      end
      data.mou__yangweiNullified = nil
    elseif event == fk.TurnStart then
      room:setPlayerMark(player, "mou__yangwei_removed-turn", 1)
    else
      room:setPlayerMark(player, "mou__yangwei_used", 0)
    end
  end,
}
mou__yangwei:addRelatedSkill(mou__yangwei_trigger)
mou__huaxiong:addSkill(mou__yangwei)
Fk:loadTranslationTable{
  ["mou__huaxiong"] = "谋华雄",
  
  ["mou__yaowu"] = "耀武",
  [":mou__yaowu"] = "锁定技，当你受到【杀】造成的伤害时，若此【杀】：为红色，伤害来源选择回复1点体力或摸一张牌；不为红色，你摸一张牌。",

  ["mou__yangwei"] = "扬威",
  [":mou__yangwei"] = "出牌阶段限一次，你可以摸两张牌且本阶段获得“威”标记，然后此技能失效直到下个回合的结束阶段。<br><em>“威”标记效果：使用【杀】的次数上限+1、使用【杀】无距离限制且无视防具牌。</em>",
  ["@@mou__yangwei-phase"] = "威",
  ["#mou__yangwei_trigger"] = "扬威",

  ["$mou__yaowu1"] = "俞涉小儿，岂是我的对手！",
  ["$mou__yaowu2"] = "上将潘凤？哼！还不是死在我刀下！",
  ["$mou__yangwei1"] = "哈哈哈哈！现在谁不知我华雄？",
  ["$mou__yangwei2"] = "定要关外诸侯，知我威名！",
  ["~mou__huaxiong"] = "小小马弓手，竟然……啊……",
}

local menghuo = General(extension, "mou__menghuo", "shu", 4)

local mou__huoshou = fk.CreateTriggerSkill{
  name = "mou__huoshou",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect, fk.TargetSpecified, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PreCardEffect then
      return player.id == data.to and player:hasSkill(self) and data.card.trueName == "savage_assault"
    elseif event == fk.TargetSpecified then
      return target ~= player and data.firstTarget and player:hasSkill(self) and data.card.trueName == "savage_assault"
    else
      if player == target and player:hasSkill(self) and player.phase == Player.Play then
        local ids = player.room:getCardsFromPileByRule("savage_assault", 1, "discardPile")
        if #ids > 0 then
          self.cost_data = ids[1]
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.PreCardEffect then
      return true
    elseif event == fk.TargetSpecified then
      data.extra_data = data.extra_data or {}
      data.extra_data.mou__huoshou = player.id
    else
      player.room:obtainCard(player, self.cost_data, true, fk.ReasonPrey)
    end
  end,

  refresh_events = {fk.PreDamage, fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    if event == fk.PreDamage then
      if data.card and data.card.trueName == "savage_assault" then
        local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if e then
          local use = e.data[1]
          return use.extra_data and use.extra_data.mou__huoshou
        end
      end
    else
      return player == target and player.phase == Player.Play and data.card.trueName == "savage_assault"
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PreDamage then
      local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        data.from = room:getPlayerById(use.extra_data.mou__huoshou)
      end
    else
      room:setPlayerMark(player, "mou__huoshou-phase", 1)
    end
  end,
}
local mou__huoshou_prohibit = fk.CreateProhibitSkill{
  name = "#mou__huoshou_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("mou__huoshou-phase") > 0 and card.trueName == "savage_assault"
  end,
}
mou__huoshou:addRelatedSkill(mou__huoshou_prohibit)
menghuo:addSkill(mou__huoshou)
local mou__zaiqi = fk.CreateTriggerSkill{
  name = "mou__zaiqi",
  events = {fk.EventPhaseEnd, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return target == player and player:hasSkill(self) and player.phase == Player.Discard and player:getMark("skill_charge") > 0
    else
      return target == player and player:hasSkill(self) and player:getMark("mou__zaiqi-turn") == 0 and player:getMark("skill_charge") < player:getMark("skill_charge_max")
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      local x = player:getMark("skill_charge")
      local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, x, "#mou__zaiqi-choose:::"..x, self.name, true)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      local tos = self.cost_data
      U.skillCharged(player, -#tos)
      room:sortPlayersByAction(tos)
      for _, pid in ipairs(tos) do
        if player.dead then break end
        local p = room:getPlayerById(pid)
        if not p.dead then
          if not p:isNude() and #room:askForDiscard(p, 1, 1, true, self.name, true, ".", "#mou__zaiqi-discard:"..player.id) > 0 then
            if not player.dead and player:isWounded() then
              room:recover({ who = player, num = 1, recoverBy = player, skillName = self.name })
            end
          else
            player:drawCards(1, self.name)
          end
        end
      end
    else
      room:setPlayerMark(player, "mou__zaiqi-turn", 1)
      U.skillCharged(player, 1)
    end
  end,
  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return data == self and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      U.skillCharged(player, 3, 7)
    else
      U.skillCharged(player, -3, -7)
    end
  end,
}
menghuo:addSkill(mou__zaiqi)
Fk:loadTranslationTable{
  ["mou__menghuo"] = "谋孟获",
  ["mou__huoshou"] = "祸首",
  [":mou__huoshou"] = "锁定技，①【南蛮入侵】对你无效；"..
  "<br>②当其他角色使用【南蛮入侵】指定目标后，你代替其成为此牌造成的伤害的来源；"..
  "<br>③出牌阶段开始时，你随机获得弃牌堆中的一张【南蛮入侵】；"..
  "<br>④当你于出牌阶段使用【南蛮入侵】后，此阶段内你不能再使用【南蛮入侵】。",
  ["mou__zaiqi"] = "再起",
  [":mou__zaiqi"] = "蓄力技（3/7），"..
  "<br>①弃牌阶段结束时，你可以消耗任意“蓄力”值并选择等量的角色，令这些角色依次选择一项：1.令你摸一张牌；2.弃置一张牌，然后你回复1点体力。"..
  "<br>②每回合一次，当你造成伤害后，获得1点“蓄力”值。",
  ["#mou__zaiqi-choose"] = "再起：选择至多%arg名角色，这些角色须选择:1.弃牌且你回复体力；2.令你摸牌",
  ["#mou__zaiqi-discard"] = "再起：弃置一张牌且 %src 回复1点体力，点“取消”：令 %src 摸一张牌",

  ["$mou__huoshou1"] = "我才是南中之主！",
  ["$mou__huoshou2"] = "整个南中都要听我的！",
  ["$mou__zaiqi1"] = "且败且战，愈战愈勇！",
  ["$mou__zaiqi2"] = "若有来日，必将汝等拿下！",
  ["~mou__menghuo"] = "吾等谨遵丞相教诲，永不复叛……",
}

local jiangwei = General(extension, "mou__jiangwei", "shu", 4)
local mou__tiaoxin = fk.CreateActiveSkill{
  name = "mou__tiaoxin",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getMark("skill_charge") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id and #selected < Self:getMark("skill_charge")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    room:addPlayerMark(player, "mou__zhiji_count", #effect.tos)
    U.skillCharged(player, -#effect.tos)
    for _, pid in ipairs(effect.tos) do
      if player.dead then break end
      local target = room:getPlayerById(pid)
      local use = room:askForUseCard(target, "slash", "slash", "#mou__tiaoxin-slash:"..player.id, true,
       {exclusive_targets = {player.id} , bypass_distances = true})
      if use then
        room:useCard(use)
      elseif not target:isNude() then
        local cards = room:askForCard(target, 1, 1, true, self.name, false, ".", "#mou__tiaoxin-give:"..player.id)
        if #cards > 0 then
          room:obtainCard(player, cards[1], false, fk.ReasonGive)
        end
      end
    end
  end
}
local mou__tiaoxin_trigger = fk.CreateTriggerSkill{
  name = "#mou__tiaoxin_trigger",
  mute = true,
  main_skill = mou__tiaoxin,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase == Player.Discard 
    and player:getMark("skill_charge") < player:getMark("skill_charge_max") then
      local n = 0
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              n = n + 1
            end
          end
        end
      end
      if n > 0 then
        self.cost_data = n
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.skillCharged(player, self.cost_data)
  end,
  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return data == self and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      U.skillCharged(player, 4, 4)
    else
      U.skillCharged(player, -4, -4)
    end
  end,
}
mou__tiaoxin:addRelatedSkill(mou__tiaoxin_trigger)
jiangwei:addSkill(mou__tiaoxin)
local mou__zhiji = fk.CreateTriggerSkill{
  name = "mou__zhiji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("mou__zhiji_count") > 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 999, "#mou__zhiji-choose", self.name, true)
    for _, pid in ipairs(tos) do
      local p = room:getPlayerById(pid)
      local mark = U.getMark(p, "@@mou__zhiji")
      table.insertIfNeed(mark, player.id)
      room:setPlayerMark(p, "@@mou__zhiji", mark)
    end
  end,
  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      local mark = U.getMark(p, "@@mou__zhiji")
      if table.contains(mark, player.id) then
        table.removeOne(mark, player.id)
        room:setPlayerMark(p, "@@mou__zhiji", #mark > 0 and mark or 0)
      end
    end
  end,
}
local mou__zhiji_prohibit = fk.CreateProhibitSkill{
  name = "#mou__zhiji_prohibit",
  is_prohibited = function(self, from, to)
    local mark = U.getMark(from, "@@mou__zhiji")
    return #mark > 0 and from ~= to and not table.contains(mark, to.id)
  end,
}
mou__zhiji:addRelatedSkill(mou__zhiji_prohibit)
jiangwei:addSkill(mou__zhiji)
Fk:loadTranslationTable{
  ["mou__jiangwei"] = "谋姜维",
  ["mou__tiaoxin"] = "挑衅",
  [":mou__tiaoxin"] = "蓄力技（4/4），"..
  "<br>①出牌阶段限一次，你可以消耗任意“蓄力”值并选择等量的其他角色，令这些角色依次选择一项：1.对你使用一张无距离限制的【杀】；2.交给你一张牌。"..
  "<br>②当你于弃牌阶段弃置牌后，你的“蓄力”值+X（X为你此次弃置的牌数）。",
  ["mou__zhiji"] = "志继",
  [":mou__zhiji"] = "觉醒技，准备阶段，若你因发动〖挑衅〗累计消耗的“蓄力”值大于3，你减1点体力上限，令任意名角色获得“北伐”标记直到你的下回合开始或死亡；拥有“北伐”标记的角色使用牌只能指定你或其为目标。",
  ["#mou__tiaoxin-slash"] = "挑衅：你须对 %src 使用【杀】，否则须交给 %src 一张牌",
  ["#mou__tiaoxin-give"] = "挑衅：请交给 %src 一张牌",
  ["#mou__zhiji-choose"] = "志继：令任意名角色获得“北伐”标记",
  ["@@mou__zhiji"] = "北伐",

  ["$mou__tiaoxin1"] = "汝等小儿，还不快跨马来战！",
  ["$mou__tiaoxin2"] = "哼！既匹夫不战，不如归耕陇亩！",
  ["$mou__zhiji1"] = "丞相之志，维岂敢忘之！",
  ["$mou__zhiji2"] = "北定中原终有日！",
  ["~mou__jiangwei"] = "市井鱼龙易一统，护国麒麟难擎天……",
}



return extension