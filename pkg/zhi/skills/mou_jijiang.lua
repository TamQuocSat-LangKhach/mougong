local mouJijiang = fk.CreateSkill({
  name = "mou__jijiang",
  tags = { Skill.Lord },
})

Fk:loadTranslationTable{
  ["mou__jijiang"] = "激将",
  [":mou__jijiang"] = "主公技，出牌阶段结束时，你可以选择一名其他角色，令一名攻击范围内含有其且体力值不小于你的其他蜀势力角色选择一项："..
  "1.视为对其使用一张【杀】；2.跳过下一个出牌阶段。",
  ["@@mou__jijiang_skip"] = "激将",
  ["#mou__jijiang-promot"] = "激将：先选择【杀】的目标，再选需要响应“激将”的蜀势力角色",
  ["mou__jijiang_slash"] = "视为对 %src 使用一张【杀】",
  ["mou__jijiang_skip"] = "跳过下一个出牌阶段",

  ["$mou__jijiang1"] = "匡扶汉室，岂能无诸将之助！",
  ["$mou__jijiang2"] = "大汉将士，何人敢战？",
}

mouJijiang:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(mouJijiang.name) and player.phase == Player.Play then
      local players = player.room.alive_players
      return #players > 2 and table.find(players, function(p) return p ~= player and p.kingdom == "shu" and p.hp >= player.hp end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(
      player,
      {
        skill_name = "mou__jijiang_choose",
        prompt = "#mou__jijiang-promot",
        no_indicate = true
      }
    )
    if success and dat then
      event:setCostData(self, dat.targets)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mouJijiang.name
    local room = player.room
    local costData = event:getCostData(self)
    local victim = costData[1]
    local bro = costData[2]
    room:doIndicate(player.id, { bro.id })
    local choices = {"mou__jijiang_skip"}
    if not bro:prohibitUse(Fk:cloneCard("slash")) and not bro:isProhibited(victim, Fk:cloneCard("slash")) then
      table.insert(choices, 1, "mou__jijiang_slash:" .. victim.id)
    end
    if room:askToChoice(bro, { choices = choices, skill_name = skillName }) == "mou__jijiang_skip" then
      room:setPlayerMark(bro, "@@mou__jijiang_skip", 1)
    else
      room:useVirtualCard("slash", nil, bro, victim, skillName, true)
    end
  end,
})

mouJijiang:addEffect(fk.EventPhaseChanging, {
  priority = 10,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@mou__jijiang_skip") > 0 and data.phase == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@mou__jijiang_skip", 0)
    data.skipped = true
  end,
})

return mouJijiang
