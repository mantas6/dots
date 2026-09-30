-- Build hooks (must be registered before the first vim.pack.add)
local function build(cmd, path)
  if vim.fn.executable(cmd[1]) ~= 1 then
    return vim.notify(cmd[1] .. ' is not installed, skipping build in ' .. path, vim.log.levels.WARN)
  end

  local result = vim.system(cmd, { cwd = path }):wait()
  if result.code ~= 0 then
    vim.notify(table.concat(cmd, ' ') .. ' failed in ' .. path .. '\n' .. result.stderr, vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('pack-build', { clear = true }),
  callback = function(ev)
    local name, kind, path = ev.data.spec.name, ev.data.kind, ev.data.path

    if kind ~= 'install' and kind ~= 'update' then
      return
    end

    if name == 'LuaSnip' then
      build({ 'make', 'install_jsregexp' }, path)
    end

    if name == 'telescope-fzf-native.nvim' then
      build({ 'make' }, path)
    end

    if name == 'nvim-treesitter' and kind == 'update' then
      if not ev.data.active then
        vim.cmd.packadd('nvim-treesitter')
      end
      require('nvim-treesitter').update()
    end
  end,
})

local gh = function(x)
  return 'https://github.com/' .. x
end

vim.pack.add({
  gh('stevearc/conform.nvim'),
  gh('lewis6991/gitsigns.nvim'),
  gh('neovim/nvim-lspconfig'),
  gh('mason-org/mason.nvim'),
  gh('mason-org/mason-lspconfig.nvim'),
  -- gh('WhoIsSethDaniel/mason-tool-installer.nvim'),
  { src = gh('saghen/blink.cmp'), version = vim.version.range('1') },
  { src = gh('L3MON4D3/LuaSnip'), version = vim.version.range('2') },
  gh('nvimtools/none-ls.nvim'),
  gh('nvim-lua/plenary.nvim'),
  gh('MeanderingProgrammer/render-markdown.nvim'),
  gh('nvim-tree/nvim-web-devicons'),
  gh('stevearc/oil.nvim'),
  gh('NMAC427/guess-indent.nvim'),
  gh('numToStr/Comment.nvim'),
  { src = gh('nvim-telescope/telescope.nvim'), version = 'v0.2.1' },
  gh('nvim-telescope/telescope-fzf-native.nvim'),
  gh('rafamadriz/neon'),
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
}, { confirm = false })

require('plugins.theme')
require('plugins.fmt')
require('plugins.git')
require('plugins.lsp')
require('plugins.cmp')
require('plugins.lsp-shim')
require('plugins.markdown')
require('plugins.oil')
require('plugins.other')
require('plugins.telescope')
require('plugins.treesitter')

-- nvim native plugins
vim.cmd.packadd('nvim.tohtml')
