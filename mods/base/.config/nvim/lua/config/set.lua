vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.o.termguicolors = true

vim.opt.scrolloff = 8

vim.opt.relativenumber = true
vim.opt.number = true

-- Set default tab size to 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.opt.hlsearch = false
vim.opt.ignorecase = true

vim.api.nvim_set_option("clipboard", "unnamedplus")

vim.opt.spell = true
vim.opt.spelllang = { 'en_us' }

vim.diagnostic.config({ virtual_text = true })
