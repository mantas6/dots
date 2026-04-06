-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require('lazy').setup({
  spec = {
    -- { 'NMAC427/guess-indent.nvim', opts = {} },
    require('plugins.bookmarks'),
    require('plugins.fmt'),
    require('plugins.git'),
    require('plugins.lsp'),
    require('plugins.cmp'),
    require('plugins.lsp-shim'),
    require('plugins.markdown'),
    require('plugins.oil'),
    require('plugins.other'),
    require('plugins.telescope'),
    require('plugins.theme'),
    require('plugins.treesitter'),
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { 'habamax' } },
  -- automatically check for plugin updates
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
})
