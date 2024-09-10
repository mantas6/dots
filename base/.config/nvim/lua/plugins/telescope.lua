return {
  "nvim-telescope/telescope.nvim",

  tag = '0.1.6',

  dependencies = {
    "nvim-lua/plenary.nvim"
  },

  config = function()
    require('telescope').setup({
      pickers = {
       find_files = { hidden = true },
      },
    })

    local builtin = require('telescope.builtin')
    local utils = require("telescope.utils")

    vim.keymap.set('n', '<leader>pp', builtin.find_files, {})
    vim.keymap.set('n', '<leader>pa', function() builtin.find_files({ no_ignore = true, prompt_title = 'All Files' }) end)
    vim.keymap.set('n', '<leader>pf', builtin.live_grep, {})
    vim.keymap.set('n', '<leader>pd', function ()
      builtin.find_files({ cwd = utils.buffer_dir() })
    end)

    vim.keymap.set('n', '<leader>pw', builtin.grep_string, {})

    vim.keymap.set('n', '<leader>pb', builtin.buffers, {})
    vim.keymap.set('n', '<leader>ph', builtin.oldfiles, {})
    vim.keymap.set('n', '<leader>ps', builtin.git_status, {})
    vim.keymap.set('n', '<leader>pr', builtin.resume, {})

    vim.keymap.set('n', '<leader>p"', builtin.registers, {})
    vim.keymap.set('n', '<leader>pq', builtin.command_history, {})
  end
}
