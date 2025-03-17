local mouTianduViewAs = fk.CreateSkill({
  name = "mou__tiandu_view_as",
})

Fk:loadTranslationTable{
  ["mou__tiandu_view_as"] = "天妒",
  ["#mou__tiandu-viewas"] = "天妒：你可以视为使用普通锦囊",
}

local U = require "packages/utility/utility"

mouTianduViewAs:addEffect("viewas", {
  interaction = function(self, player)
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(player, "mou__tiandu", all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names, default_choice = "AskForCardsChosen" }
    end
  end,
  expand_pile = function (self)
    return { self.card_map[self.interaction.data] }
  end,
  card_filter = function(self, player, to_select, selected)
    return to_select == self.card_map[self.interaction.data]
  end,
  view_as = function(self, player, cards)
    if #cards > 0 then
      local card = Fk:cloneCard(self.interaction.data)
      card.skillName = "mou__tiandu"
      return card
    end
  end,
})

return mouTianduViewAs
