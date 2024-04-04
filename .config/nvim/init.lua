require("plugins")
require("lsp")
require("treesitter")

vim.opt.scrolloff = 8

vim.opt.relativenumber = true
vim.opt.number = true

-- Set default tab size to 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.api.nvim_set_option("clipboard", "unnamed")

vim.g.neon_style = "default"
vim.g.neon_transparent = true
vim.cmd[[colorscheme neon]]

-- Keymap
vim.g.mapleader = " "

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>p', builtin.find_files, {})
vim.keymap.set('n', '<leader>f', builtin.live_grep, {})
