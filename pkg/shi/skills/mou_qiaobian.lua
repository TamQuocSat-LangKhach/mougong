local mouQiaobian = fk.CreateSkill({
  name = "mou__qiaobian",
})

Fk:loadTranslationTable{
  ["mou__qiaobian"] = "巧变",
  [":mou__qiaobian"] = "每回合限一次，判定阶段、摸牌阶段、出牌阶段开始前，你可以跳过此阶段并执行对应跳过阶段的效果："..
  "<br>判定阶段：失去1点体力并选择一名其他角色，然后你将判定区里所有的牌置入该角色的判定区（无法置入的判定牌改为置入弃牌堆）；"..
  "<br>摸牌阶段：下个准备阶段开始时，你摸五张牌并回复1点体力；"..
  "<br>出牌阶段：将手牌数弃置至六张并跳过弃牌阶段，然后你移动场上的一张牌。",
  ["#mou__qiaobian-invoke"] = "巧变：你可以跳过 %arg",
  ["#mou__qiaobian-choose"] = "巧变：将你判定区里所有的牌置入一名其他角色的判定区",
  ["#mou__qiaobian-move"] = "巧变：请选择两名角色，移动场上的一张牌",
  ["@@mou__qiaobian_delay"] = "巧变",

  ["$mou__qiaobian1"] = "因势而变，则可引势而为",
  ["$mou__qiaobian2"] = "将计就计，变夺胜机。",
}

mouQiaobian:addEffect(fk.EventPhaseChanging, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(mouQiaobian.name) and
      player:usedSkillTimes(mouQiaobian.name, Player.HistoryTurn) == 0 and
      not data.skipped and
      data.phase > Player.Start and
      data.phase < Player.Discard
  end,
  on_cost = function(self, event, target, player, data)
    return
      player.room:askToSkillInvoke(
        player,
        {
          skill_name = mouQiaobian.name,
          prompt = "#mou__qiaobian-invoke:::" .. Util.PhaseStrMapper(data.phase)
        }
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.skipped = true

    ---@type string
    local skillName = mouQiaobian.name
    if data.phase == Player.Judge then
      room:loseHp(player, 1, skillName)
      if #player:getCardIds("j") > 0 then
        local tos = room:askToChoosePlayers(
          player,
          {
            targets = room:getOtherPlayers(player, false),
            min_num = 1,
            max_num = 1, 
            prompt = "#mou__qiaobian-choose",
            skill_name = skillName,
            cancelable = false
          }
        )
        if #tos > 0 then
          local to = tos[1]
          local moveInfos = {}
          for _, id in ipairs(player:getCardIds("j")) do
            local vcard = player:getVirualEquip(id)
            local card = vcard or Fk:getCardById(id)
            if to:hasDelayedTrick(card.name) or to.dead or table.contains(to.sealedSlots, Player.JudgeSlot) then
              table.insert(moveInfos, {
                ids = { id },
                from = player.id,
                toArea = Card.DiscardPile,
                moveReason = fk.ReasonPutIntoDiscardPile,
                proposer = player.id,
                skillName = skillName,
              })
            else
              table.insert(moveInfos, {
                ids = { id },
                from = player.id,
                to = to.id,
                toArea = Card.PlayerJudge,
                moveReason = fk.ReasonPut,
                proposer = player.id,
                skillName = skillName,
              })
            end
          end
          room:moveCards(table.unpack(moveInfos))
        end
      end
    elseif data.phase == Player.Draw then
      room:setPlayerMark(player, "@@mou__qiaobian_delay", 1)
    else
      player:skip(Player.Discard)
      if player:getHandcardNum() > 6 then
        room:askToDiscard(
          player,
          {
            min_num = player:getHandcardNum() - 6,
            max_num = player:getHandcardNum() - 6,
            include_equip = false,
            skill_name = skillName,
            cancelable = false
          }
        )
        if player.dead then return end
      end
      if #room:canMoveCardInBoard() > 0 then
        local targets = room:askToChooseToMoveCardInBoard(player, { prompt = "#mou__qiaobian-move", skill_name = skillName, cancelable = false })
        if #targets == 2 then
          room:askToMoveCardInBoard(player, { target_one = targets[1], target_two = targets[2], skill_name = skillName })
        end
      end
    end
    return true
  end,
})

mouQiaobian:addEffect(fk.EventPhaseStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@mou__qiaobian_delay") > 0 and player.phase == Player.Start
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mouQiaobian.name
    local room = player.room
    player:broadcastSkillInvoke(skillName)
    room:setPlayerMark(player, "@@mou__qiaobian_delay", 0)
    player:drawCards(5, skillName)
    if not player.dead and player:isWounded() then
      room:recover { num = 1, skillName = skillName, who = player , recoverBy = player}
    end
  end,
})

return mouQiaobian
