local extension = Package("mou_yu")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_yu"] = "谋攻篇-虞包",
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
    room:broadcastSkillInvoke("mou__jushou", 3)
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
    room:broadcastSkillInvoke("mou__jushou", 2)
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
    room:broadcastSkillInvoke("mou__jushou", 1)
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
  is_prohibited = function() return false end,
  prohibit_use = function(self, player, card)
    -- FIXME: 确保是因为【杀】而出闪，并且指明好事件id
    if Fk.currentResponsePattern ~= "jink" or card.name ~= "jink" then
      return false
    end

    local suits = player:getMark("mou__liegong")
    if type(suits) == "string" and suits ~= "" then
      suits = suits:split("+")
      if table.contains(suits, card:getSuitString()) then
        return true
      end
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
      player:getMark("mouliegongRecord") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local logic = room.logic
    local cardUseEvent = logic:getCurrentEvent().parent
    cardUseEvent.liegong_used = true

    -- 让他不能出闪
    local target = room:getPlayerById(data.to)
    local suits = player:getMark("mouliegongRecord")
    room:setPlayerMark(target, self.name, suits)

    -- 展示牌堆顶的牌，计算加伤数量
    suits = suits:split("+")
    local cards = room:getNCards(#suits - 1)
    room:moveCardTo(cards, Card.DiscardPile) -- FIXME
    data.additionalDamage = (data.additionalDamage or 0) +
    #table.filter(cards, function(id)
      local c = Fk:getCardById(id)
      return table.contains(suits, c:getSuitString())
    end)
  end,

  refresh_events = {fk.TargetConfirmed, fk.CardUsing, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self.name)) then return end
    local room = player.room
    if event == fk.CardUseFinished then
      return room.logic:getCurrentEvent().liegong_used
    else
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      room:setPlayerMark(player, "mouliegongRecord", 0)
      room:setPlayerMark(player, "@mouliegongRecord", 0)
      for _, p in ipairs(room:getAlivePlayers()) do
        room:setPlayerMark(p, "mou__liegong", 0)
      end
    else
      local suit = data.card:getSuitString()
      if table.contains({ "spade", "heart", "club", "diamond" }, suit) then
        local m = player:getMark("mouliegongRecord")
        if m == 0 then
          m = suit
        elseif type(m) == "string" then
          local suits = m:split("+")
          table.insertIfNeed(suits, suit)
          m = table.concat(suits, "+")
        end
        room:setPlayerMark(player, "mouliegongRecord", m)
        local card_suits_table = {
          spade = "♠",
          club = "♣",
          heart = "♥",
          diamond = "♦",
        }
        room:setPlayerMark(player, "@mouliegongRecord", table.concat(
          table.map(m:split("+"), function(s) return card_suits_table[s] end)
          , ""))
      end
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

return extension
