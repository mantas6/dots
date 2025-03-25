return {
  "nvim-neo-tree/neo-tree.nvim",

  branch = "v3.x",

  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "muniftanjim/nui.nvim",
  },

  config = function()
    require('neo-tree').setup({
      enable_diagnostics = true,
      -- hijack_netrw_behavior = 'open_current',
      filesystem = {
        filtered_items = {
          visible = true, -- This is what you want: If you set this to `true`, all "hide" just mean "dimmed out"
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = {
            '.git',
            '.DS_Store',
          },
        },
      },
    });

    vim.keymap.set('n', '<leader>s', ':Neotree reveal<CR>', {})
  end
}
