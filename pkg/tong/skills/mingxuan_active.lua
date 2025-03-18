local mingxuanActive = fk.CreateSkill({
  name = "mingxuan_active",
})

Fk:loadTranslationTable{
  ["mingxuan_active"] = "暝眩",
}

mingxuanActive:addEffect("active", {
  can_use = Util.FalseFunc,
  target_num = 0,
  min_card_num = 1,
  max_card_num = function ()
    local room = Fk:currentRoom()
    local targetRecorded = Self:getTableMark("@[player]mingxuan")
    return #table.filter(room.alive_players, function (p)
      return p.id ~= Self.id and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected >= self.max_card_num() then return false end
    local card = Fk:getCardById(to_select)
    return table.every(selected, function (id)
      return card.suit ~= Fk:getCardById(id).suit
    end)
  end,
  target_tip = function(self, player, to_select)
    if to_select ~= player and not table.contains(player:getTableMark("@[player]mingxuan"), to_select.id) then
      return "#mingxuan_tip"
    end
  end,
})

return mingxuanActive
