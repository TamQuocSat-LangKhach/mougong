local yingwu = fk.CreateSkill({
  name = "yingwu",
})

Fk:loadTranslationTable{
  ["yingwu"] = "莺舞",
  ["#yingwu_charge"] = "莺舞",
  [":yingwu"] = "你使用非伤害类普通锦囊结算结束后，若你拥有至少两个“椎”标记，则你移除两个“椎”标记，然后摸一张牌，"..
    "且可以选择一名角色视为对其使用一张【杀】（计入次数，无次数限制）。每阶段限两次，当你于出牌阶段内使用非伤害类普通锦囊指定一个目标后，"..
    "若你拥有技能〖掠影〗，则你获得一个“椎”标记。",

  ["#yingwu-slash"] = "莺舞：你可以视为使用【杀】，选择%arg名角色为目标",

  ["$yingwu1"] = "莺舞曼妙，杀机亦藏其中！",
  ["$yingwu2"] = "莺翼之羽，便是诛汝之锋！",
}

yingwu:addEffect(fk.TargetSpecified, {
  mute = true,
  times = function(self, player)
    return player.phase == Player.Play and 2 - player:usedEffectTimes(self.name, Player.HistoryPhase) or -1
  end,
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(yingwu.name) and
      target == player and
      data.card:isCommonTrick() and
      not data.card.is_damage_card and
      player:usedEffectTimes(self.name, Player.HistoryPhase) < 2
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@lueying_hit")
  end,
})

yingwu:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(yingwu.name) and
      target == player and
      data.card:isCommonTrick() and
      not data.card.is_damage_card and
      player:getMark("@lueying_hit") > 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = yingwu.name
    local room = player.room
    room:removePlayerMark(player, "@lueying_hit", 2)
    room:drawCards(player, 1, skillName)
    local slash = Fk:cloneCard("slash")
    slash.skillName = skillName
    if player:prohibitUse(slash) then return false end
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    if max_num == 0 then return false end
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if not (p == player or player:isProhibited(p, slash)) then
        table.insert(targets, p)
      end
    end
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = max_num,
        prompt = "#yingwu-slash:::" .. max_num, 
        skill_name = skillName,
        cancelable = true,
        no_indicate = true,
      }
    )
    if #tos > 0 then
      room:useCard({
        from = player,
        tos = tos,
        card = slash,
      })
    end
  end,
})

return yingwu
