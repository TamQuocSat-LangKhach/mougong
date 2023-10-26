-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package("mougong_token", Package.CardPack)
extension.extensionName = "mougong"

Fk:loadTranslationTable{
  ["mougong_token"] = "谋攻篇衍生牌",
}

local peaceSpellSkill = fk.CreateTriggerSkill{
  name = "#mougong__peace_spell_skill",
  attached_equip = "mougong__peace_spell",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.damageType ~= fk.NormalDamage
  end,
  on_use = function(self, event, target, player, data)
    return true
  end,
}
local mougong__peace_spell_maxcards = fk.CreateMaxCardsSkill{
  name = "#mougong__peace_spell_maxcards",
  correct_func = function(self, player)
    if player:hasSkill("#mougong__peace_spell_skill") then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms - 1
    else
      return 0
    end
  end,
}
peaceSpellSkill:addRelatedSkill(mougong__peace_spell_maxcards)
Fk:addSkill(peaceSpellSkill)
local mougong__peace_spell = fk.CreateArmor{
  name = "&mougong__peace_spell",
  suit = Card.Heart,
  number = 3,
  equip_skill = peaceSpellSkill,
  on_uninstall = function(self, room, player)
    Armor.onUninstall(self, room, player)
    if not player.dead and self.equip_skill:isEffectable(player) then
      player:drawCards(2, self.name)
      if player.hp > 1 then
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
extension:addCard(mougong__peace_spell)
Fk:loadTranslationTable{
  ["mougong__peace_spell"] = "太平要术",
  [":mougong__peace_spell"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，防止你受到的属性伤害；你的手牌上限+X（X为存活势力数-1）；"..
  "当你失去装备区里的【太平要术】后，你摸两张牌，然后若你的体力值大于1，则你失去1点体力。",
}

return extension
