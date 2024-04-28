local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local function createWidget(command, formatter, timeout)
    local widget = wibox.widget.textbox();
    timeout = timeout or 5

    gears.timer {
        timeout   = timeout,
        call_now  = true,
        autostart = true,
        callback  = function()
            awful.spawn.easy_async(
            {"sh", "-c", command},
                function(out, _err, _reason, exitCode)
                    local params = {
                        color = '#bfbfbf',
                        icon = '󰕟',
                        text = exitCode == 0 and out or '-',
                    }

                    if type(formatter) == 'function' then
                        formatter(params)
                    else
                        params.icon = formatter
                    end

                    widget.markup = string.format('<span foreground="%s"> %s   %s</span>', params.color, params.icon, params.text)
                end
            )
        end
    }

    return widget
end

return createWidget

