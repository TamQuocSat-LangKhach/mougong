local extension = Package("mou_neng")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_neng"] = "谋攻篇-能包",
}

local mou__lijian = fk.CreateActiveSkill{
  name = "mou__lijian",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected < #Fk:currentRoom().alive_players and
      not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected < #selected_cards + 1 and to_select ~= Self.id 
  end,
  min_card_num = 1,
  min_target_num = 2,
  feasible = function (self, selected, selected_cards)
    return #selected > 1 and #selected == #selected_cards +1 
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local tos = table.simpleClone(effect.tos)
    room:sortPlayersByAction(tos, false)
    local targets = table.map(tos, function(id) return room:getPlayerById(id) end)
    for _, src in ipairs(targets) do
      if not src.dead then
        if table.contains(tos, src.id) then
          local dest = src:getNextAlive()
          while not table.contains(targets, dest) do
            dest = dest:getNextAlive()
          end
          if dest == src then break end
          table.removeOne(tos, src.id)
          room:useVirtualCard("duel", nil, src, dest, self.name)
        else
          break
        end
      end
    end
  end,
}
local mou__biyue = fk.CreateTriggerSkill{
  name = "mou__biyue",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local targets = {}
    player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 999, function(e)
      local damage = e.data[5]
      if damage then
        table.insertIfNeed(targets, damage.to.id)
      end
    end, Player.HistoryTurn)
   
    player:drawCards(math.min(1 + #targets, 5), self.name)
  end,
}
local diaochan = General:new(extension, "mou__diaochan", "qun", 3, 3, General.Female)
diaochan:addSkill(mou__lijian)
diaochan:addSkill(mou__biyue)
Fk:loadTranslationTable{
  ["mou__diaochan"] = "谋貂蝉",
  ["mou__lijian"] = "离间",
  [":mou__lijian"] = "出牌阶段限一次，你可以选择至少两名其他角色并弃置X张牌（X为你选择的角色数减一），然后他们依次对逆时针最近座次的你选择的另一名角色视为使用一张【决斗】。",
  ["mou__biyue"] = "闭月",
  [":mou__biyue"] = "回合结束时，你可以摸X张牌(X为本回合内受到过伤害的角色数+1且至多为5)。",
}

local mou__xueyi = fk.CreateTriggerSkill{
  name = "mou__xueyi$",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
     local room = player.room
     local to = room:getPlayerById(data.to)
     return target == player and player:hasSkill(self.name) and to.kingdom == "qun" and to ~= player
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local mou__xueyi_Max = fk.CreateMaxCardsSkill{
  name = "#mou__xueyi_Max",
  correct_func = function(self, player)
    if player:hasSkill(self.name) then
      local hmax = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p ~= player and p.kingdom == "qun" then 
          hmax = hmax + 1
        end
      end
      return hmax *2
    else
      return 0
    end
  end,
}
local mou__luanji_Draw = fk.CreateTriggerSkill{
  name = "#mou__luanji_Draw",
  anim_type = "offensive",
  events = {fk.CardUseFinished,fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.card.name == "jink" then
      return data.responseToEvent and data.responseToEvent.from == player.id and data.responseToEvent.card.name =="archery_attack"
    end 
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
  }
local mou__luanji = fk.CreateViewAsSkill{
  name = "mou__luanji",
  anim_type = "offensive",
  pattern = "archery_attack",
  enabled_at_play = function(self, player)
        return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 1 then 
      return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip 
    elseif #selected == 2 then
      return false
    end

    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then
      return nil
    end

    local c = Fk:cloneCard("archery_attack")
    c:addSubcards(cards)
    return c
  end,
}
local mouyuanshao = General(extension, "mou__yuanshao", "qun", 4)
mou__xueyi:addRelatedSkill(mou__xueyi_Max)
mou__luanji:addRelatedSkill(mou__luanji_Draw)
mouyuanshao:addSkill(mou__luanji)
mouyuanshao:addSkill(mou__xueyi)
Fk:loadTranslationTable{
  ["mou__yuanshao"] = "谋袁绍",
  ["mou__luanji"] = "乱击",
  ["#mou__luanji_Draw"] = "乱击",
  [":mou__luanji"] = "①出牌阶段限一次，你可以将两张手牌当做【万箭齐发】使用。;②当有角色因响应你的【万箭齐发】打出【闪】时，你摸一张牌。",
  ["mou__xueyi"] = "血裔",
  [":mou__xueyi"] = "主公技，①锁定技，你的手牌上限+2X(X为场上现存其他群势力角色数)。;②当你使用牌指定其他群雄角色为目标时，你摸一张牌。",
}

return extension