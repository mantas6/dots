local awful = require("awful")
local wibox = require("wibox")
local createWidget = require("statusbar-widget")

local module = {};

module.keyboard = awful.widget.keyboardlayout()

module.clock = wibox.widget.textclock("    %a %d %H:%M:%S", 1)

module.ping = createWidget("status-mod ping", '')

module.bar = createWidget("bar", function (params)
  params.text = string.gsub(params.text, ' ', '   ')
  params.icon = ''
end, 3)

return module
