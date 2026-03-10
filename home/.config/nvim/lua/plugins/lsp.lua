return {
  -- Main LSP Configuration
  'neovim/nvim-lspconfig',
  dependencies = {
    {
      'mason-org/mason.nvim',
      opts = {},
    },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'saghen/blink.cmp',
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        -- Not sure if I need this
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        local client = vim.lsp.get_client_by_id(event.data.client_id)

        if client and client:supports_method('textDocument/inlayHint', event.buf) then
          map('<leader>bh', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
      callback = function()
        vim.lsp.buf.clear_references()
      end,
    })

    ---@type table<string, vim.lsp.Config>
    local servers = {
      intelephense = {},
      bashls = {},
      dockerls = {},
      cssls = {},
      jsonls = {},
      pyright = {},
      gopls = {},
      lua_ls = {},
      ts_ls = {
        filetypes = {
          'javascript',
          'javascriptreact',
          'javascript.jsx',
          'javascript.vue',
          'typescript',
          'typescriptreact',
          'typescript.tsx',
        },
      },
    }

    local user = os.getenv('USER') or os.getenv('USERNAME')
    local hostname = vim.loop.os_gethostname()

    vim.lsp.config('nixd', {
      cmd = { 'nixd' },
      settings = {
        nixd = {
          nixpkgs = {
            expr = 'import <nixpkgs> { }',
          },
          formatting = {
            command = { 'alejandra' }, -- or nixfmt or nixpkgs-fmt
          },
          options = {
            nixos = {
              expr = '(builtins.getFlake "/home/' .. user .. '/.dots").nixosConfigurations.' .. hostname .. '.options',
            },
            --   home_manager = {
            --       expr = '(builtins.getFlake "/PATH/TO/FLAKE").homeConfigurations.CONFIGNAME.options',
            --   },
          },
        },
      },
    })

    vim.lsp.enable({ 'nixd' })

    -- Ensure the servers and tools above are installed
    --
    -- To check the current status of installed tools and/or manually install
    -- other tools, you can run
    --    :Mason
    --
    -- You can press `g?` for help in this menu.
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      -- You can add other tools here that you want Mason to install
    })

    require('mason-tool-installer').setup({ ensure_installed = ensure_installed })

    for name, server in pairs(servers) do
      vim.lsp.config(name, server)
      vim.lsp.enable(name)
    end
  end,
}
-- return {
--   'VonHeikemen/lsp-zero.nvim',
--   branch = 'v3.x',
--   dependencies = {
--     'williamboman/mason.nvim',
--     'williamboman/mason-lspconfig.nvim',
--     'neovim/nvim-lspconfig',
--     'hrsh7th/nvim-cmp',
--     'hrsh7th/cmp-nvim-lsp',
--     'L3MON4D3/LuaSnip',
--   },
--   config = function()
--     local lsp = require('lsp-zero')
--
--     lsp.on_attach(function(client, bufnr)
--       -- see :help lsp-zero-keybindings
--       -- to learn the available actions
--       lsp.default_keymaps({
--         buffer = bufnr,
--         exclude = { 'go', 'gi' },
--       })
--     end)
--
--     require('mason').setup({})
--     require('mason-lspconfig').setup({
--       ensure_installed = {
--         'intelephense',
--         'bashls',
--         'lua_ls',
--         'dockerls',
--         'cssls',
--         'jsonls',
--         'gopls',
--         'pyright',
--         'ts_ls',
--       },
--       handlers = {
--         lsp.default_setup,
--       },
--     })
--
--     local user = os.getenv('USER') or os.getenv('USERNAME')
--     local hostname = vim.loop.os_gethostname()
--
--     vim.lsp.config('ts_ls', {
--       filetypes = {
--         'javascript',
--         'javascriptreact',
--         'javascript.jsx',
--         'javascript.vue',
--         'typescript',
--         'typescriptreact',
--         'typescript.tsx',
--       },
--     })
--
--     -- vim.lsp.config.nixd = {
--     -- require("lspconfig").nixd.setup({
--     vim.lsp.config('nixd', {
--       cmd = { 'nixd' },
--       settings = {
--         nixd = {
--           nixpkgs = {
--             expr = 'import <nixpkgs> { }',
--           },
--           formatting = {
--             command = { 'alejandra' }, -- or nixfmt or nixpkgs-fmt
--           },
--           options = {
--             nixos = {
--               expr = '(builtins.getFlake "/home/' .. user .. '/.dots").nixosConfigurations.' .. hostname .. '.options',
--             },
--             --   home_manager = {
--             --       expr = '(builtins.getFlake "/PATH/TO/FLAKE").homeConfigurations.CONFIGNAME.options',
--             --   },
--           },
--         },
--       },
--     })
--
--     vim.lsp.enable({ 'nixd' })
--   end,
-- }
