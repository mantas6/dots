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

config.font_size = 20
config.color_scheme = 'Tokyo Night'
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
config.font = wezterm.font('JetBrains Mono', {
  -- harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
})

config.enable_kitty_graphics = true
config.max_fps = 144
config.window_decorations = 'RESIZE'
config.window_close_confirmation = 'NeverPrompt'

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
  {
    key = '0',
    mods = 'SUPER',
    action = action.ResetFontSize
  },
  {
    key = '=',
    mods = 'SUPER',
    action = action.IncreaseFontSize
  },
  {
    key = '-',
    mods = 'SUPER',
    action = action.DecreaseFontSize
  },
}

-- wezterm start --title "My Custom Title"
-- WEZ_ONESHOT=1 wezterm start --title "Wezterm Oneshot"
local isOneShot = os.getenv('WEZ_ONESHOT')

if isOneShot then
  -- config.window_class
  wezterm.on('window-focus-changed', function(window, pane)
    if not window:is_focused() then
      window:perform_action(wezterm.action.CloseCurrentTab { confirm = false }, pane)
    end
  end)
end

return config
