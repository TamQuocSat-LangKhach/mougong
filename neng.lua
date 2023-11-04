local extension = Package("mou_neng")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_neng"] = "谋攻篇-能包",
}

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
  ["$mou__yangwei2"] = "定要关外诸侯，知我威名!",
  ["~mou__huaxiong"] = "小小马弓手，竟然……啊……",
}
return extension