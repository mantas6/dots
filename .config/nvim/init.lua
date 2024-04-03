require("plugins")
require("lsp")

vim.opt.scrolloff = 5

vim.opt.relativenumber = true
vim.opt.number = true

-- Set default tab size to 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.api.nvim_set_option("clipboard", "unnamed")

vim.g.mapleader = " "
