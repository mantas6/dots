---@module 'oil'
---@type oil.SetupOpts
local opts = {
  default_file_explorer = true,
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  view_options = {
    show_hidden = true,
  },
}

require('oil').setup(opts)

-- vim.keymap.set('n', '<leader>o', ':Oil<CR>')
vim.keymap.set('n', '-', ':Oil<CR>')
