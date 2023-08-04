local extension = Package("mou_shi")
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mou_shi"] = "谋攻篇-识包",
}
local mou__tieji = fk.CreateTriggerSkill{
  name = "mou__tieji",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
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
    if choice == "tieji-zhiqu" and choice1 ~= "tieji-chuzheng" and not to:isNude() then
      local card = room:askForCardChosen(player, to, "he", self.name)
     room:obtainCard(player, card, false, fk.ReasonPrey)
    end
    if choice == "tieji-raozheng" and choice1 ~= "tieji-huwei" then
      player:drawCards(2, self.name)
    end
  end,
}

local machao = General:new(extension, "mou__machao", "shu", 4)
machao.subkingdom = "god"
machao:addSkill("mashu")
machao:addSkill(mou__tieji)
Fk:loadTranslationTable{
  ["mou__machao"] = "谋马超",
  ["mou__tieji"] = "铁骑",
  [":mou__tieji"] = "你可以令目标角色不能响应此【杀】，且其所有非锁定技失效直到回合结束。然后你与其进行谋弈。若你赢，且你选择的选项为：“直取敌营”，则你获得其一张牌；“扰阵疲敌”，你摸两张牌。",
  ["tieji-zhiqu"] = "直取敌营: 谋奕成功后获得对方一张牌",
  ["tieji-raozheng"] = "扰阵疲敌:谋奕成功后你摸两张牌",
  ["tieji-chuzheng"] = "出阵迎敌",
  ["tieji-huwei"] = "拱卫中军",
  ["#mou__tieji-active"] = "铁骑:请选择你需要进行谋奕的选项",
  ["#tieji_log"] = "%from 发动了“%arg2”谋奕结果为【%arg】。",
 
}
return extension
