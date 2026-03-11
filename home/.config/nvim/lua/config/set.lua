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

vim.o.signcolumn = 'yes'

vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.updatetime = 250
vim.o.timeoutlen = 500

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.spell = true
vim.opt.spelllang = 'en'

vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = {
    severity = {
      min = vim.diagnostic.severity.WARN,
    },
  },

  -- Can switch between these as you prefer
  virtual_text = true, -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  -- jump = { float = true },
})

-- vim.o.grepprg = 'set grepprg=rg --vimgrep --no-heading --smart-case'
