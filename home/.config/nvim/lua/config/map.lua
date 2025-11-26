function ToggleHighlightSearch()
  if vim.o.hlsearch then
    vim.o.hlsearch = false
  else
    vim.o.hlsearch = true
  end
end

function ToggleSpellLang()
  if vim.bo.spelllang == 'en' then
    vim.bo.spelllang = 'lt'
    print('Spell language: Lithuanian')
  else
    vim.bo.spelllang = 'en'
    print('Spell language: English')
  end
end

-- function ToggleVirtualText()
--   -- local bufnr = vim.api.nvim_get_current_buf()
--   local current = vim.diagnostic.config().virtual_text
--   vim.diagnostic.config({ virtual_text = not current })
-- end
-- vim.keymap.set('n', '<leader>bv', ':lua ToggleVirtualText() <CR>', { desc = 'Toggle virtual text' })

-- Map <leader>h to toggle search highlighting
vim.api.nvim_set_keymap('n', '<leader>h', ':lua ToggleHighlightSearch()<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>bl', ':lua ToggleSpellLang() <CR>', { desc = 'Toggle spelllang between en and lt' })

vim.keymap.set('n', '<leader>bp', ':LspZeroFormat<CR>')
vim.api.nvim_set_keymap('n', '<leader>bm', ':silent w | :silent !zero fmt %:p <CR>', {})
vim.keymap.set('n', '<leader>bn', vim.lsp.buf.code_action, {})

vim.api.nvim_set_keymap('n', '<leader>yb', ':silent !echo %:. | xc<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>yd', ':silent !dirname %:. | xc<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>yf', ':silent !basename %:. | xc<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ya', ':silent !echo %:p | xc<CR>', {})

vim.api.nvim_set_keymap('n', '<leader>ec', ':e composer.json <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ep', ':e presentation.md <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ed', ':e *compose.y* <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>en', ':e .env <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>er', ':e README.md <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ei', ':e .gitignore <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ex', ':e .git/info/exclude <CR>', {})

vim.keymap.set('n', '<leader>z', '1z=')
vim.keymap.set('n', '<leader>a', '<C-^>')
vim.keymap.set('n', '<leader>w', '<C-w>w')

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- alias :W to :w
vim.api.nvim_command('command W write')

vim.api.nvim_command('command X set splitright | vsp | terminal bash %:p')

vim.keymap.set("n", "<C-f>", "<C-f>zz")
vim.keymap.set("n", "<C-b>", "<C-b>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")


vim.keymap.set("x", "<leader>v", [["_dP]])
