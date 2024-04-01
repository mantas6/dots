vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use {
      'VonHeikemen/lsp-zero.nvim',
      branch = 'v3.x',
      requires = {
        {'williamboman/mason.nvim'},
        {'williamboman/mason-lspconfig.nvim'},

        {'neovim/nvim-lspconfig'},
        {'hrsh7th/nvim-cmp'},
        {'hrsh7th/cmp-nvim-lsp'},
        {'L3MON4D3/LuaSnip'},
      }
    }
end)
