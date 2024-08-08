return {
  "lewis6991/gitsigns.nvim",

  config = function ()
    require('gitsigns').setup({
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },

      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation through hunks
        map('n', ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, {expr=true})

        -- Navigation through hunks
        map('n', '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, {expr=true})

        -- Actions
        map('n', '<leader>gS', gs.stage_buffer)
        map('n', '<leader>ga', gs.stage_hunk)
        map('n', '<leader>gu', gs.undo_stage_hunk)
        map('n', '<leader>gR', gs.reset_buffer)
        map('n', '<leader>gp', gs.preview_hunk)
        map('n', '<leader>gv', ':<C-U>Gitsigns select_hunk<CR>')

        map('n', '<leader>gd', gs.diffthis)
        -- map('n', '<leader>gD', function() gs.diffthis('~') end)
      end
    })
  end
}
