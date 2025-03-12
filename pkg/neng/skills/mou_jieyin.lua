local mouJieyin = fk.CreateSkill({
  name = "mou__jieyin",
  tags = { Skill.Quest },
})

Fk:loadTranslationTable{
  ["mou__jieyin"] = "结姻",
  [":mou__jieyin"] = "使命技，游戏开始时，你选择一名其他角色令其获得“助”。"..
  "出牌阶段开始时，有“助”的角色须选择一项：1. 若其有手牌，交给你两张手牌（若其手牌不足两张则交给你所有手牌），然后其获得一点“护甲”；"..
  "2. 令你移动或移除助标记（若其不是第一次获得“助”标记，则你只能移除“助”标记）。<br>\
  <strong>失败</strong>：当“助”标记被移除时，你回复1点体力并获得你武将牌上所有“妆”牌，你将势力修改为“吴”，减1点体力上限。",

  ["#mou__xiaoji-discard"] = "枭姬：选择一名角色，弃置其装备区或判定区里的一张牌",

  ["$mou__xiaoji1"] = "吾之所通，何止十八般兵刃！",
  ["$mou__xiaoji2"] = "既如此，就让尔等见识一番！",
}

local mouJieyinCanUse = function (player)
  return not player:getQuestSkillState(mouJieyin.name) and player:hasSkill(mouJieyin.name)
end

local mouJieyinFailed = function (self, event, target, player, data)
  local room = player.room
  player:broadcastSkillInvoke(mouJieyin.name, 2)
  room:updateQuestSkillState(player, mouJieyin.name, true)
  local mark = player:getMark("mou__jieyin_target")
  room:setPlayerMark(player, "mou__jieyin_target", 0)
  local to = room:getPlayerById(mark)
  if to:getMark("@@mou__jieyin") > 0 and table.every(room.alive_players, function (p)
    return p:getMark("mou__jieyin_target") ~= mark
  end) then
    room:setPlayerMark(to, "@@mou__jieyin", 0)
  end
  if player:isWounded() then
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = mouJieyin.name
    })
  end
  room:changeKingdom(player, "wu", true)
  local dowry = player:getPile("mou__liangzhu_dowry")
  if #dowry > 0 then
    room:moveCards({
      ids = dowry,
      from = player.id,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = player.id,
      skillName = mouJieyin.name,
      moveVisible = true
    })
  end
  room:changeMaxHp(player, -1)
  room:invalidateSkill(player, mouJieyin.name)
end

mouJieyin:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return mouJieyinCanUse(player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, mouJieyin.name)
    player:broadcastSkillInvoke(mouJieyin.name, 1)
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        skill_name = mouJieyin.name,
        prompt = "#mou__jieyin-choose",
        cancelable = false
      }
    )
    if #tos > 0 then
      local to = tos[1]
      room:setPlayerMark(to, "@@mou__jieyin", 1)
      room:setPlayerMark(player, "mou__jieyin_target", to.id)
    end
  end,
})

mouJieyin:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not mouJieyinCanUse(player) or player.phase ~= Player.Play then
      return false
    end

    local mark = player:getMark("mou__jieyin_target")
    if mark ~= 0 then
      return not player.room:getPlayerById(mark).dead
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(mouJieyin.name, 1)
    local mark = player:getMark("mou__jieyin_target")
    if mark ~= 0 then
      local to = room:getPlayerById(mark)
      local x = math.max(1,math.min(2, to:getHandcardNum()))
      local cards = room:askToCards(
        to,
        {
          min_num = x,
          max_num = 2,
          include_equip = false,
          skill_name = mouJieyin.name,
          cancelable = true,
          pattern = ".",
          prompt = "#mou__jieyin-price:" .. player.id .. "::".. tostring(x)
        }
      )
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          from = mark,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonGive,
          proposer = mark,
          skillName = mouJieyin.name,
          moveVisible = false
        })
        room:changeShield(to, 1)
        return false
      else
        local mark2 = player:getTableMark("mou__jieyin_break")
        if not table.contains(mark2, mark) then
          table.insert(mark2, mark)
          room:setPlayerMark(player, "mou__jieyin_break", mark2)
          local targets = {}
          for _, p in ipairs(room.alive_players) do
            if p ~= player and p ~= to then
              table.insert(targets, p)
            end
          end
          if #targets > 0 then
            local tos = room:askToChoosePlayers(
              player,
              {
                targets = targets,
                min_num = 1,
                max_num = 1,
                prompt = "#mou__jieyin-transfer::" .. mark,
                skill_name = mouJieyin.name,
                cancelable = true
              }
            )
            if #tos > 0 then
              room:setPlayerMark(player, "mou__jieyin_target", tos[1].id)
              if table.every(room.alive_players, function (p)
                return p:getMark("mou__jieyin_target") ~= mark
              end) then
                room:setPlayerMark(to, "@@mou__jieyin", 0)
              end
              room:setPlayerMark(tos[1], "@@mou__jieyin", 1)
              return false
            end
          end
        end
      end
    end

    mouJieyinFailed(self, event, target, player, data)
  end,
})

mouJieyin:addEffect(fk.Deathed, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return mouJieyinCanUse(player) and player:getMark("mou__jieyin_target") == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = mouJieyinFailed,
})

mouJieyin:addEffect(fk.BuryVictim, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("mou__jieyin_target") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("mou__jieyin_target")
    room:setPlayerMark(player, "mou__jieyin_target", 0)
    local to = room:getPlayerById(mark)
    if to:getMark("@@mou__jieyin") > 0 and table.every(room.alive_players, function (p)
      return p:getMark("mou__jieyin_target") ~= mark
    end) then
      room:setPlayerMark(to, "@@mou__jieyin", 0)
    end
  end,
})

return mouJieyin
