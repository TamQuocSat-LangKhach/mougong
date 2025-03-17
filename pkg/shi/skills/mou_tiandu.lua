local mouTiandu = fk.CreateSkill({
  name = "mou__tiandu",
  tags = { Skill.Switch },
})

Fk:loadTranslationTable{
  ["mou__tiandu"] = "天妒",
  [":mou__tiandu"] = "转换技，出牌阶段开始时，阳：你可以弃置两张手牌并记录这些牌的花色，然后可以视为使用任意普通锦囊牌；"..
  "阴：你判定，若结果为你记录过的花色，你受到1点无来源伤害。当此次判定的结果确定后，你获得判定牌。",
  [":mou__tiandu_yang"] = "转换技，出牌阶段开始时，"..
  "<font color=\"#E0DB2F\">阳：你可以弃置两张手牌并记录这些牌的花色，然后可以视为使用任意普通锦囊牌；"..
  "<font color=\"gray\">阴：你判定，若结果为你记录过的花色，你受到1点无来源伤害。当此次判定的结果确定后，你获得判定牌。</font>",
  [":mou__tiandu_yin"] = "转换技，出牌阶段开始时，"..
  "<font color=\"gray\">阳：你可以弃置两张手牌并记录这些牌的花色，然后可以视为使用任意普通锦囊牌；"..
  "<font color=\"#E0DB2F\">阴：你判定，若结果为你记录过的花色，你受到1点无来源伤害。当此次判定的结果确定后，你获得判定牌。</font>",
  ["#mou__tiandu_delay"] = "天妒",

  ["#mou__tiandu-invoke"] = "是否使用 天妒，弃置两张手牌来视为使用普通锦囊",
  ["@[suits]mou__tiandu"] = "天妒",

  ["$mou__tiandu1"] = "顺应天命，即为大道所归。",
  ["$mou__tiandu2"] = "计高于人，为天所妒。",
}

local U = require "packages/utility/utility"

mouTiandu:addEffect(fk.EventPhaseStart, {
  anim_type = "switch",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(mouTiandu.name) and
      player == target and
      player.phase == Player.Play and
      (player:getSwitchSkillState(mouTiandu.name, false) == fk.SwitchYin or player:getHandcardNum() > 1)
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = mouTiandu.name
    if player:getSwitchSkillState(skillName, false) == fk.SwitchYang then
      local cards = player.room:askToDiscard(
        player,
        {
          min_num = 2,
          max_num = 2,
          include_equip = false,
          skill_name = skillName,
          cancelable = true,
          pattern = ".",
          prompt = "#mou__tiandu-invoke",
          skip = true
        }
      )
      if #cards > 0 then
        event:setCostData(self, cards) 
        return true
      end
    else
      event:setCostData(self, {})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mouTiandu.name
    local room = player.room
    local cards = event:getCostData(self)
    if #cards > 0 then
      room:notifySkillInvoked(player, skillName)
      player:broadcastSkillInvoke(skillName, 1)
      local suits = player:getTableMark("@[suits]mou__tiandu")
      local updata_mark = false
      for _, id in ipairs(cards) do
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit and table.insertIfNeed(suits, suit) then
          updata_mark = true
        end
      end
      if updata_mark then
        room:setPlayerMark(player, "@[suits]mou__tiandu", suits)
      end
      room:throwCard(cards, skillName, player, player)
      if player.dead then return false end
      local cardMap = player:getMark("mou__tiandu_cardmap")
      if type(cardMap) ~= "table" then
        cardMap = {}
        local tricks = U.getUniversalCards(room, "t")
        for _, id in ipairs(tricks) do
          cardMap[Fk:getCardById(id).name] = id
        end
        room:setPlayerMark(player, "mou__tiandu_cardmap", cardMap)
      end
      local _, dat = room:askToUseActiveSkill(
        player,
        {
          skill_name = "mou__tiandu_view_as",
          prompt = "#mou__tiandu-viewas",
          cancelable = true,
          extra_data = { card_map = cardMap }
        }
      )
      if dat then
        local card = Fk:cloneCard(dat.interaction)
        card.skillName = skillName
        room:useCard{
          card = card,
          from = player,
          tos = dat.targets,
          extraUse = true,
        }
      end
    else
      room:notifySkillInvoked(player, skillName)
      player:broadcastSkillInvoke(skillName, 2)
      local suits = player:getTableMark("@[suits]mou__tiandu")
      local judge_pattern = table.concat(table.map(suits, function (suit)
        return U.ConvertSuit(suit, "int", "str")
      end), ",")
      local judge = {
        who = player,
        reason = skillName,
        pattern = ".|.|".. judge_pattern,
      }
      room:judge(judge)
      if table.contains(suits, judge.card.suit) and not player.dead then
        room:damage{
          to = player,
          damage = 1,
          skillName = skillName,
        }
      end
    end
  end,
})

mouTiandu:addEffect(fk.FinishJudge, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.reason == mouTiandu.name and player.room:getCardArea(data.card.id) == Card.Processing
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, data.card, true)
  end,
})

mouTiandu:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@[suits]mou__tiandu", 0)
end)

return mouTiandu
