local awful = require("awful")
local wibox = require("wibox")
local createWidget = require("statusbar-widget")

local module = {};

module.keyboard = awful.widget.keyboardlayout()

module.bar = createWidget("bar", function (params)
  params.text = string.gsub(params.text, ' ', '   ')
  params.icon = ''
end, 2)

return module
