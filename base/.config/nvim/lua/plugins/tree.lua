return {
    'nvim-tree/nvim-tree.lua',

    dependencies = {
        'nvim-tree/nvim-web-devicons',
    },

    config = function ()
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        vim.opt.termguicolors = true

        vim.keymap.set('n', '<leader>ss', ':NvimTreeToggle<CR>', {})
        vim.keymap.set('n', '<leader>sr', ':NvimTreeFindFile<CR>', {})

        local function on_attach(bufnr)
          local api = require "nvim-tree.api"

          local function opts(desc)
            return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end

          -- default mappings
          api.config.mappings.default_on_attach(bufnr)

          -- custom mappings
          vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
        end

        require("nvim-tree").setup {
            on_attach = on_attach,
        }
    end
}
