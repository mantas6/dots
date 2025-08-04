return {
  "rafamadriz/neon",
  config = function()
    vim.g.neon_style = "default"
    vim.g.neon_italic_keyword = true
    vim.g.neon_italic_function = true
    vim.g.neon_transparent = true
    vim.cmd [[colorscheme neon]]
    vim.cmd [[highlight statusline guibg=NONE]]
  end
}
