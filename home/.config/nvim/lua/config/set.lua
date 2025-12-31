vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.o.termguicolors = true

vim.opt.scrolloff = 8

vim.opt.relativenumber = true
vim.opt.number = true

-- Set default tab size to 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.o.undofile = true
vim.o.swapfile = false

vim.o.hlsearch = false
vim.o.ignorecase = true
vim.o.smartcase = true
-- vim.o.inccommand = 'split'

vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.spell = true
vim.opt.spelllang = 'en'

vim.diagnostic.config({ virtual_text = true })

-- vim.o.grepprg = 'set grepprg=rg --vimgrep --no-heading --smart-case'
