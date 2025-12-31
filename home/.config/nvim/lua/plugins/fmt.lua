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
        php = { 'pint' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
      },
    })
  end,
}
