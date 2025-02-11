function ToggleHighlightSearch()
  if vim.o.hlsearch then
    vim.o.hlsearch = false
  else
    vim.o.hlsearch = true
  end
end

-- Map <leader>h to toggle search highlighting
vim.api.nvim_set_keymap('n', '<leader>h', ':lua ToggleHighlightSearch()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>bf', ':LspZeroFormat<CR>', {})

vim.api.nvim_set_keymap('n', '<leader>yb', ':silent !echo % | xc<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>yd', ':silent !dirname % | xc<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>yf', ':silent !basename % | xc<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ya', ':silent !echo %:p | xc<CR>', {})

vim.api.nvim_set_keymap('n', '<leader>bm', ':silent w | :silent !zero fmt %:p | :e <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>w', ':silent w | :silent !./tinker-autocmd % <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>W', ':silent w | !./tinker-autocmd % <CR>', {})

vim.api.nvim_set_keymap('n', '<leader>ew', ':e tinker-autocmd <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ec', ':e composer.json <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ep', ':e presentation.md <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ed', ':e *compose.y* <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>en', ':e .env <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>er', ':e README.md <CR>', {})

-- alias :W to :w
vim.api.nvim_command('command W write')

vim.api.nvim_command('command X set splitright | vsp | terminal bash %:p')

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>v", [["_dP]])
