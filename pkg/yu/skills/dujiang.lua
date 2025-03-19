local dujiang = fk.CreateSkill({
  name = "dujiang",
  tags = { Skill.Wake },
})

Fk:loadTranslationTable{
  ["dujiang"] = "渡江",
  [":dujiang"] = "觉醒技，准备阶段，若你的护甲值不小于3，你获得技能〖夺荆〗。",

  ["$dujiang1"] = "大军渡江，昼夜驰上！",
  ["$dujiang2"] = "白衣摇橹，昼夜兼行！",
}

dujiang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      player:usedSkillTimes(dujiang.name, Player.HistoryGame) == 0 and
      player:hasSkill(dujiang.name) and
      target == player and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player.shield >= 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "duojing")
  end,
})

return dujiang
