local extension = Package("mou_neng")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_neng"] = "谋攻篇-能包",
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

  ["$mou__luanji1"] = "与我袁本初为敌，下场只有一个！",
  ["$mou__luanji2"] = "弓弩手，乱箭齐下，射杀此贼！",
  ["$mou__xueyi1"] = "四世三公之贵，岂是尔等寒门可及？",
  ["$mou__xueyi2"] = "吾袁门名冠天下，何须奉天子为傀？",
  ["~mou__yuanshao"] = "我不可能输给曹阿瞒，不可能！",
}

return extension