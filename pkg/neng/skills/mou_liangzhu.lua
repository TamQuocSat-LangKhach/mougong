local mouLiangzhu = fk.CreateSkill({
  name = "mou__liangzhu",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = { "shu" },
})

Fk:loadTranslationTable{
  ["mou__liangzhu"] = "良助",
  [":mou__liangzhu"] = "蜀势力技，出牌阶段限一次，你可以将其他角色装备区一张牌置于你的武将牌上，称为“妆”，然后有“助”的角色回复1点体力或摸两张牌。",

  ["#mou__liangzhu-active"] = "发动良助，选择一名角色，将其装备区里的一张牌作为“妆”",
  ["mou__liangzhu_dowry"] = "妆",
  ["#mou__liangzhu-choice"] = "良助：选择回复1点体力或者摸2张牌",

  ["$mou__liangzhu1"] = "助君得胜战，跃马提缨枪！",
  ["$mou__liangzhu2"] = "平贼成君业，何惜上沙场！",
}

mouLiangzhu:addEffect("active", {
  anim_type = "control",
  prompt = "#mou__liangzhu-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and #to_select:getCardIds(Player.Equip) > 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if target.dead or player.dead or #target:getCardIds(Player.Equip) == 0 then return end
    local id = room:askToChooseCard(player, { target = target, flag = "e", skill_name = self.name })
    player:addToPile("mou__liangzhu_dowry", id, true, self.name)
    local mark = player:getMark("mou__jieyin_target")
    if mark ~= 0 then
      local to = room:getPlayerById(mark)
      if to.dead then return false end
      local choices = {"draw2"}
      if to:isWounded() then
        table.insert(choices, "recover")
      end
      local choice = room:askToChoice(
        to,
        {
          choices = choices,
          skill_name = self.name,
          prompt = "#mou__liangzhu-choice",
          cancelable = false,
          all_choices = {"draw2", "recover"}
        }
      )
      if choice == "draw2" then
        room:drawCards(to, 2, self.name)
      else
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
})

return mouLiangzhu
