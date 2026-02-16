return {
  "norcalli/nvim-colorizer.lua",

  config = function()
    require('colorizer').setup({ 'html', 'blade', 'css', 'vue' }, { names = false })
  end
}
