local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local function createWidget(command, icon)
    local widget = wibox.widget.textbox();

    gears.timer {
        timeout   = 5,
        call_now  = true,
        autostart = true,
        callback  = function()
            awful.spawn.easy_async(
            {"sh", "-c", command},
                function(out)
                    local color = '#bfbfbf';
                    widget.markup = string.format('<span foreground="%s"> %s   %s</span>', color, icon, out)
                end
            )
        end
    }

    return widget
end

return createWidget

