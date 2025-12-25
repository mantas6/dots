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

vim.api.nvim_set_keymap('n', '<leader>h', ':lua ToggleHighlightSearch()<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>bl', ':lua ToggleSpellLang() <CR>', { desc = 'Toggle spelllang between en and lt' })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('configured-lsp-attach', { clear = true }),
  callback = function(args)
    local ft = vim.bo[args.buf].filetype

    if ft == 'php' then
      vim.keymap.set('n', '<leader>bm', ':silent w | :silent !php-fmt-ns %:p <CR>', { buffer = args.buf })
    end
    vim.keymap.set('n', '<leader>br', vim.lsp.buf.rename, { buffer = args.buf })
    vim.keymap.set('n', '<leader>bn', vim.lsp.buf.code_action, { buffer = args.buf })

    vim.keymap.set('n', '<leader>bp', function()
      vim.lsp.buf.format({
        filter = function(client)
          if ft == 'php' then
            return client.name == 'null-ls'
          else
            return true
          end
        end,
        bufnr = args.buf,
      });
    end, { buffer = args.buf })
  end,
})


vim.api.nvim_set_keymap('n', '<leader>yb', ':silent !echo %:. | xc<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>yd', ':silent !dirname %:. | xc<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>yf', ':silent !basename %:. | xc<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ya', ':silent !echo %:p | xc<CR>', {})

vim.api.nvim_set_keymap('n', '<leader>ec', ':e composer.json <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>ep', ':e PRESENTATION.md <CR>', {})
vim.api.nvim_set_keymap('n', '<leader>el', ':e LINKS.md <CR>', {})
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

local function add_bible_text(type)
  local output = vim.fn.system('curl -fsSL "$(sat-base-url)/api/bible/' .. type .. '"')
  output = output:gsub("\n$", "")

  vim.cmd('normal! i' .. output .. '  ')
end

vim.keymap.set('n', '<leader>-', function() add_bible_text('word') end, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>_', function() add_bible_text('random') end, { noremap = true, silent = true })
