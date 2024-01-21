local extension = Package("mou_yu")
extension.extensionName = "mougong"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["mou_yu"] = "谋攻篇-虞包",
}
local mouhuanggai = General(extension, "mou__huanggai", "wu", 4)
local mou__kurou = fk.CreateTriggerSkill{
  name = "mou__kurou",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
     local room = player.room
     local tar, card =room:askForChooseCardAndPlayers( player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
     ".|.|.|hand", "#mou__kurou-give", self.name , true)
    if #tar > 0 and card then
      self.cost_data = {tar[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(self.cost_data[2])
    room:obtainCard(self.cost_data[1], card, false, fk.ReasonGive)
    if player.dead then return end
    if card.trueName == "analeptic" or card.trueName == "peach" then
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
      if player.shield >= 5 or not player:hasSkill(self) then break end
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
  bypass_times = function(self, player, skill, scope, card)
    return card and player:hasSkill("mou__zhaxiang") and player:getMark("mou__zhaxiang-phase") < player:getLostHp()
    and player.phase == Player.Play
  end,
  bypass_distances = function(self, player, skill, card)
    return card and player:hasSkill("mou__zhaxiang") and player:getMark("mou__zhaxiang-phase") < player:getLostHp()
    and player.phase == Player.Play
  end,
}
mou__zhaxiang:addRelatedSkill(mou__zhaxiang_targetmod)
mou__zhaxiang:addRelatedSkill(mou__zhaxiang_trigger)
mouhuanggai:addSkill(mou__zhaxiang)
Fk:loadTranslationTable{
  ["mou__huanggai"] = "谋黄盖",
  ["mou__kurou"] = "苦肉",
  ["#mou__kurou_hujia"] = "苦肉",
  [":mou__kurou"] = "①出牌阶段开始时，你可以将一张手牌交给一名其他角色，若如此做，你失去一点体力，若你交出的牌为【桃】或【酒】则改为两点；②当你失去一点体力值时，你获得两点护甲。",
  ["mou__zhaxiang"] = "诈降",
  [":mou__zhaxiang"] = "锁定技，①摸牌阶段，你的摸牌基数+X；②出牌阶段，你使用的前X张牌无距离和次数限制且无法响应（X为你已损失的体力值）。",
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

local mou__yujin = General(extension, "mou__yujin", "wei", 4)
local mou__xiayuan = fk.CreateTriggerSkill{
  name = "mou__xiayuan",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
    and player:getHandcardNum() > 1 and target.shield < 5
    and data.extra_data and data.extra_data.mou__xiayuan_num
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 2, 2, false, self.name, true, ".",
    "#mou__xiayuan-card::"..target.id..":"..data.extra_data.mou__xiayuan_num, true)
    if #cards == 2 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if not target.dead then
      room:changeShield(target, data.extra_data.mou__xiayuan_num)
    end
  end,

  refresh_events = {fk.HpChanged},
  can_refresh = function (self, event, target, player, data)
    return target == player and player.shield == 0 and data.reason == "damage" and data.shield_lost > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.Damage)
    if e then
      local damage = e.data[1]
      damage.extra_data = damage.extra_data or {}
      damage.extra_data.mou__xiayuan_num = data.shield_lost
    end
  end,
}
mou__yujin:addSkill(mou__xiayuan)
local mou__jieyue = fk.CreateTriggerSkill{
  name = "mou__jieyue",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and player.phase == Player.Finish
  end,
  on_cost = function (self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#mou__jieyue-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:changeShield(to, 1)
    if not to:isNude() and not player.dead then
      local card = room:askForCard(to, 1, 1, true, self.name, true, ".", "#mou__jieyue-give:"..player.id)
      if #card > 0 then
        room:obtainCard(player, card[1], false, fk.ReasonGive)
      end
    end
  end,
}
mou__yujin:addSkill(mou__jieyue)
Fk:loadTranslationTable{
  ["mou__yujin"] = "谋于禁",
  ["mou__xiayuan"] = "狭援",
  [":mou__xiayuan"] = "每轮限一次，其他角色受到伤害后，若此伤害令其失去全部“护甲”，则你可以弃置两张手牌，令其获得本次伤害结算中期失去的“护甲”。",
  ["#mou__xiayuan-card"] = "狭援：你可以弃置两张手牌，令 %dest 获得 %arg 点护甲",
  ["mou__jieyue"] = "节钺",
  [":mou__jieyue"] = "结束阶段，你可以令一名其他角色获得1点“护甲”，然后其可以交给你一张牌。",
  ["#mou__jieyue-choose"] = "节钺：你可以令一名其他角色获得1点“护甲”",
  ["#mou__jieyue-give"] = "节钺：你可以交给 %src 一张牌",

  ["$mou__xiayuan1"] = "速置粮草，驰援天柱山。",
  ["$mou__xiayuan2"] = "援军既至，定攻克此地！",
  ["$mou__jieyue1"] = "尔等小儿，徒费兵力！",
  ["$mou__jieyue2"] = "雕虫小技，静待则已。",
  ["~mou__yujin"] = "禁……愧于丞相……",
}

local mouhuangzhong = General(extension, "mou__huangzhong", "shu", 4)
local mouliegongFilter = fk.CreateFilterSkill{
  name = "#mou__liegong_filter",
  card_filter = function(self, card, player)
    return card.trueName == "slash" and
      card.name ~= "slash" and
      not player:getEquipment(Card.SubtypeWeapon) and
      player:hasSkill(self) and
      table.contains(player.player_cards[Player.Hand], card.id)
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
      #AimGroup:getAllTargets(data.tos) == 1 and
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

local huangyueying = General(extension, "mou__huangyueying", "shu", 3, 3, General.Female)
local mou__jizhi = fk.CreateTriggerSkill{
  name = "mou__jizhi",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card:isCommonTrick()
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.AfterCardsMove, fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == self.name then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              room:setCardMark(Fk:getCardById(id), "@@mou__jizhi-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.AfterTurnEnd then
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "@@mou__jizhi-inhand", 0)
      end
    end
  end,
}
local mou__jizhi_maxcards = fk.CreateMaxCardsSkill{
  name = "#mou__jizhi_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@mou__jizhi-inhand") > 0
  end,
}
local mou__qicai_select = fk.CreateActiveSkill{
  name = "mou__qicai_select",
  expand_pile = "mou__qicai_discardpile",
  can_use = Util.FalseFunc,
  target_num = 0,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    if #selected ~= 0 then return false end
    local card = Fk:getCardById(to_select)
    return card.type == Card.TypeEquip and not table.contains(U.getMark(Self, "@$mou__qicai"), card.trueName) and
    Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip and
    U.canMoveCardIntoEquip(Fk:currentRoom():getPlayerById(Self:getMark("mou__qicai_target-tmp")), to_select, false)
  end,
}
Fk:addSkill(mou__qicai_select)

local mou__qicai = fk.CreateActiveSkill{
  name = "mou__qicai",
  prompt = "#mou__qicai-active",
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = U.getMark(player, "@$mou__qicai")
    local ids = table.filter(room.discard_pile, function (id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and not table.contains(mark, card.trueName)
    end)
    player.special_cards["mou__qicai_discardpile"] = table.simpleClone(ids)
    player:doNotify("ChangeSelf", json.encode {
      id = player.id,
      handcards = player:getCardIds("h"),
      special_cards = player.special_cards,
    })
    room:setPlayerMark(player, "mou__qicai_target-tmp", target.id)
    local success, dat = room:askForUseActiveSkill(player, "mou__qicai_select",
    "#mou__qicai-choose::" .. effect.tos[1], true, Util.DummyTable, true)
    room:setPlayerMark(player, "qicai_target-tmp", 0)
    player.special_cards["mou__qicai_discardpile"] = {}
    player:doNotify("ChangeSelf", json.encode {
      id = player.id,
      handcards = player:getCardIds("h"),
      special_cards = player.special_cards,
    })
    if success then
      if player.room.settings.gameMode == "m_1v2_mode" then
        table.insert(mark, Fk:getCardById(dat.cards[1]).trueName)
        room:setPlayerMark(player, "@$mou__qicai", mark)
      end
      U.moveCardIntoEquip(room, target, dat.cards, self.name)
      room:setPlayerMark(target, "@mou__qicai_target", 3)
      room:setPlayerMark(target, "mou__qicai_source", effect.from)
    end
  end,
}
local mou__qicai_trigger = fk.CreateTriggerSkill{
  name = "#mou__qicai_trigger",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(mou__qicai) then return false end
    local room = player.room
    local qicai_pairs = {}
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@mou__qicai_target") > 0 and p:getMark("mou__qicai_source") == player.id then
        qicai_pairs[p.id] = {}
      end
    end
    for _, move in ipairs(data) do
      if move.to ~= nil and qicai_pairs[move.to] ~= nil and move.toArea == Card.PlayerHand then
        local to = room:getPlayerById(move.to)
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == to and
          Fk:getCardById(id):isCommonTrick() then
            table.insert(qicai_pairs[move.to], id)
          end
        end
      end
    end
    for _, ids in pairs(qicai_pairs) do
      if #ids > 0 then
        self.cost_data = qicai_pairs
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(mou__qicai.name)
    local room = player.room
    local to_get = {}
    for pid, ids in pairs(self.cost_data) do
      if #ids > 0 then
        room:doIndicate(player.id, {pid})
        local to = room:getPlayerById(pid)
        local x = to:getMark("@mou__qicai_target")
        if x < #ids then
          ids = table.random(ids, x)
        end
        if #ids == x then
          room:setPlayerMark(to, "@mou__qicai_target", 0)
          room:setPlayerMark(to, "mou__qicai_source", 0)
        else
          room:removePlayerMark(to, "@mou__qicai_target", #ids)
        end
        table.insertTable(to_get, ids)
      end
    end
    room:moveCardTo(to_get, Card.PlayerHand, player, fk.ReasonGive, mou__qicai.name, nil, false, player.id)
  end,

  refresh_events = {fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventLoseSkill and data ~= mou__qicai then return false end
    return player:getMark("mou__qicai_source") == target.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@mou__qicai_target", 0)
    room:setPlayerMark(player, "mou__qicai_source", 0)
  end,
}
local mou__qicai_target = fk.CreateTargetModSkill{
  name = "#mou__qicai_target",
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(mou__qicai) and card and card.type == Card.TypeTrick
  end,
}
mou__jizhi:addRelatedSkill(mou__jizhi_maxcards)
mou__qicai:addRelatedSkill(mou__qicai_trigger)
mou__qicai:addRelatedSkill(mou__qicai_target)
huangyueying:addSkill(mou__jizhi)
huangyueying:addSkill(mou__qicai)

Fk:loadTranslationTable{
  ["mou__huangyueying"] = "谋黄月英",
  ["mou__jizhi"] = "集智",
  [":mou__jizhi"] = "锁定技，当你使用普通锦囊牌时，你摸一张牌，以此法获得的牌本回合不计入手牌上限。",
  ["mou__qicai"] = "奇才",
  [":mou__qicai"] = "你使用锦囊牌无距离限制。出牌阶段限一次，你可以选择一名其他角色，"..
  "将手牌或弃牌堆中一张装备牌置入其装备区（若为斗地主模式，则每种牌名限一次），"..
  "然后其获得“奇”标记。有“奇”标记的角色接下来获得的三张普通锦囊牌须交给你。",

  ["@@mou__jizhi-inhand"] = "集智",
  ["#mou__qicai-active"] = "发动 奇才，选择1名角色令其装装备，然后其获得的锦囊牌须交给你",
  ["#mou__qicai-choose"] = "奇才：令%dest装备你手牌或弃牌堆里的一张装备牌",
  ["mou__qicai_select"] = "奇才",
  ["mou__qicai_discardpile"] = "弃牌堆",
  ["@mou__qicai_target"] = "奇",
  ["@$mou__qicai"] = "奇才",
  ["#mou__qicai_trigger"] = "奇才",

  ["$mou__jizhi1"] = "解之有万法，吾独得千计。",
  ["$mou__jizhi2"] = "慧思万千，以成我之所想。",
  ["$mou__qicai1"] = "依我此计，便可破之。",
  ["$mou__qicai2"] = "以此无用之物，换得锦囊妙计。",
  ["~mou__huangyueying"] = "何日北平中原，夫君再返隆中……",
}

return extension
