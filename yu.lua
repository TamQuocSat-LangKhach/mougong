local extension = Package("mou_yu")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_yu"] = "谋攻篇-虞包",
}
local mouhuanggai = General(extension, "mou__huanggai", "wu", 2, 4)
mouhuanggai.shield = 2
local mou__kurou = fk.CreateTriggerSkill{
  name = "mou__kurou",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
     local room = player.room
     local tar, card =room:askForChooseCardAndPlayers(
      player,
      table.map(room:getOtherPlayers(player, true), function(p) return p.id end), 1, 1, ".|.|.|hand", "#mou__kurou-give", self.name , true)
    if #tar > 0 and card then
      self.cost_data = tar[1]
      self.cost_data2 = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
     room:obtainCard(self.cost_data, self.cost_data2, false, fk.ReasonGive)
    if Fk:getCardById(self.cost_data2).trueName == "analeptic" or Fk:getCardById(self.cost_data2).trueName == "peach" then
      room:loseHp(player, 2, self.name)
    else
      room:loseHp(player, 1, self.name)  
    end
  end,
}
local mou__kurou_hujia = fk.CreateTriggerSkill{
  name = "#mou__kurou_hujia",
  frequency = Skill.Compulsory,
  events = {fk.HpLost},
  on_trigger = function(self, event, target, player, data)
    for i = 1, data.num do
      if player.shield >= 5 then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:changeShield(player, 2)
  end,
}
mou__kurou:addRelatedSkill(mou__kurou_hujia)
mouhuanggai:addSkill(mou__kurou)
local mou__zhaxiang = fk.CreateTriggerSkill{
  name = "mou__zhaxiang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getLostHp()
  end,
}

local mou__zhaxiang_trigger = fk.CreateTriggerSkill{
  name = "#mou__zhaxiang_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill("mou__zhaxiang") and data.card.type ~=Card.TypeEquip and player:getMark("mou__zhaxiang-phase") <= player:getLostHp()
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsive = true
  end,
  
  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill("mou__zhaxiang", true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "mou__zhaxiang-phase", 1)
  end,
}
local mou__zhaxiang_targetmod = fk.CreateTargetModSkill{
  name = "#mou__zhaxiang_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if card and player:hasSkill("mou__zhaxiang") and player.phase == Player.Play and player:getMark("mou__zhaxiang-phase") < player:getLostHp() then
      return 999
    end
    return 0
  end,
  distance_limit_func =  function(self, player, skill, card)
    if card and player:hasSkill("mou__zhaxiang") and player:getMark("mou__zhaxiang-phase") < player:getLostHp() and player.phase == Player.Play then
      return 999
    end
  end,
}
mou__zhaxiang:addRelatedSkill(mou__zhaxiang_targetmod)
mou__zhaxiang:addRelatedSkill(mou__zhaxiang_trigger)
mouhuanggai:addSkill(mou__zhaxiang)
Fk:loadTranslationTable{
  ["mou__huanggai"] = "谋黄盖",
  ["mou__kurou"] = "苦肉",
  ["#mou__kurou_hujia"] = "苦肉",
  [":mou__kurou"] = "①出牌阶段开始时，你可以将一张手牌交给一名其他角色，若如此做，你失去一点体力，若你交出的牌为【桃】或【酒】则改为两点。;②，当你失去一点体力值时，你获得两点护甲。",
  ["mou__zhaxiang"] = "诈降",
  [":mou__zhaxiang"] = "锁定技，①摸牌阶段，你的摸牌基数+X；②出牌阶段，你使用的前X张牌无距离和次数限制且无法响应。(X为你已损失的体力值)。",
  ["#mou__kurou-give"] = "苦肉：你可以将一张手牌交给一名其他角色，若如此做，你失去一点体力，若你交出的牌为【桃】或【酒】则改为两点",

  ["$mou__kurou1"] = "既不能破，不如依张子布之言，投降便罢！",
  ["$mou__kurou2"] = "周瑜小儿！破曹不得，便欺吾三世老臣乎？",
  ["$mou__zhaxiang1"] = "江东六郡之卒，怎敌丞相百万雄师！	",
  ["$mou__zhaxiang2"] = "闻丞相虚心纳士，盖愿率众归降！",
  ["~mou__huanggai"] = "哈哈哈哈，公瑾计成，老夫死也无憾了……",
}
local moucaoren = General(extension, "mou__caoren", "wei", 4)
moucaoren.shield = 1

local moujushouDraw = fk.CreateTriggerSkill{
  name = "#mou__jushou_draw",
  mute = true,
  events = { fk.TurnedOver },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.faceup
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("mou__jushou", 3)
    room:notifySkillInvoked(player, "mou__jushou", "drawcard")
    player:drawCards(player.shield, self.name)
  end,
}
local moujushouShibei = fk.CreateTriggerSkill{
  name = "#mou__jushou_shibei",
  mute = true,
  events = { fk.Damaged },
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self)) then
      return
    end
    return not player.faceup
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = { "turnover", "add1shield", "Cancel" }
    if player.shield >= 5 then table.removeOne(choices, "add1shield") end
    local choice = room:askForChoice(player, choices, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("mou__jushou", 2)
    room:notifySkillInvoked(player, "mou__jushou", "masochism")
    if self.cost_data == "turnover" then
      player:turnOver()
    else
      room:changeShield(player, 1)
    end
  end,
}
local moujushou = fk.CreateActiveSkill{
  name = "mou__jushou",
  mute = true,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and player.faceup
  end,
  target_num = 0,
  card_num = 0,
  card_filter = function() return false end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    from:broadcastSkillInvoke("mou__jushou", 1)
    room:notifySkillInvoked(from, "mou__jushou", "defensive")
    from:turnOver()
    local s = from.shield
    if s < 5 then
      local cards = room:askForDiscard(from, 1, math.min(2, 5 - s), true,
        self.name, true, nil, "#mou__jushou-discard")
      if #cards > 0 then
        room:changeShield(from, #cards)
      end
    end
  end,
}
moujushou:addRelatedSkill(moujushouDraw)
moujushou:addRelatedSkill(moujushouShibei)
moucaoren:addSkill(moujushou)
local moujiewei = fk.CreateActiveSkill{
  name = "mou__jiewei",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and player.shield > 0
  end,
  target_num = 1,
  card_num = 0,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and
      not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:changeShield(player, -1)
    local target = room:getPlayerById(effect.tos[1])

    local cids = target.player_cards[Player.Hand]
    room:fillAG(player, cids)

    local id = room:askForAG(player, cids, false, self.name)
    room:closeAG(player)

    if not id then return false end
    room:obtainCard(player, id, false)
  end,
}
moucaoren:addSkill(moujiewei)
Fk:loadTranslationTable{
  ["mou__caoren"] = "谋曹仁",
  ["mou__jushou"] = "据守",
  ["#mou__jushou_shibei"] = "据守",
  ["#mou__jushou_draw"] = "据守",
  [":mou__jushou"] = "①出牌阶段限一次，若你的武将牌正面朝上，你可以翻面，" ..
    "然后你弃置至多两张牌并获得等量的“护甲”。<br/>" ..
    "②当你受到伤害后，若你的武将牌背面朝上，你可以选择一项：" ..
    "1.翻面；2.获得1点“护甲”。<br/>" ..
    "③当你的武将牌从背面翻至正面时，你摸等同于你“护甲”值的牌。",
  ["#mou__jushou-discard"] = "据守：你现在可以弃至多两张牌并获得等量护甲",
  ["turnover"] = "翻面",
  ["add1shield"] = "获得1点护甲",
  ["mou__jiewei"] = "解围",
  [":mou__jiewei"] = "出牌阶段限一次，你可以失去1点“护甲”并选择一名其他" ..
    "角色，你观看其手牌并获得其中一张。",
  ["$mou__jushou1"] = "白马沉河共歃誓，怒涛没城亦不悔！",
  ["$mou__jushou2"] = "山水速疾来去易，襄樊镇固永难开！",
  ["$mou__jushou3"] = "汉水溢流断归路，守城之志穷且坚！",
  ["$mou__jiewei1"] = "同袍之谊，断不可弃之！",
  ["$mou__jiewei2"] = "贼虽势盛，若吾出马，亦可解之。",
  ["~mou__caoren"] = "吾身可殉，然襄樊之地万不可落于吴蜀之手……",
}

local mouhuangzhong = General(extension, "mou__huangzhong", "shu", 4)
local mouliegongFilter = fk.CreateFilterSkill{
  name = "#mou__liegong_filter",
  card_filter = function(self, card, player)
    return card.trueName == "slash" and
      card.name ~= "slash" and
      not player:getEquipment(Card.SubtypeWeapon) and
      player:hasSkill(self)
  end,
  view_as = function(self, card, player)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = "mou__liegong"
    return c
  end,
}
local mouliegongProhibit = fk.CreateProhibitSkill{
  name = "#mou__liegong_prohibit",
  prohibit_use = function(self, player, card)
    -- FIXME: 确保是因为【杀】而出闪，并且指明好事件id
    if Fk.currentResponsePattern ~= "jink" or card.name ~= "jink" or player:getMark("mou__liegong") == 0 then
      return false
    end
    if table.contains(player:getMark("mou__liegong"), card:getSuitString(true)) then
      return true
    end
  end,
}
local mouliegong = fk.CreateTriggerSkill{
  name = "mou__liegong",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      data.card.trueName == "slash" and
      #TargetGroup:getRealTargets(data.tos) == 1 and
      player:getMark("@mouliegongRecord") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local logic = room.logic
    local cardUseEvent = logic:getCurrentEvent().parent
    cardUseEvent.liegong_used = true

    -- 让他不能出闪
    local target = room:getPlayerById(data.to)
    local suits = player:getMark("@mouliegongRecord")
    room:setPlayerMark(target, self.name, suits)

    -- 展示牌堆顶的牌，计算加伤数量
    local cards = room:getNCards(#suits - 1)
    room:moveCardTo(cards, Card.DiscardPile) -- FIXME
    data.additionalDamage = (data.additionalDamage or 0) +
    #table.filter(cards, function(id)
      local c = Fk:getCardById(id)
      return table.contains(suits, c:getSuitString(true))
    end)
  end,

  refresh_events = {fk.TargetConfirmed, fk.CardUsing, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self)) then return end
    local room = player.room
    if event == fk.CardUseFinished then
      return room.logic:getCurrentEvent().liegong_used
    else
      return data.card.suit ~= Card.NoSuit
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      room:setPlayerMark(player, "@mouliegongRecord", 0)
      for _, p in ipairs(room:getAlivePlayers()) do
        room:setPlayerMark(p, "mou__liegong", 0)
      end
    else
      local suit = data.card:getSuitString(true)
      local record = type(player:getMark("@mouliegongRecord")) == "table" and player:getMark("@mouliegongRecord") or {}
      table.insertIfNeed(record, suit)
      room:setPlayerMark(player, "@mouliegongRecord", record)
    end
  end,
}
mouliegong:addRelatedSkill(mouliegongFilter)
mouliegong:addRelatedSkill(mouliegongProhibit)
mouhuangzhong:addSkill(mouliegong)
Fk:loadTranslationTable{
  ["mou__huangzhong"] = "谋黄忠",
  ["~mou__huangzhong"] = "弦断弓藏，将老孤亡…",
  ["mou__liegong"] = "烈弓",
  [":mou__liegong"] = "若你未装备武器，你的【杀】只能当作普通【杀】使用或打出。"
   .. "你使用牌时或成为其他角色使用牌的目标后，若此牌的花色未被“烈弓”记录，"
   .. "则记录此种花色。当你使用【杀】指定唯一目标后，你可以展示牌堆顶的X张牌"
   .. "（X为你记录的花色数-1，且至少为0），然后每有一张牌花色与“烈弓”记录的"
   .. "花色相同，你令此【杀】伤害+1，且其不能使用“烈弓”记录花色的牌响应此"
   .. "【杀】。若如此做，此【杀】结算结束后，清除“烈弓”记录的花色。",
  ["$mou__liegong1"] = "矢贯坚石，劲冠三军！",
  ["$mou__liegong2"] = "吾虽年迈，箭矢犹锋！",
  ["@mouliegongRecord"] = "烈弓",
  ["#mou__liegong_filter"] = "烈弓",
}


local mou__lvmeng = General(extension, "mou__lvmeng", "wu", 4)
local mou__keji = fk.CreateActiveSkill{
  name = "mou__keji",
  anim_type = "defensive",
  interaction = function()
    local choices = {}
    for _, c in ipairs({"moukeji_choice1","moukeji_choice2"}) do
      if Self:getMark("mou__keji"..c.."-phase") == 0 then
        table.insert(choices, c)
      end
    end
    if #choices == 0 then return end
    return UI.ComboBox {choices = choices}
  end,
  can_use = function(self, player)
    if (not player:isKongcheng() or player.hp > 0) then
      return player:usedSkillTimes(self.name, Player.HistoryPhase) < (player:usedSkillTimes("dujiang", Player.HistoryGame) == 0 and 2 or 1)
    end
  end,
  card_num = function (self)
    local choice = self.interaction.data
    if choice == "moukeji_choice1" then
      return 1
    elseif choice == "moukeji_choice2" then
      return 0
    end
    return 999
  end,
  card_filter = function(self, to_select, selected)
    if self.interaction.data == "moukeji_choice1" then
      return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
    end
    return false
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:addPlayerMark(player, "mou__keji"..self.interaction.data.."-phase")
    if #effect.cards > 0 then
      room:throwCard(effect.cards, self.name, player, player)
      if player.dead then return end
      room:changeShield(player, 1)
    else
      room:loseHp(player, 1, self.name)
      if player.dead then return end
      room:changeShield(player, 2)
    end
  end,
}
local mou__keji_maxcards = fk.CreateMaxCardsSkill{
  name = "#mou__keji_maxcards",
  correct_func = function(self, player)
    return player:hasSkill("mou__keji") and player.shield or 0
  end,
}
mou__keji:addRelatedSkill(mou__keji_maxcards)
local mou__keji_prohibit = fk.CreateProhibitSkill{
  name = "#mou__keji_prohibit",
  prohibit_use = function(self, player, card)
    return card and card.name == "peach" and player:hasSkill("mou__keji") and not player.dying
  end,
}
mou__keji:addRelatedSkill(mou__keji_prohibit)
mou__lvmeng:addSkill(mou__keji)
local dujiang = fk.CreateTriggerSkill{
  name = "dujiang",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:hasSkill(self) and target == player and player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player.shield >= 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "duojing")
  end,
}
mou__lvmeng:addSkill(dujiang)
local duojing = fk.CreateTriggerSkill{
  name = "duojing",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and player.shield > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#duojing-invoke:"..data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeShield(player, -1)
    local to = room:getPlayerById(data.to)
    room:addPlayerMark(to, fk.MarkArmorNullified)
    data.extra_data = data.extra_data or {}
    data.extra_data.duojingNullified = data.extra_data.duojingNullified or {}
    data.extra_data.duojingNullified[tostring(data.to)] = (data.extra_data.duojingNullified[tostring(data.to)] or 0) + 1
    if not player.dead and not to:isKongcheng() then
      local id = room:askForCardChosen(player, to, "h", self.name)
      room:obtainCard(player, id, false, fk.ReasonPrey)
    end
    room:addPlayerMark(player, "duojing-phase")
  end,
  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.duojingNullified
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.duojingNullified) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.duojingNullified = nil
  end,
}
local duojing_tm = fk.CreateTargetModSkill{
  name = "#duojing_tm",
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill("duojing") and skill and scope and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("duojing-phase")
    end
  end,
}
duojing:addRelatedSkill(duojing_tm)
mou__lvmeng:addRelatedSkill(duojing)
Fk:loadTranslationTable{
  ["mou__lvmeng"] = "谋吕蒙",
  ["mou__keji"] = "克己",
  [":mou__keji"] = "①出牌阶段每个选项各限一次（若你已觉醒“渡江”，改为出牌阶段限一次），你可以选择一项：1.弃置一张手牌，获得1点“护甲”；2.失去1点体力，获得2点“护甲”（“护甲”值至多为5）。②你的手牌上限+X（X为你的“护甲”值）。③若你不处于濒死状态，你不能使用【桃】。",
  ["moukeji_choice1"] = "弃牌加1甲",
  ["moukeji_choice2"] = "掉血加2甲",
  ["#mou__keji_prohibit"] = "克己",
  ["dujiang"] = "渡江",
  [":dujiang"] = "觉醒技，准备阶段，若你的“护甲”值不小于3，你获得技能“夺荆”。",
  ["duojing"] = "夺荆",
  [":duojing"] = "当你使用【杀】指定一名角色为目标时，你可以失去1点“护甲”，令此【杀】无视该角色的防具，然后你获得该角色的一张手牌，本阶段你使用【杀】的次数上限+1。",
  ["#duojing-invoke"] = "夺荆:你可以失去1点护甲，令此【杀】无视%src的防具，获得%src一张手牌，本阶段使用【杀】的次数上限+1",

  ["$mou__keji1"] = "事事克己，步步虚心！",
  ["$mou__keji2"] = "勤学潜习，始觉自新！",
  ["$dujiang1"] = "大军渡江，昼夜驰上！",
  ["$dujiang2"] = "白衣摇橹，昼夜兼行！",
  ["$duojing1"] = "快舟轻甲，速袭其后！",
  ["$duojing2"] = "复取荆州，尽在掌握！",
  ["~mou__lvmeng"] = "义封胆略过人，主公可任之……",
}

return extension
