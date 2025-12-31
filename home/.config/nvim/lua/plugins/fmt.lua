return {
  'stevearc/conform.nvim',

  config = function()
    require("conform").setup({
      notify_on_error = false,
      notify_no_formatters = false,
      default_format_opts = {
        async = true,
        lsp_format = 'first',
        stop_after_first = false,
      },
      formatters_by_ft = {
        php = { 'php-fmt-ns', 'pint' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
      },
      formatters = {
        ['php-fmt-ns'] = {
          command = 'php-fmt-ns',
          args = { '--stdin', '$FILENAME' },
        },
      },
    })
  end,
}
