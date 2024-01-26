local tong = require 'packages.mougong.tong'
local yu = require 'packages.mougong.yu'
local zhi = require 'packages.mougong.zhi'
local shi = require 'packages.mougong.shi'
local neng = require 'packages.mougong.neng'

Fk:loadTranslationTable{
  ["mou"] = "谋",
  ["mougong"] = "谋攻篇",
}

return {
  tong,
  yu,
  zhi,
  neng,
  shi,
}
