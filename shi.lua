local extension = Package("mou_shi")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_shi"] = "谋攻篇-识包",
}
local mou__tieji = fk.CreateTriggerSkill{
  name = "mou__tieji",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name, 1)
    local to = room:getPlayerById(data.to)
    data.disresponsive = true
    room:addPlayerMark(to, "@@tieji-turn")
    room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
    local choice = room:askForChoice(player, {"tieji-zhiqu" ,"tieji-raozheng"}, self.name,"#mou__tieji-active")
    local choice1 = room:askForChoice(to, {"tieji-chuzheng" ,"tieji-huwei"} , self.name,"#mou__tieji-active")
    local jieguo
    if (choice == "tieji-zhiqu" and choice1 ~= "tieji-chuzheng") or (choice == "tieji-raozheng" and choice1 ~= "tieji-huwei") then
      jieguo = "谋奕成功"
    else
      jieguo = "谋奕失败"
    end
    room:doBroadcastNotify("ShowToast", Fk:translate(jieguo))
    if choice == "tieji-zhiqu" and choice1 ~= "tieji-chuzheng" then
      player:broadcastSkillInvoke(self.name, 2)
      if not to:isNude() then
        local card = room:askForCardChosen(player, to, "he", self.name)
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
    elseif choice == "tieji-raozheng" and choice1 ~= "tieji-huwei" then
      player:broadcastSkillInvoke(self.name, 3)
      player:drawCards(2, self.name)
    else
      player:broadcastSkillInvoke(self.name, 4)
    end
  end,
}
local machao = General:new(extension, "mou__machao", "shu", 4)
machao:addSkill("mashu")
machao:addSkill(mou__tieji)
Fk:loadTranslationTable{
  ["mou__machao"] = "谋马超",
  ["mou__tieji"] = "铁骑",
  [":mou__tieji"] = "你可以令目标角色不能响应此【杀】，且其所有非锁定技失效直到回合结束。然后你与其进行谋弈。若你赢，且你选择的选项为：“直取敌营”，则你获得其一张牌；“扰阵疲敌”，你摸两张牌。",
  ["tieji-zhiqu"] = "直取敌营: 谋奕成功后获得对方一张牌",
  ["tieji-raozheng"] = "扰阵疲敌:谋奕成功后你摸两张牌",
  ["tieji-chuzheng"] = "出阵迎敌:用于防御直取敌营",
  ["tieji-huwei"] = "拱卫中军:用于防御扰阵疲敌",
  ["#mou__tieji-active"] = "铁骑:请选择你需要进行谋奕的选项",
  ["#tieji_log"] = "%from 发动了“%arg2”谋奕结果为【%arg】。",

  ["$mou__tieji1"] = "厉马秣兵，只待今日！",
  ["$mou__tieji2"] = "敌军防备空虚，出击直取敌营！",
  ["$mou__tieji3"] = "敌军早有防备，先行扰阵疲敌！",
  ["$mou__tieji4"] = "全军速撤回营，以期再觅良机！",
  ["~mou__machao"] = "父兄妻儿具丧，吾有何面目活于世间……",
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

  ["$mou__lijian1"] = "太师若献妾于吕布，妾宁死不受此辱。",
  ["$mou__lijian2"] = "贱妾污浊之身，岂可复侍将军。",
  ["$mou__biyue1"] = "薄酒醉红颜，广袂羞掩面。",
  ["$mou__biyue2"] = "芳草更芊芊，荷池映玉颜。",
  ["~mou__diaochan"] = "终不负阿父之托……",
}

return extension
