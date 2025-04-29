local awful = require("awful")
local gears = require("gears")

return function()
  local focused = awful.screen.focused()

  local hostname = io.popen("uname -n"):read("*l")
  local satUrl = io.popen("sat-base-url"):read("*l")

  local apps = {}

  if string.find(hostname, '13') then
    apps = {
      {
        tag = 1,
        exec = {
          'sesh connect generic',
          terminal_cmd .. ' attach-session -t generic',
        }
      },
      {
        tag = 2,
        exec = {
          'chromium --app=https://messenger.com',
        }
      },
      {
        tag = 3,
        exec = {
          'chromium --new-window https://gmail.com',
        }
      },
    }
  else
    apps = {
      {
        tag = 1,
        exec = {
          'chromium --new-window https://chatgpt.com',
          'sesh connect generic',
          terminal_cmd .. ' attach-session -t generic',
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
          'chromium https://google.com',
        }
      },
      --     {
      --       tag = 4,
      --       exec = {
      --         terminal_cmd,
      --
      --         function()
      --           local client = focused.tags[1]:clients()[2]
      --
      --           if client then
      --             client:toggle_tag(focused.tags[4])
      --           end
      --         end,
      --       }
      --     },
      {
        tag = 8,
        exec = {
          'chromium --new-window ' .. satUrl .. '/resources/transactions',
          'chromium --new-window ' .. satUrl .. '/resources/articles',
        }
      },
      {
        tag = 9,
        exec = {
          'chromium --app=http://l4/' .. os.date('%Y') .. '.html',
        }
      },
    }
  end

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
