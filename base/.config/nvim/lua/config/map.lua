function ToggleHighlightSearch()
  if vim.o.hlsearch then
    vim.o.hlsearch = false
  else
    vim.o.hlsearch = true
  end
end

-- Map <leader>h to toggle search highlighting
vim.api.nvim_set_keymap('n', '<leader>h', ':lua ToggleHighlightSearch()<CR>', { noremap = true, silent = true })

-- alias :W to :w
vim.api.nvim_command('command W write')

vim.api.nvim_command('command X set splitright | vsp | terminal bash %:p')

