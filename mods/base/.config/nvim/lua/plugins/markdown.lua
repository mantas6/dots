return {
  {
    'MeanderingProgrammer/render-markdown.nvim',

    opts = {
      code = {
        -- Determines how the top / bottom of code block are rendered.
        -- | none  | do not render a border                               |
        -- | thick | use the same highlight as the code body              |
        -- | thin  | when lines are empty overlay the above & below icons |
        -- | hide  | conceal lines unless language name or icon is added  |
        border = 'thin',
      },
      heading = { enabled = false },
    },

    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  },
}
