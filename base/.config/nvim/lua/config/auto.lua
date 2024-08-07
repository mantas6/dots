local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local group = augroup('MyAutoCommands', { clear = true })

autocmd('BufEnter', {
    group = group,
    callback = function()
        vim.opt.autoindent = true
        vim.opt.smartindent = true
    end
})

autocmd('FileType', {
    pattern = { 'lua', 'javascript', 'vue' },
    command = 'setlocal shiftwidth=2 softtabstop=2 expandtab',
})

