return {
  -- Main LSP Configuration
  'neovim/nvim-lspconfig',
  dependencies = {
    {
      'mason-org/mason.nvim',
      opts = {},
    },
    'mason-org/mason-lspconfig.nvim',
    -- 'WhoIsSethDaniel/mason-tool-installer.nvim',
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

        map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
        map('gl', function()
          vim.diagnostic.open_float({ scope = 'line' })
        end, '[G]et [L]ine Diagnostics')
      end,
    })

    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
      callback = function()
        vim.lsp.buf.clear_references()
      end,
    })

    local user = os.getenv('USER') or os.getenv('USERNAME')
    local hostname = vim.loop.os_gethostname()

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
      nixd = {
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
                expr = '(builtins.getFlake "/home/'
                  .. user
                  .. '/.dots").nixosConfigurations.'
                  .. hostname
                  .. '.options',
              },
              --   home_manager = {
              --       expr = '(builtins.getFlake "/PATH/TO/FLAKE").homeConfigurations.CONFIGNAME.options',
              --   },
            },
          },
        },
      },
    }

    local ensure_installed = vim.tbl_filter(function(s)
      return s ~= 'nixd'
    end, vim.tbl_keys(servers or {}))

    vim.list_extend(ensure_installed, {
      -- You can add other tools here that you want Mason to install
    })

    -- require('mason-tool-installer').setup({ ensure_installed = ensure_installed })

    for name, server in pairs(servers) do
      vim.lsp.config(name, server)
      vim.lsp.enable(name)
    end
  end,
}
