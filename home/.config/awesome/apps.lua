local awful = require("awful")
local gears = require("gears")

return function()
  local focused = awful.screen.focused()

  local hostname = io.popen("uname -n"):read("*l")
  local satUrl = io.popen("sat-base-url"):read("*l")

  local apps = {}

  if string.find(hostname, 'tp') then
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
          'chromium --new-window https://meteofor.lt/weather-alytus-4152/month',
        }
      },
      {
        tag = 3,
        exec = {
          'firefox --new-window https://www.youtube.com/feed/subscriptions',
          'chromium --new-window https://www.icloud.com/reminders',
        }
      },
      {
        tag = 4,
        exec = {
          'sesh connect large',
          terminal .. '  -o font.size=50 -e tmux attach-session -t large',
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
          'chromium --new-window ' .. satUrl .. '/Kd4z7q/resources/transactions',
          'chromium --new-window ' .. satUrl .. '/Kd4z7q/resources/articles',
        }
      },
      {
        tag = 9,
        exec = {
          'chromium --app=http://gal/' .. os.date('%Y') .. '.html',
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
