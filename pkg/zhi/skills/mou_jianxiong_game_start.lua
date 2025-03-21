local mouJianxiongGameStart = fk.CreateSkill({
  name = "mou__jianxiong_gamestart",
})

Fk:loadTranslationTable{
  ["mou__jianxiong_gamestart"] = "奸雄",
}

mouJianxiongGameStart:addEffect("active", {
  card_num = 0,
  target_num = 0,
  interaction = function()
    return UI.Spin { from = 1, to = 2 }
  end,
})

return mouJianxiongGameStart
