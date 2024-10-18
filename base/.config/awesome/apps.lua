local awful = require("awful")
local gears = require("gears")

return function()
  local focused = awful.screen.focused()

  local apps = {
    {
      tag = 1,
      exec = {
        'chromium --new-window https://chatgpt.com',
        terminal_cmd,
      }
    },
    {
      tag = 2,
      exec = {
        'chromium --app=https://messenger.com',
        'chromium',
      }
    },
    {
      tag = 3,
      exec = {
        'chromium --new-window https://www.youtube.com/feed/subscriptions',
        'chromium --new-window https://www.netflix.com/browse',
        'chromium https://wiki.archlinux.org/title/Main_page',
      }
    },
    {
      tag = 4,
      exec = {
        terminal_cmd,

        function()
          local first_client = nil
          for _, c in ipairs(focused.tags[1]:clients()) do
            first_client = c
            break
          end

          if first_client then
            first_client:toggle_tag(focused.tags[4])
          end
        end
      }
    },
    {
      tag = 5,
      exec = { terminal_cmd }
    },
    {
      tag = 8,
      exec = {
        'chromium --new-window ' .. os.getenv('SAT_BASE_URL') .. '/resources/transactions',
        'chromium --new-window ' .. os.getenv('SAT_BASE_URL') .. '/resources/articles',
      }
    },
    {
      tag = 9,
      exec = {
        'chromium --app=http://l4/' .. os.date('%Y') .. '.html',
      }
    },
  }

  local timeout = 0

  for _, group in ipairs(apps) do
    -- If tag has clients, skip it
    if #focused.tags[group.tag]:clients() > 0 then
      goto continue
    end

    -- Jump to tag of the application
    gears.timer.start_new(timeout, function()
      focused.tags[group.tag]:view_only()
    end)

    -- Spawn the clients
    for _, cmd in ipairs(group.exec) do
      gears.timer.start_new(timeout, function()
        if type(cmd) == 'function' then
          cmd()
        else
          awful.spawn(cmd)
        end
      end)

      timeout = timeout + 0.5
    end

    ::continue::
  end

  gears.timer.start_new(timeout, function()
    focused.tags[1]:view_only()
  end)
end
