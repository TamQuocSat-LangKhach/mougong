local extension = Package("mou_shi")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_shi"] = "谋攻篇-识包",
}
local U = require "packages/utility/utility"

local machao = General:new(extension, "mou__machao", "shu", 4)
local mou__tieji = fk.CreateTriggerSkill{
  name = "mou__tieji",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to ~= player.id and
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
    local choices = U.doStrategy(room, player, to, {"tieji-zhiqu","tieji-raozheng"}, {"tieji-chuzheng","tieji-huwei"}, self.name, 1)
    if choices[1] == "tieji-zhiqu" and choices[2] ~= "tieji-chuzheng" then
      player:broadcastSkillInvoke(self.name, 2)
      if not to:isNude() then
        local card = room:askForCardChosen(player, to, "he", self.name)
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
    elseif choices[1] == "tieji-raozheng" and choices[2] ~= "tieji-huwei" then
      player:broadcastSkillInvoke(self.name, 3)
      player:drawCards(2, self.name)
    else
      player:broadcastSkillInvoke(self.name, 4)
    end
  end,
}
machao:addSkill("mashu")
machao:addSkill(mou__tieji)
Fk:loadTranslationTable{
  ["mou__machao"] = "谋马超",
  ["#mou__machao"] = "阻戎负勇",
  ["mou__tieji"] = "铁骑",
  [":mou__tieji"] = "每当你使用【杀】指定其他角色为目标后，你可令其不能响应此【杀】，且所有非锁定技失效直到回合结束。然后你与其进行谋弈。若你赢，且你选择的选项为：“直取敌营”，则你获得其一张牌；“扰阵疲敌”，你摸两张牌。",
  ["tieji-zhiqu"] = "直取敌营",
  ["tieji-raozheng"] = "扰阵疲敌",
  ["tieji-chuzheng"] = "出阵迎敌",
  ["tieji-huwei"] = "拱卫中军",
  [":tieji-zhiqu"] = "谋奕成功后，获得对方一张牌",
  [":tieji-raozheng"] = "谋奕成功后，你摸两张牌",
  [":tieji-chuzheng"] = "用于防御“直取敌营”(防止其获得你牌)",
  [":tieji-huwei"] = "用于防“御扰阵疲敌”(防止其摸两张牌)",

  ["$mou__tieji1"] = "厉马秣兵，只待今日！",
  ["$mou__tieji2"] = "敌军防备空虚，出击直取敌营！",
  ["$mou__tieji3"] = "敌军早有防备，先行扰阵疲敌！",
  ["$mou__tieji4"] = "全军速撤回营，以期再觅良机！",
  ["~mou__machao"] = "父兄妻儿具丧，吾有何面目活于世间……",
}

local mou__fazheng = General(extension, "mou__fazheng", "shu", 3)
local mou__xuanhuo = fk.CreateActiveSkill{
  name = "mou__xuanhuo",
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function (self, to_select, selected)
    return #selected == 0
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@@mou__xuanhuo") == 0
  end,
  on_use = function(self, room, effect)
    local to = room:getPlayerById(effect.tos[1])
    room:obtainCard(to, effect.cards[1], false, fk.ReasonGive)
    room:setPlayerMark(to, "@@mou__xuanhuo", 1)
  end,
}
local mou__xuanhuo_delay = fk.CreateTriggerSkill{
  name = "#mou__xuanhuo_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local tos = {}
      local mark = player:getTableMark("mou__xuanhuo_count")
      for _, move in ipairs(data) do
        if move.to and move.toArea == Card.PlayerHand and move.to ~= player.id then
          local to = player.room:getPlayerById(move.to)
          if to.phase ~= Player.Draw and not to:isKongcheng() and to:getMark("@@mou__xuanhuo") > 0
          and (mark[tostring(move.to)] or 0) < 5 then
            table.insertIfNeed(tos, move.to)
          end
        end
      end
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, pid in ipairs(self.cost_data) do
      if player.dead then return end
      local to = room:getPlayerById(pid)
      local mark = player:getTableMark("mou__xuanhuo_count")
      local count = mark[tostring(to.id)] or 0
      if not to:isKongcheng() and count < 5 then
        mark[tostring(to.id)] = count + 1
        room:setPlayerMark(player, "mou__xuanhuo_count", mark)
        room:obtainCard(player, table.random(to:getCardIds("h")), false, fk.ReasonPrey)
      end
    end
  end,
}
mou__xuanhuo:addRelatedSkill(mou__xuanhuo_delay)
mou__fazheng:addSkill(mou__xuanhuo)
local mou__enyuan = fk.CreateTriggerSkill{
  name = "mou__enyuan",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Start
    and table.find(player.room:getOtherPlayers(player), function(p) return p:getMark("@@mou__xuanhuo") > 0 end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:getMark("@@mou__xuanhuo") > 0 then
        room:setPlayerMark(p, "@@mou__xuanhuo", 0)
        local mark = player:getTableMark("mou__xuanhuo_count")
        local count = mark[tostring(p.id)] or 0
        if count >= 3 then
          player:broadcastSkillInvoke(self.name, 1)
          if not player:isNude() then
            local cards = #player:getCardIds("he") < 3 and player:getCardIds("he") or
            room:askForCard(player, 3, 3, true, self.name, false, ".", "#mou__enyuan-give:"..p.id)
            room:obtainCard(p, cards, false, fk.ReasonGive)
          end
        else
          player:broadcastSkillInvoke(self.name, 2)
          room:loseHp(p, 1, self.name)
          if not player.dead and player:isWounded() then
            room:recover { num = 1, skillName = self.name, who = player , recoverBy = player}
          end
        end
      end
    end
    room:setPlayerMark(player, "mou__xuanhuo_count", 0)
  end,
}
mou__fazheng:addSkill(mou__enyuan)
Fk:loadTranslationTable{
  ["mou__fazheng"] = "谋法正",
  ["#mou__fazheng"] = "经学思谋",
  ["mou__xuanhuo"] = "眩惑",
  [":mou__xuanhuo"] = "出牌阶段限一次，你可以交给一名没有“眩”标记的其他角色一张牌并令其获得“眩”标记。有“眩”标记的角色于摸牌阶段外获得牌时，你随机获得其一张手牌（每个“眩”标记最多令你获得五张牌）。",
  ["@@mou__xuanhuo"] = "眩",
  ["mou__enyuan"] = "恩怨",
  [":mou__enyuan"] = "锁定技，准备阶段，若有“眩”标记的角色自其获得“眩”标记开始你获得其的牌数：不小于3，你移除其“眩”标记，然后交给其三张牌；小于3，其移除“眩”标记并失去1点体力，然后你回复1点体力。",
  ["#mou__enyuan-give"] = "恩怨：交给 %src 三张牌",
  
  ["$mou__xuanhuo1"] = "虚名虽然无用，可沽万人之心。",
  ["$mou__xuanhuo2"] = "效金台碣馆之事，布礼贤仁德之名。",
  ["$mou__enyuan1"] = "恩如泰山，当还以东海。",
  ["$mou__enyuan2"] = "汝既负我，哼哼，休怪军法无情！",
  ["~mou__fazheng"] = "蜀翼双折，吾主王业，就靠孔明了……",
}

local mou__lijian = fk.CreateActiveSkill{
  name = "mou__lijian",
  anim_type = "offensive",
  min_card_num = 1,
  min_target_num = 2,
  prompt = function (self, selected_cards)
    return "#mou__lijian:::"..#selected_cards..":"..(#selected_cards + 1)
  end,
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
  feasible = function (self, selected, selected_cards)
    return #selected > 1 and #selected == #selected_cards + 1
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
    player.room.logic:getActualDamageEvents(999, function(e)
      table.insertIfNeed(targets, e.data[1].to.id)
    end, Player.HistoryTurn)
    player:drawCards(math.min(1 + #targets, 5), self.name)
  end,
}
local diaochan = General:new(extension, "mou__diaochan", "qun", 3, 3, General.Female)
diaochan:addSkill(mou__lijian)
diaochan:addSkill(mou__biyue)
Fk:loadTranslationTable{
  ["mou__diaochan"] = "谋貂蝉",
  ["#mou__diaochan"] = "绝世的舞姬",
  ["mou__lijian"] = "离间",
  [":mou__lijian"] = "出牌阶段限一次，你可以选择至少两名其他角色并弃置X张牌（X为你选择的角色数-1），然后他们依次对逆时针最近座次的你选择的另一名角色视为使用一张【决斗】。",
  ["mou__biyue"] = "闭月",
  [":mou__biyue"] = "回合结束时，你可以摸X张牌（X为本回合内受到过伤害的角色数+1且至多为5）。",
  ["#mou__lijian"] = "离间：弃置%arg张牌，令%arg2名角色互相决斗！",

  ["$mou__lijian1"] = "太师若献妾于吕布，妾宁死不受此辱。",
  ["$mou__lijian2"] = "贱妾污浊之身，岂可复侍将军。",
  ["$mou__biyue1"] = "薄酒醉红颜，广袂羞掩面。",
  ["$mou__biyue2"] = "芳草更芊芊，荷池映玉颜。",
  ["~mou__diaochan"] = "终不负阿父之托……",
}

local mou__chengong = General(extension, "mou__chengong", "qun", 3)
local mou__mingce = fk.CreateActiveSkill{
  name = "mou__mingce",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#mou__mingce",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive)
    if player.dead or target.dead then return end
    if room:askForChoice(target, {"mou__mingce_losehp:"..player.id, "draw1"}, self.name) == "draw1" then
      target:drawCards(1, self.name)
    else
      room:loseHp(target, 1, self.name)
      if not player.dead then
        player:drawCards(2, self.name)
        room:addPlayerMark(player, "@mou__mingce")
      end
    end
  end,
}
local mou__mingce_trigger = fk.CreateTriggerSkill{
  name = "#mou__mingce_trigger",
  events = {fk.EventPhaseStart},
  main_skill = mou__mingce,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:getMark("@mou__mingce") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#mou__mingce-choose:::"..player:getMark("@mou__mingce"), self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(mou__mingce.name)
    local to = room:getPlayerById(self.cost_data)
    room:damage { from = player, to = to, damage = player:getMark("@mou__mingce"), skillName = self.name }
    room:setPlayerMark(player, "@mou__mingce", 0)
  end,
}
mou__mingce:addRelatedSkill(mou__mingce_trigger)
mou__chengong:addSkill(mou__mingce)
local mou__zhichi = fk.CreateTriggerSkill{
  name = "mou__zhichi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@mou__zhichi-turn", 1)
  end,
}
local mou__zhichi_delay = fk.CreateTriggerSkill{
  name = "#mou__zhichi_delay",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@mou__zhichi-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(mou__zhichi.name)
    player.room:sendLog{ type = "#PreventDamageBySkill", from = player.id, arg = mou__zhichi.name }
    return true
  end,
}
mou__zhichi:addRelatedSkill(mou__zhichi_delay)
mou__chengong:addSkill(mou__zhichi)
Fk:loadTranslationTable{
  ["mou__chengong"] = "谋陈宫",
  ["#mou__chengong"] = "刚直壮烈",
  ["mou__mingce"] = "明策",
  [":mou__mingce"] = "①出牌阶段限一次，你可以交给一名其他角色一张牌，令其选择一项：1.失去1点体力，令你摸两张牌并获得1个“策”标记；2.摸一张牌。<br>"..
  "②出牌阶段开始时，若你拥有“策”标记，你可以选择一名其他角色，对其造成X点伤害并移去所有“策”标记（X为你的“策”标记数）。",
  ["#mou__mingce"] = "明策：交给一名角色一张牌，其选择失去体力令你摸牌，或其摸一张牌",
  ["mou__mingce_losehp"] = "你失去1点体力，令%src摸两张牌并获得“策”标记",
  ["#mou__mingce-choose"] = "明策：移去所有“策”标记，对一名其他角色造成 %arg 点伤害",
  ["@mou__mingce"] = "策",
  ["#mou__mingce_trigger"] = "明策",
  ["mou__zhichi"] = "智迟",
  [":mou__zhichi"] = "锁定技，当你受到伤害后，防止本回合你受到的伤害。",
  ["@@mou__zhichi-turn"] = "智迟",
  ["#PreventDamageBySkill"] = "由于 %arg 的效果，%from 受到的伤害被防止",

  ["$mou__mingce1"] = "行吾此计，可使将军化险为夷。",
  ["$mou__mingce2"] = "分兵驻扎，可互为掎角之势。",
  ["$mou__zhichi1"] = "哎！怪我智迟，竟少算一步。",
  ["$mou__zhichi2"] = "将军勿急，我等可如此行事。",
  ["~mou__chengong"] = "何必多言！宫唯求一死……",
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
    not Self:prohibitUse(card) and not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), card)
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
      room:useVirtualCard("iron_chain", effect.cards, player, table.map(effect.tos, Util.Id2PlayerMapper), self.name)
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
    player:reset()
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
  ["#mou__pangtong"] = "凤雏",
	["illustrator:mou__pangtong"] = "铁杵文化",

  ["mou__lianhuan"] = "连环",
  [":mou__lianhuan"] = "出牌阶段，你可以将一张♣手牌当【铁索连环】使用（每个出牌阶段限一次）或重铸；当你使用【铁索连环】时，你可以失去1点体力。"..
  "若如此做，当此牌指定一名角色为目标后，若其未横置，你随机弃置其一张手牌。",
  ["#mou__lianhuan"] = "连环：你可以将一张手牌当【铁索连环】使用（每个出牌阶段限一次）或重铸",
  ["#mou__lianhuan_ts"] = "连环",
  ["#mou__lianhuan-invoke"] = "连环：你可以失去1点体力，当此【铁索连环】指定未横置的角色为目标后，你随机弃置其一张手牌",

  ["mou__niepan"] = "涅槃",
  [":mou__niepan"] = "限定技，当你处于濒死状态时，你可以弃置区域里的所有牌，复原你的武将牌，然后摸两张牌并将体力回复至2点，最后修改〖连环〗。<br>"..
  "<b>连环·修改：</b>出牌阶段，你可以将一张♣手牌当【铁索连环】使用（每个出牌阶段限一次）或重铸；你使用【铁索连环】可以额外指定任意名角色为目标；"..
  "当你使用【铁索连环】指定一名角色为目标后，若其未横置，你随机弃置其一张手牌。",

  ["$mou__lianhuan1"] = "任凭潮涌，连环无惧！",
  ["$mou__lianhuan2"] = "并排横江，可利水战！",
  ["$mou__niepan1"] = "凤雏涅槃，只为再生！",
  ["$mou__niepan2"] = "烈火焚身，凤羽更丰！",
  ["~mou__pangtong"] = "落凤坡，果真为我葬身之地……",
}
local mou__xuhuang = General:new(extension, "mou__xuhuang", "wei", 4, 4)
local mou__duanliang = fk.CreateActiveSkill{
  name = "mou__duanliang",
  anim_type = "control",
  mute = true,
  prompt = "#mou__duanliang",
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
    local choices = U.doStrategy(room, player, to, {"mou__duanliang-weicheng","mou__duanliang-jinjun"}, {"mou__duanliang-tuji","mou__duanliang-shoucheng"}, self.name, 1)
    if choices[1] == "mou__duanliang-weicheng" and choices[2] ~= "mou__duanliang-tuji" then
      player:broadcastSkillInvoke(self.name, 2)
      local use
      if #room.draw_pile > 0 then
        local id = room.draw_pile[1]
        local card = Fk:cloneCard("supply_shortage")
        card.skillName = self.name
        card:addSubcard(id)
        if U.canUseCardTo(room, player, to, card, false) then
          room:useVirtualCard("supply_shortage", {id}, player, to, self.name, true)
          use = true
        end
      end
      if not use and not to:isNude() then
        local id = room:askForCardChosen(player, to, "he", self.name)
        room:obtainCard(player, id, false, fk.ReasonPrey)
      end
    elseif choices[1] == "mou__duanliang-jinjun" and choices[2] ~= "mou__duanliang-shoucheng" then
      player:broadcastSkillInvoke(self.name, 3)
      room:useVirtualCard("duel", nil, player, to, self.name)
    else
      player:broadcastSkillInvoke(self.name, 4)
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
  ["#mou__xuhuang"] = "径行截辎",
  ["mou__duanliang"] = "断粮",
  [":mou__duanliang"] = "出牌阶段限一次，你可以与一名其他角色进行一次“谋弈”：<br>围城断粮，你将牌堆顶的一张牌当无距离限制的【兵粮寸断】对其使用，若无法使用改为你获得其一张牌；<br>擂鼓进军，你视为对其使用一张【决斗】。",
  ["#mou__duanliang"] = "断粮：与一名其他角色进行“谋弈”，视为对其使用【兵粮寸断】或【决斗】",
  ["mou__duanliang-weicheng"] = "围城断粮",
  ["mou__duanliang-jinjun"] = "擂鼓进军",
  ["mou__duanliang-tuji"] = "全军突击",
  ["mou__duanliang-shoucheng"] = "闭门守城",
  [":mou__duanliang-weicheng"] = "谋奕成功后，视为使用【兵粮寸断】，若无法使用改为获得其一张牌",
  [":mou__duanliang-jinjun"] = "谋奕成功后，视为使用【决斗】",
  [":mou__duanliang-tuji"] = "用于防御围城断粮：防止其对你使用【兵粮寸断】或获得你一张牌",
  [":mou__duanliang-shoucheng"] = "用于防御擂鼓进军：防止其对你使用【决斗】",

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

local mou__zhanghe = General(extension, "mou__zhanghe", "wei", 4)
local mou__qiaobian = fk.CreateTriggerSkill{
  name = "mou__qiaobian",
  anim_type = "control",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
    data.to > Player.Start and data.to < Player.Discard
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mou__qiaobian-invoke:::" .. Util.PhaseStrMapper(data.to))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:skip(data.to)
    if data.to == Player.Judge then
      room:loseHp(player, 1, self.name)
      if #player:getCardIds("j") > 0 then
        local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#mou__qiaobian-choose", self.name, false)
        if #tos > 0 then
          local to = room:getPlayerById(tos[1])
          local moveInfos = {}
          for _, id in ipairs(player:getCardIds("j")) do
            local vcard = player:getVirualEquip(id)
            local card = vcard or Fk:getCardById(id)
            if to:hasDelayedTrick(card.name) or to.dead or table.contains(to.sealedSlots, Player.JudgeSlot) then
              table.insert(moveInfos, {
                ids = {id},
                from = player.id,
                toArea = Card.DiscardPile,
                moveReason = fk.ReasonPutIntoDiscardPile,
                proposer = player.id,
                skillName = self.name,
              })
            else
              table.insert(moveInfos, {
                ids = {id},
                from = player.id,
                to = to.id,
                toArea = Card.PlayerJudge,
                moveReason = fk.ReasonPut,
                proposer = player.id,
                skillName = self.name,
              })
            end
          end
          room:moveCards(table.unpack(moveInfos))
        end
      end
    elseif data.to == Player.Draw then
      room:setPlayerMark(player, "@@mou__qiaobian_delay", 1)
    else
      player:skip(Player.Discard)
      if player:getHandcardNum() > 6 then
        room:askForDiscard(player, player:getHandcardNum()-6, player:getHandcardNum()-6, false, self.name, false)
        if player.dead then return end
      end
      if #room:canMoveCardInBoard() > 0 then
        local targets = room:askForChooseToMoveCardInBoard(player, "#mou__qiaobian-move", self.name, false)
        if #targets == 2 then
          targets = table.map(targets, Util.Id2PlayerMapper)
          room:askForMoveCardInBoard(player, targets[1], targets[2], self.name)
        end
      end
    end
    return true
  end,
}
local mou__qiaobian_delay = fk.CreateTriggerSkill{
  name = "#mou__qiaobian_delay",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@mou__qiaobian_delay") > 0 and player.phase == Player.Start
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(mou__qiaobian.name)
    room:setPlayerMark(player, "@@mou__qiaobian_delay", 0)
    player:drawCards(5, mou__qiaobian.name)
    if not player.dead and player:isWounded() then
      room:recover { num = 1, skillName = mou__qiaobian.name, who = player , recoverBy = player}
    end
  end,
}
mou__qiaobian:addRelatedSkill(mou__qiaobian_delay)
mou__zhanghe:addSkill(mou__qiaobian)
Fk:loadTranslationTable{
  ["mou__zhanghe"] = "谋张郃",
  ["mou__qiaobian"] = "巧变",
  [":mou__qiaobian"] = "每回合限一次，判定阶段、摸牌阶段、出牌阶段开始前，你可以跳过此阶段并执行对应跳过阶段的效果："..
  "<br>判定阶段：失去1点体力并选择一名其他角色，然后你将判定区里所有的牌置入该角色的判定区（无法置入的判定牌改为置入弃牌堆）；"..
  "<br>摸牌阶段：下个准备阶段开始时，你摸五张牌并回复1点体力；"..
  "<br>出牌阶段：将手牌数弃置至六张并跳过弃牌阶段，然后你移动场上的一张牌。",
  ["#mou__qiaobian-invoke"] = "巧变：你可以跳过 %arg",
  ["#mou__qiaobian-choose"] = "巧变：将你判定区里所有的牌置入一名其他角色的判定区",
  ["#mou__qiaobian-move"] = "巧变：请选择两名角色，移动场上的一张牌",
  ["@@mou__qiaobian_delay"] = "巧变",

  ["$mou__qiaobian1"] = "因势而变，则可引势而为",
  ["$mou__qiaobian2"] = "将计就计，变夺胜机。",
  ["~mou__zhanghe"] = "未料竟中孔明之计……",
}

local mou__ganning = General(extension, "mou__ganning", "wu", 4)
local mou__qixi = fk.CreateActiveSkill{
  name = "mou__qixi",
  anim_type = "control",
  prompt = function()
    local numMap = {}
    for _, id in ipairs(Self:getCardIds("h")) do
      local str = Fk:getCardById(id):getSuitString(true)
      if str ~= "log_nosuit" then
        numMap[str] = (numMap[str] or 0) + 1
      end
    end
    local max_num = 0
    for _, v in pairs(numMap) do
      max_num = math.max(max_num, v)
    end
    local suits = {}
    for suit, v in pairs(numMap) do
      if v == max_num then
        table.insert(suits, Fk:translate(suit))
      end
    end
    return "#mou__qixi-promot:::"..table.concat(suits, ",")
  end,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
    and table.find(player:getCardIds("h"), function (id) return Fk:getCardById(id).suit ~= Card.NoSuit end)
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
    local suits = {"log_spade","log_club","log_heart","log_diamond"}
    local numMap = {}
    for _, suit in ipairs(suits) do
      numMap[suit] = 0
    end
    for _, id in ipairs(player:getCardIds("h")) do
      local str = Fk:getCardById(id):getSuitString(true)
      if numMap[str] then
        numMap[str] = numMap[str] + 1
      end
    end
    local max_num = 0
    for _, v in pairs(numMap) do
      max_num = math.max(max_num, v)
    end
    local wrong_num = 0
    while #suits > 0 do
      local choice = room:askForChoice(to, suits, self.name, "#mou__qixi-guess::"..player.id)
      if numMap[choice] ~= max_num then
        wrong_num = wrong_num + 1
        table.removeOne(suits, choice)
        if #suits == 0 or not room:askForSkillInvoke(player, self.name, nil, "#mou__qixi-again") then break end
      else
        if not player:isKongcheng() then
          player:showCards(player:getCardIds("h"))
        end
        break
      end
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
    local moves = {}
    for i, to in ipairs(effect.tos) do
      table.insert(moves, {
        ids = { effect.cards[i] },
        from = player.id,
        to = to,
        toArea = Card.PlayerSpecial,
        moveReason = fk.ReasonPut,
        skillName = self.name,
        specialName = "@mou__fenwei",
        moveVisible = true,
        proposer = player.id,
      })
    end
    room:moveCards(table.unpack(moves))
    if not player.dead then
      player:drawCards(#effect.cards, self.name)
    end
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
      room:obtainCard(target, target:getPile("@mou__fenwei"), true, fk.ReasonPrey)
    else
      room:moveCards({
        from = target.id,
        ids = target:getPile("@mou__fenwei"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
      AimGroup:cancelTarget(data, target.id)
      return true
    end
  end,
}
mou__fenwei:addRelatedSkill(mou__fenwei_trigger)
mou__ganning:addSkill(mou__fenwei)
Fk:loadTranslationTable{
  ["mou__ganning"] = "谋甘宁",
  ["#mou__ganning"] = "兴王定霸",
	["illustrator:mou__ganning"] = "君桓文化",

  ["mou__qixi"] = "奇袭",
  [":mou__qixi"] = "出牌阶段限一次，你可以选择一名其他角色，令其猜测你手牌中最多的花色。若猜错，你可以令该角色从未猜测过的花色中再次猜测；若猜对，你展示所有手牌。然后你弃置其区域内X张牌（X为此阶段该角色猜错的次数，不足则全弃）。",
  ["#mou__qixi-again"] = "奇袭：你可以令其再猜一次",
  ["#mou__qixi-guess"] = "奇袭：猜测%dest手牌中最多的花色",
  ["#mou__qixi-promot"] = "奇袭：您手牌中最多的花色为：%arg",
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

local moucaopi = General(extension, "mou__caopi", "wei", 3)
Fk:loadTranslationTable{
  ["mou__caopi"] = "谋曹丕",
  ["#mou__caopi"] = "魏文帝",
  ["~mou__caopi"] = "大魏如何踏破吴蜀，就全看叡儿了……",
}

local mouxingshang = fk.CreateActiveSkill{
  name = "mou__xingshang",
  anim_type = "support",
  prompt = "#mou__xingshang",
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    local choiceList = {
      "mou__xingshang_restore",
      "mou__xingshang_draw",
      "mou__xingshang_recover",
      "mou__xingshang_memorialize",
    }
    local choices = {}
    local markValue = Self:getMark("@mou__xingshang_song")
    if markValue > 1 then
      table.insertTable(choices, { choiceList[1], choiceList[2] })
    end
    if markValue > 2 then
      table.insert(choices, choiceList[3])
    end
    if markValue > 3 then
      if
        table.find(
          Fk:currentRoom().players,
          function(p)
            return p.dead and p.rest < 1 and not table.contains(Fk:currentRoom():getBanner('memorializedPlayers') or {}, p.id)
          end
        )
      then
        local skills = Fk.generals[Self.general]:getSkillNameList()
        if Self.deputyGeneral ~= "" then
          table.insertTableIfNeed(skills, Fk.generals[Self.deputyGeneral]:getSkillNameList())
        end

        if table.find(skills, function(skillName) return skillName == self.name end) then
          table.insert(choices, "mou__xingshang_memorialize")
        end
      end
    end

    return UI.ComboBox { choices = choices, all_choices = choiceList }
  end,
  times = function(self)
    return Self.phase == Player.Play and 2 - Self:getMark("mou__xingshang_used-phase") or -1
  end,
  can_use = function(self, player)
    return player:getMark("mou__xingshang_used-phase") < 2 and player:getMark("@mou__xingshang_song") > 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected > 0 then
      return false
    end

    local interactionData = self.interaction.data
    if interactionData == "mou__xingshang_recover" then
      return Fk:currentRoom():getPlayerById(to_select).maxHp < 10
    elseif interactionData == "mou__xingshang_memorialize" then
      return to_select == Self.id
    end

    return true
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(player, "mou__xingshang_used-phase")

    local choice = self.interaction.data
    if choice == "mou__xingshang_restore" then
      room:removePlayerMark(player, "@mou__xingshang_song", 2)
      target:reset()
    elseif choice:startsWith("mou__xingshang_draw") then
      room:removePlayerMark(player, "@mou__xingshang_song", 2)
      target:drawCards(3, self.name)
    elseif choice == "mou__xingshang_recover" then
      room:removePlayerMark(player, "@mou__xingshang_song", 3)
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
      if target.dead then return end
      room:changeMaxHp(target, 1)

      if not target.dead and #target.sealedSlots > 0 then
        room:resumePlayerArea(target, {table.random(target.sealedSlots)})
      end
    elseif choice == "mou__xingshang_memorialize" then
      room:removePlayerMark(player, "@mou__xingshang_song", 4)
      local zhuisiPlayers = room:getBanner('memorializedPlayers') or {}
      table.insertIfNeed(zhuisiPlayers, target.id)
      room:setBanner('memorializedPlayers', zhuisiPlayers)

      local availablePlayers = table.map(table.filter(room.players, function(p)
        return not p:isAlive() and p.rest < 1 and not table.contains(room:getBanner('memorializedPlayers') or {}, p.id)
      end), Util.IdMapper)
      local toId
      local result = room:askForCustomDialog(
        target, self.name,
        "packages/mougong/qml/ZhuiSiBox.qml",
        { availablePlayers, "$MouXingShang" }
      )

      if result == "" then
        toId = table.random(availablePlayers)
      else
        toId = json.decode(result).playerId
      end

      local to = room:getPlayerById(toId)
      local skills = Fk.generals[to.general]:getSkillNameList()
      if to.deputyGeneral ~= "" then
        table.insertTableIfNeed(skills, Fk.generals[to.deputyGeneral]:getSkillNameList())
      end
      skills = table.filter(skills, function(skill_name)
        local skill = Fk.skills[skill_name]
        return not skill.lordSkill and not (#skill.attachedKingdom > 0 and not table.contains(skill.attachedKingdom, target.kingdom))
      end)
      if #skills > 0 then
        room:handleAddLoseSkills(target, table.concat(skills, "|"))
      end

      room:setPlayerMark(target, "@mou__xingshang_memorialized", to.deputyGeneral ~= "" and "seat#" .. to.seat or to.general)
      room:handleAddLoseSkills(player, "-" .. self.name .. '|-mou__fangzhu|-mou__songwei')
    end
  end,

  on_lose = function (self, player)
    local room = player.room
    room:setPlayerMark(player, "mou__xingshang_used-phase", 0)
    room:setPlayerMark(player, "mou__xingshang_damaged-turn", 0)
    room:setPlayerMark(player, "@mou__xingshang_song", 0)
  end
}
local mouxingshangTriggger = fk.CreateTriggerSkill{
  name = "#mou__xingshang_trigger",
  mute = true,
  main_skill = mouxingshang,
  events = {fk.Damaged, fk.Death},
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(mouxingshang) and
      player:getMark("@mou__xingshang_song") < 9 and
      (event ~= fk.Damaged or (player:getMark("mou__xingshang_damaged-turn") == 0 and data.to:isAlive()))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:setPlayerMark(player, "mou__xingshang_damaged-turn", 1)
    end

    room:addPlayerMark(player, "@mou__xingshang_song", math.min(2, 9 - player:getMark("@mou__xingshang_song")))
  end,
}
Fk:loadTranslationTable{
  ["mou__xingshang"] = "行殇",
  [":mou__xingshang"] = "当一名角色受到伤害后（每回合限一次）或死亡时，则你获得两枚“颂”标记（你至多拥有9枚“颂”标记）；" ..
  "出牌阶段限两次，你可选择一名角色并移去至少一枚“颂”令其执行对应操作：2枚，复原武将牌或摸三张牌；" ..
  "3枚，回复1点体力并加1点体力上限，然后随机恢复一个已废除的装备栏（目标体力上限不大于9方可选择）；" ..
  "4枚，<a href='memorialize'>追思</a>一名已阵亡的角色（你选择自己且你的武将牌上有〖行殇〗时方可选择此项），"..
  "获得其武将牌上除主公技外的所有技能，然后你失去〖行殇〗、〖放逐〗、〖颂威〗。",

  ["memorialize"] = "#\"<b>追思</b>\"：被追思过的角色本局游戏不能再成为追思的目标。",
  ["#mou__xingshang"] = "放逐：你可选择一名角色，消耗一定数量的“颂”标记对其进行增益",
  ["#mou__xingshang_trigger"] = "行殇",
  ["$MouXingShang"] = "行殇",
  ["@mou__xingshang_song"] = "颂",
  ["@mou__xingshang_memorialized"] = "行殇",
  ["mou__xingshang_restore"] = "2枚：复原武将牌",
  ["mou__xingshang_draw"] = "2枚：摸三张牌",
  ["mou__xingshang_recover"] = "3枚：恢复体力与区域",
  ["mou__xingshang_memorialize"] = "4枚：追思技能",

  ["$mou__xingshang1"] = "纵是身死，仍要为我所用。",
  ["$mou__xingshang2"] = "汝九泉之下，定会感朕之情。",
}

mouxingshang:addRelatedSkill(mouxingshangTriggger)
moucaopi:addSkill(mouxingshang)

local moufangzhu = fk.CreateActiveSkill{
  name = "mou__fangzhu",
  anim_type = "control",
  prompt = "#mou__fangzhu",
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    local choiceList = {
      "mou__fangzhu_only_basic",
      "mou__fangzhu_only_trick",
      "mou__fangzhu_only_equip",
      "mou__fangzhu_nullify_skill",
      "mou__fangzhu_disresponsable",
      "mou__fangzhu_turn_over",
    }
    local choices = {"mou__fangzhu_only_basic"}
    local x = Self:getMark("@mou__xingshang_song")
    if x > 3 then
      table.insert(choices, "mou__fangzhu_disresponsable")
      if x > 5 then
        table.insert(choices, "mou__fangzhu_only_trick")
        if not Fk:currentRoom():isGameMode("1v2_mode") then
          table.insert(choices, "mou__fangzhu_nullify_skill")
          if x > 7 then
            table.insert(choices, "mou__fangzhu_only_equip")
            table.insert(choices, "mou__fangzhu_turn_over")
          end
        end
      end
    end
    return UI.ComboBox { choices = choices, all_choices = choiceList }
  end,
  can_use = function(self, player)
    return
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      player:getMark("@mou__xingshang_song") > 1 and
      player:hasSkill(mouxingshang, true)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    local choice = self.interaction.data
    if choice:startsWith("mou__fangzhu_only") then
      choice = choice:sub(-5)
      room:removePlayerMark(player, "@mou__xingshang_song", choice == "basic" and 2 or (choice == "trick" and 6 or 8))
      local limit_mark = target:getTableMark("@mou__fangzhu_limit")
      table.insertIfNeed(limit_mark, choice.."_char")
      room:setPlayerMark(target, "@mou__fangzhu_limit", limit_mark)
    elseif choice == "mou__fangzhu_nullify_skill" then
      room:removePlayerMark(player, "@mou__xingshang_song", 6)
      room:setPlayerMark(target, "@@mou__fangzhu_skill_nullified", 1)
    elseif choice == "mou__fangzhu_disresponsable" then
      room:removePlayerMark(player, "@mou__xingshang_song", 4)
      room:setPlayerMark(target, "@@mou__fangzhu_disresponsable", 1)
    elseif choice == "mou__fangzhu_turn_over" then
      room:removePlayerMark(player, "@mou__xingshang_song", 8)
      target:turnOver()
    end
  end,
}
local moufangzhuRefresh = fk.CreateTriggerSkill{
  name = "#mou__fangzhu_refresh",
  refresh_events = { fk.AfterTurnEnd, fk.CardUsing },
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterTurnEnd then
      return
        target == player and
        table.find(
          { "@mou__fangzhu_limit", "@@mou__fangzhu_skill_nullified", "@@mou__fangzhu_disresponsable" },
          function(markName) return player:getMark(markName) ~= 0 end
        )
    end

    return
      target == player and
      table.find(
        player.room.alive_players,
        function(p) return p:getMark("@@mou__fangzhu_disresponsable") > 0 and p ~= target end
      )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room

    if event == fk.AfterTurnEnd then
      for _, markName in ipairs({ "@mou__fangzhu_limit", "@@mou__fangzhu_skill_nullified", "@@mou__fangzhu_disresponsable" }) do
        if player:getMark(markName) ~= 0 then
          room:setPlayerMark(player, markName, 0)
        end
      end
    else
      data.disresponsiveList = data.disresponsiveList or {}
      local tos = table.filter(
        player.room.alive_players,
        function(p) return p:getMark("@@mou__fangzhu_disresponsable") > 0 and p ~= target end
      )
      table.insertTableIfNeed(data.disresponsiveList, table.map(tos, Util.IdMapper))
    end
  end,
}
local moufangzhuProhibit = fk.CreateProhibitSkill{
  name = "#mou__fangzhu_prohibit",
  prohibit_use = function(self, player, card)
    local typeLimited = player:getMark("@mou__fangzhu_limit")
    if typeLimited == 0 then return false end
    if table.every(Card:getIdList(card), function(id)
      return table.contains(player:getCardIds(Player.Hand), id)
    end) then
      return #typeLimited > 1 or typeLimited[1] ~= card:getTypeString() .. "_char"
    end
  end,
}
local moufangzhuNullify = fk.CreateInvaliditySkill {
  name = "#mou__fangzhu_nullify",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@mou__fangzhu_skill_nullified") > 0 and skill:isPlayerSkill(from)
  end
}
Fk:loadTranslationTable{
  ["mou__fangzhu"] = "放逐",
  [":mou__fangzhu"] = "出牌阶段限一次，若你有〖行殇〗，则你可以选择一名其他角色，并移去至少一枚“颂”标记令其执行对应操作：" ..
  "2枚，直到其下个回合结束，其不能使用除基本牌外的手牌；4枚，直到其下个回合结束，其不可响应除其外的角色使用的牌，" ..
  "6枚，直到其下个回合结束，其所有武将技能失效，或其不能使用除锦囊牌外的手牌；8枚，其翻面，或直到其下个回合结束，其不能使用除装备牌外的手牌"..
  "（若为斗地主，则令其他角色技能失效、只可使用装备牌及翻面的效果不可选择）。",
  ["#mou__fangzhu"] = "放逐：你可选择一名角色，消耗一定数量的“颂”标记对其进行限制",
  ["#mou__fangzhu_prohibit"] = "放逐",
  ["@mou__fangzhu_limit"] = "放逐限",
  ["@@mou__fangzhu_skill_nullified"] = "放逐 技能失效",
  ["@@mou__fangzhu_disresponsable"] = "放逐 不可响应",
  ["mou__fangzhu_only_basic"] = "2枚：只可使用基本牌",
  ["mou__fangzhu_only_trick"] = "6枚：只可使用锦囊牌",
  ["mou__fangzhu_only_equip"] = "8枚：只可使用装备牌",
  ["mou__fangzhu_nullify_skill"] = "6枚：武将技能失效",
  ["mou__fangzhu_disresponsable"] = "4枚：不可响应他人牌",
  ["mou__fangzhu_turn_over"] = "8枚：翻面",

  ["$mou__fangzhu1"] = "战败而降，辱我国威，岂能轻饶！",
  ["$mou__fangzhu2"] = "此等过错，不杀已是承了朕恩。",
}

moufangzhu:addRelatedSkill(moufangzhuRefresh)
moufangzhu:addRelatedSkill(moufangzhuProhibit)
moufangzhu:addRelatedSkill(moufangzhuNullify)
moucaopi:addSkill(moufangzhu)
--[[
local mousongwei = fk.CreateActiveSkill{
  name = "mou__songwei$",
  anim_type = "control",
  prompt = "#mou__songwei",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p.kingdom == "wei" end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).kingdom == "wei"
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local skills = Fk.generals[target.general]:getSkillNameList(true)
    if target.deputyGeneral ~= "" then
      table.insertTableIfNeed(skills, Fk.generals[target.deputyGeneral]:getSkillNameList(true))
    end
    if #skills > 0 then
      skills = table.map(skills, function(skillName) return "-" .. skillName end)
      room:handleAddLoseSkills(target, table.concat(skills, "|"), nil, true, false)
    end

    room:setPlayerMark(target, "@@mou__songwei_target", 1)
  end,
}
]]
local mousongwei = fk.CreateTriggerSkill{
  name = "mou__songwei$",
  events = { fk.EventPhaseStart },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Play and
      player:hasSkill(self) and
      player:hasSkill(mouxingshang, true) and
      player:getMark("@mou__xingshang_song") < 9 and
      table.find(player.room.alive_players, function(p) return p.kingdom == "wei" and p ~= player end)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local weiNum = #table.filter(room.alive_players, function(p) return p.kingdom == "wei" and p ~= player end)
    room:addPlayerMark(player, "@mou__xingshang_song", math.min(weiNum * 2, 9 - player:getMark("@mou__xingshang_song")))
  end,
}
Fk:loadTranslationTable{
  ["mou__songwei"] = "颂威",
  [":mou__songwei"] = "主公技，出牌阶段开始时，若你有〖行殇〗，你获得X枚“颂”标记（X为存活的其他魏势力角色数的两倍）。",
  --["#mou__songwei"] = "颂威：你可以让一名其他魏国角色失去技能",
  --["@@mou__songwei_target"] = "已颂威",

  ["$mou__songwei1"] = "江山锦绣，尽在朕手。",
  ["$mou__songwei2"] = "成功建业，扬我魏威。",
}

--mousongwei:addRelatedSkill(mousongweiTrigger)
moucaopi:addSkill(mousongwei)

local handang = General(extension, "mou__handang", "wu", 4)
Fk:loadTranslationTable{
  ["mou__handang"] = "谋韩当",
  ["#mou__handang"] = "石城侯",
  ["~mou__handang"] = "吾子难堪大用，主公勿以重任相托……",
}

local gongqi = fk.CreateTriggerSkill{
  name = "mou__gongqi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(self) and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local ids = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#mou__gongqi-discard", true)
    if #ids > 0 then
      self.cost_data = ids[1]
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local colorStr = Fk:getCardById(self.cost_data):getColorString()
    room:throwCard(self.cost_data, self.name, player, player)
    room:setPlayerMark(player, "@mou__gongqi-phase", colorStr)
  end,

  refresh_events = {fk.HandleAskForPlayCard},
  can_refresh = function(self, event, target, player, data)
    return data.eventData and data.eventData.from == player.id and player:getMark("@mou__gongqi-phase") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if not data.afterRequest then
      room:setBanner("mou__gongqi_user", player.id)
    else
      room:setBanner("mou__gongqi_user", 0)
    end
  end,
}
local gongqiBuff = fk.CreateAttackRangeSkill{
  name = "#mou__gongqi_buff",
  correct_func = function(self, from, to)
    if from:hasSkill("mou__gongqi") then
      return 4
    end
  end,
}
local gongqiProhibit = fk.CreateProhibitSkill{
  name = "#mou__gongqi_prohibit",
  prohibit_use = function(self, player, card)
    local room = Fk:currentRoom()
    local user = room:getBanner("mou__gongqi_user")
    if user and player.id ~= user then
      user = room:getPlayerById(user)
      local colorStr = user:getMark("@mou__gongqi-phase")
      if colorStr == 0 then
        return false
      end

      local subcards = card:isVirtual() and card.subcards or {card.id}
      return
        #subcards > 0 and
        (
          card.color == Card.NoColor or
          card:getColorString() ~= colorStr or
          table.find(subcards, function(id)
            return room:getCardArea(id) ~= Card.PlayerHand
          end)
        )
    end
  end,
  prohibit_response = function(self, player, card)
    local room = Fk:currentRoom()
    local user = room:getBanner("mou__gongqi_user")
    if user and player.id ~= user then
      user = room:getPlayerById(user)
      local colorStr = user:getMark("@mou__gongqi-phase")
      if colorStr == 0 then
        return false
      end

      local subcards = card:isVirtual() and card.subcards or {card.id}
      return
        #subcards > 0 and
        (
          card.color == Card.NoColor or
          card:getColorString() ~= colorStr or
          table.find(subcards, function(id)
            return room:getCardArea(id) ~= Card.PlayerHand
          end)
        )
    end
  end,
}
Fk:loadTranslationTable{
  ["mou__gongqi"] = "弓骑",
  [":mou__gongqi"] = "你的攻击范围+4；出牌阶段开始时，你可以弃置一张牌，令其他角色于阶段内不能使用或打出与此牌颜色不同且不为手牌的非虚拟牌响应你使用的牌。",
  ["#mou__gongqi-discard"] = "弓骑：你可弃置一张牌，此阶段其他角色只能使用非虚拟且颜色相同的手牌响应你的牌",
  ["@mou__gongqi-phase"] = "弓骑",
  ["#mou__gongqi_prohibit"] = "弓骑",

  ["$mou__gongqi1"] = "敌寇首级，且看吾一箭取之！",
  ["$mou__gongqi2"] = "末将尤善骑射，今示于主公一观。",
}

gongqi:addRelatedSkill(gongqiBuff)
gongqi:addRelatedSkill(gongqiProhibit)
handang:addSkill(gongqi)

local jiefan = fk.CreateActiveSkill{
  name = "mou__jiefan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local others = table.filter(room:getOtherPlayers(target), function(p) return p:inMyAttackRange(target) end)
    if #others == 0 then
      return
    end

    local choice = room:askForChoice(target, { "beishui", "mou__jiefan_discard", "mou__jiefan_draw:::" .. #others }, self.name)
    if choice == "beishui" then
      room:invalidateSkill(room:getPlayerById(effect.from), self.name)
    end

    if choice == "beishui" or choice == "mou__jiefan_discard" then
      for _, p in ipairs(others) do
        room:askForDiscard(p, 1, 1, true, self.name, false)
      end
    end

    if choice == "beishui" or choice:startsWith("mou__jiefan_draw") then
      target:drawCards(#others, self.name)
    end
  end,
}
local jiefanResume = fk.CreateTriggerSkill{
  name = "#mou__jiefan_resume",
  mute = true,
  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return
      target ~= player and
      data.damage and
      data.damage.from == player and
      table.contains(player:getTableMark(MarkEnum.InvalidSkills), "mou__jiefan")
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:validateSkill(player, "mou__jiefan")
  end,
}

Fk:loadTranslationTable{
  ["mou__jiefan"] = "解烦",
  [":mou__jiefan"] = "出牌阶段限一次，你可以令一名角色选择一项：1.令攻击范围内含有其的角色依次弃置一张牌；" ..
  "2.其摸攻击范围内含有其的角色数张牌；背水：此技能失效直到你杀死其他角色。",
  ["mou__jiefan_discard"] = "令攻击范围内含有你的角色依次弃置一张牌",
  ["mou__jiefan_draw"] = "摸%arg张牌",
  ["@@mou__jiefan_nullified"] = "解烦失效",

  ["$mou__jiefan1"] = "一箭可解之事，何使公忧烦至此。",
  ["$mou__jiefan2"] = "贼盛不足惧，有吾解烦营。",
}

jiefan:addRelatedSkill(jiefanResume)
handang:addSkill(jiefan)

local guojia = General(extension, "mou__guojia", "wei", 3)

Fk:loadTranslationTable{
  ["mou__guojia"] = "谋郭嘉",
  ["#mou__guojia"] = "奉己佐君",
  ["~mou__guojia"] = "蒙天所召，嘉先去矣，咳咳咳……",
}

local tianduViewAs = fk.CreateViewAsSkill{
  name = "mou__tiandu_view_as",
  interaction = function(self)
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(Self, "mou__tiandu", all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names, default_choice = "AskForCardsChosen" }
    end
  end,
  expand_pile = function (self)
    return { self.card_map[self.interaction.data] }
  end,
  card_filter = function(self, to_select, selected)
    return to_select == self.card_map[self.interaction.data]
  end,
  view_as = function(self, cards)
    if #cards > 0 then
      local card = Fk:cloneCard(self.interaction.data)
      card.skillName = "mou__tiandu"
      return card
    end
  end,
}

local tiandu = fk.CreateTriggerSkill{
  name = "mou__tiandu",
  anim_type = "switch",
  switch_skill_name = "mou__tiandu",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and player.phase == Player.Play and
    (player:getSwitchSkillState(self.name, false) == fk.SwitchYin or player:getHandcardNum() > 1)
  end,
  on_cost = function(self, event, target, player, data)
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      local cards = player.room:askForDiscard(player, 2, 2, false, self.name, true, ".", "#mou__tiandu-invoke", true)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    else
      self.cost_data = {}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data
    if #cards > 0 then
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name, 1)
      local suits = player:getTableMark("@[suits]mou__tiandu")
      local updata_mark = false
      for _, id in ipairs(cards) do
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit and table.insertIfNeed(suits, suit) then
          updata_mark = true
        end
      end
      if updata_mark then
        room:setPlayerMark(player, "@[suits]mou__tiandu", suits)
      end
      room:throwCard(cards, self.name, player, player)
      if player.dead then return false end
      local cardMap = player:getMark("mou__tiandu_cardmap")
      if type(cardMap) ~= "table" then
        cardMap = {}
        local tricks = U.getUniversalCards(room, "t")
        for _, id in ipairs(tricks) do
          cardMap[Fk:getCardById(id).name] = id
        end
        room:setPlayerMark(player, "mou__tiandu_cardmap", cardMap)
      end
      local _, dat = room:askForUseViewAsSkill(player, "mou__tiandu_view_as", "#mou__tiandu-viewas", true, {card_map = cardMap})
      if dat then
        local card = Fk:cloneCard(dat.interaction)
        card.skillName = self.name
        room:useCard{
          card = card,
          from = player.id,
          tos = table.map(dat.targets, function(p) return {p} end),
          extraUse = true,
        }
      end
    else
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name, 2)
      local suits = player:getTableMark("@[suits]mou__tiandu")
      local judge_pattern = table.concat(table.map(suits, function (suit)
        return U.ConvertSuit(suit, "int", "str")
      end), ",")
      local judge = {
        who = player,
        reason = self.name,
        pattern = ".|.|".. judge_pattern,
      }
      room:judge(judge)
      if table.contains(suits, judge.card.suit) and not player.dead then
        room:damage{
          to = player,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,

  on_lose = function (self, player)
    player.room:setPlayerMark(player, "@[suits]mou__tiandu", 0)
  end,
}

local tianduDelay = fk.CreateTriggerSkill{
  name = "#mou__tiandu_delay",
  events = {fk.FinishJudge},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.reason == tiandu.name and player.room:getCardArea(data.card.id) == Card.Processing
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, data.card, true)
  end,
}

Fk:loadTranslationTable{
  ["mou__tiandu"] = "天妒",
  [":mou__tiandu"] = "转换技，出牌阶段开始时，阳：你可以弃置两张手牌并记录这些牌的花色，然后可以视为使用任意普通锦囊牌；"..
  "阴：你判定，若结果为你记录过的花色，你受到1点无来源伤害。当此次判定的结果确定后，你获得判定牌。",
  ["#mou__tiandu_delay"] = "天妒",
  ["mou__tiandu_view_as"] = "天妒",

  ["#mou__tiandu-invoke"] = "是否使用 天妒，弃置两张手牌来视为使用普通锦囊",
  ["#mou__tiandu-viewas"] = "天妒：你可以视为使用普通锦囊",
  ["@[suits]mou__tiandu"] = "天妒",

  ["$mou__tiandu1"] = "顺应天命，即为大道所归。",
  ["$mou__tiandu2"] = "计高于人，为天所妒。",
}

Fk:addSkill(tianduViewAs)
tiandu:addRelatedSkill(tianduDelay)
guojia:addSkill(tiandu)

local yiji = fk.CreateTriggerSkill{
  name = "mou__yiji",
  anim_type = "masochism",
  events = {fk.Damaged, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or target ~= player then return false end
    if event == fk.EnterDying then
      local room = player.room
      local logic = room.logic
      local dying_event = logic:getCurrentEvent():findParent(GameEvent.Dying, true)
      if dying_event == nil then return false end
      local mark = player:getMark("mou__yiji-round")
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.Dying, 1, function (e)
          local last_dying = e.data[1]
          if last_dying.who == player.id then
            mark = e.id
            room:setPlayerMark(player, "mou__yiji-round", mark)
            return true
          end
          return false
        end, Player.HistoryRound)
      end
      return mark == dying_event.id
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = event == fk.Damaged and 2 or 1
    player:drawCards(x, self.name)
    if player.dead or player:isKongcheng() then return end
    room:askForYiji(player, player:getCardIds("h"), room:getOtherPlayers(player, false), self.name, 0, x)
  end
}

Fk:loadTranslationTable{
  ["mou__yiji"] = "遗计",
  [":mou__yiji"] = "当你受到伤害后，你可以摸两张牌，然后可以将一至两张手牌交给其他角色。"..
  "当你每轮首次进入濒死状态后，你可以摸一张牌，然后可以将一张手牌交给其他角色。",

  ["$mou__yiji1"] = "此身赴黄泉，望明公见计如晤。",
  ["$mou__yiji2"] = "身不能征伐，此计或可襄君太平！",
}

guojia:addSkill(yiji)



return extension
