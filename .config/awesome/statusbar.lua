local awful = require("awful")
local wibox = require("wibox")
local createWidget = require("statusbar-widget")

local module = {};

module.keyboard = awful.widget.keyboardlayout()

module.clock = wibox.widget.textclock("%a %d %H:%M:%S", 1)

module.ping = createWidget("ping -c 1 google.com | grep 'time=' | awk -F 'time=' '{print $2}'", '')

-- Battery

local batteryPath = '/sys/class/power_supply/BAT0'
module.battery = createWidget("echo -n $(<"..batteryPath.."/capacity):$(<"..batteryPath.."/status)", function(params)
    local percentage = string.match(params.text, "([^:]+)")
    local status = string.match(params.text, ":(.+)"):match("^%s*(.-)%s*$")

    if status == 'Not charging' then
        params.icon = ''
    elseif status == 'Charging' then
        params.icon = '󱐋'
    else
        local percentNum = tonumber(percentage)

        if percentNum > 80 then
            params.icon = '' -- full
        elseif percentNum > 60 then
            params.icon = '' -- 2/3
        elseif percentNum > 40 then
            params.icon = '' -- 1/2
        elseif percentNum > 20 then
            params.icon = '' -- 1/3
        else
            params.icon = '' -- 0
        end
    end

    params.text = percentage..'%'
end)


module.memory = createWidget("free -h | awk '/Mem:/ {print $3}'", '󰘚')
module.load = createWidget("cut -d ' ' -f1 < /proc/loadavg", '')
module.updates = createWidget("checkupdates | wc -l", '󰏗', 300)

-- cat /proc/loadavg | cut -d ' ' -f1
-- free -h | awk '/Mem:/ {print $3}'

return module
