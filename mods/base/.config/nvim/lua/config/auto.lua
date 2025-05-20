local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local group = augroup('MyAutoCommands', { clear = true })
local yank_group = augroup('HighlightYank', {})

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

autocmd('BufEnter', {
    group = group,
    callback = function()
        vim.opt.autoindent = true
        vim.opt.smartindent = true
    end
})

autocmd('FileType', {
    pattern = { 'lua', 'javascript', 'vue', 'nix' },
    command = 'setlocal shiftwidth=2 softtabstop=2 expandtab',
})

autocmd({"BufWritePre"}, {
    group = group,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

vim.filetype.add({
  pattern = {
    [".*%.blade%.php"] = "html",
  },
})
