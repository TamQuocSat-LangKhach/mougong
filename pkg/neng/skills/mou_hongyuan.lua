local mouHongyuan = fk.CreateSkill({
  name = "mou__hongyuan",
  tags = { Skill.Charge },
})

Fk:loadTranslationTable{
  ["mou__hongyuan"] = "弘援",
  [":mou__hongyuan"] = "蓄力技（1/3），<br>①当你一次性获得至少两张牌时，你可以消耗1点“蓄力”点令至多两名角色各摸一张牌。"..
  "<br>②当一名其他角色一次性失去至少两张牌时，你可以消耗1点“蓄力”点令其摸两张牌（若为身份模式，则改为摸一张牌）。",

  ["#mou__hongyuan-choose"] = "弘援：你可以消耗1点“蓄力”点，令至多两名角色各摸一张牌",
  ["#mou__hongyuan-invoke"] = "弘援：你可以消耗1点“蓄力”点，令 %src 摸%arg张牌",

  ["$mou__hongyuan1"] = "舍己以私，援君之危急！",
  ["$mou__hongyuan2"] = "身为萤火之光，亦当照于天下！",
}

local U = require "packages/utility/utility"

mouHongyuan:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(mouHongyuan.name) or player:getMark("skill_charge") == 0 then return false end
    local plist = {}
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand then
        if #move.moveInfo > 1 then
          table.insert(plist, player)
        end
      end
      if move.from and move.from ~= player and move.from:isAlive() then
        if #table.filter(move.moveInfo, function (info)
          return info.fromArea == Player.Hand or info.fromArea == Player.Equip
        end) > 1 then
          table.insert(plist, move.from)
        end
      end
    end
    if #plist > 0 then
      event:setCostData(self, { tos = plist })
      return true
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local plist = table.simpleClone(event:getCostData(self).tos)
    player.room:sortByAction(plist)
    for _, p in ipairs(plist) do
      if not player:hasSkill(mouHongyuan.name) or player:getMark("skill_charge") == 0 then break end
      if p:isAlive() then
        self:doCost(event, p, player, data)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if target == player then
      local tos = room:askToChoosePlayers(
        player,
        {
          targets = room:getAlivePlayers(false),
          min_num = 1,
          max_num = 2,
          prompt = "#mou__hongyuan-choose",
          skill_name = mouHongyuan.name
        }
      )
      if #tos > 0 then
        room:sortByAction(tos)
        event:setCostData(self, { tos = tos })
        return true
      end
    elseif
      room:askToSkillInvoke(
        player,
        {
          skill_name = mouHongyuan.name,
          prompt = "#mou__hongyuan-invoke:" .. target.id .. "::" .. (room:isGameMode("role_mode") and 1 or 2)
        }
      )
    then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mouHongyuan.name
    local room = player.room
    U.skillCharged(player, -1)
    if target == player then
      for _, p in ipairs(event:getCostData(self).tos) do
        if not p.dead then
          p:drawCards(1, skillName)
        end
      end
    else
      target:drawCards(room:isGameMode("role_mode") and 1 or 2, skillName)
    end
  end,
})

mouHongyuan:addAcquireEffect(function (self, player)
  U.skillCharged(player, 1, 3)
end)

mouHongyuan:addLoseEffect(function (self, player)
  U.skillCharged(player, -1, -3)
end)

return mouHongyuan
