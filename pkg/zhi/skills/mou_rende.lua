local mouRende = fk.CreateSkill({
  name = "mou__rende",
})

Fk:loadTranslationTable{
  ["mou__rende"] = "仁德",
  [":mou__rende"] = "①出牌阶段开始时，你获得2枚“仁望”标记（至多拥有8枚）；"..
  "<br>②出牌阶段，你可以选择一名本阶段未选择过的其他角色，交给其任意张牌，然后你获得等量枚“仁望”标记；"..
  "<br>③每回合限一次，当你需要使用或打出基本牌时，你可以移去2枚“仁望”标记，视为使用或打出之。",
  ["@mou__renwang"] = "仁望",
  ["#mou__rende-invoke"] = "仁德：可以移去2枚“仁望”标记，视为使用或打出 %arg",
  ["#mou__rende-name"] = "仁德：选择视为使用或打出的所需的基本牌的牌名",
  ["#mou__rende-target"] = "仁德：选择使用【%arg】的目标角色",
  ["#mou__rende_response"] = "仁望",
  ["#mou__rende-promot"] = "仁望：将牌交给其他角色获得“仁望”标记，或移去标记视为使用基本牌",

  ["$mou__rende1"] = "仁德为政，自得民心！",
  ["$mou__rende2"] = "民心所望，乃吾政所向！",
}

mouRende:addEffect("active", {
  prompt = "#mou__rende-promot",
  interaction = function(self, player)
    local choices = { "mou__rende" }
    if player:getMark("@mou__renwang") > 1 and player:getMark("mou__rende_vs-turn") == 0 then
      local all_names = Fk:getAllCardNames("b")
      table.insertTable(choices, player:getViewAsCardNames(mouRende.name, all_names))
    end
    return UI.ComboBox { choices = choices }
  end,
  card_filter = function(self, player, to_select, selected)
    return self.interaction.data == "mou__rende"
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if self.interaction.data == "mou__rende" then
      return
        #selected == 0 and
        to_select ~= player and
        to_select:getMark("mou__rende_target-phase") == 0
    elseif self.interaction.data ~= nil then
      local to_use = Fk:cloneCard(self.interaction.data)
      to_use.skillName = mouRende.name
      if (#selected == 0 or to_use.multiple_targets) and player:isProhibited(to_select, to_use) then
        return false
      end

      return to_use.skill:targetFilter(player, to_select, selected, selected_cards, to_use)
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if self.interaction.data == "mou__rende" then
      return #selected_cards > 0 and #selected == 1
    else
      local to_use = Fk:cloneCard(self.interaction.data)
      to_use.skillName = mouRende.name
      return to_use.skill:feasible(player, selected, selected_cards, to_use)
    end
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = mouRende.name
    local player = effect.from
    if self.interaction.data == "mou__rende" then
      local target = effect.tos[1]
      room:setPlayerMark(target, "mou__rende_target-phase", 1)
      local mark = player:getTableMark("mou__rende_target")
      if table.insertIfNeed(mark, target.id) then
        room:setPlayerMark(player, "mou__rende_target", mark)
      end
      room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, skillName, nil, false, player)
      if not player:isAlive() then return end
      room:setPlayerMark(player, "@mou__renwang", math.min(8, player:getMark("@mou__renwang") + #effect.cards))
    else
      room:removePlayerMark(player, "@mou__renwang", 2)
      room:setPlayerMark(player, "mou__rende_vs-turn", 1)
      local use = {
        from = player,
        tos = effect.tos,
        card = Fk:cloneCard(self.interaction.data),
      }
      use.card.skillName = skillName
      room:useCard(use)
    end
  end,
})

mouRende:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mouRende.name) and target == player and player.phase == Player.Play and player:getMark("@mou__renwang") < 8
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@mou__renwang", math.min(8, player:getMark("@mou__renwang") + 2))
  end,
})

local mouRendeTriggerViewAsCanTrigger = function(self, event, target, player, data)
  return
    target == player and
    player:hasSkill(mouRende.name) and
    player:getMark("@mou__renwang") > 1 and
    player:getMark("mou__rende_vs-turn") == 0 and
    data.pattern and
    Exppattern:Parse(data.pattern):matchExp(".|.|.|.|.|basic")
end

local mouRendeTriggerViewAsOnCost = function(self, event, target, player, data)
  local basicCards = Fk:getAllCardNames("b")
  local names = {}
  for _, name in ipairs(basicCards) do
    local card = Fk:cloneCard(name)
    if Exppattern:Parse(data.pattern):match(card) then
      table.insertIfNeed(names, name)
    end
  end
  if #names > 0 then
    local name = names[1]
    if #names > 1 then
      name = table.every(names, function(str) return string.sub(str, -5) == "slash" end) and "slash" or "basic"
    end
    if player.room:askToSkillInvoke(player, { skill_name = mouRende.name, prompt = "#mou__rende-invoke:::" .. name }) then
      event:setCostData(self, names)
      return true
    end
  end
end

mouRende:addEffect(fk.AskForCardUse, {
  mute = true,
  can_trigger = mouRendeTriggerViewAsCanTrigger,
  on_cost = mouRendeTriggerViewAsOnCost,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mouRende.name
    local room = player.room
    local names = event:getCostData(self)
    local extra_data = data.extraData
    local isAvailableTarget = function(card, p)
      if extra_data then
        if type(extra_data.must_targets) == "table" and #extra_data.must_targets > 0 and
            not table.contains(extra_data.must_targets, p.id) then
          return false
        end
        if type(extra_data.exclusive_targets) == "table" and #extra_data.exclusive_targets > 0 and
            not table.contains(extra_data.exclusive_targets, p.id) then
          return false
        end
      end
      return not player:isProhibited(p, card) and card.skill:modTargetFilter(player, p, {}, card, extra_data)
    end
    local findCardTarget = function(card)
      local tos = {}
      for _, p in ipairs(room.alive_players) do
        if isAvailableTarget(card, p) then
          table.insert(tos, p)
        end
      end
      return tos
    end
    names = table.filter(names, function (c_name)
      local card = Fk:cloneCard(c_name)
      return not player:prohibitUse(card) and (card.skill:getMinTargetNum(player) == 0 or #findCardTarget(card) > 0)
    end)
    if #names == 0 then return false end
    local name = room:askToChoice(player, { choices = names, skill_name = skillName, prompt = "#mou__rende-name" })
    player:broadcastSkillInvoke(skillName)
    room:removePlayerMark(player, "@mou__renwang", 2)
    room:setPlayerMark(player, "mou__rende_vs-turn", 1)
    local card = Fk:cloneCard(name)
    card.skillName = skillName
    data.result = {
      from = player,
      card = card,
    }
    if card.skill:getMinTargetNum(player) == 1 then
      local tos = findCardTarget(card)
      if #tos == 1 then
        data.result.tos = tos
      elseif #tos > 1 then
        data.result.tos = room:askToChoosePlayers(
          player,
          {
            targets = tos,
            min_num = 1,
            max_num = 1,
            prompt = "#mou__rende-target:::" .. name,
            skill_name = skillName,
            cancelable = false,
            no_indicate = true
          }
        )
      else
        return false
      end
    end
    if data.eventData then
      data.result.toCard = data.eventData.toCard
      data.result.responseToEvent = data.eventData.responseToEvent
    end
    return true
  end
})

mouRende:addEffect(fk.AskForCardResponse, {
  mute = true,
  can_trigger = mouRendeTriggerViewAsCanTrigger,
  on_cost = mouRendeTriggerViewAsOnCost,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mouRende.name
    local room = player.room
    names = table.filter(names, function (c_name)
      return not player:prohibitResponse(Fk:cloneCard(c_name))
    end)
    if #names == 0 then return false end
    local name = room:askToChoice(player, { choices = names, skill_name = skillName, prompt = "#mou__rende-name" })
    player:broadcastSkillInvoke(skillName)
    room:removePlayerMark(player, "@mou__renwang", 2)
    room:setPlayerMark(player, "mou__rende_vs-turn", 1)
    local card = Fk:cloneCard(name)
    card.skillName = skillName
    data.result = card
    return true
  end
})

mouRende:addLoseEffect(function (self, player)
  if player:getMark("@mou__renwang") ~= 0 then
    player.room:setPlayerMark(player, "@mou__renwang", 0)
  end
end)

return mouRende
