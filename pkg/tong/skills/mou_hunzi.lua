local mouHunzi = fk.CreateSkill({
  name = "mou__hunzi",
  tags = { Skill.Wake },
})

Fk:loadTranslationTable{
  ["mou__hunzi"] = "魂姿",
  [":mou__hunzi"] = "觉醒技，当你脱离濒死状态时，你减1点体力上限，获得1点护甲，摸三张牌，然后获得〖英姿〗和〖英魂〗。",
  ["mou__zhiba"] = "制霸",
  [":mou__zhiba"] = "主公技，限定技，当你进入濒死状态时，你可以回复X点体力（X为吴势力角色数-1）"..
  "并修改〖激昂〗（将“出牌阶段限一次”改为“出牌阶段限X次（X为吴势力角色数）”），"..
  "然后其他吴势力角色依次{受到1点无伤害来源的伤害，若其死亡，你摸三张牌}。",

  ["$mou__hunzi1"] = "群雄逐鹿之时，正是吾等崭露头角之日！",
  ["$mou__hunzi2"] = "胸中远志几时立，正逢建功立业时！",
}

mouHunzi:addEffect(fk.AfterDying, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(mouHunzi.name) and
      player:usedSkillTimes(mouHunzi.name, Player.HistoryGame) == 0
  end,
  can_wake = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    room:changeShield(player, 1)
    if player.dead then return false end
    room:drawCards(player, 3, mouHunzi.name)
    if player.dead then return false end
    room:handleAddLoseSkills(player, "mou__yingzi|yinghun", nil, true, false)
  end,
})

return mouHunzi
