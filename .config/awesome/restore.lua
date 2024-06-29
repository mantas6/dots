-- Save and restore tags, when monitor setup is changed
local naughty = require("naughty")
local awful = require("awful")

tag.connect_signal("request::screen", function(t)
  local fallback_tag = nil

  -- find tag with same name on any other screen
  for other_screen in screen do
    if other_screen ~= t.screen then
      fallback_tag = awful.tag.find_by_name(other_screen, t.name)
      if fallback_tag ~= nil then
        break
      end
    end
  end

  -- no tag with same name exists, chose random one
  if fallback_tag == nil then
    fallback_tag = awful.tag.find_fallback()
  end

  if not (fallback_tag == nil) then
    local clients = t:clients()

    for _, c in ipairs(clients) do
      -- TODO: support for multitag clients
      c:move_to_tag(fallback_tag)
    end
  end
end)
