return {
  "nvim-neo-tree/neo-tree.nvim",

  branch = "v3.x",

  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "muniftanjim/nui.nvim",
  },

  config = function ()
    require('neo-tree').setup({
      enable_diagnostics = true,
      -- hijack_netrw_behavior = 'open_current',
    });

    vim.keymap.set('n', '<leader>ss', ':Neotree toggle<CR>', {})
    vim.keymap.set('n', '<leader>sr', ':Neotree reveal<CR>', {})
  end
}
