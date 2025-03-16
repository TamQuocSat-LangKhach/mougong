local extension = Package:new("mou_shi")
extension.extensionName = "mougong"

extension:loadSkillSkelsByPath("./packages/mougong/pkg/shi/skills")

Fk:loadTranslationTable{
  ["mou_shi"] = "谋攻篇-识包",
}

General:new(extension, "mou__machao", "shu", 4):addSkills { "mashu", "mou__tieji" }
Fk:loadTranslationTable{
  ["mou__machao"] = "谋马超",
  ["#mou__machao"] = "阻戎负勇",

  ["~mou__machao"] = "父兄妻儿具丧，吾有何面目活于世间……",
}

General:new(extension, "mou__fazheng", "shu", 3):addSkills { "mou__xuanhuo", "mou__enyuan" }
Fk:loadTranslationTable{
  ["mou__fazheng"] = "谋法正",
  ["#mou__fazheng"] = "经学思谋",

  ["~mou__fazheng"] = "蜀翼双折，吾主王业，就靠孔明了……",
}

General:new(extension, "mou__diaochan", "qun", 3, 3, General.Female):addSkills { "mou__lijian", "mou__biyue" }
Fk:loadTranslationTable{
  ["mou__diaochan"] = "谋貂蝉",
  ["#mou__diaochan"] = "绝世的舞姬",

  ["~mou__diaochan"] = "终不负阿父之托……",
}

General:new(extension, "mou__chengong", "qun", 3):addSkills { "mou__mingce", "mou__zhichi" }
Fk:loadTranslationTable{
  ["mou__chengong"] = "谋陈宫",
  ["#mou__chengong"] = "刚直壮烈",

  ["~mou__chengong"] = "何必多言！宫唯求一死……",
}

General:new(extension, "mou__pangtong", "shu", 3):addSkills { "mou__lianhuan", "mou__niepan" }
Fk:loadTranslationTable{
  ["mou__pangtong"] = "谋庞统",
  ["#mou__pangtong"] = "凤雏",
	["illustrator:mou__pangtong"] = "铁杵文化",

  ["~mou__pangtong"] = "落凤坡，果真为我葬身之地……",
}

General:new(extension, "mou__xuhuang", "wei", 4):addSkills { "mou__duanliang", "mou__shipo" }
Fk:loadTranslationTable{
  ["mou__xuhuang"] = "谋徐晃",
  ["#mou__xuhuang"] = "径行截辎",

  ["~mou__xuhuang"] = "为主效劳，何畏生死……",
}

General:new(extension, "mou__zhanghe", "wei", 4):addSkills { "mou__qiaobian" }
Fk:loadTranslationTable{
  ["mou__zhanghe"] = "谋张郃",

  ["~mou__zhanghe"] = "未料竟中孔明之计……",
}

return extension
