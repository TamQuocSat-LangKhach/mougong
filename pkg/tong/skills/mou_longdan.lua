local mouLongdan = fk.CreateSkill({
  name = "mou__longdan",
})

Fk:loadTranslationTable{
  ["mou__longdan"] = "龙胆",
  [":mou__longdan"] = "剩余可用X次（X初始为1且最大为3，每名角色的回合结束时X加1），"..
  "<br>当你需要使用或打出【杀】或【闪】时，你可以将一张【杀】当【闪】、【闪】当【杀】使用或打出。当你以此法使用【杀】或者【闪】结算完毕后，你摸一张牌。",
  ["@mou__longdan_times"] = "龙胆",
  ["#mou__longdan0"] = "龙胆:将一张【杀】当【闪】、【闪】当【杀】使用或打出",
  ["#mou__longdan1"] = "龙胆:将一张基本牌当任意基本牌使用或打出",

  ["$mou__longdan1"] = "长坂沥赤胆，佑主成忠名！",
  ["$mou__longdan2"] = "龙驹染碧血，银枪照丹心！",
}

local U = require "packages/utility/utility"

local longdanLimitation = 3

local getLongdanTimes = function (player)
  local longdanMark = player:getMark("@mou__longdan_times")
  return type(longdanMark) == "string" and tonumber(longdanMark:split("/")[1]) or 0
end

local addLongdanTimes = function (player, num)
  local room = player.room
  local longdanMark = player:getMark("@mou__longdan_times")
  local longdanTimes = getLongdanTimes(player)

  if num > 0 then
    num = math.min(longdanLimitation - longdanTimes, num)
    if num < 0 then
      return
    end
  else
    num = math.max(-longdanTimes, num)
  end

  if type(longdanMark) == "string" then
    room:setPlayerMark(player, "@mou__longdan_times", (longdanTimes + num) .. "/" .. longdanLimitation)
  else
    room:setPlayerMark(player, "@mou__longdan_times", num .. "/" .. longdanLimitation)
  end
end

mouLongdan:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, player)
    return "#mou__longdan" .. player:getMark("@@mou__jizhu")
  end,
  interaction = function(self, player)
    local all_names = player:getMark("@@mou__jizhu") == 0 and { "slash", "jink" } or Fk:getAllCardNames("b")
    local names = player:getViewAsCardNames(mouLongdan.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected ~= 0 or not self.interaction.data then return false end
    local card = Fk:getCardById(to_select)
    if player:getMark("@@mou__jizhu") == 0 then
      return card.trueName == (self.interaction.data == "jink" and "slash" or "jink")
    else
      return card.type == Card.TypeBasic
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = mouLongdan.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    addLongdanTimes(player, -1)
    use.extra_data = use.extra_data or {}
    use.extra_data.mou__longdan = player.id
  end,
  enabled_at_play = function(self, player)
    return getLongdanTimes(player) > 0
  end,
  enabled_at_response = function (self, player, response)
    if getLongdanTimes(player) > 0 and Fk.currentResponsePattern then
      local names = player:getMark("@@mou__jizhu") == 0 and { "slash", "jink" } or Fk:getAllCardNames("b")
      return table.find(names, function (name)
        local card = Fk:cloneCard(name)
        card.skillName = mouLongdan.name
        return Exppattern:Parse(Fk.currentResponsePattern):match(card)
      end)
    end
  end,
})

mouLongdan:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isAlive() and data.extra_data and data.extra_data.mou__longdan == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, mouLongdan.name)
  end,
})

mouLongdan:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mouLongdan.name) and getLongdanTimes(player) < longdanLimitation
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    addLongdanTimes(player, 1)
  end,
})

mouLongdan:addAcquireEffect(function (self, player)
  addLongdanTimes(player, 1)
end)

mouLongdan:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@mou__longdan_times", 0)
end)

return mouLongdan
