return {
  'nvimtools/none-ls.nvim',

  config = function()
    local null_ls = require("null-ls")
    local h = require("null-ls.helpers")

    local calc_ls = h.make_builtin({
      name = "calc-ls",
      method = null_ls.methods.DIAGNOSTICS,
      filetypes = { "php" },
      generator_opts = {
        command = "calc-ls",
        args = {},
        to_stdin = true,
        format = "json",
        runtime_condition = function(params)
          return params.bufname:match("%.calc%.php$") ~= nil
        end,
        on_output = function(params)
          local diags = {}
          for _, item in ipairs(params.output) do
            table.insert(diags, {
              row = item.line,
              message = item.message,
              severity = h.diagnostics.severities["hint"],
            })
          end
          return diags
        end,
      },
      factory = h.generator_factory,
    })

    null_ls.setup({
      sources = {
        null_ls.builtins.diagnostics.phpstan,
        -- null_ls.builtins.formatting.pint,
        -- null_ls.builtins.formatting.shfmt,
        calc_ls,
      },
    })
  end,
}
