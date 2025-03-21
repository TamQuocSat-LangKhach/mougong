local mouZhiheng = fk.CreateSkill({
  name = "mou__zhiheng",
})

Fk:loadTranslationTable{
  ["mou__zhiheng"] = "制衡",
  [":mou__zhiheng"] = "出牌阶段限一次，你可以弃置任意张牌并摸等量的牌。若你以此法弃置了所有的手牌，你多摸1+X张牌（X为你的“业”数），然后你弃置一枚“业”。",

  ["$mou__zhiheng1"] = "稳坐山河，但观世变。",
  ["$mou__zhiheng2"] = "身处惊涛，尤可弄潮。",
}

mouZhiheng:addEffect("active", {
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(mouZhiheng.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = mouZhiheng.name
    local from = effect.from
    local hand = from:getCardIds("h")
    local more = #hand > 0
    for _, id in ipairs(hand) do
      if not table.contains(effect.cards, id) then
        more = false
        break
      end
    end
    local num1 = from:getMark("@tongye")
    room:throwCard(effect.cards, skillName, from, from)
    room:drawCards(from, #effect.cards + (more and 1 + num1 or 0), skillName)
    if more and num1 > 0 then
      room:removePlayerMark(from, "@tongye", 1)
    end
  end
})

return mouZhiheng
