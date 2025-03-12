local mouXiaoji = fk.CreateSkill({
  name = "mou__xiaoji",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = { "wu" },
})

Fk:loadTranslationTable{
  ["mou__xiaoji"] = "枭姬",
  [":mou__xiaoji"] = "吴势力技，当你失去装备区里的一张牌后，你摸两张牌，然后你可以弃置场上的一张牌。",

  ["#mou__jieyin-choose"] = "结姻：选择一名角色，令其获得“助”标记",
  ["#mou__jieyin-price"] = "结姻：选择%arg张手牌交给%src，或点取消令其移动“助”标记",
  ["#mou__jieyin-transfer"] = "结姻：将%dest的“助”标记移动给一名角色，或点取消移除“助”标记",
  ["@@mou__jieyin"] = "助",

  ["$mou__jieyin1"] = "君若不负吾心，妾自随君千里。",
  ["$mou__jieyin2"] = "夫妻之情既断，何必再问归期！",
}

mouXiaoji:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(mouXiaoji.name) then return end
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  trigger_times = function (self, event, target, player, data)
    local i = 0
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            i = i + 1
          end
        end
      end
    end

    return i
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:drawCards(player, 2, mouXiaoji.name)
    if player.dead then return false end
    local targets = table.filter(room.alive_players, function (p)
      return #p:getCardIds("ej") > 0
    end)
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#mou__xiaoji-discard",
        skill_name = mouXiaoji.name,
        cancelable = true
      }
    )
    if #tos == 0 then return false end
    local to = tos[1]
    local card = room:askToChooseCard(player, { target = to, flag = "ej", skill_name = mouXiaoji.name})
    room:throwCard({ card }, mouXiaoji.name, to, player)
  end,
})

return mouXiaoji
