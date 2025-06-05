return {
  "nvim-telescope/telescope.nvim",

  tag = '0.1.8',

  dependencies = {
    "nvim-lua/plenary.nvim"
  },

  config = function()
    require('telescope').setup({
      pickers = {
        find_files = { hidden = true },
        grep_string = {
          additional_args = { "--hidden" }
        },
        live_grep = {
          additional_args = { "--hidden", "--fixed-strings" }
        },
        git_files = { use_git_root = false },
        -- git_status = { use_git_root = false },
      },
    })

    local builtin = require('telescope.builtin')
    local utils = require("telescope.utils")

    -- vim.keymap.set('n', '<C-p>', builtin.git_files, {})
    vim.keymap.set('n', '<leader>pe', builtin.git_files, {})
    vim.keymap.set('n', '<leader>pa', function() builtin.find_files({ no_ignore = true, prompt_title = 'All Files' }) end)
    vim.keymap.set('n', '<leader>pf', builtin.live_grep, {})
    vim.keymap.set('n', '<leader>pd', function()
      builtin.find_files({ cwd = utils.buffer_dir() })
    end)

    vim.keymap.set('n', '<leader>pw', builtin.grep_string, {})

    vim.keymap.set('n', '<leader>pb', builtin.buffers, {})
    vim.keymap.set('n', '<leader>ph', builtin.oldfiles, {})
    vim.keymap.set('n', '<leader>ps', builtin.git_status, {})
    vim.keymap.set('n', '<leader>pr', builtin.resume, {})

    vim.keymap.set('n', '<leader>p"', builtin.registers, {})
    vim.keymap.set('n', '<leader>pq', builtin.command_history, {})

    vim.keymap.set('n', '<leader>pl', builtin.lsp_document_symbols, {})
    vim.keymap.set('n', '<leader>pm', builtin.marks, {})
  end
}
