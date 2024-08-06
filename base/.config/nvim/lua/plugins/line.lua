return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },

    config = function ()
        require('lualine').setup({
            options = {
                section_separators = '',
                component_separators = '',
                globalstatus = true,
            },
            sections = {
                lualine_x = {'filetype', 'filesize'},
                lualine_y = {},
            },
        })
    end
}
