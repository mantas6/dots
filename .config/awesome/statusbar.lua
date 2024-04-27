local awful = require("awful")
local wibox = require("wibox")
local createWidget = require("statusbar-widget")

local module = {};

module.keyboard = awful.widget.keyboardlayout()

module.clock = wibox.widget.textclock("%a %d %H:%M:%S", 1)

module.ping = awful.widget.watch("bash -c \"echo -n '    '&& ping -c 1 google.com | grep 'time=' | awk -F 'time=' '{print $2}'\"", 5);

module.ping = createWidget("ping -c 1 google.com | grep 'time=' | awk -F 'time=' '{print $2}'", '')
module.battery = createWidget("echo $(</sys/class/power_supply/BAT0/capacity)%", '󱐋')
module.memory = createWidget("free -h | awk '/Mem:/ {print $3}'", '󰘚')
module.load = createWidget("cut -d ' ' -f1 < /proc/loadavg", '')

-- cat /proc/loadavg | cut -d ' ' -f1
-- free -h | awk '/Mem:/ {print $3}'

return module
