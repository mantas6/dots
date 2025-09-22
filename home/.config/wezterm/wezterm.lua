local w = require 'wezterm'

local c = w.config_builder()
local a = w.action

c.disable_default_key_bindings = true
c.disable_default_mouse_bindings = true
c.enable_tab_bar = false

c.send_composed_key_when_left_alt_is_pressed = false
c.send_composed_key_when_right_alt_is_pressed = false

c.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

c.font_size = 16
c.color_scheme = 'Tokyo Night'

c.keys = {
  {
    key = 'c',
    mods = 'SUPER',
    action = a.CopyTo 'Clipboard'
  },
  {
    key = 'v',
    mods = 'SUPER',
    action = a.PasteFrom 'Clipboard'
  },
}

-- wezterm start --title "My Custom Title"
-- w.on("window-focus-changed", function(window, pane)
--   if not window:is_focused() then
--     window:perform_action(w.action.CloseCurrentTab { confirm = false }, pane)
--   end
-- end)

return c
