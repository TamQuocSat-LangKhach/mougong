local mouJijiangChoose = fk.CreateSkill({
  name = "mou__jijiang_choose",
})

Fk:loadTranslationTable{
  ["mou__jijiang_choose"] = "激将",
}

mouJijiangChoose:addEffect("active", {
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected > 1 or to_select == player then return false end
    if #selected == 0 then
      return true
    else
      local victim = selected[1]
      local bro = to_select
      return bro.kingdom == "shu" and bro.hp >= player.hp and bro:inMyAttackRange(victim)
    end
  end,
})

return mouJijiangChoose
