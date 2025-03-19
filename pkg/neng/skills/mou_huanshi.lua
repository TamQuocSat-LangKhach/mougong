local mouHuanshi = fk.CreateSkill({
  name = "mou__huanshi",
})

Fk:loadTranslationTable{
  ["mou__huanshi"] = "缓释",
  [":mou__huanshi"] = "当一名角色的判定牌生效前，你观看牌堆顶的一张牌，然后你可以用此牌或一张手牌替换之。",

  ["#mou__huanshi-card"] = "缓释：可以用手牌或牌堆顶牌替换 %dest 进行“%arg”判定的判定牌%arg2",

  ["$mou__huanshi1"] = "济危以仁，泽国生春。",
  ["$mou__huanshi2"] = "谏而不犯，正而不毅。",
}

mouHuanshi:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mouHuanshi.name) and not (player:isNude() and player.hp < 1)
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { target.id } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mouHuanshi.name
    local room = player.room
    local ex = {}
    if #room.draw_pile > 0 then
      table.insert(ex, room.draw_pile[1])
    end
    local cards = room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = skillName,
        pattern = ".",
        prompt = "#mou__huanshi-card::" .. target.id .. ":" .. data.reason .. ":" .. data.card:toLogString(),
        expand_pile = ex
      }
    )
    if #cards == 0 then return end
    local fromPlace = room:getCardArea(cards[1])
    local oldCards = { data.card:getEffectiveId() }
    room:retrial(Fk:getCardById(cards[1]), player, data, skillName, fromPlace == Player.Hand)
    if fromPlace == Card.DrawPile then
      -- 实测交换牌堆牌并不是换到牌堆原位置(也不知道去哪了)，暂定置于牌堆顶吧
      room:moveCards{
        ids = oldCards,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
      }
    end
  end,
})

return mouHuanshi
