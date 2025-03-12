-- SPDX-License-Identifier: GPL-3.0-or-later

-- require("packages.mougong.i18n.en_US")

local prefix = "packages.mougong.pkg."

local neng = require (prefix .. "neng")

Fk:loadTranslationTable {
    ["mougong"] = "谋攻篇",
    ["mou"] = "谋",
}

return {
    neng,
}
