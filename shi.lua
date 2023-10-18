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
local mou__lianhuan = fk.CreateActiveSkill{
  name = "mou__lianhuan",
  mute = true,
  card_num = 1,
  min_target_num = 0,
  prompt = "#mou__lianhuan",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, selected_targets)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Club and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards ~= 1 or Self:getMark("mou__lianhuan_used-phase") > 0 then return false end
    local card = Fk:cloneCard("iron_chain")
    card:addSubcard(selected_cards[1])
    return card.skill:canUse(Self, card) and card.skill:targetFilter(to_select, selected, selected_cards, card) and
      not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), card)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke(self.name)
    if #effect.tos == 0 then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:recastCard(effect.cards, player, self.name)
    else
      room:notifySkillInvoked(player, self.name, "control")
      room:sortPlayersByAction(effect.tos)
      room:addPlayerMark(player, "mou__lianhuan_used-phase")
      room:useVirtualCard("iron_chain", effect.cards, player, table.map(effect.tos, function(id)
        return room:getPlayerById(id) end), self.name)
    end
  end,
}
local mou__lianhuan_targetmod = fk.CreateTargetModSkill{
  name = "#mou__lianhuan_targetmod",
  extra_target_func = function(self, player, skill, card)
    if card and card.name == "iron_chain" and player:getMark("mou__lianhuan_levelup") > 0  then
      return 999
    end
  end,
}
mou__lianhuan:addRelatedSkill(mou__lianhuan_targetmod)
local mou__lianhuan_ts = fk.CreateTriggerSkill{
  name = "#mou__lianhuan_ts",
  anim_type = "control",
  events = {fk.CardUsing , fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return player:hasSkill(self.name) and target == player and data.card.name == "iron_chain" and player:getMark("mou__lianhuan_levelup") == 0 and player.hp > 0
    else
      local room = player.room
      local to = room:getPlayerById(data.to)
      if player:hasSkill(self.name) and target == player and data.card.name == "iron_chain" and not (to.dead or to.chained or to:isKongcheng()) then
        local use_data = room.logic:getCurrentEvent()
        return player:getMark("mou__lianhuan_levelup") > 0 or (use_data and use_data.data[1].extra_data and use_data.data[1].extra_data.mou__lianhuan_used)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      return room:askForSkillInvoke(player, self.name, nil, "#mou__lianhuan-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      data.extra_data = data.extra_data or {}
      data.extra_data.mou__lianhuan_used = true
      room:loseHp(player, 1, self.name)
    else
      local to = room:getPlayerById(data.to)
      if to:isKongcheng() then return false end
      local throw = table.random(to:getCardIds("h"), 1)
      room:throwCard(throw, self.name, to, player)
    end
  end,
}
mou__lianhuan:addRelatedSkill(mou__lianhuan_ts)
local mou__niepan = fk.CreateTriggerSkill{
  name = "mou__niepan",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("hej")
    if player.dead then return end
    if not player.faceup then
      player:turnOver()
    end
    if player.chained then
      player:setChainState(false)
    end
    player:drawCards(2, self.name)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = math.min(2, player.maxHp) - player.hp,
        recoverBy = player,
        skillName = self.name,
      })
    end
    room:addPlayerMark(player, "mou__lianhuan_levelup")
  end,
}

local mou__pangtong = General:new(extension, "mou__pangtong", "shu", 3, 3)
mou__pangtong:addSkill(mou__lianhuan)
mou__pangtong:addSkill(mou__niepan)

Fk:loadTranslationTable{
  ["mou__pangtong"] = "谋庞统",

  ["mou__lianhuan"] = "连环",
  [":mou__lianhuan"] = "出牌阶段，你可以将一张梅花手牌当【铁索连环】使用（每个出牌阶段限一次）或重铸；当你使用【铁索连环】时，你可以失去1点体力。若如此做，当此牌指定一名角色为目标后，若其未横置，你随机弃置其一张手牌。",
  ["#mou__lianhuan"] = "连环：你可以将一张手牌当【铁索连环】使用（每个出牌阶段限一次）或重铸",
  ["#mou__lianhuan_ts"] = "连环",
  ["#mou__lianhuan-invoke"] = "连环：你可以失去1点体力，当此【铁索连环】指定未横置的角色为目标后，你随机弃置其一张手牌",

  ["mou__niepan"] = "涅槃",
  [":mou__niepan"] = "限定技，当你处于濒死状态时，你可以弃置区域里的所有牌，复原你的武将牌，然后摸两张牌并将体力回复至2点，最后修改〖连环〗。<br><b>连环·修改：</b>出牌阶段，你可以将一张梅花手牌当【铁索连环】使用（每个出牌阶段限一次）或重铸；你使用【铁索连环】可以额外指定任意名角色为目标；当你使用【铁索连环】指定一名角色为目标后，若其未横置，你随机弃置其一张手牌。",
}

return extension
