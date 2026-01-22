return {
  'stevearc/conform.nvim',

  config = function()
    require("conform").setup({
      notify_on_error = false,
      notify_no_formatters = false,

      -- log_level = vim.log.levels.DEBUG,

      default_format_opts = {
        async = true,
        lsp_format = 'first',
        stop_after_first = false,
      },

      formatters_by_ft = {
        php = { 'php-fmt-ns', 'pint' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        go = {},
        markdown = { 'prettier' },
        html = { 'prettier' },
        blade = { 'prettier' },
      },

      formatters = {
        ['php-fmt-ns'] = {
          command = 'php-fmt-ns',
          args = { '--stdin', '$FILENAME' },
        },

        rector = {
          command = 'rector',
          args = { '$FILENAME' },
          cwd = require('conform.util').root_file({ 'rector.php' }),
          require_cwd = true,
          stdin = false,
        },
      },
    })
  end,
}
