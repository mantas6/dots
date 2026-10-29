return {
  {
    'OXY2DEV/markview.nvim',
    -- Already lazy-loads itself; must load after the colorscheme (default priority is 50).
    lazy = false,
    priority = 49,

    opts = {
      preview = {
        icon_provider = 'devicons',
        -- Rendered in these modes; insert / visual show the raw buffer.
        modes = { 'n', 'no', 'c' },
        -- Keep empty so the cursor line is never un-rendered while moving around.
        hybrid_modes = {},
      },
      markdown = {
        headings = { enable = false },
        list_items = {
          -- No virtual indentation, so lists don't shift when switching to insert mode.
          marker_minus = { add_padding = false },
          marker_plus = { add_padding = false },
          marker_star = { add_padding = false },
        },
      },
    },

    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  },
}
