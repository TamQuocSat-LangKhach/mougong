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
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
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
    return target == player and player:hasSkill(self.name) and player:isWounded()
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
    return target == player and player:hasSkill(self.name) and player.faceup
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
    if not (target == player and player:hasSkill(self.name)) then
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
      player:hasSkill(self.name)
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
    return target == player and player:hasSkill(self.name) and
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
    if not (target == player and player:hasSkill(self.name)) then return end
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
local mou__ganning = General(extension, "mou__ganning", "wu", 4)
local mou__qixi = fk.CreateActiveSkill{
  name = "mou__qixi",
  anim_type = "control",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local suits = {"spade","club","heart","diamond","nosuit"}
    local num = {0,0,0,0,0}
    local max_num = 0
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      num[card.suit] = num[card.suit] + 1
      max_num = math.max(max_num, num[card.suit])
    end
    local max_suit = {}
    for i = 1, 5 do
      if num[i] == max_num then
        table.insert(max_suit, suits[i])
      end
    end
    local choice = room:askForChoice(to, suits, self.name, "#mou__qixi-guess::"..player.id)
    local wrong_num = 0
    local right = table.contains(max_suit, choice)
    if not right then
      wrong_num = wrong_num + 1
      if room:askForSkillInvoke(player, self.name, nil, "#mou__qixi-again") then
        table.removeOne(suits, choice)
        choice = room:askForChoice(to, suits, self.name, "#mou__qixi-guess::"..player.id)
        if table.contains(max_suit, choice) then
          right = true
        else
          wrong_num = wrong_num + 1
        end
      end
    end
    if right and not player:isKongcheng() then
      player:showCards(player:getCardIds("h"))
    end
    local throw_num = math.min(#to:getCardIds("hej"), wrong_num)
    if player.dead or throw_num == 0 then return end
    local throw = room:askForCardsChosen(player, to, throw_num, throw_num, "hej", self.name)
    room:throwCard(throw, self.name, to, player)
  end
}
mou__ganning:addSkill(mou__qixi)
local mou__fenwei = fk.CreateActiveSkill{
  name = "mou__fenwei",
  anim_type = "control",
  min_card_num = 1,
  max_card_num = 3,
  min_target_num = 1,
  max_target_num = 3,
  frequency = Skill.Limited,
  target_filter = function(self, to_select, selected)
    return #selected < 3
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 3
  end,
  feasible = function(self, selected, selected_cards)
    return #selected >= 1 and #selected <= 3 and #selected_cards == #selected
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not player:isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for i, to in ipairs(table.map(effect.tos, Util.Id2PlayerMapper)) do
      to:addToPile("@mou__fenwei", effect.cards[i], true, self.name)
    end
    player:drawCards(#effect.cards, self.name)
  end,
}
local mou__fenwei_trigger = fk.CreateTriggerSkill{
  name = "#mou__fenwei_trigger",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card.type == Card.TypeTrick and #target:getPile("@mou__fenwei") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"#mou__fenwei_get" , "#mou__fenwei_cancel"}, self.name, "#mou__fenwei-choice::"..target.id..":"..data.card:toLogString())
    if choice == "#mou__fenwei_get" then
      local dummy = Fk:cloneCard("slash")
      dummy:addSubcards(target:getPile("@mou__fenwei"))
      room:obtainCard(target, dummy, true, fk.ReasonJustMove)
    else
      room:moveCards({
        from = target.id,
        ids = target:getPile("@mou__fenwei"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
      AimGroup:cancelTarget(data, target.id)
    end
  end,
}
mou__fenwei:addRelatedSkill(mou__fenwei_trigger)
mou__ganning:addSkill(mou__fenwei)
Fk:loadTranslationTable{
  ["mou__ganning"] = "谋甘宁",
  ["mou__qixi"] = "奇袭",
  [":mou__qixi"] = "出牌阶段限一次，你可以选择一名其他角色，令其猜测你手牌中最多的花色。若猜错，你可以令该角色从未猜测过的花色中再次猜测；若猜对，你展示所有手牌。然后你弃置其区域内X张牌（X为此阶段该角色猜错的次数，不足则全弃）。",
  ["#mou__qixi-again"] = "奇袭：你可以令其再猜一次",
  ["#mou__qixi-guess"] = "奇袭：猜测%dest手牌中最多的花色",
  ["mou__fenwei"] = "奋威",
  [":mou__fenwei"] = "限定技，出牌阶段，你可以将至多三张牌分别置于等量名角色的武将牌上，称为“威”，然后你摸等量牌。有“威”的角色成为锦囊牌的目标时，你须选择一项：1. 令其获得“威”；2. 移去其“威”，取消此目标。",
  ["@mou__fenwei"] = "威",
  ["#mou__fenwei_trigger"] = "奋威",
  ["#mou__fenwei-choice"] = "奋威：1. 令%dest获得“威”；2. 移去“威”，令%arg的目标取消%dest",
  ["#mou__fenwei_get"] = "令其获得“威”",
  ["#mou__fenwei_cancel"] = "移去“威”,取消目标",
  ["$mou__qixi1"] = "击敌不备，奇袭拔寨！",
  ["$mou__qixi2"] = "轻羽透重铠，奇袭溃坚城！",
  ["$mou__fenwei1"] = "舍身护主，扬吴将之风！",
  ["$mou__fenwei2"] = "袭军挫阵，奋江东之威！",
  ["~mou__ganning"] = "蛮将休得猖狂！呃啊！",
}
return extension
