return {
    "nvim-telescope/telescope.nvim",

    tag = '0.1.6',

    dependencies = {
        "nvim-lua/plenary.nvim"
    },

    config = function()
        require('telescope').setup({})

        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>pp', builtin.find_files, {})
        vim.keymap.set('n', '<leader>pf', builtin.live_grep, {})
        vim.keymap.set('n', '<leader>pb', builtin.buffers, {})
        vim.keymap.set('n', '<leader>ps', builtin.git_status, {})
    end
}
