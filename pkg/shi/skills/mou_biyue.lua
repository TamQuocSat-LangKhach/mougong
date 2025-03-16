local mouBiyue = fk.CreateSkill({
  name = "mou__biyue",
})

Fk:loadTranslationTable{
  ["mou__biyue"] = "闭月",
  [":mou__biyue"] = "回合结束时，你可以摸X张牌（X为本回合内受到过伤害的角色数+1且至多为5）。",

  ["$mou__biyue1"] = "薄酒醉红颜，广袂羞掩面。",
  ["$mou__biyue2"] = "芳草更芊芊，荷池映玉颜。",
}

mouBiyue:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mouBiyue.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local targets = {}
    player.room.logic:getActualDamageEvents(999, function(e)
      table.insertIfNeed(targets, e.data.to.id)
      return false
    end, Player.HistoryTurn)
    player:drawCards(math.min(1 + #targets, 5), self.name)
  end,
})

return mouBiyue
