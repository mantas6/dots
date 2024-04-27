local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

local function create()
    local widget = wibox.widget.textbox();

    gears.timer {
        timeout   = 10,
        call_now  = true,
        autostart = true,
        callback  = function()
            awful.spawn.easy_async(
            {"sh", "-c", "cut -d ' ' -f1 < /proc/loadavg"},
                function(out)
                    local icon = '';
                    local color = '#737373';
                    widget.markup = string.format('<span foreground="%s"> %s   %s</span>', color, icon, out)
                end
            )
        end
    }

    return widget
end

return create
