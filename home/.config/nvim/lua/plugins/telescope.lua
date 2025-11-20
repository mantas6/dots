return {
  "nvim-telescope/telescope.nvim",

  tag = '0.1.8',

  dependencies = {
    "nvim-lua/plenary.nvim"
  },

  config = function()
    require('telescope').setup({
      defaults = {
        sorting_strategy = 'descending',
        borderchars = { '', '', '', '', '', '', '', '' },
        path_displays = 'smart',
        layout_strategy = 'horizontal',
        layout_config = {
          height = 100,
          width = 400,
          prompt_position = 'bottom',
          preview_cutoff = 0,
        }
      },
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
    vim.keymap.set('n', '<leader>pF', ':Telescope live_grep search_dirs={""}<Left><Left>', {})

    vim.keymap.set('n', '<leader>pd', function()
      builtin.find_files({ cwd = utils.buffer_dir() })
    end)

    vim.keymap.set('n', '<leader>pD', function()
      builtin.find_files({ cwd = utils.buffer_dir():match('(.*/)') })
    end)

    vim.keymap.set('n', '<leader>pw', builtin.grep_string, {})

    vim.keymap.set('n', '<leader>pb', builtin.buffers, {})
    vim.keymap.set('n', '<leader>pq', builtin.oldfiles, {})
    vim.keymap.set('n', '<leader>ps', builtin.git_status, {})
    vim.keymap.set('n', '<leader>pr', builtin.resume, {})

    vim.keymap.set('n', '<leader>p"', builtin.registers, {})
    vim.keymap.set('n', '<leader>p:', builtin.command_history, {})

    vim.keymap.set('n', '<leader>pl', builtin.lsp_document_symbols, {})
    vim.keymap.set('n', '<leader>pk', builtin.lsp_references, {})
    vim.keymap.set('n', '<leader>pm', builtin.marks, {})
    vim.keymap.set('n', '<leader>pz', builtin.spell_suggest, {})

    vim.keymap.set('n', '<leader>pc', builtin.git_bcommits, {})
    vim.keymap.set('n', '<leader>ph', builtin.help_tags, { desc = 'Telescope help tags' })
  end
}
