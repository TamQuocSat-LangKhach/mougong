local mouQicaiSelect = fk.CreateSkill({
  name = "mou__qicai_select",
})

Fk:loadTranslationTable{
  ["mou__qicai_select"] = "奇才",
}

local U = require "packages/utility/utility"

mouQicaiSelect:addEffect("active", {
  expand_pile = function (self, player)
    return player:getTableMark("mou__qicai_discardpile")
  end,
  can_use = Util.FalseFunc,
  target_num = 0,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    if #selected ~= 0 then return false end
    local card = Fk:getCardById(to_select)
    if
      Fk:currentRoom():isGameMode("1v2_mode") and
      (card.sub_type ~= Card.SubtypeArmor or table.contains(player:getTableMark("@$mou__qicai"), card.trueName))
    then
      return false
    end

    return
      card.type == Card.TypeEquip and
      (table.contains(player:getTableMark("mou__qicai_discardpile"), to_select) or Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip) and
      U.canMoveCardIntoEquip(Fk:currentRoom():getPlayerById(player:getMark("mou__qicai_target-tmp")), to_select, false)
  end,
})

return mouQicaiSelect
