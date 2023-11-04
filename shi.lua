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
    return target == player and player:hasSkill(self) and
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
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
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
      return player:hasSkill(self) and target == player and data.card.name == "iron_chain" and player:getMark("mou__lianhuan_levelup") == 0 and player.hp > 0
    else
      local room = player.room
      local to = room:getPlayerById(data.to)
      if player:hasSkill(self) and target == player and data.card.name == "iron_chain" and not (to.dead or to.chained or to:isKongcheng()) then
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
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
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
local mou__xuhuang = General:new(extension, "mou__xuhuang", "wei", 4, 4)
local mou__duanliang = fk.CreateActiveSkill{
  name = "mou__duanliang",
  anim_type = "control",
  mute = true,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  card_filter = function() return false end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name, 1)
    local choice = room:askForChoice(player, {"mou__duanliang-weicheng" ,"mou__duanliang-jinjun"}, self.name,"#mou__duanliang-active")
    local choice1 = room:askForChoice(to, {"mou__duanliang-tuji" ,"mou__duanliang-shoucheng"} , self.name,"#mou__duanliang-active")
    local jieguo
    if (choice == "mou__duanliang-weicheng" and choice1 ~= "mou__duanliang-tuji") or (choice == "mou__duanliang-jinjun" and choice1 ~= "mou__duanliang-shoucheng") then
      jieguo = "谋奕成功"
    else
      jieguo = "谋奕失败"
      player:broadcastSkillInvoke(self.name, 4)
    end
    room:doBroadcastNotify("ShowToast", Fk:translate(jieguo))
    if choice == "mou__duanliang-weicheng" then
      if choice1 ~= "mou__duanliang-tuji" then
        player:broadcastSkillInvoke(self.name, 2)
        local use
        if #room.draw_pile > 0 then
          local id = room.draw_pile[1]
          local card = Fk:cloneCard("supply_shortage")
          card:addSubcard(id)
          if not to:hasDelayedTrick("supply_shortage") and not player:isProhibited(to, card) then
            room:useVirtualCard("supply_shortage", {id}, player, to, self.name)
            use = true
          end
        end
        if not use and not to:isNude() then
          local id = room:askForCardChosen(player, to, "he", self.name)
          room:obtainCard(player, id, false, fk.ReasonPrey)
        end
      end
    else
      if choice1 ~= "mou__duanliang-shoucheng" then
        player:broadcastSkillInvoke(self.name, 3)
        if not player:isProhibited(to, Fk:cloneCard("duel")) then
          room:useVirtualCard("duel", nil, player, to, self.name)
        end
      end
    end
  end,
}
mou__xuhuang:addSkill(mou__duanliang)
local mou__shipo = fk.CreateTriggerSkill{
  name = "mou__shipo",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      return table.find(player.room:getOtherPlayers(player), function (p) return p.hp < player.hp or p:hasDelayedTrick("supply_shortage") end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets1 = table.filter(player.room.alive_players, function (p) return p.hp < player.hp end)
    local targets2 = table.filter(player.room:getOtherPlayers(player), function (p) return p:hasDelayedTrick("supply_shortage") end)
    local choices = {}
    if #targets1 > 0 then table.insert(choices, "mou__shipo_choice1") end
    if #targets2 > 0 then table.insert(choices, "mou__shipo_choice2") end
    local choice = room:askForChoice(player, choices, self.name, "#mou__shipo-choose")
    local targets = {}
    if choice == "mou__shipo_choice2" then
      targets = targets2
    else
      local tos = room:askForChoosePlayers(player, table.map(targets1, Util.IdMapper), 1, 1, "#mou__shipo-choose", self.name, false)
      targets = {room:getPlayerById(tos[1])}
    end
    for _, to in ipairs(targets) do
      if player.dead then break end
      local card = room:askForCard(to, 1, 1, false, self.name, true, ".", "#mou__shipo-give::"..player.id)
      if #card > 0 then
        local get = card[1]
        room:obtainCard(player, get, false, fk.ReasonGive)
        if room:getCardArea(get) == Card.PlayerHand and room:getCardOwner(get) == player then
          local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#mou__shipo-present:::"..Fk:getCardById(get):toLogString(), self.name, true)
          if #tos > 0 then
            room:obtainCard(tos[1], get, false, fk.ReasonGive)
          end
        end
      else
        room:damage { from = player, to = to, damage = 1, skillName = self.name }
      end
    end
  end,
}
mou__xuhuang:addSkill(mou__shipo)
Fk:loadTranslationTable{
  ["mou__xuhuang"] = "谋徐晃",
  
  ["mou__duanliang"] = "断粮",
  [":mou__duanliang"] = "出牌阶段限一次，你可以与一名其他角色进行一次“谋弈”：<br>围城断粮，你将牌堆顶的一张牌当无距离限制的【兵粮寸断】对其使用，若无法使用改为你获得其一张牌；<br>擂鼓进军，你视为对其使用一张【决斗】。",
  ["mou__duanliang-weicheng"] = "围城断粮: 谋奕成功后视为使用【兵粮寸断】",
  ["mou__duanliang-jinjun"] = "擂鼓进军:谋奕成功后视为使用【决斗】",
  ["mou__duanliang-tuji"] = "全军突击:用于防御围城断粮(兵粮寸断)",
  ["mou__duanliang-shoucheng"] = "闭门守城:用于防御擂鼓进军(决斗)",
  ["#mou__duanliang-active"] = "断粮：请选择你需要进行谋奕的选项",

  ["mou__shipo"] = "势迫",
  [":mou__shipo"] = "结束阶段，你可以令一名体力值小于你的角色或所有判定区里有【兵粮寸断】的其他角色选择一项：1.交给你一张手牌，且你可以将此牌交给一名其他角色；2.受到1点伤害。",
  ["mou__shipo_choice1"] = "选择一名体力值小于你的角色",
  ["mou__shipo_choice2"] = "所有判定区里有【兵粮寸断】的其他角色",
  ["#mou__shipo-choose"] = "选择“势迫”的目标",
  ["#mou__shipo-give"] = "势迫：你须交给%dest一张手牌，否则受到1点伤害",
  ["#mou__shipo-present"] = "势迫：你可以将%arg交给一名其他角色",

  ["$mou__duanliang1"] = "常读兵法，终有良策也！",
  ["$mou__duanliang2"] = "烧敌粮草，救主于危急！",
  ["$mou__duanliang3"] = "敌陷混乱之机，我军可长驱直入！",
  ["$mou__duanliang4"] = "敌既识破吾计，则断不可行矣！",
  ["$mou__shipo1"] = "已向尔等陈明利害，奉劝尔等早日归降！",
  ["$mou__shipo2"] = "此时归降或可封赏，即至城破必斩无赦！",
  ["~mou__xuhuang"] = "为主效劳，何畏生死……",
}

local mou__ganning = General(extension, "mou__ganning", "wu", 4)
local mou__qixi = fk.CreateActiveSkill{
  name = "mou__qixi",
  anim_type = "control",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local suits = {"spade","club","heart","diamond","nosuit"}
    local num = {0,0,0,0,0}
    local max_num = 0
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      num[card.suit] = num[card.suit] + 1
      max_num = math.max(max_num, num[card.suit])
    end
    local max_suit = {}
    for i = 1, 5 do
      if num[i] == max_num then
        table.insert(max_suit, suits[i])
      end
    end
    local choice = room:askForChoice(to, suits, self.name, "#mou__qixi-guess::"..player.id)
    local wrong_num = 0
    local right = table.contains(max_suit, choice)
    if not right then
      wrong_num = wrong_num + 1
      if room:askForSkillInvoke(player, self.name, nil, "#mou__qixi-again") then
        table.removeOne(suits, choice)
        choice = room:askForChoice(to, suits, self.name, "#mou__qixi-guess::"..player.id)
        if table.contains(max_suit, choice) then
          right = true
        else
          wrong_num = wrong_num + 1
        end
      end
    end
    if right and not player:isKongcheng() then
      player:showCards(player:getCardIds("h"))
    end
    local throw_num = math.min(#to:getCardIds("hej"), wrong_num)
    if player.dead or throw_num == 0 then return end
    local throw = room:askForCardsChosen(player, to, throw_num, throw_num, "hej", self.name)
    room:throwCard(throw, self.name, to, player)
  end
}
mou__ganning:addSkill(mou__qixi)
local mou__fenwei = fk.CreateActiveSkill{
  name = "mou__fenwei",
  anim_type = "control",
  min_card_num = 1,
  max_card_num = 1,
  min_target_num = 1,
  max_target_num = 3,
  frequency = Skill.Limited,
  target_filter = function(self, to_select, selected)
    return #selected < 3
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 3
  end,
  feasible = function(self, selected, selected_cards)
    return #selected >= 1 and #selected <= 3 and #selected_cards == #selected
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not player:isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for i, to in ipairs(table.map(effect.tos, Util.Id2PlayerMapper)) do
      to:addToPile("@mou__fenwei", effect.cards[i], true, self.name)
    end
    player:drawCards(#effect.cards, self.name)
  end,
}
local mou__fenwei_trigger = fk.CreateTriggerSkill{
  name = "#mou__fenwei_trigger",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.type == Card.TypeTrick and #target:getPile("@mou__fenwei") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"#mou__fenwei_get" , "#mou__fenwei_cancel"}, self.name, "#mou__fenwei-choice::"..target.id..":"..data.card:toLogString())
    if choice == "#mou__fenwei_get" then
      local dummy = Fk:cloneCard("slash")
      dummy:addSubcards(target:getPile("@mou__fenwei"))
      room:obtainCard(target, dummy, true, fk.ReasonJustMove)
    else
      room:moveCards({
        from = target.id,
        ids = target:getPile("@mou__fenwei"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
      AimGroup:cancelTarget(data, target.id)
    end
  end,
}
mou__fenwei:addRelatedSkill(mou__fenwei_trigger)
mou__ganning:addSkill(mou__fenwei)
Fk:loadTranslationTable{
  ["mou__ganning"] = "谋甘宁",
  ["mou__qixi"] = "奇袭",
  [":mou__qixi"] = "出牌阶段限一次，你可以选择一名其他角色，令其猜测你手牌中最多的花色。若猜错，你可以令该角色从未猜测过的花色中再次猜测；若猜对，你展示所有手牌。然后你弃置其区域内X张牌（X为此阶段该角色猜错的次数，不足则全弃）。",
  ["#mou__qixi-again"] = "奇袭：你可以令其再猜一次",
  ["#mou__qixi-guess"] = "奇袭：猜测%dest手牌中最多的花色",
  ["mou__fenwei"] = "奋威",
  [":mou__fenwei"] = "限定技，出牌阶段，你可以将至多三张牌分别置于等量名角色的武将牌上，称为“威”，然后你摸等量牌。有“威”的角色成为锦囊牌的目标时，你须选择一项：1. 令其获得“威”；2. 移去其“威”，取消此目标。",
  ["@mou__fenwei"] = "威",
  ["#mou__fenwei_trigger"] = "奋威",
  ["#mou__fenwei-choice"] = "奋威：1. 令%dest获得“威”；2. 移去“威”，令%arg的目标取消%dest",
  ["#mou__fenwei_get"] = "令其获得“威”",
  ["#mou__fenwei_cancel"] = "移去“威”,取消目标",
  ["$mou__qixi1"] = "击敌不备，奇袭拔寨！",
  ["$mou__qixi2"] = "轻羽透重铠，奇袭溃坚城！",
  ["$mou__fenwei1"] = "舍身护主，扬吴将之风！",
  ["$mou__fenwei2"] = "袭军挫阵，奋江东之威！",
  ["~mou__ganning"] = "蛮将休得猖狂！呃啊！",
}



return extension
