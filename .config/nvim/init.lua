require("plugins")
require("tree")
require("lsp")
require("treesitter")

vim.opt.scrolloff = 8

vim.opt.relativenumber = true
vim.opt.number = true

-- Set default tab size to 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- vim.opt.autoindent = true
-- vim.opt.smartindent = true

vim.opt.hlsearch = false

vim.api.nvim_set_option("clipboard", "unnamed")

vim.o.termguicolors = true
vim.g.neon_style = "default"
vim.g.neon_italic_keyword = true
vim.g.neon_italic_function = true
vim.g.neon_transparent = true
vim.cmd[[colorscheme neon]]

-- Keymap
-- TODO: move to separate file
vim.g.mapleader = " "

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>oo', builtin.find_files, {})
vim.keymap.set('n', '<leader>of', builtin.live_grep, {})
vim.keymap.set('n', '<leader>ob', builtin.buffers, {})

-- NvimTree
vim.keymap.set('n', '<leader>ss', ':NvimTreeToggle<CR>', {})
vim.keymap.set('n', '<leader>sr', ':NvimTreeFindFile<CR>', {})


-- if place up to, hotkey doesnt work
require("harpoon_config")
