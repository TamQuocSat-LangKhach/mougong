-- SPDX-License-Identifier: GPL-3.0-or-later

-- require("packages.mougong.i18n.en_US")

local prefix = "packages.mougong.pkg."

local neng = require (prefix .. "neng")
local shi = require (prefix .. "shi")

Fk:loadTranslationTable {
    ["mougong"] = "谋攻篇",
    ["mou"] = "谋",
    ["shi"] = "识",
}

return {
    neng,
    shi,
}
