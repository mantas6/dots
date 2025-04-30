local awful = require("awful")
local wibox = require("wibox")
local createWidget = require("statusbar-widget")

local module = {};

module.keyboard = awful.widget.keyboardlayout()

module.clock = wibox.widget.textclock("    %a %d %H:%M:%S", 1)

module.ping = createWidget("status-mod ping", '')

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

        if percentNum == nil then
          params.text = ''
          params.icon = ''
          return
        end

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


module.memory = createWidget("status-mod memory", '󰘚')
module.load = createWidget("status-mod cpu", '')
module.cpuf = createWidget("status-mod frequency", '󰓅', 3)

module.temp = createWidget("status-mod temperature", '󰏈', 5)
module.disk = createWidget("status-mod disk", '', 60)

return module
