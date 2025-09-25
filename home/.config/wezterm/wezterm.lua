local wezterm = require 'wezterm'

local config = wezterm.config_builder()
local action = wezterm.action

config.disable_default_key_bindings = true
config.disable_default_mouse_bindings = true
config.enable_tab_bar = false

config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

config.font_size = 16
config.color_scheme = 'Tokyo Night'
config.font = wezterm.font('JetBrains Mono', {})

config.keys = {
  {
    key = 'c',
    mods = 'SUPER',
    action = action.CopyTo 'Clipboard'
  },
  {
    key = 'v',
    mods = 'SUPER',
    action = action.PasteFrom 'Clipboard'
  },
}

-- wezterm start --title "My Custom Title"
-- wezterm start --env MY_CUSTOM_ARG="hello-world"
-- -- local my_arg = os.getenv("MY_CUSTOM_ARG")
-- wezterm.on("window-focus-changed", function(window, pane)
--   if not window:is_focused() then
--     window:perform_action(wezterm.action.CloseCurrentTab { confirm = false }, pane)
--   end
-- end)

return config
