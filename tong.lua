local extension = Package("mou_tong")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_tong"] = "谋攻篇-同包",
}
local xiahoushi = General(extension, "mou__xiahoushi", "shu", 3, 3, General.Female)

local mou__qiaoshi = fk.CreateTriggerSkill{
  name = "mou__qiaoshi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 and player:isWounded() and
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
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash" and not Self.prohibitDiscard(Fk:getCardById(to_select))
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
    room:broadcastSkillInvoke(mou__yanyu.name)
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





return extension
