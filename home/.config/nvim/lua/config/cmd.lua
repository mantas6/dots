vim.api.nvim_create_user_command('F', function(opts)
  require('telescope.builtin').find_files({
    default_text = opts.args
  })
end, { nargs = 1 })
