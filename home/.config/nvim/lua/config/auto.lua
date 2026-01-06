local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local group = augroup('MyAutoCommands', { clear = true })
local yank_group = augroup('HighlightYank', {})

autocmd('TextYankPost', {
  group = yank_group,
  pattern = '*',
  callback = function()
    vim.hl.on_yank({
      higroup = 'IncSearch',
      timeout = 40,
    })
  end,
})

autocmd('BufEnter', {
  group = group,
  callback = function()
    vim.opt.autoindent = true
    vim.opt.smartindent = true
  end
})

autocmd('FileType', {
  pattern = {
    'lua',
    'vue',
    'nix',
    'ts',
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'javascript.vue',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  command = 'setlocal shiftwidth=2 softtabstop=2 expandtab',
})

autocmd({ "BufWritePre" }, {
  group = group,
  pattern = "*",
  command = [[%s/\s\+$//e]],
})
