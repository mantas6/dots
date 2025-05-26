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
        "vue_ls",
        "dockerls",
        "cssls",
        "jsonls",
        "gopls",
        "pyright",
        "ts_ls",
      },
      handlers = {
        lsp.default_setup,
      },
    })

    local user = os.getenv("USER") or os.getenv("USERNAME");
    local hostname = vim.loop.os_gethostname()

    require("lspconfig").nixd.setup({
      cmd = { "nixd" },
      settings = {
        nixd = {
          nixpkgs = {
            expr = "import <nixpkgs> { }",
          },
          formatting = {
            command = { "alejandra" }, -- or nixfmt or nixpkgs-fmt
          },
          options = {
            nixos = {
                expr = '(builtins.getFlake "/home/'..user..'/.dots").nixosConfigurations.'..hostname..'.options',
            },
          --   home_manager = {
          --       expr = '(builtins.getFlake "/PATH/TO/FLAKE").homeConfigurations.CONFIGNAME.options',
          --   },
          },
        },
      },
    })
  end
}
