local extension = Package("mou_yu")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_yu"] = "谋攻篇-虞包",
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
    cardUseEvent.liegong_damage = #table.filter(cards, function(id)
      local c = Fk:getCardById(id)
      return table.contains(suits, c:getSuitString())
    end)
  end,

  refresh_events = {fk.TargetConfirmed, fk.CardUsing,
    fk.DamageCaused, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self.name)) then return end
    local room = player.room
    if event == fk.CardUseFinished then
      return room.logic:getCurrentEvent().liegong_used
    elseif event == fk.DamageCaused then
      return room.logic:getCurrentEvent().parent.parent.liegong_used
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
        room:setPlayerMark(p, "mouliegong", 0)
      end
    elseif event == fk.DamageCaused then
      data.damage = data.damage + room.logic:getCurrentEvent()
        .parent.parent.liegong_damage
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
