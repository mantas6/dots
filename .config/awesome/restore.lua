-- Save and restore tags, when monitor setup is changed
local naughty = require("naughty")
local awful = require("awful")

local tag_store = {}

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
    local output = next(t.screen.outputs)

    if tag_store[output] == nil then
      tag_store[output] = {}
    end

    clients = t:clients()
    tag_store[output][t.name] = clients

    for _, c in ipairs(clients) do
      c:move_to_tag(fallback_tag)
    end
  end
end)

screen.connect_signal("added", function(s)
  local output = next(s.outputs)
  naughty.notify({ text = output .. " Connected" })

  tags = tag_store[output]
  if not (tags == nil) then
    naughty.notify({ text = "Restoring Tags" })

    for _, tag in ipairs(s.tags) do
      clients = tags[tag.name]
      if not (clients == nil) then
        for _, client in ipairs(clients) do
          client:move_to_tag(tag)
        end
      end
    end
  end
end)
