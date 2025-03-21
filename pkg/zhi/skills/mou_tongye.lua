local mouTongye = fk.CreateSkill({
  name = "mou__tongye",
  tags = { Skill.Compulsory },
})

Fk:loadTranslationTable{
  ["mou__tongye"] = "统业",
  [":mou__tongye"] = "锁定技，结束阶段，你可以猜测场上的装备数量于你的下个准备阶段开始时有无变化。若你猜对，" ..
  "你获得一枚“业”（至多拥有2个“业”标记），猜错，你弃置一枚“业”。",

  ["tongye1"] = "统业猜测:有变化",
  ["tongye2"] = "统业猜测:无变化",
  ["@tongye"] = "业",
  ["@@tongye1"] = "统业:有变",
  ["@@tongye2"] = "统业:不变",

  ["$mou__tongye1"] = "上下一心，君臣同志。",
  ["$mou__tongye2"] = "胸有天下者，必可得其国。",
}

mouTongye:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player.phase == Player.Finish then
        return true
      elseif player.phase == Player.Start then
        return player:getMark("@@tongye1") > 0 or player:getMark("@@tongye2") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room.alive_players) do
      n = n + #p:getCardIds("e")
    end
    if player.phase == Player.Start then
      if player:getMark("@@tongye1") ~= 0 then
        if player:getMark("tongye_num") ~= n then
          if player:getMark("@tongye") < 2 then
            room:addPlayerMark(player, "@tongye", 1)
          end
        else
          room:removePlayerMark(player, "@tongye", 1)
        end
        room:setPlayerMark(player, "@@tongye1", 0)
      end
      if player:getMark("@@tongye2") ~= 0 then
        if player:getMark("tongye_num") == n then
          if player:getMark("@tongye") < 2 then
            room:addPlayerMark(player, "@tongye", 1)
          end
        else
          room:removePlayerMark(player, "@tongye", 1)
        end
        room:setPlayerMark(player, "@@tongye2", 0)
      end
      room:setPlayerMark(player, "tongye_num", 0)
    else
      room:setPlayerMark(player, "tongye_num", n)
      local choice = room:askToChoice(player, { choices = { "tongye1", "tongye2" }, skill_name = mouTongye.name })
      if choice == "tongye1" then
        room:addPlayerMark(player, "@@tongye1")
      end
      if choice == "tongye2" then
        room:addPlayerMark(player, "@@tongye2")
      end
    end
  end,
})

return mouTongye
