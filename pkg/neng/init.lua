local extension = Package:new("mou_neng")
extension.extensionName = "mougong"

extension:loadSkillSkelsByPath("./packages/mougong/pkg/neng/skills")

Fk:loadTranslationTable{
  ["mou_neng"] = "谋攻篇-能包",
}

General:new(extension, "mou__sunshangxiang", "shu", 4, 4, General.Female):addSkills {
  "mou__jieyin",
  "mou__liangzhu",
  "mou__xiaoji",
}
Fk:loadTranslationTable{
  ["mou__sunshangxiang"] = "谋孙尚香",
  ["#mou__sunshangxiang"] = "骄豪明俏",
  ["illustrator:mou__sunshangxiang"] = "暗金",

  ["~mou__sunshangxiang"] = "此去一别，竟无再见之日……",
}

General:new(extension, "mou__yuanshao", "qun", 4):addSkills { "mou__luanji", "mou__xueyi" }
Fk:loadTranslationTable{
  ["mou__yuanshao"] = "谋袁绍",
  ["#mou__yuanshao"] = "高贵的名门",

  ["~mou__yuanshao"] = "我不可能输给曹阿瞒，不可能！",
}

return extension
