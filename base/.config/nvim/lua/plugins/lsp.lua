return {
  'VonHeikemen/lsp-zero.nvim',
  branch = 'v3.x',
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-nvim-lsp',
    'L3MON4D3/LuaSnip',
  },
  config = function ()
    local lsp = require('lsp-zero')

    lsp.on_attach(function(client, bufnr)
      -- see :help lsp-zero-keybindings
      -- to learn the available actions
      lsp.default_keymaps({buffer = bufnr})
    end)

    require('mason').setup({})
    require('mason-lspconfig').setup({
      ensure_installed = {
        "intelephense",
        "bashls",
        "lua_ls",
        "volar",
        "dockerls",
        "cssls",
        "jsonls",
        "gopls",
      },
      handlers = {
        lsp.default_setup,
      },
    })
  end
}
