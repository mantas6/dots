local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local function createWidget(command, formatter)
    local widget = wibox.widget.textbox();

    gears.timer {
        timeout   = 5,
        call_now  = true,
        autostart = true,
        callback  = function()
            awful.spawn.easy_async(
            {"sh", "-c", command},
                function(out)
                    local params = {
                        color = '#bfbfbf',
                        icon = '󰕟',
                        text = out,
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

