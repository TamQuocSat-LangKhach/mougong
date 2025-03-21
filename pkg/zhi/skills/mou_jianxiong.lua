local mouJianxiong = fk.CreateSkill({
  name = "mou__jianxiong",
})

Fk:loadTranslationTable{
  ["mou__jianxiong"] = "奸雄",
  [":mou__jianxiong"] = "游戏开始时，你可以获得至多两枚“治世”标记。当你受到伤害后，你可以获得对你造成伤害的牌并摸1-X张牌，然后你可以移除1枚“治世”（X为“治世”的数量）。",

  ["#mou__jianxiong-dismark"] = "奸雄：你可移除1枚“治世”，削弱“清正”，增强“奸雄”",
  ["#mou__jianxiong-gamestart"] = "奸雄：可获得至多2个“治世”标记，削弱“奸雄”，增强“清正”",
  ["@mou__jianxiong"] = "治世",

  ["$mou__jianxiong1"] = "古今英雄盛世，尽赴沧海东流。",
  ["$mou__jianxiong2"] = "骖六龙行御九州，行四海路下八邦！",
}

local U = require "packages/utility/utility"

mouJianxiong:addEffect(fk.GameStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mouJianxiong.name)
  end,
  on_cost = function (self, event, target, player, data)
    local _, dat = player.room:askToUseActiveSkill(player, { skill_name = "mou__jianxiong_gamestart", prompt = "#mou__jianxiong-gamestart" })
    if dat then
      event:setCostData(self, dat.interaction)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player,  "@mou__jianxiong", event:getCostData(self))
  end,
})

mouJianxiong:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(mouJianxiong.name) and
      (
        (data.card and U.hasFullRealCard(player.room, data.card)) or
        player:getMark("@mou__jianxiong") == 0
      )
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mouJianxiong.name
    local room = player.room
    if data.card and U.hasFullRealCard(player.room, data.card) then
      room:moveCardTo(data.card, Player.Hand, player, fk.ReasonPrey, skillName)
      if player.dead then return end
    end
    local num = 1 - player:getMark("@mou__jianxiong")
    if num > 0 then
      player:drawCards(num, skillName)
    end
    if player:getMark("@mou__jianxiong") > 0 then
      if room:askToSkillInvoke(player, { skill_name = skillName, prompt = "#mou__jianxiong-dismark" }) then
        room:removePlayerMark(player, "@mou__jianxiong", 1)
      end
    end
  end,
})

return mouJianxiong
