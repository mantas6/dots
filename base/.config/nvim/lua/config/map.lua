function ToggleHighlightSearch()
  if vim.o.hlsearch then
    vim.o.hlsearch = false
  else
    vim.o.hlsearch = true
  end
end

function CopyCurrentBufferPath()
  local filepath = vim.fn.expand('%:~:.')
  vim.fn.setreg('+', filepath) -- Copy to system clipboard
  vim.fn.setreg('"', filepath) -- Copy to unnamed register (default for pasting)
  print('Copied buffer name: ' .. filepath)
end

-- Map <leader>h to toggle search highlighting
vim.api.nvim_set_keymap('n', '<leader>h', ':lua ToggleHighlightSearch()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>bf', ':LspZeroFormat<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>by', ':lua CopyCurrentBufferPath()<CR>', {})

vim.api.nvim_set_keymap('n', '<leader>bm', ':!zero fmt %:p<CR>', {})

-- alias :W to :w
vim.api.nvim_command('command W write')

vim.api.nvim_command('command X set splitright | vsp | terminal bash %:p')
