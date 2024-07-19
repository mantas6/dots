require("config.lazy")

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local group = augroup('MyAutoCommands', { clear = true })

autocmd('BufEnter', {
    group = group,
    callback = function()
        vim.opt.autoindent = true
        vim.opt.smartindent = true
    end
})

vim.opt.scrolloff = 8

vim.opt.relativenumber = true
vim.opt.number = true

-- Set default tab size to 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true



vim.opt.hlsearch = false

vim.api.nvim_set_option("clipboard", "unnamedplus")


vim.opt.spell = true
vim.opt.spelllang = { 'en_us' }

-- Keymap
-- TODO: move to separate file
vim.g.mapleader = " "


-- NvimTree
vim.keymap.set('n', '<leader>ss', ':NvimTreeToggle<CR>', {})
vim.keymap.set('n', '<leader>sr', ':NvimTreeFindFile<CR>', {})
