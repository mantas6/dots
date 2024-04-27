local awful = require("awful")
local wibox = require("wibox")

local module = {};

module.keyboard = awful.widget.keyboardlayout()

module.clock = wibox.widget.textclock("%a %d %H:%M:%S", 1)

module.ping = awful.widget.watch("bash -c \"echo -n '    '&& ping -c 1 google.com | grep 'time=' | awk -F 'time=' '{print $2}'\"", 5);

module.battery = awful.widget.watch('bash -c \'echo " 󱐋 " $(</sys/class/power_supply/BAT0/capacity)%\' ', 15);

module.load = awful.widget.watch("bash -c \"echo -n '    ' && cut -d ' ' -f1 < /proc/loadavg\"", 5);

module.memory = awful.widget.watch("bash -c \"echo -n ' 󰘚  ' && free -h | awk '/Mem:/ {print $3}'\"", 5);

-- cat /proc/loadavg | cut -d ' ' -f1
-- free -h | awk '/Mem:/ {print $3}'

return module
