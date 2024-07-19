local awful = require("awful")
local wibox = require("wibox")
local createWidget = require("statusbar-widget")

local module = {};

module.keyboard = awful.widget.keyboardlayout()

module.clock = wibox.widget.textclock("    %a %d %H:%M:%S", 1)

module.ping = createWidget("ping -c 1 google.com | grep 'time=' | awk -F 'time=' '{print $2}'", '')

-- Battery

local batteryPath = '/sys/class/power_supply/BAT0'
module.battery = createWidget("printf \"%s\" \"$(cat "..batteryPath.."/capacity):$(cat "..batteryPath.."/status)\"", function(params)
    local percentage = string.match(params.text, "([^:]+)")
    local status = string.match(params.text, ":(.+)"):match("^%s*(.-)%s*$")

    if status == 'Not charging' then
        params.icon = ''
        params.color = '#c0c0c0';
    elseif status == 'Charging' then
        params.icon = '󱐋'
        params.color = '#ffa500';
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

        if percentNum > 20 then
            params.color = '#57996e';
        else
            params.color = '#be2908';
        end
    end

    params.text = percentage..'%'
end)


module.memory = createWidget("free -h | awk '/Mem:/ {print $3}'", '󰘚')
module.load = createWidget("cut -d ' ' -f1 < /proc/loadavg", '')
module.updates = createWidget("checkupdates | wc -l", '󰏗', 300)
module.journal = createWidget('curl "$SAT_JOURNAL_WC_URI"', '', 600)
-- module.track = createWidget("track show", '', 5)
module.cpuf = createWidget("echo $(grep MHz /proc/cpuinfo | sed 's/.* //' | awk '{sum += $1} END {if (NR > 0) printf \"%.1f\", sum / NR / 1000}')G/$(grep MHz /proc/cpuinfo | sed 's/.* //' | sort -rn | awk 'NR==1 {printf \"%.1f\", $1 / 1000}')G", '󰓅', 3)
module.rain = createWidget("meteo -r | jq -r '[.[] | select(.totalPrecipitation > 0)] | .[0] | .forecastTime'", '󰖗', 300);

-- cat /proc/loadavg | cut -d ' ' -f1
-- free -h | awk '/Mem:/ {print $3}'

return module
