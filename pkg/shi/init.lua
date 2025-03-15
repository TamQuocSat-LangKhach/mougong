local extension = Package:new("mou_shi")
extension.extensionName = "mougong"

extension:loadSkillSkelsByPath("./packages/mougong/pkg/shi/skills")

Fk:loadTranslationTable{
  ["mou_shi"] = "谋攻篇-识包",
}

General:new(extension, "mou__fazheng", "shu", 3):addSkills { "mou__xuanhuo", "mou__enyuan" }
Fk:loadTranslationTable{
  ["mou__fazheng"] = "谋法正",
  ["#mou__fazheng"] = "经学思谋",

  ["~mou__fazheng"] = "蜀翼双折，吾主王业，就靠孔明了……",
}

return extension
