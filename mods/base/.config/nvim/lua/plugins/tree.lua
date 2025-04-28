return {
  "nvim-neo-tree/neo-tree.nvim",

  branch = "v3.x",

  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "muniftanjim/nui.nvim",
  },

  opts = {
    enable_diagnostics = true,
    hijack_netrw_behavior = 'disabled',
    filesystem = {
      filtered_items = {
        visible = true,   -- This is what you want: If you set this to `true`, all "hide" just mean "dimmed out"
        hide_dotfiles = false,
        hide_gitignored = true,
        hide_by_name = {
          '.git',
          '.DS_Store',
        },
      },
    },
  },

  keys = {
    { '<C-t>', ':Neotree reveal<CR>', desc = 'neo-tree' },
  },
}
