-- SPDX-License-Identifier: GPL-3.0-or-later

-- require("packages.mougong.i18n.en_US")

local prefix = "packages.mougong.pkg."

local neng = require (prefix .. "neng")
local shi = require (prefix .. "shi")
local tong = require (prefix .. "tong")
local yu = require (prefix .. "yu")

Fk:loadTranslationTable {
    ["mougong"] = "谋攻篇",
    ["mou"] = "谋",

    ["neng"] = "能",
    ["shi"] = "识",
    ["tong"] = "同",
    ["yu"] = "虞",
}

return {
    neng,
    shi,
    tong,
    yu,
}
