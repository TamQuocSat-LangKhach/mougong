local extension = Package("mou_tong")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_tong"] = "谋攻篇-同包",
}
local sunce = General(extension, "mou__sunce", "wu", 2 , 4)
local mou__jiang_draw = fk.CreateTriggerSkill{
  name = "#mou__jiang_draw",
  anim_type = "drawcard",
  events ={fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("mou__jiang") and
      ((data.card.trueName == "slash" and data.card.color == Card.Red) or data.card.name == "duel")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local mou__jiang_target = fk.CreateTriggerSkill{
  name = "#mou__jiang_target",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("mou__jiang") and #player.room.alive_players > 2 and data.card.trueName == "duel"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not table.contains(data.tos[1], p.id) and not player:isProhibited(p, data.card) then
        table.insertIfNeed(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#mou__jiang-choose:::"..data.card:toLogString(), "mou__jiang", true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1)
    TargetGroup:pushTargets(data.targetGroup, self.cost_data)
  end,
}
local mou__jiang = fk.CreateViewAsSkill{
  name = "mou__jiang",
  anim_type = "offensive",
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("duel")
    card:addSubcards(Self:getCardIds(Player.Hand))
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    local X = 1
    if player:usedSkillTimes("mou__zhiba", Player.HistoryGame) > 0 then
        local num1 = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.kingdom == "wu" then 
          num1 = num1 + 1
        end
      end
      X = num1
    end
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < X and not player:isKongcheng()
  end,
}
local mou__hunzi = fk.CreateTriggerSkill{
  name ="mou__hunzi",
  frequency = Skill.Wake,
  events = {fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 
  end,
  can_wake = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:changeShield(player, 2)
    player:drawCards(3, self.name)
    room:handleAddLoseSkills(player, "mou__yingzi|yinghun", nil, true, false)
  end,
}
local mou__zhiba_draw = fk.CreateTriggerSkill{
  name = "#mou__zhiba_draw",
  anim_type = "control",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill("mou__zhiba", false, true) and data.damage and data.damage.skillName == "mou__zhiba"
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, self.name)
  end,
}
local mou__zhiba = fk.CreateTriggerSkill{
  name = "mou__zhiba$",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      not table.every(player.room:getOtherPlayers(player), function(p) return p.kingdom ~= "wu" end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "wu" then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      for _, id in ipairs(targets) do
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    end
    if not player.dead then
      for _, id in ipairs(targets) do
         local p = room:getPlayerById(id)
        if not p.dead then
          room:damage{
            from = nil,
            to = p,
            damage = 1,
            skillName = self.name
          }
        end
      end
    end
  end,
}
mou__jiang:addRelatedSkill(mou__jiang_draw)
mou__jiang:addRelatedSkill(mou__jiang_target)
mou__zhiba:addRelatedSkill(mou__zhiba_draw)
sunce:addSkill(mou__jiang)
sunce:addSkill(mou__hunzi)
sunce:addSkill(mou__zhiba)
sunce:addRelatedSkill("mou__yingzi")
sunce:addRelatedSkill("yinghun")
Fk:loadTranslationTable{
  ["mou__sunce"] = "谋孙策",
  ["#mou__jiang_draw"] = "激昂",
  ["#mou__jiang_target"] = "激昂",
  ["#mou__jiang-choose"] = "激昂:你可以为【%arg】额外指定一个目标，若如此做，你失去一点体力。",
  ["mou__jiang"] = "激昂",
  [":mou__jiang"] = "①当你使用【决斗】指定目标时，你可以额外指定一个目标，然后你失去一点体力。②当你使用【决斗】或红色【杀】指定目标后，或成为【决斗】或红色【杀】的目标后，你可以摸一张牌。③出牌阶段限X次，你可以将所有手牌当做决斗使用。(X为1，若已发动“制霸”，则X改为现存吴势力角色数)",
  ["mou__hunzi"] = "魂姿",
  [":mou__hunzi"] = "觉醒技，当你脱离濒死状态时，你减1点体力上限，获得两点护甲并摸三张牌然后获得〖英姿〗和〖英魂〗。",
  ["mou__zhiba"] = "制霸",
  [":mou__zhiba"] = "主公技，限定技，当你进入濒死状态时，你可以回复X点体力并修改“激昂”(X为吴势力角色数)，然后其他吴势力角色依次受到1点无来源伤害，若其因此死亡，你摸三张牌。",

  ["$mou__jiang1"] = "义武奋扬，荡尽犯我之寇！",
  ["$mou__jiang2"] = "锦绣江东，岂容小丑横行！",
  ["$mou__hunzi1"] = "群雄逐鹿之时，正是吾等崭露头角之日！",
  ["$mou__hunzi2"] = "胸中远志几时立，正逢建功立业时！",
  ["$mou__zhiba1"] = "知君英豪，望来归效！",
  ["$mou__zhiba2"] = "孰胜孰负，犹未可知！",
  ["$mou__yingzi_mou__sunce1"] = "今与公瑾相约，共图天下霸业！",
  ["$mou__yingzi_mou__sunce2"] = "空言岂尽意，跨马战沙场！",
  ["$yinghun_mou__sunce1"] = "父亲英魂犹在，助我定乱平贼！",
  ["$yinghun_mou__sunce2"] = "扫尽门庭之寇，贼自畏我之威！",
  ["~mou__sunce"] = "大志未展，权弟当继……",
}
--[[
local mou__xiaoqiao = General(extension, "mou__xiaoqiao", "wu", 3, 3, General.Female)
local mou__hongyan = fk.CreateFilterSkill{
  name = "mou__hongyan",
  card_filter = function(self, to_select, player)
    return to_select.suit == Card.Spade and player:hasSkill(self)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, to_select.number)
  end,
}
local mou__hongyan_delay = fk.CreateTriggerSkill{
  name = "#mou__hongyan_delay",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) -- and data.card.suit == Card.Heart
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suitStr = room:askForChoice(player, {"spade","club","heart","diamond"}, self.name, "#mou__hongyan-choice::"..target.id..":"..data.reason)
    local color = (suitStr == "spade" or suitStr == "spade") and Card.Black or Card.Red
    data.card.suit = Util.getSuitFromString(suitStr)
    data.color = color
    room:sendLog{
      type = "#ChangedJudge",
      from = player.id,
      to = { target.id },
      card = { data.card:getEffectiveId() },
      arg = self.name,
    }
  end,
}
mou__hongyan:addRelatedSkill(mou__hongyan_delay)
mou__xiaoqiao:addSkill(mou__hongyan)
Fk:loadTranslationTable{
  ["mou__xiaoqiao"] = "谋小乔",
  ["mou__tianxiang"] = "天香",
  [":mou__tianxiang"] = "①出牌阶段限两次，你可将一张红色牌交给一名没有“天香”标记的其他角色，并令其获得对应花色的“天香”标记。"..
  "<br>②当你受到伤害时，你可以选择一名拥有“天香”标记的其他角色，移除其“天香”标记，并根据移除的“天香”花色发动：红桃，你防止此伤害，然后令其受到防止伤害的来源角色造成的1点伤害；方块，其交给你两张牌。"..
  "<br>③准备阶段，你移除场上所有“天香”标记，并摸等量的牌。",
  ["#mou__tianxiang-choose"] = "天香：移除一名角色的“天香”标记并“天香”花色发动效果",
  ["mou__hongyan"] = "红颜",
  [":mou__hongyan"] = "锁定技，①你的♠️牌均视为♥️牌；②当一名角色的判定牌生效前，若此牌的花色为♥️，你将此牌的判定结果改为任意一种花色。",
  ["#mou__hongyan-choice"] = "红颜：修改 %dest 进行 %arg 判定结果的花色",
  ["#mou__hongyan_delay"] = "红颜",
  ["$mou__tianxiang1"] = "灿如春华，皎如秋月。",
  ["$mou__tianxiang2"] = "凤眸流盼，美目含情。",
  ["$mou__hongyan"] = "（琴声）",
  ["~mou__xiaoqiao"] = "朱颜易改，初心永在……",
}
--]]
local liucheng = General(extension, "mou__liucheng", "qun", 3, 3, General.Female)

local lveying = fk.CreateTriggerSkill{
  name = "lveying",
  events = {fk.CardUseFinished},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and data.card.trueName == "slash" and player:getMark("@lveying_hit") > 1
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@lveying_hit", 2)
    room:drawCards(player, 1, self.name)
    local dismantlement = Fk:cloneCard("dismantlement")
    dismantlement.skillName = self.name
    if player:prohibitUse(dismantlement) then return false end
    local max_num = dismantlement.skill:getMaxTargetNum(player, dismantlement)
    if max_num == 0 then return false end
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if not (p == player or p:isAllNude() or player:isProhibited(p, dismantlement)) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, max_num, "#lveying-dismantlement:::" .. max_num, self.name, true, true)
    if #tos > 0 then
      room:useCard({
        from = player.id,
        tos = table.map(tos, function(pid) return { pid } end),
        card = dismantlement,
      })
    end
  end,
}

local lveying_charge = fk.CreateTriggerSkill{
  name = "#lveying_charge",
  events = {fk.TargetSpecified},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lveying.name) and target == player and data.card.trueName == "slash" and player:usedSkillTimes(self.name) < 2
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@lveying_hit")
  end,
}

local yingwu = fk.CreateTriggerSkill{
  name = "yingwu",
  events = {fk.CardUseFinished},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and data.card:isCommonTrick() and not data.card.is_damage_card and
      player:getMark("@lveying_hit") > 1
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@lveying_hit", 2)
    room:drawCards(player, 1, self.name)
    local slash = Fk:cloneCard("slash")
    slash.skillName = self.name
    if player:prohibitUse(slash) then return false end
    local max_num = slash.skill:getMaxTargetNum(player, slash)
    if max_num == 0 then return false end
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if not (p == player or player:isProhibited(p, slash)) then
        table.insert(targets, p.id)
      end
    end
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, max_num, "#yingwu-slash:::" .. max_num, self.name, true, true)
    if #tos > 0 then
      room:useCard({
        from = player.id,
        tos = table.map(tos, function(pid) return { pid } end),
        card = slash,
      })
    end
  end,
}

local yingwu_charge = fk.CreateTriggerSkill{
  name = "#yingwu_charge",
  events = {fk.TargetSpecified},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yingwu.name) and target == player and data.card:isCommonTrick() and not data.card.is_damage_card and
      player:usedSkillTimes(self.name) < 2
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@lveying_hit")
  end,
}

lveying:addRelatedSkill(lveying_charge)
yingwu:addRelatedSkill(yingwu_charge)
liucheng:addSkill(lveying)
liucheng:addSkill(yingwu)

Fk:loadTranslationTable{
  ["mou__liucheng"] = "谋刘赪",

  ["lveying"] = "掠影",
  ["#lveying_charge"] = "掠影",
  [":lveying"] = "你使用【杀】结算结束后，若你拥有至少两个“椎”标记，则你移除两个“椎”标记，然后摸一张牌，"..
    "且可以选择一名角色视为对其使用一张【过河拆桥】。出牌阶段限两次，你使用【杀】指定一个目标后，你获得一个“椎”标记。",
  ["yingwu"] = "莺舞",
  ["#yingwu_charge"] = "掠影",
  [":yingwu"] = "你使用非伤害类普通锦囊结算结束后，若你拥有至少两个“椎”标记，则你移除两个“椎”标记，然后摸一张牌，"..
    "且可以选择一名角色视为对其使用一张【杀】（计入次数，无次数限制）。出牌阶段限两次，你使用非伤害类普通锦囊指定一个目标后，"..
    "若你拥有技能“掠影”，则你获得一个“椎”标记。",

  ["@lveying_hit"] = "椎",
  ["#lveying-dismantlement"] = "掠影：你可以视为使用【过河拆桥】，选择%arg名角色为目标",
  ["#yingwu-slash"] = "莺舞：你可以视为使用【杀】，选择%arg名角色为目标",

  ["$lveying1"] = "避实击虚，吾可不惮尔等蛮力！",
  ["$lveying2"] = "疾步如风，谁人可视吾影？",
  ["$yingwu1"] = "莺舞曼妙，杀机亦藏其中！",
  ["$yingwu2"] = "莺翼之羽，便是诛汝之锋！",
  ["~mou__liucheng"] = "此番寻药未果，怎医叙儿之疾……",
}

local yangwan = General(extension, "mou__yangwan", "qun", 3, 3, General.Female)

local mingxuan_active = fk.CreateActiveSkill{
  name = "mingxuan_active",
  can_use = function() return false end,
  target_num = 0,
  min_card_num = 1,
  max_card_num = function ()
    local room = Fk:currentRoom()
    local targetRecorded = type(Self:getMark("mingxuan_targets")) == "table" and Self:getMark("mingxuan_targets") or {}
    return #table.filter(room.alive_players, function (p)
      return p.id ~= Self.id and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, to_select, selected)
    if #selected >= self.max_card_num() then return false end
    local card = Fk:getCardById(to_select)
    return table.every(selected, function (id)
      return card.suit ~= Fk:getCardById(id).suit end)
  end,
}

local mingxuan = fk.CreateTriggerSkill{
  name = "mingxuan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    if player:isKongcheng() then return false end
    local room = player.room
    local targetRecorded = type(player:getMark("mingxuan_targets")) == "table" and player:getMark("mingxuan_targets") or {}
    local targets = table.filter(room.alive_players, function (p)
      return p ~= player and not table.contains(targetRecorded, p.id)
    end)
    if #targets == 0 then return false end
    local to_give = table.random(player.player_cards[Player.Hand] , 1)
    for _, p in ipairs(room.alive_players) do
      if table.contains(targetRecorded, p.id) then
        room:addPlayerMark(p, "@@mingxuan")
      end
    end
    local _, ret = room:askForUseActiveSkill(player, "mingxuan_active", "#mingxuan-select", false)
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@@mingxuan", 0)
    end
    if ret then
      to_give = ret.cards
    end
    local tos = {}
    local moveInfos = {}
    for _, id in ipairs(to_give) do
      if #targets == 0 then break end
      local to = table.random(targets)
      table.removeOne(targets, to)
      table.insert(tos, to.id)
      table.insert(moveInfos, {
        from = player.id,
        ids = {id},
        to = to.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = self.name,
        moveVisible = false
      })
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      for _, id in ipairs(tos) do
        if player.dead then break end
        local to = room:getPlayerById(id)
        if not to.dead then
          local use = room:askForUseCard(to, "slash", "slash", "#mingxuan-slash:" .. player.id, true,
          { must_targets = {player.id}, bypass_distances = true, bypass_times = true })
          if use then
            use.extraUse = true
            room:useCard(use)
            table.insertIfNeed(targetRecorded, id)
          else
            local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#mingxuan-give:"..player.id)
            room:obtainCard(player.id, card[1], false, fk.ReasonGive)
            if not player.dead then
              room:drawCards(player, 1, self.name)
            end
          end
        end
      end
    end
    if not player.dead then
      room:setPlayerMark(player, "mingxuan_targets", targetRecorded)
    end
  end,
}

local xianchou = fk.CreateTriggerSkill{
  name = "xianchou",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead and
      not table.every(player.room.alive_players, function (p)
        return p.id == player.id or p.id == data.from.id end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if not data.from or data.from.dead then return false end
    local targets = table.map(room.alive_players, function (p) return p.id end)
    table.removeOne(targets, player.id)
    table.removeOne(targets, data.from.id)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xianchou-choose::" .. data.from.id, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForDiscard(to, 1, 1, true, self.name, true, ".", "#xianchou-discard:" .. player.id .. ":"..data.from.id)
    if #card > 0 then
      if to.dead or data.from.dead then return false end
      local slash = Fk:cloneCard("slash")
      slash.skillName = self.name
      if to:prohibitUse(slash) or to:isProhibited(data.from, slash) then return false end
      local use = {from = to.id, tos = {{data.from.id}}, card = slash, extraUse = true}
      room:useCard(use)
      if use.damageDealt then
        if not to.dead then
          room:drawCards(to, 1, self.name)
        end
        if not player.dead and player:isWounded() then
          room:recover({
            who = player,
            num = 1,
            recoverBy = to,
            skillName = self.name
          })
        end
      end
    end
  end,
}
Fk:addSkill(mingxuan_active)
yangwan:addSkill(mingxuan)
yangwan:addSkill(xianchou)

Fk:loadTranslationTable{
  ["mou__yangwan"] = "谋杨婉",

  ["mingxuan"] = "暝眩",
  ["mingxuan_active"] = "暝眩",
  [":mingxuan"] = "锁定技，出牌阶段开始时，若你有牌且场上有未被本技能记录的其他角色，你须选择X张花色各不相同的手牌，"..
    "交给这些角色中随机X名角色各一张牌（X最大为这些角色数且至少为1)。然后依次令交给牌角色选择一项：1. 对你使用一张【杀】，然后你记录该角色；"..
    "2. 交给你一张牌，然后你摸一张牌。",
  ["xianchou"] = "陷仇",
  [":xianchou"] = "当你受到伤害后，可以选择一名除伤害来源以外的其他角色，该角色可以弃置一张牌，视为对伤害来源使用一张无距离与次数限制的"..
  "普通【杀】。若此【杀】造成伤害，则该角色摸一张牌，你回复1点体力。",

  ["@@mingxuan"] = "暝眩",
  ["#mingxuan-select"] = "暝眩：选择花色各不相同的手牌，随机交给没有被暝眩记录的角色",
  ["#mingxuan-slash"] = "暝眩：你可以对%src使用一张【杀】，或点取消则必须将一张一张牌交给该角色",
  ["#mingxuan-give"] = "暝眩：选择一张牌交给%src",

  ["#xianchou-choose"] = "陷仇：你可选择一名角色，令其可弃置一张手牌视为对%dest使用【杀】",
  ["#xianchou-discard"] = "陷仇：你可以弃置一张手牌，视为对%dest使用【杀】，若造成伤害则摸一张牌且%src回复1点体力",

  ["$mingxuan1"] = "闻汝节行俱佳，今特设宴相请。",
  ["$mingxuan2"] = "百闻不如一见，夫人果真非凡。",
  ["$xianchou1"] = "夫君勿忘，杀妻害子之仇！",
  ["$xianchou2"] = "吾母子之仇，便全靠夫君来报了！",
  ["~mou__yangwan"] = "引狗入寨，悔恨交加……",
}

local xiahoushi = General(extension, "mou__xiahoushi", "shu", 3, 3, General.Female)

local mou__qiaoshi = fk.CreateTriggerSkill{
  name = "mou__qiaoshi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name) == 0 and player:isWounded() and
      data.from and data.from ~= player and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return data.from and not data.from.dead and player.room:askForSkillInvoke(data.from, self.name, nil,
      "#mou__qiaoshi-invoke:"..player.id.. "::"..data.damage)
  end,
  on_use = function(self, event, target, player, data)
    local from = data.from
    if player:isWounded() then
      player.room:recover({
        who = player,
        num = math.min(data.damage, player:getLostHp()),
        recoverBy = from,
        skillName = self.name
      })
    end
    if from and not from.dead then
      from:drawCards(2, self.name)
    end
  end,
}

local mou__yanyu = fk.CreateActiveSkill{
  name = "mou__yanyu",
  anim_type = "drawcard",
  prompt = "#mou__yanyu",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash" and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player)
    player:drawCards(1, self.name)
  end,
}

local mou__yanyu_trigger = fk.CreateTriggerSkill{
  name = "#mou__yanyu_trigger",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mou__yanyu.name) and player.phase == player.Play and
      player:usedSkillTimes(mou__yanyu.name, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#mou__yanyu-draw:::" ..  3*player:usedSkillTimes(mou__yanyu.name, Player.HistoryTurn), self.name, true)
    if #to > 0 then
      self.cost_data = room:getPlayerById(to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, mou__yanyu.name, self.anim_type)
    player:broadcastSkillInvoke(mou__yanyu.name)
    room:drawCards(self.cost_data, 3*player:usedSkillTimes(mou__yanyu.name, Player.HistoryTurn), mou__yanyu.name)
  end,
}

mou__yanyu:addRelatedSkill(mou__yanyu_trigger)
xiahoushi:addSkill(mou__qiaoshi)
xiahoushi:addSkill(mou__yanyu)

Fk:loadTranslationTable{
  ["mou__xiahoushi"] = "谋夏侯氏",

  ["mou__qiaoshi"] = "樵拾",
  [":mou__qiaoshi"] = "每回合限一次，你受到其他角色造成的伤害后，伤害来源可以令你回复等同此次伤害值的体力，若如此做，该角色摸两张牌。",
  ["mou__yanyu"] = "燕语",
  ["#mou__yanyu_trigger"] = "燕语",
  [":mou__yanyu"] = "出牌阶段限两次，你可以弃置一张【杀】并摸一张牌。出牌阶段结束时，你可以令一名其他角色摸X张牌（X为你此回合以此法弃置【杀】的数量的三倍）。",

  ["#mou__qiaoshi-invoke"] = "樵拾：你可以令%src回复%arg点体力，然后你摸两张牌",
  ["#mou__yanyu"] = "燕语：你可以弃置一张【杀】，然后摸一张牌",
  ["#mou__yanyu-draw"] = "燕语：你可以选择一名其他角色，令其摸%arg张牌",

  ["$mou__qiaoshi1"] = "拾樵城郭边，似有苔花开。",
  ["$mou__qiaoshi2"] = "拾樵采薇，怡然自足。",
  ["$mou__yanyu1"] = "燕语呢喃唤君归！",
  ["$mou__yanyu2"] = "燕燕于飞，差池其羽。",
  ["~mou__xiahoushi"] = "玄鸟不曾归，君亦不再来……",
}

local mouzhurong = General(extension, "mou__zhurong", "shu", 4, 4, General.Female)

local mou__juxiang = fk.CreateTriggerSkill{
  name = "mou__juxiang",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect, fk.CardUseFinished, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.PreCardEffect then
      return data.card.trueName == "savage_assault" and data.to == player.id
    elseif event == fk.CardUseFinished then
      if target ~= player and data.card.trueName == "savage_assault" then
        local room = player.room
        local card_ids = data.card:isVirtual() and data.card.subcards or { data.card.id }
        return #card_ids > 0 and table.every(card_ids, function (id)
          return room:getCardArea(id) == Card.Processing
        end)
      end
    elseif event == fk.EventPhaseStart then
      if target == player and player.phase == Player.Finish then
        local room = player.room
        local cards = room:getTag("mou__juxiang")
        return (type(cards) ~= "table" or #cards > 0) and #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          return use.from == player.id and use.card.trueName == "savage_assault"
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.PreCardEffect then
      return true
    elseif event == fk.CardUseFinished then
      player.room:obtainCard(player, data.card, true, fk.ReasonJustMove)
    elseif event == fk.EventPhaseStart then
      local room = player.room
      local cards = room:getTag("mou__juxiang")
      if type(cards) ~= "table" then
        cards = {
          {Card.Spade, 13}, {Card.Spade, 11}, {Card.Spade, 9}, {Card.Spade, 7},
          {Card.Club, 13}, {Card.Club, 11}, {Card.Club, 9}, {Card.Club, 7}
        }
      end
      if #cards == 0 then return false end
      local to_give =  table.remove(cards, math.random(1, #cards))
      room:setTag("mou__juxiang", cards)
      local targets = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper),
      1, 1, "#mou__juxiang-choose", self.name, false)
      if #targets > 0 then
        local toGain = room:printCard("savage_assault", to_give[1], to_give[2])
        room:moveCards({
          ids = {toGain.id},
          to = targets[1],
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonGive,
          proposer = player.id,
          skillName = self.name,
          moveVisible = true,
        })
      end
    end
  end,
}
local mou__lieren = fk.CreateTriggerSkill{
  name = "mou__lieren",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self)) then return false end
    if data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) == 1 then
      local to = player.room:getPlayerById(data.to)
      return not (to.dead or to:isKongcheng())
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mou__lieren-invoke::"..data.to)
  end,
  on_use = function(self, event, _, player, data)
    local room = player.room
    local target = room:getPlayerById(data.to)
    room:drawCards(player, 1, self.name)
    if player.dead or target.dead or player:isKongcheng() or target:isKongcheng() then return false end
    local pindian = player:pindian({target}, self.name)
    if pindian.results[data.to].winner == player then
      data.extra_data = data.extra_data or {}
      local mou__lieren_record = data.extra_data.mou__lieren_record or {}
      table.insert(mou__lieren_record, player.id)
      data.extra_data.mou__lieren_record = mou__lieren_record
    end
  end,
}
local mou__lieren_delay = fk.CreateTriggerSkill{
  name = "#mou__lieren_delay",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.mou__lieren_record and
      table.contains(data.extra_data.mou__lieren_record, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(mou__lieren.name)
    local tos = TargetGroup:getRealTargets(data.tos)
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p ~= player and not table.contains(tos, p.id) end), Util.IdMapper)
    targets = room:askForChoosePlayers(player, targets, 1, 1, "#mou__lieren-choose", mou__lieren.name, true)
    if #targets > 0 then
      room:damage{
        from = player,
        to = room:getPlayerById(targets[1]),
        damage = 1,
        skillName = mou__lieren.name,
      }
    end
  end,
}
mou__lieren:addRelatedSkill(mou__lieren_delay)
mouzhurong:addSkill(mou__juxiang)
mouzhurong:addSkill(mou__lieren)

Fk:loadTranslationTable{
  ["mou__zhurong"] = "谋祝融",
  ["mou__juxiang"] = "巨象",
  [":mou__juxiang"] = "锁定技，【南蛮入侵】对你无效；当其他角色使用的【南蛮入侵】结算结束后，你获得之。"..
  "结束阶段，若你本回合未使用过【南蛮入侵】，你随机将游戏外一张【南蛮入侵】交给一名角色（游戏外共有8张【南蛮入侵】）。",
  ["mou__lieren"] = "烈刃",
  [":mou__lieren"] = "当你使用【杀】指定一名其他角色为唯一目标后，你可以摸一张牌，然后与其拼点。"..
  "若你赢，此【杀】结算结束后，你可对另一名其他角色造成1点伤害。",

  ["#mou__juxiang-choose"] = "巨象：选择1名角色获得【南蛮入侵】",
  ["#mou__lieren-invoke"] = "是否使用烈刃，摸一张牌并与%dest拼点",
  ["#mou__lieren_delay"] = "烈刃",
  ["#mou__lieren-choose"] = "烈刃：可选择一名角色，对其造成1点伤害",

  ["$mou__juxiang1"] = "哼！何须我亲自出马！",
  ["$mou__juxiang2"] = "都给我留下吧！",
  ["$mou__lieren1"] = "哼！可知本夫人厉害？",
  ["$mou__lieren2"] = "我的飞刀，谁敢小瞧？",
  ["~mou__zhurong"] = "大王……这诸葛亮果然厉害……",
}


return extension
