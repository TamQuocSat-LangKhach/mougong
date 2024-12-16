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
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
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
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonGive,
            proposer = mark,
            skillName = self.name,
            moveVisible = false
          })
          room:changeShield(to, 1)
          return false
        else
          local mark2 = player:getTableMark("mou__jieyin_break")
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
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
        moveVisible = true
      })
    end
    room:changeMaxHp(player, -1)
    room:invalidateSkill(player, self.name)
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
  ["#mou__sunshangxiang"] = "骄豪明俏",
  ["illustrator:mou__sunshangxiang"] = "暗金",
  ["mou__jieyin"] = "结姻",
  [":mou__jieyin"] = "使命技，游戏开始时，你选择一名其他角色令其获得“助”。"..
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

local mou__luanji = fk.CreateViewAsSkill{
  name = "mou__luanji",
  anim_type = "offensive",
  pattern = "archery_attack",
  prompt = "#mou__luanji-viewas",
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards == 2 then
      local archery_attack = Fk:cloneCard("archery_attack")
      archery_attack:addSubcards(cards)
      return archery_attack
    end
  end,
}
local mou__luanji_trigger = fk.CreateTriggerSkill{
  name = "#mou__luanji_trigger",
  anim_type = "drawcard",
  --main_skill = mou__luanji,
  events = {fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mou__luanji) and player:usedSkillTimes(self.name) < 3 and data.card.name == "jink" then
      return data.responseToEvent and data.responseToEvent.from == player.id and
      data.responseToEvent.card.name =="archery_attack"
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(mou__luanji.name)
    player:drawCards(1, self.name)
  end,
}
local mou__xueyi = fk.CreateTriggerSkill{
  name = "mou__xueyi$",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player:usedSkillTimes(self.name) < 2 and
    data.to ~= player.id and player.room:getPlayerById(data.to).kingdom == "qun"
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local mou__xueyi_maxcards = fk.CreateMaxCardsSkill{
  name = "#mou__xueyi_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(mou__xueyi) then
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
mou__luanji:addRelatedSkill(mou__luanji_trigger)
mou__xueyi:addRelatedSkill(mou__xueyi_maxcards)
local mouyuanshao = General(extension, "mou__yuanshao", "qun", 4)
mouyuanshao:addSkill(mou__luanji)
mouyuanshao:addSkill(mou__xueyi)
Fk:loadTranslationTable{
  ["mou__yuanshao"] = "谋袁绍",
  ["#mou__yuanshao"] = "高贵的名门",
  ["mou__luanji"] = "乱击",
  [":mou__luanji"] = "出牌阶段限一次，你可以将两张手牌当【万箭齐发】使用；"..
  "当其他角色打出【闪】响应你使用的【万箭齐发】时，你摸一张牌（每回合你以此法至多获得三张牌）。",
  ["mou__xueyi"] = "血裔",
  [":mou__xueyi"] = "主公技，锁定技，你的手牌上限+2X（X为其他群势力角色数）；"..
  "当你使用牌指定其他群势力角色为目标后，你摸一张牌（每回合你以此法至多获得两张牌）。",

  ["#mou__luanji-viewas"] = "发动乱击，选择两手牌当【万箭齐发】使用",
  ["#mou__luanji_trigger"] = "乱击",

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
    room:invalidateSkill(player, self.name)
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
      room:validateSkill(player, "mou__yangwei")
    end
  end,
}
mou__yangwei:addRelatedSkill(mou__yangwei_trigger)
mou__huaxiong:addSkill(mou__yangwei)
Fk:loadTranslationTable{
  ["mou__huaxiong"] = "谋华雄",
  ["#mou__huaxiong"] = "跋扈雄狮",

  ["mou__yaowu"] = "耀武",
  [":mou__yaowu"] = "锁定技，当你受到【杀】造成的伤害时，若此【杀】：为红色，伤害来源选择回复1点体力或摸一张牌；不为红色，你摸一张牌。",
  ["mou__yangwei"] = "扬威",
  [":mou__yangwei"] = "出牌阶段限一次，你可以摸两张牌且本阶段获得“威”标记，然后此技能失效直到下个回合的结束阶段。<br>"..
  "<em>“威”标记效果：使用【杀】的次数上限+1、使用【杀】无距离限制且无视防具牌。</em>",
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
  events = {fk.PreCardEffect, fk.TargetSpecified, fk.EventPhaseStart, fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PreCardEffect then
      return player.id == data.to and player:hasSkill(self) and data.card.trueName == "savage_assault"
    elseif event == fk.TargetSpecified then
      return target ~= player and data.firstTarget and player:hasSkill(self) and data.card.trueName == "savage_assault"
    elseif player == target and player:hasSkill(self) and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        local ids = player.room:getCardsFromPileByRule("savage_assault", 1, "discardPile")
        if #ids > 0 then
          self.cost_data = ids[1]
          return true
        end
      else
        return data.card.name == "savage_assault"
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.PreCardEffect then
      return true
    elseif event == fk.TargetSpecified then
      data.extra_data = data.extra_data or {}
      data.extra_data.mou__huoshou = player.id
    elseif event == fk.EventPhaseStart then
      player.room:obtainCard(player, self.cost_data, true, fk.ReasonPrey)
    else
      player.room:setPlayerMark(player, "mou__huoshou-phase", 1)
    end
  end,

  refresh_events = {fk.PreDamage},
  can_refresh = function(self, event, target, player, data)
    if data.card and data.card.trueName == "savage_assault" then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.mou__huoshou
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      data.from = room:getPlayerById(use.extra_data.mou__huoshou)
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
        room:sortPlayersByAction(tos)
        self.cost_data = {tos = tos}
        return true
      end
    else
      self.cost_data = nil
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      local tos = table.map(self.cost_data.tos, Util.Id2PlayerMapper)
      U.skillCharged(player, -#tos)
      for _, p in ipairs(tos) do
        if player.dead then break end
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
  ["#mou__menghuo"] = "南蛮王",
  ["illustrator:mou__menghuo"] = "刘小狼Syaoran",
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
jiangwei.shield = 1
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
      local mark = p:getTableMark("@@mou__zhiji")
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
      local mark = p:getTableMark("@@mou__zhiji")
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
    local mark = from:getTableMark("@@mou__zhiji")
    return #mark > 0 and from ~= to and not table.contains(mark, to.id)
  end,
}
mou__zhiji:addRelatedSkill(mou__zhiji_prohibit)
jiangwei:addSkill(mou__zhiji)
Fk:loadTranslationTable{
  ["mou__jiangwei"] = "谋姜维",
  ["#mou__jiangwei"] = "见危授命",
  ["cv:mou__jiangwei"] = "杨超然",
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

local guanyu = General(extension, "mou__guanyu", "shu", 4)
Fk:loadTranslationTable{
  ["mou__guanyu"] = "谋关羽",
  ["#mou__guanyu"] = "关圣帝君",
  ["~mou__guanyu"] = "大哥，翼德，来生再于桃园，论豪情壮志……",
}
local mouWuSheng = fk.CreateViewAsSkill{
  name = "mou__wusheng",
  pattern = "slash",
  card_num = 1,
  prompt = "#mou__wusheng",
  card_filter = function(self, to_select, selected)
    if #selected == 1 or not table.contains(Self:getHandlyIds(true), to_select) then return false end
    local c = Fk:cloneCard("slash")
    return (Fk.currentResponsePattern == nil and Self:canUse(c)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  interaction = function(self)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if
        not table.contains(allCardNames, card.name) and
        card.trueName == "slash" and
        (
          (Fk.currentResponsePattern == nil and Self:canUse(card)) or
          (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))
        ) and
        not Self:prohibitUse(card) then
        table.insert(allCardNames, card.name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  view_as = function(self, cards)
    local choice = self.interaction.data
    if not choice or #cards ~= 1 then return end
    local c = Fk:cloneCard(choice)
    c:addSubcards(cards)
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:canUse(Fk:cloneCard("slash"))
  end,
  enabled_at_response = function(self, player)
    return Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("slash"))
  end,
}
local mouWuShengTrigger = fk.CreateTriggerSkill{
  name = "#mou__wusheng_trigger",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    local room = player.room

    return
      target == player and
      player:hasSkill("mou__wusheng") and
      player.phase == Player.Play and
      table.find(room:getOtherPlayers(player), function(p)
        return p.role ~= "lord" or not p.role_shown or table.contains({"m_1v2_mode", "brawl_mode"}, room.settings.gameMode)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return p.role ~= "lord" or not p.role_shown or table.contains({"m_1v2_mode", "brawl_mode"}, room.settings.gameMode)
    end)

    if #targets then
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#mou__wusheng-choose", self.name)
      if #tos > 0 then
        self.cost_data = {tos = tos}
        player:broadcastSkillInvoke("mou__wusheng")
        return true
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(room:getPlayerById(self.cost_data.tos[1]), "@mou__wusheng-phase", "")
      room:setPlayerMark(player, "mou__wusheng_from-phase", 1)
    end
  end,
}
local mouWuShengTargetMod = fk.CreateTargetModSkill{
  name = "#mou__wusheng_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.trueName == "slash" and player:getMark("mou__wusheng_from-phase") > 0 and to and to:getMark("@mou__wusheng-phase") ~= 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and card.trueName == "slash" and player:getMark("mou__wusheng_from-phase") > 0 and to and to:getMark("@mou__wusheng-phase") ~= 0
  end,
}
local mouWuShengBuff = fk.CreateTriggerSkill{
  name = "#mou__wusheng_buff",
  mute = true,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and player:getMark("mou__wusheng_from-phase") ~= 0
    and player.room:getPlayerById(data.to):getMark("@mou__wusheng-phase") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    if to:isAlive() then
      local usedTimes = to:getMark("@mou__wusheng-phase")
      room:setPlayerMark(to, "@mou__wusheng-phase", type(usedTimes) == "string" and 1 or usedTimes + 1)
    end

    local drawNum = room:isGameMode("role_mode") and 2 or 1
    player:drawCards(drawNum, "mou__wusheng")
  end,
}
local mouWuShengProhibit = fk.CreateProhibitSkill{
  name = "#mou__wusheng_prohibit",
  is_prohibited = function(self, from, to, card)
    local usedTimes = to:getMark("@mou__wusheng-phase")
    return
      from:getMark("mou__wusheng_from-phase") > 0 and
      card and
      card.trueName == "slash" and
      type(usedTimes) == "number" and
      usedTimes > 2
  end,
}
Fk:loadTranslationTable{
  ["mou__wusheng"] = "武圣",
  [":mou__wusheng"] = "你可以将一张手牌当任意【杀】使用或打出；出牌阶段开始时，你可以选择一名不为主公的其他角色，此阶段你拥有以下效果：" ..
  "你对其使用【杀】无距离和次数限制；当你使用【杀】指定其为目标后，你摸一张牌（若为身份模式则改为摸两张牌）；" ..
  "当你对其使用三张【杀】后，本阶段不可再使用【杀】指定其为目标。",
  ["#mou__wusheng_trigger"] = "武圣",
  ["#mou__wusheng"] = "武圣：你可以将一张手牌当任意【杀】使用或打出",
  ["@mou__wusheng-phase"] = "被武圣",
  ["#mou__wusheng-choose"] = "武圣：你可选择一名非主公角色，此阶段可对其出三张【杀】且对其用【杀】摸一张牌",

  ["$mou__wusheng1"] = "千军斩将而回，于某又有何难？",
  ["$mou__wusheng2"] = "对敌岂遵一招一式！",
  ["$mou__wusheng3"] = "关某既出，敌将定皆披靡。",
}

mouWuSheng:addRelatedSkill(mouWuShengTrigger)
mouWuSheng:addRelatedSkill(mouWuShengTargetMod)
mouWuSheng:addRelatedSkill(mouWuShengBuff)
mouWuSheng:addRelatedSkill(mouWuShengProhibit)
guanyu:addSkill(mouWuSheng)

Fk:addQmlMark{
  name = "mou__yijue",
  qml_path = function(name, value, p)
    return "packages/mougong/qml/YiJueBox"
  end,
  how_to_show = function(name, value, p)
    if type(value) == "table" then
      return tostring(#value)
    end
    return " "
  end,
}

local mouYiJue = fk.CreateTriggerSkill{
  name = "mou__yijue",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return
      data.from == player and
      player:hasSkill(self) and
      player.phase ~= Player.NotActive and
      player ~= data.to and
      data.to:isAlive() and
      data.damage >= math.max(0, data.to.hp) + data.to.shield and
      not table.contains(player.tag["mou__yijue_targets"] or {}, data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local yijueTargets = player.tag["mou__yijue_targets"] or {}
    table.insertIfNeed(yijueTargets, data.to.id)
    player.tag["mou__yijue_targets"] = yijueTargets

    local room = player.room
    room:setPlayerMark(
      player,
      "@[mou__yijue]",
      table.map(yijueTargets, function(id) return room:getPlayerById(id).seat end)
    )
    room:setPlayerMark(data.to, "mou__yijue-turn", player.id)

    return true
  end,
}
local mouYiJueCancel = fk.CreateTriggerSkill{
  name = "#mou__yijue_cancel",
  mute = true,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.room:getPlayerById(data.to):getMark("mou__yijue-turn") == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    AimGroup:cancelTarget(data, data.to)
    return true
  end,
}
Fk:loadTranslationTable{
  ["mou__yijue"] = "义绝",
  [":mou__yijue"] = "锁定技，每名角色限一次，当其他角色于你的回合内对受到你造成的伤害时，若伤害值不小于其体力值和护甲之和，" ..
  "则防止此伤害，且直到本回合结束，当你使用牌指定其为目标时，取消之。",
  ["@[mou__yijue]"] = "义绝",

  ["$mou__yijue1"] = "承君之恩，今日尽报。",
  ["$mou__yijue2"] = "下次沙场相见，关某定不留情。",
}

mouYiJue:addRelatedSkill(mouYiJueCancel)
guanyu:addSkill(mouYiJue)


local gaoshun = General(extension, "mou__gaoshun", "qun", 4)
Fk:loadTranslationTable{
  ["mou__gaoshun"] = "谋高顺",
  ["#mou__gaoshun"] = "攻无不克",
  ["~mou__gaoshun"] = "宁为断头鬼，不当受降虏……",
}

local xianzhen = fk.CreateActiveSkill{
  name = "mou__xianzhen",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return
      #selected == 0 and
      to_select ~= Self.id and
      not (
        Fk:currentRoom():isGameMode("role_mode") and
        Fk:currentRoom():getPlayerById(to_select).hp >= Self.hp
      )
  end,
  on_use = function(self, room, effect)
    room:setPlayerMark(room:getPlayerById(effect.tos[1]), "@@mou__xianzhen-phase", effect.from)
  end
}
local xianzhenDistance = fk.CreateTargetModSkill{
  name = "#mou__xianzhen_distance",
  bypass_distances = function (self, player, skill, card, to)
    return to:getMark("@@mou__xianzhen-phase") == player.id
  end
}
local xianzhenPindian = fk.CreateTriggerSkill{
  name = "#mou__xianzhen_pindian",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and data.card.trueName == "slash") then
      return false
    end

    local to = player.room:getPlayerById(data.to)
    return to:getMark("@@mou__xianzhen-phase") == player.id and player:canPindian(to)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mou__xianzhen-pindian::" .. data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local pindian = player:pindian({ to }, self.name)

    if pindian.results[to.id].winner == player then
      if player:getMark("mou__xianzhen_damaged-turn") < 1 then
        room:addPlayerMark(player, "mou__xianzhen_damaged-turn")

        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = xianzhen.name,
        }
      end

      if not data.extraUse then
        data.extraUse = true
        player:addCardUseHistory(data.card.trueName, -1)
      end

      local cardEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not cardEvent then return false end
      cardEvent.mouxianzhenArmor = true
      for _, p in ipairs(room.alive_players) do
        room:addPlayerMark(p, fk.MarkArmorNullified)
      end

      local pindianCard = pindian.results[to.id].toCard
      if player:isAlive() and pindianCard.trueName == "slash" and room:getCardArea(pindianCard) == Card.DiscardPile then
        room:obtainCard(player, pindianCard, true, fk.ReasonPrey, player.id)
      end
    end
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if player ~= target then return false end
    local cardEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    return cardEvent and cardEvent.mouxianzhenArmor
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:removePlayerMark(p, fk.MarkArmorNullified)
    end
  end,
}
Fk:loadTranslationTable{
  ["mou__xianzhen"] = "陷阵",
  [":mou__xianzhen"] = "出牌阶段限一次，你可以选择一名其他角色（若为身份模式，则改为一名体力值小于你的其他角色）。" ..
  "本阶段内你对其使用牌无距离限制，且当你使用【杀】指定其为目标后，你可以与其拼点。若你赢，则你对其造成1点伤害（每回合限一次），" ..
  "然后此【杀】无视防具、不计入次数；若其拼点牌为【杀】，则你获得之。",
  ["#mou__xianzhen_pindian"] = "陷阵",
  ["@@mou__xianzhen-phase"] = "被陷阵",
  ["#mou__xianzhen-pindian"] = "陷阵：你可与 %dest 拼点，若你赢则对其造成1点伤害（限一次）且此杀无视防具不计次数",

  ["$mou__xianzhen1"] = "陷阵营中，皆是以一敌百之士！",
  ["$mou__xianzhen2"] = "军令既出，使命必完！",
}

xianzhen:addRelatedSkill(xianzhenDistance)
xianzhen:addRelatedSkill(xianzhenPindian)
gaoshun:addSkill(xianzhen)

local jinjiu = fk.CreateFilterSkill{
  name = "mou__jinjiu",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(self) and card.name == "analeptic" and
    (table.contains(player.player_cards[Player.Hand], card.id) or isJudgeEvent)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
}
local jinjiuTrigger = fk.CreateTriggerSkill{
  name = "#mou__jinjiu_trigger",
  frequency = Skill.Compulsory,
  anim_type = "defensive",
  events = {fk.DamageInflicted, fk.PindianCardsDisplayed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      if not (target == player and player:hasSkill(jinjiu) and data.card and data.card.trueName == "slash") then
        return false
      end

      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if parentUseData then
        local drankBuff = parentUseData and (parentUseData.data[1].extra_data or {}).drankBuff or 0
        if drankBuff > 0 then
          self.cost_data = drankBuff
          return true
        end
      end
    else
      if not player:hasSkill(jinjiu) then
        return false
      end

      if data.from == player then
        for _, result in pairs(data.results) do
          if result.toCard.name == "analeptic" then
            return true
          end
        end
      elseif table.contains(data.tos, player) then
        return data.fromCard.name == "analeptic"
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      data.damage = 1
    else
      if data.from == player then
        for _, result in pairs(data.results) do
          if result.toCard.name == "analeptic" then
            result.toCard.number = 1
          end
        end
      else
        data.fromCard.number = 1
      end
    end
  end,
}
local jinjiuProhibit = fk.CreateProhibitSkill{
  name = "#mou__jinjiu_prohibit",
  frequency = Skill.Compulsory,
  prohibit_use = function(self, player, card)
    if card and card.name == "analeptic" then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p.phase ~= Player.NotActive and p:hasSkill(jinjiu) and p ~= player
      end)
    end
  end,
}
Fk:loadTranslationTable{
  ["mou__jinjiu"] = "禁酒",
  [":mou__jinjiu"] = "锁定技，你的【酒】均视为【杀】；当你受到【酒】【杀】造成的伤害时，此伤害改为1；你的回合内，其他角色不能使用【酒】；" ..
  "当与你拼点的角色拼点牌亮出后，若此牌为【酒】，则此牌的点数视为1。",
  ["#mou__jinjiu_trigger"] = "禁酒",
  ["#mou__jinjiu_prohibit"] = "禁酒",

  ["$mou__jinjiu1"] = "军规严戒，不容稍纵形骸！",
  ["$mou__jinjiu2"] = "黄汤乱军误事，不可不禁！",
}

jinjiu:addRelatedSkill(jinjiuTrigger)
jinjiu:addRelatedSkill(jinjiuProhibit)
gaoshun:addSkill(jinjiu)

local gongsunzan = General(extension, "mou__gongsunzan", "qun", 4)
Fk:loadTranslationTable{
  ["mou__gongsunzan"] = "谋公孙瓒",
  ["#mou__gongsunzan"] = "劲震幽土",
  ["~mou__gongsunzan"] = "称雄半生，岂可为他人俘虏，啊啊啊……",
}

local yicong = fk.CreateTriggerSkill{
  name = "mou__yicong",
  anim_type = "support",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getMark("skill_charge") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    for i = 1, player:getMark("skill_charge") do
      table.insert(choices, tostring(i))
    end
    table.insert(choices, "Cancel")
    local num = room:askForChoice(player, choices, self.name, "#mou__yicong-cost")
    if num == "Cancel" then
      return false
    end

    local choice = room:askForChoice(player, { "mou__yicong_offensive", "mou__yicong_defensive", "Cancel" }, self.name)
    if choice == "Cancel" then
      return false
    end

    self.cost_data = { tonumber(num), choice }
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = tonumber(self.cost_data[1])
    U.skillCharged(player, -num)

    local isDefensive = self.cost_data[2] == "mou__yicong_defensive"
    room:setPlayerMark(
      player,
      isDefensive and "@@mou__yicong_def-round" or "@@mou__yicong_off-round",
      1
    )

    num = math.min(4 - #player:getPile("mou__yicong_hu&"), num)
    if num < 1 then
      return false
    end

    local ids = room:getCardsFromPileByRule(isDefensive and "jink" or "slash", num)
    if #ids > 0 then
      player:addToPile("mou__yicong_hu&", ids, true, self.name)
    end
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return data == self and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      U.skillCharged(player, 2, 4)
    else
      U.skillCharged(player, -2, -4)
    end
  end,
}
local yicongDistance = fk.CreateDistanceSkill{
  name = "#mou__yicong_distance",
  correct_func = function(self, from, to)
    if from:getMark("@@mou__yicong_off-round") > 0 then
      return -1
    end
    if to:getMark("@@mou__yicong_def-round") > 0 then
      return 1
    end
  end,
}
Fk:loadTranslationTable{
  ["mou__yicong"] = "义从",
  [":mou__yicong"] = "蓄力技（2/4），每轮开始时，你可以消耗至少一点蓄力点并选择一项：1.令你本轮计算与其他角色的距离-1，" ..
  "并将牌堆中的X张【杀】置于你的武将牌上，称为“扈”；2.令其他角色本轮计算与你的距离+1，并将牌堆中X张【闪】置于你的武将牌上，" ..
  "称为“扈”（X为你以此法消耗的蓄力点数）。你至多拥有四张“扈”且你可将“扈”如手牌般使用或打出。",
  ["#mou__yicong-cost"] = "义从：你可消耗至少一点蓄力点发动“义从”",
  ["mou__yicong_offensive"] = "本轮你至其他角色距离-1",
  ["mou__yicong_defensive"] = "本轮其他角色至你距离+1",
  ["@@mou__yicong_def-round"] = "义从 +1",
  ["@@mou__yicong_off-round"] = "义从 -1",
  ["mou__yicong_hu&"] = "扈",

  ["$mou__yicong1"] = "尔等性命，皆在吾甲骑之间。",
  ["$mou__yicong2"] = "围以疲敌，不做无谓之战。",
}

yicong:addRelatedSkill(yicongDistance)
gongsunzan:addSkill(yicong)

local qiaomeng = fk.CreateTriggerSkill{
  name = "mou__qiaomeng",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card and
      data.card.trueName == "slash" and
      player:hasSkill(self) and
      player:hasSkill("mou__yicong", true)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = { "mou__qiaomeng_gain", "Cancel" }
    if data.to:isAlive() and not data.to:isAllNude() then
      table.insert(choices, 1, "mou__qiaomeng_discard::" .. data.to.id)
    end

    local choice = room:askForChoice(player, choices, self.name, "#mou__qiaomeng-choose")
    if choice == "Cancel" then
      return false
    end

    self.cost_data = choice
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data:startsWith("mou__qiaomeng_discard") then
      if data.to:isAlive() and not data.to:isAllNude() then
        local id = room:askForCardChosen(player, data.to, "hej", self.name)
        room:throwCard(id, self.name, data.to, player)
        player:drawCards(1, self.name)
      end
    else
      U.skillCharged(player, 3)
    end
  end,
}
Fk:loadTranslationTable{
  ["mou__qiaomeng"] = "趫猛",
  [":mou__qiaomeng"] = "当你使用【杀】对一名角色造成伤害后，你可以选择一项：1.弃置其区域内的一张牌，然后你摸一张牌；" ..
  "2.获得3点蓄力点。",
  ["mou__qiaomeng_discard"] = "弃置%dest区域内的一张牌且你摸一张牌",
  ["mou__qiaomeng_gain"] = "获得3点蓄力点",

  ["$mou__qiaomeng1"] = "观今天下，何有我义从之敌。",
  ["$mou__qiaomeng2"] = "众将征战所得，皆为汝等所有。",
}

gongsunzan:addSkill(qiaomeng)


local zhugejin = General(extension, "mou__zhugejin", "wu", 3)
Fk:loadTranslationTable{
  ["mou__zhugejin"] = "谋诸葛瑾",
  ["#mou__zhugejin"] = "才猷蕴借",
  ["~mou__zhugejin"] = "君臣相托，生死不渝……",
}

local huanshi = fk.CreateTriggerSkill{
  name = "mou__huanshi",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not (player:isNude() and player.hp < 1)
  end,
  on_cost = function(self, event, target, player, data)
    -- 实测锁定触发
    self.cost_data = {tos = {target.id}}
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ex = {}
    for i = 1, math.min(player.hp, #room.draw_pile) do
      table.insert(ex, room.draw_pile[i])
    end
    local cards = room:askForCard(player, 1, 1, false, self.name, true, ".",
    "#mou__huanshi-card::"..target.id..":"..data.reason..":"..data.card:toLogString(), ex)
    if #cards == 0 then return end
    local fromPlace = room:getCardArea(cards[1])
    local oldCards = {data.card:getEffectiveId()}
    room:retrial(Fk:getCardById(cards[1]), player, data, self.name, fromPlace == Player.Hand)
    if fromPlace == Card.DrawPile then
      -- 实测交换牌堆牌并不是换到牌堆原位置(也不知道去哪了)，暂定置于牌堆顶吧
      room:moveCards{
        ids = oldCards,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
      }
    end
  end,
}
zhugejin:addSkill(huanshi)

Fk:loadTranslationTable{
  ["mou__huanshi"] = "缓释",
  [":mou__huanshi"] = "当一名角色的判定牌生效前，你观看牌堆顶的X张牌（X为你的体力值），然后你可以用这些牌/手牌中的其中一张牌替换之",
  ["#mou__huanshi-card"] = "缓释：可以用手牌或牌堆顶牌替换 %dest 进行“%arg”判定的判定牌%arg2",
  ["$mou__huanshi1"] = "济危以仁，泽国生春。",
  ["$mou__huanshi2"] = "谏而不犯，正而不毅。",
}

local hongyuan = fk.CreateTriggerSkill{
  name = "mou__hongyuan",
  events = {fk.AfterCardsMove},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:getMark("skill_charge") == 0 then return false end
    local plist = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        if #move.moveInfo > 1 then
          table.insert(plist, player.id)
        end
      end
      if move.from and move.from ~= player.id and not player.room:getPlayerById(move.from).dead then
        if #table.filter(move.moveInfo, function (info)
          return info.fromArea == Player.Hand or info.fromArea == Player.Equip
        end) > 1 then
          table.insert(plist, move.from)
        end
      end
    end
    if #plist > 0 then
      self.cost_data = {tos = plist}
      return true
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local plist = table.simpleClone(self.cost_data.tos)
    player.room:sortPlayersByAction(plist)
    for _, pid in ipairs(plist) do
      if not player:hasSkill(self) or player:getMark("skill_charge") == 0 then break end
      local p = player.room:getPlayerById(pid)
      if not p.dead then
        self:doCost(event, p, player, data)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if target == player then
      local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 2, "#mou__hongyuan-choose", self.name, true)
      if #tos > 0 then
        room:sortPlayersByAction(tos)
        self.cost_data = {tos = tos}
        return true
      end
    elseif room:askForSkillInvoke(player, self.name, nil, "#mou__hongyuan-invoke:"..target.id) then
      self.cost_data = {tos = {target.id}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.skillCharged(player, -1)
    if target == player then
      for _, p in ipairs(table.map(self.cost_data.tos, Util.Id2PlayerMapper)) do
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    else
      target:drawCards(2, self.name)
    end
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return data == self and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      U.skillCharged(player, 1, 4)
    else
      U.skillCharged(player, -1, -4)
    end
  end,
}
zhugejin:addSkill(hongyuan)

Fk:loadTranslationTable{
  ["mou__hongyuan"] = "弘援",
  [":mou__hongyuan"] = "蓄力技（1/4），<br>①当你一次性获得至少两张牌时，你可以消耗1点“蓄力”点令至多两名角色各摸一张牌。"..
  "<br>②当一名其他角色一次性失去至少两张牌时，你可以消耗1点“蓄力”点令其摸两张牌。",
  ["#mou__hongyuan-choose"] = "弘援：你可以消耗1点“蓄力”点，令至多两名角色各摸一张牌",
  ["#mou__hongyuan-invoke"] = "弘援：你可以消耗1点“蓄力”点，令 %src 其摸两张牌",
  ["$mou__hongyuan1"] = "舍己以私，援君之危急！",
  ["$mou__hongyuan2"] = "身为萤火之光，亦当照于天下！",
}

local mingzhe = fk.CreateTriggerSkill{
  name = "mou__mingzhe",
  events = {fk.AfterCardsMove},
  anim_type = "support",
  frequency = Skill.Compulsory,
  times = function (self)
    return 3 - Self:usedSkillTimes(self.name, Player.HistoryRound)
  end,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase == Player.NotActive and player:usedSkillTimes(self.name, Player.HistoryRound) < 3 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Player.Hand or info.fromArea == Player.Equip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num, draw = 0, false
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Player.Hand or info.fromArea == Player.Equip then
            num = num + 1
            if Fk:getCardById(info.cardId).type ~= Card.TypeBasic then
              draw = true
            end
          end
        end
      end
    end
    if not draw then num = 0 end
    local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
    "#mou__mingzhe-choose:::"..num, self.name, false)
    local to = room:getPlayerById(tos[1])
    U.skillCharged(to, 1)
    if num > 0 then
      to:drawCards(num, self.name)
    end
  end,
}
zhugejin:addSkill(mingzhe)

Fk:loadTranslationTable{
  ["mou__mingzhe"] = "明哲",
  [":mou__mingzhe"] = "锁定技，每轮限三次。当你于回合外失去牌时，你选择一名角色，若其有“蓄力”技，令其获得1点“蓄力”点，若其中有非基本牌，其摸与你失去牌等量的牌",
  ["#mou__mingzhe-choose"] = "明哲：选择一名角色，令其获得1点“蓄力”，摸%arg张牌",
  ["$mou__mingzhe1"] = "事事不求成功，但求尽善尽全。",
  ["$mou__mingzhe2"] = "明可查冒进之失，哲以避险躁之性。",
}

local zhangliao = General(extension, "mou__zhangliao", "wei", 4)

local tuxi = fk.CreateTriggerSkill{
  name = "mou__tuxi",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  times = function (self)
    return 3 - Self:usedSkillTimes(self.name, Player.HistoryTurn)
  end,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) < 3 and player.phase ~= Player.NotActive then
      local ids = {}
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName ~= self.name then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
      ids = U.moveCardsHoldingAreaCheck(player.room, ids)
      if #ids > 0 then
        self.cost_data = ids
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local _,ret = player.room:askForUseActiveSkill(player, "mou__tuxi_active", "#mou__tuxi", true, {optional_cards = self.cost_data})
    if ret then
      player.room:sortPlayersByAction(ret.targets)
      self.cost_data = {cards = ret.cards, tos = ret.targets}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.map(self.cost_data.tos, Util.Id2PlayerMapper)
    room:moveCardTo(self.cost_data.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
    for _, to in ipairs(tos) do
      if player.dead then break end
      if not to:isKongcheng() then
        local cid = room:askForCardChosen(player, to, "h", self.name)
        room:obtainCard(player, cid, false, fk.ReasonPrey, player.id, self.name)
      end
    end
  end,
}

local tuxi_active = fk.CreateActiveSkill{
  name = "mou__tuxi_active",
  min_card_num = 1,
  min_target_num = 1,
  card_filter = function(self, to_select, selected)
    return table.contains(self.optional_cards or {}, to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local to = Fk:currentRoom():getPlayerById(to_select)
    return #selected < #selected_cards and Self.id ~= to_select and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
}
Fk:addSkill(tuxi_active)

zhangliao:addSkill(tuxi)

local dengfeng = fk.CreateTriggerSkill{
  name = "mou__dengfeng",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Start
  end,
  on_cost = function (self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
    1, 1, "#mou__dengfeng-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local choices = {"mou__dengfeng_equip", "mou__dengfeng_slash", "mou__dengfeng_beishui"}
    local choice = choices[2]
    if #to:getCardIds("e") > 0 then
      choice = room:askForChoice(player, choices, self.name)
    end
    if choice == "mou__dengfeng_beishui" then
      room:loseHp(player, 1, self.name)
    end
    if choice ~= "mou__dengfeng_slash" and #to:getCardIds("e") > 0 then
      local cards = room:askForCardsChosen(player, to, 1, 2, "e", self.name)
      room:obtainCard(to, cards, true, fk.ReasonPrey, to.id, self.name)
    end
    if choice ~= "mou__dengfeng_equip" and not player.dead then
      local ids = room:getCardsFromPileByRule("slash")
      if #ids > 0 then
        room:obtainCard(player, ids, true, fk.ReasonJustMove, player.id, self.name)
      end
    end
  end,
}
zhangliao:addSkill(dengfeng)

Fk:loadTranslationTable{
  ["mou__zhangliao"] = "谋张辽",
  ["#mou__zhangliao"] = "古之召虎",

  ["mou__tuxi"] = "突袭",
  [":mou__tuxi"] = "你的回合内限三次，当你不因此技能获得牌后，你可以将其中任意张牌置入弃牌堆，然后你获得至多X名其他角色各一张手牌（X为你此次以此法置入弃牌堆的牌数）。",
  ["mou__tuxi_active"] = "突袭",
  ["#mou__tuxi"] = "突袭：你可以将获得的牌置入弃牌堆，获得至多等量其他角色各一张牌",

  ["mou__dengfeng"] = "登锋",
  [":mou__dengfeng"] = "准备阶段，你可以选择一名其他角色并选择一项：1.选择其装备区里至多两张牌，令其获得之；2.你从牌堆中获得一张【杀】。背水：失去1点体力。",
  ["#mou__dengfeng-choose"] = "登锋：选择一名其他角色，令其收回装备牌，或你摸一张【杀】",
  ["mou__dengfeng_equip"] = "选择其装备区里至多两张牌令其收回",
  ["mou__dengfeng_slash"] = "你从牌堆中获得一张【杀】",
  ["mou__dengfeng_beishui"] = "背水：失去1点体力。",

  ["$mou__tuxi1"] = "成败之机，在此一战，诸君何疑！",
  ["$mou__tuxi2"] = "及敌未合，折其盛势，以安众心！",
  ["$mou__dengfeng1"] = "擒权覆吴，今便得成所愿，众将且奋力一战！",
  ["$mou__dengfeng2"] = "甘、凌之流，何可阻我之攻势！",
  ["~mou__zhangliao"] = "陛下亲临问疾，臣诚惶诚恐……",
}

return extension