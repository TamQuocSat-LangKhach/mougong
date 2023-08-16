local extension = Package("mou_zhi")
extension.extensionName = "mougong"

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
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 4 
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and #selected_cards > 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      local card = Fk:cloneCard("indulgence")
      card:addSubcard(selected_cards[1])
      return target:hasDelayedTrick("indulgence") or (to_select ~= Self.id and not Self:isProhibited(target, card))
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if target:hasDelayedTrick("indulgence") then
      room:throwCard(effect.cards, self.name, player, player)
      for _, id in ipairs(target.player_cards[Player.Judge]) do
        local card = target:getVirualEquip(id)
        if not card then card = Fk:getCardById(id) end
        if card.name == "indulgence" then
          room:throwCard({id}, self.name, target, player)
        end
      end
    else
      room:useVirtualCard("indulgence", effect.cards, player, target, self.name)
    end
    player:drawCards(2, self.name)
    if not player:isNude() then
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
}
local mou__liuli = fk.CreateTriggerSkill{
  name = "mou__liuli",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    local ret = target == player and player:hasSkill(self.name) and
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
        if p ~= player and p.id ~= data.from and p:getMark("@liuli_dangxian") == 0 then
           table.insert(targets, p.id)
        end
      end
     local tar = room:askForChoosePlayers(player, targets, 1, 1, "#mou__liuli-choose", self.name, true)
      if #tar > 0 then
         room:removePlayerMark(player, "mou__liuli-turn", 1)
          for _, p in ipairs(room.alive_players) do
            if p:getMark("@liuli_dangxian") ~= 0 then
                room:removePlayerMark(p, "@liuli_dangxian", 1)
            end
          end
         room:addPlayerMark(room:getPlayerById(tar[1]), "@liuli_dangxian", 1)
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
    return target == player and player:getMark("@liuli_dangxian") ~=0 and data.to == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@liuli_dangxian", 1)
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
  ["mou__liuli"] = "流离",
  ["#mou__liuli_dangxian"] = "流离",
  [":mou__liuli"] = "每当你成为【杀】的目标时，你可以弃置一张牌并选择你攻击范围内为此【杀】合法目标（无距离限制）的一名角色：若如此做，该角色代替你成为此【杀】的目标。若你以此法弃置了<font color='red'>♥️</font>牌，则你可以令一名不为此【杀】使用者的其他角色获得“流离”标记，且移去场上所有其他的“流离”（每回合限一次）。有“流离”的角色回合开始时，其移去其“流离”并执行一个额外的出牌阶段。",
  ["#mou__liuli-target"] = "流离：你可以弃置一张牌，将【杀】的目标转移给一名其他角色。若你以此法弃置的牌花色是<font color='red'>♥️</font>，则你可以令一名除此杀使用者的其他角色获得“流离”标记",
  ["#mou__liuli-choose"] = "流离：你可以令一名除此【杀】使用者的其他角色获得“流离”标记并清除场上的其他流离标记。",
   ["@liuli_dangxian"] = "流离",

}

local caocao = General(extension, "mou__caocao", "wei", 4)
local mou__jianxiong = fk.CreateTriggerSkill{
  name = "mou__jianxiong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
     return target == player and player:hasSkill(self.name) and ((data.card and target.room:getCardArea(data.card) == Card.Processing) or 2 - player:getMark("@mou__jianxiong") > 0)
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
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
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
     return player:hasSkill(self.name) and target == player and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
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
  [":mou__jianxiong"] = "①游戏开始时，你可以获得至多两枚【治世】标记;②当你受到伤害后，你可以获得对你造成伤害的牌并摸2-X张牌，然后你可以移除1枚【治世】。（X为【治世】的数量且至多为2）。",
  ["mou__qingzheng"] = "清正",
  [":mou__qingzheng"] = "出牌阶段开始时，你可以选择一名有手牌的其他角色，你弃置3-X(X为你的【治世】标记数)种花色的所有手牌，然后观看其手牌并选择一种花色的牌，其弃置所有该花色的手牌。若如此做，你以此法弃置的牌＞其弃置的手牌，你对其造成一点伤害，然后若你拥有【奸雄】且【治世】标记＜2，你可以获得一枚【治世】。",
  ["mou__hujia"] = "护驾",
  [":mou__hujia"] = "主公技，每轮限一次，当你即将受到伤害时，你可以将此伤害转移给一名其他“魏”势力角色。",
  ["#mou__jianxiong-dismark"] = "奸雄:是否弃置一枚【治世】标记?。",
  ["#mou__jianxiong-choice"] = "奸雄:请选择要获得的【治世】标记数量。",
  ["#mou__qingzheng-addmark"] = "清正:是否获得一个【治世】标记?",
  ["#mou__qingzheng-choose"] = "清正:是否发动【清正】?选择一名有手牌的其他角色?",
  ["#mou__qingzheng-discard"] = "清正:请选择一种花色的所有牌弃置，总共%arg 次 现在是第%arg2 次",
  ["#mou__hujia-choose"] = "护驾:是否发动【护驾】，防止此次伤害?选择一名其他角色“魏”势力角色将此伤害转移给其?",
  ["@mou__jianxiong"] = "治世",
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
    if target == player and player:hasSkill(self.name) then
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
sunquan:addSkill(mou__zhiheng)
sunquan:addSkill(mou__tongye)
sunquan:addSkill("jiuyuan")
Fk:loadTranslationTable{
  ["mou__sunquan"] = "谋孙权",
  ["mou__zhiheng"] = "制衡",
  [":mou__zhiheng"] = "出牌阶段限一次，你可以弃置任意张牌并摸等量的牌。若你以此法弃置了所有的手牌，你多摸1+X张牌(X为你的“业”数)，然后你弃置一枚“业”。",
  ["mou__tongye"] = "统业",
  [":mou__tongye"] = "锁定技，结束阶段，你可以猜测场上的装备数量于你的下个准备阶段开始时有无变化。若你猜对，你获得一枚“业”，猜错，你弃置一枚“业”。",
    ["tongye1"] = "统业猜测:有变化",
    ["tongye2"] = "统业猜测:无变化",
    ["@tongye"] = "业",
    ["@@tongye1"] = "统业猜测:有变化",
    ["@@tongye2"] = "统业猜测:无变化",
  
}
local mouzhouyu = General(extension, "mou__zhouyu", "wu", 3)
local mou__yingzi = fk.CreateTriggerSkill{
  name = "mou__yingzi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
     return target == player and player:hasSkill(self.name) and (#player.player_cards[Player.Hand] > 1 or #player.player_cards[Player.Equip] > 0 or player.hp > 1)
  end,
  on_use = function(self, event, target, player, data)
     if player.hp > 1 then
       player.room:addPlayerMark(player, "mou__yingzi-turn", 1)
     end
     if #player.player_cards[Player.Hand] > 1 then
       player.room:addPlayerMark(player, "mou__yingzi-turn", 1)
     end
     if #player.player_cards[Player.Equip] > 0 then
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
  [":mou__fanjian"] = "出牌阶段，你可以选择一名其他角色和一张牌(每种花色每回合限一次)并声明一个花色，其须选择一项:①猜测此牌花色是否与你声明的花色相同;②翻面。;然后其正面向上获得此牌。若其选择猜测且猜测错误，其失去1点体力，否则其令你〖反间〗于本回合失效。",
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
return extension
