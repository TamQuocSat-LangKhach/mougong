local mouTuxiActive = fk.CreateSkill({
  name = "mou__tuxi_active",
})

Fk:loadTranslationTable{
  ["mou__tuxi_active"] = "突袭",
}

mouTuxiActive:addEffect("active", {
  min_card_num = 1,
  min_target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return table.contains(self.optional_cards or {}, to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < #selected_cards and player ~= to_select and not to_select:isKongcheng()
  end,
})

return mouTuxiActive
