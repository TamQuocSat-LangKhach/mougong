local mouZhangwu = fk.CreateSkill({
  name = "mou__zhangwu",
  tags = { Skill.Limited },
})

Fk:loadTranslationTable{
  ["mou__zhangwu"] = "章武",
  [":mou__zhangwu"] = "限定技，出牌阶段，你可以令〖仁德〗选择过的所有角色依次交给你X张牌（X为游戏轮数-1，至多为3），然后你回复3点体力，失去技能〖仁德〗。",
  ["#mou__zhangwu-give"] = "章武：请交给 %dest %arg 张牌",
  ["#mou__zhangwu-prompt"] = "章武：你可以令获得“仁德”牌的角色交给你牌，你回复3点体力并失去“仁德”",

  ["$mou__zhangwu1"] = "众将皆言君恩，今当献身以报！",
  ["$mou__zhangwu2"] = "汉贼不两立，王业不偏安！",
}

mouZhangwu:addEffect("active", {
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(mouZhangwu.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  prompt = "#mou__zhangwu-prompt",
  on_use = function(self, room, effect)
    ---@type string
    local skillName = mouZhangwu.name
    local player = effect.from
    local x = math.min(3, (room:getBanner("RoundCount") - 1))
    if x > 0 then
      local mark = player:getTableMark("mou__rende_target")
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not player:isAlive() then break end
        if p:isAlive() and table.contains(mark, p.id) and not p:isNude() then
          local cards = (#p:getCardIds("he") < x) and
          p:getCardIds("he") or
          room:askToCards(
            p,
            {
              min_num = x,
              max_num = x,
              include_equip = true,
              skill_name = skillName,
              cancelable = false,
              prompt = "#mou__zhangwu-give::" .. player.id .. ":" .. x,
            }
          )
          if #cards > 0 then
            room:obtainCard(player, cards, false, fk.ReasonGive, p, skillName)
          end
        end
      end
    end
    if player:isAlive() and player:isWounded() then
      room:recover { num = 3, skillName = skillName, who = player, recoverBy = player}
    end
    room:handleAddLoseSkills(player, "-mou__rende")
  end,
})

return mouZhangwu
