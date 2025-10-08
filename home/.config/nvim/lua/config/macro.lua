local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local group = augroup('MyMacroCommands', { clear = true })

autocmd('BufEnter', {
  group = group,
  pattern = '*',
  callback = function()
    vim.fn.setreg('l',  "oconsole.log()ha")
    vim.fn.setreg('k',  "oconsole.log({})hha")
    vim.fn.setreg('f',  "A() => {}")
    vim.fn.setreg('m',  "$a() {}==@o")
    vim.fn.setreg('o',  "^f}i\nO//")
    vim.fn.setreg('p',  "f_x~")
    vim.fn.setreg('i',  "f-i\nll")
  end
})

-- vim.keymap.set("n", "<leader>ml", "oconsole.log()<Esc>ha")
-- vim.keymap.set("n", "<leader>mo", "$i<Enter><Esc>O")
