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

vim.api.nvim_set_keymap('n', '<leader>bm', ':silent w | :silent !zero fmt %:p | :e <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>w', ':silent w | :silent !./tinker-autocmd % <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>W', ':silent w | !./tinker-autocmd % <CR>', {})

vim.api.nvim_set_keymap('n', '<leader>ew', ':e tinker-autocmd <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ec', ':e composer.json <CR>', {})

-- alias :W to :w
vim.api.nvim_command('command W write')

vim.api.nvim_command('command X set splitright | vsp | terminal bash %:p')

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>v", [["_dP]])
