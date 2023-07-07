local extension = Package("mou_zhi")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_zhi"] = "谋攻篇-知包",
}
local sunquan = General(extension, "mou__sunquan", "wu", 4)
local mou__zhiheng = fk.CreateActiveSkill{
  name = "mou__zhiheng",
  anim_type = "drawcard",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local hand = from:getCardIds(Player.Hand)
    local more = #hand > 0
    for _, id in ipairs(hand) do
      if not table.contains(effect.cards, id) then
        more = false
        break
      end
    end
    local num1 = from:getMark("@tongye")
    room:throwCard(effect.cards, self.name, from, from)
    room:drawCards(from, #effect.cards + (more and 1 or 0) + num1, self.name)
    if more and num1 > 0 then
      room:removePlayerMark(from, "@tongye", 1)
    end
  end
}
local mou__tongye = fk.CreateTriggerSkill{
  name = "mou__tongye",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if player.phase == Player.Finish then 
        return true
      elseif player.phase == Player.Start then
        return player:getMark("@@tongye1") > 0 or player:getMark("@@tongye2") >0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
     local n = 0
    for _, p in ipairs(room:getAlivePlayers()) do
      for _, id in ipairs(p:getCardIds{Player.Equip}) do
         n = n+1
      end
    end
    if player.phase == Player.Start then
      if player:getMark("@@tongye1") ~= 0 then
        if player:getMark("tongye_num") ~=n then
          room:addPlayerMark(player, "@tongye", 1)
        else
          room:removePlayerMark(player, "@tongye", 1)
        end
        room:setPlayerMark(player, "@@tongye1", 0)
      end
      if player:getMark("@@tongye2") ~= 0 then
        if player:getMark("tongye_num") == n then
          room:addPlayerMark(player, "@tongye", 1)
        else
          room:removePlayerMark(player, "@tongye", 1)
        end
        room:setPlayerMark(player, "@@tongye2", 0)
      end
       room:setPlayerMark(player, "tongye_num", 0)
    else
      room:addPlayerMark(player, "tongye_num", n)
      local choice = room:askForChoice(player, { "tongye1", "tongye2"}, self.name)
      if choice == "tongye1" then
        room:addPlayerMark(player, "@@tongye1")
      end
      if choice == "tongye2" then
        room:addPlayerMark(player, "@@tongye2")
      end
    end
  end,
}
sunquan:addSkill(mou__zhiheng)
sunquan:addSkill(mou__tongye)
sunquan:addSkill("jiuyuan")
Fk:loadTranslationTable{
  ["mou__sunquan"] = "谋孙权",
  ["mou__zhiheng"] = "制衡",
  [":mou__zhiheng"] = "出牌阶段限一次，你可以弃置任意张牌并摸等量的牌。若你以此法弃置了所有的手牌，你多摸1+X张牌(X为你的“业”数)，然后你弃置一枚“业”。",
  ["mou__tongye"] = "统业",
  [":mou__tongye"] = "锁定技，结束阶段，你可以猜测场上的装备数量于你的下个准备阶段开始时有无变化。若你猜对，你获得一枚“业”，猜错，你弃置一枚“业”。",
    ["@tongye"] = "业",
    ["@@tongye1"] = "统业猜测:有变化",
    ["@@tongye2"] = "统业猜测:无变化",
  
}
local mouzhouyu = General(extension, "mou__zhouyu", "wu", 3)
local mou__yingzi = fk.CreateTriggerSkill{
  name = "mou__yingzi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
     return target == player and player:hasSkill(self.name) and (#player.player_cards[Player.Hand] > 1 or #player.player_cards[Player.Equip] > 0 or player.hp > 1)
  end,
  on_use = function(self, event, target, player, data)
     if player.hp > 1 then
       player.room:addPlayerMark(player, "mou__yingzi-turn", 1)
     end
     if #player.player_cards[Player.Hand] > 1 then
       player.room:addPlayerMark(player, "mou__yingzi-turn", 1)
     end
     if #player.player_cards[Player.Equip] > 0 then
       player.room:addPlayerMark(player, "mou__yingzi-turn", 1)
     end
     data.n = data.n+player:getMark("mou__yingzi-turn")
  end,
}
local mou__yingzi_maxcards = fk.CreateMaxCardsSkill{
  name = "#mou__yingzi_maxcards",
  correct_func = function(self, player)
    if player:hasSkill("mou__yingzi") then
      return player:getMark("mou__yingzi-turn")
    else
      return 0
    end
  end,
}
mou__yingzi:addRelatedSkill(mou__yingzi_maxcards)

local mou__fanjian = fk.CreateActiveSkill{
  name = "mou__fanjian",
  anim_type = "control",
  interaction = function(self)
    local choiceList = {"spade", "heart", "club", "diamond"}
    return UI.ComboBox { choices = choiceList }
  end,
  card_num = 1,
  target_num = 1,
   can_use = function(self, player)
     return player:getMark("mou__fanjian-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    if Self:getMark("moufanjianRecord-turn") ~= 0 then
      local suitsx = Self:getMark("moufanjianRecord-turn")
      suitsx = suitsx:split("+")
     return not table.contains(suitsx, Fk:getCardById(to_select):getSuitString())
    else return true end
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
      local player = room:getPlayerById(effect.from)
      local target = room:getPlayerById(effect.tos[1])
      room:sendLog{
        type = "#fanjian_log",
        from = player.id,
        arg = self.interaction.data,
        arg2 = self.name
      }
      local choiceList = { "mou__fanjian_true","mou__fanjian_false", "mou__fanjian_fanmian" }
    local choice = room:askForChoice(player, choiceList , self.name,"#mou__fanjian-active:::"..self.interaction.data)
    if choice == "mou__fanjian_fanmian" then
      target:turnOver()
    elseif choice == "mou__fanjian_true" then
      if self.interaction.data == Fk:getCardById(effect.cards[1]):getSuitString() then 
        room:setPlayerMark(player, "mou__fanjian-turn", 1)
      else 
        room:loseHp(target, 1, self.name)
      end
    elseif choice == "mou__fanjian_false" then
      if self.interaction.data ~= Fk:getCardById(effect.cards[1]):getSuitString() then 
        room:setPlayerMark(player, "mou__fanjian-turn", 1)
      else 
        room:loseHp(target, 1, self.name)
      end
    end
     if not target.dead then
        room:obtainCard(target.id, effect.cards[1], false, fk.ReasonGive)
     end
      local suit = Fk:getCardById(effect.cards[1]):getSuitString()
      if table.contains({ "spade", "heart", "club", "diamond" }, suit) then
        local m = player:getMark("moufanjianRecord-turn")
        if m == 0 then
          m = suit
        elseif type(m) == "string" then
          local suits = m:split("+")
          table.insertIfNeed(suits, suit)
          m = table.concat(suits, "+")
        end
        room:setPlayerMark(player, "moufanjianRecord-turn", m)
        local card_suits_table = {
          spade = "♠",
          club = "♣",
          heart = "♥",
          diamond = "♦",
        }
        room:setPlayerMark(player, "@moufanjianRecord-turn", table.concat(
          table.map(m:split("+"), function(s) return card_suits_table[s] end)
          , ""))
      end
  end,
}
mouzhouyu:addSkill(mou__yingzi)
mouzhouyu:addSkill(mou__fanjian)
Fk:loadTranslationTable{
  ["mou__zhouyu"] = "谋周瑜",
  ["mou__yingzi"] = "英姿",
  ["#mou__yingzi_maxcards"] = "英姿",
  [":mou__yingzi"] = "锁定技，摸牌阶段开始时，你每满足以下一项条件此摸牌阶段摸牌基数和本回合手牌上限便+1，你的手牌数不少于2，你的装备区内牌数不少于1，你的体力值不少于2。",
  ["mou__fanjian"] = "反间",
  [":mou__fanjian"] = "出牌阶段，你可以选择一名其他角色和一张牌(每种花色每回合限一次)并声明一个花色，其须选择一项:①猜测此牌花色是否与你声明的花色相同;②翻面。;然后其正面向上获得此牌。若其选择猜测且猜测错误，其失去1点体力，否则其令你〖反间〗于本回合失效。",
  ["mou__fanjian_true"] = "花色相同",
  ["mou__fanjian_false"] = "花色不相同",
  ["mou__fanjian_fanmian"] = "你翻面",
  
  ["#mou__fanjian-active"] = "反间:请猜测选择的牌花色是否与%arg 相同或者选择翻面。",
  ["#fanjian_log"] = "%from 发动了“%arg2”，声明的花色为 【%arg】。",
  ["@moufanjianRecord-turn"] = "反间",
  
  ["$mou__yingzi1"] = "交之总角，付之九州！",
  ["$mou__yingzi2"] = "定策分两治，纵马饮三江！",
  ["$mou__fanjian1"] = "若不念汝三世之功，今日定斩不赦！",
  ["$mou__fanjian2"] = "比之自内，不自失也！",
  ["~mou__zhouyu"] = "瑜虽不惧曹军，但惧白驹过隙……",
}
return extension
