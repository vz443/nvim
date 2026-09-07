vim.pack.add{
  { src = 'https://github.com/neovim/nvim-lspconfig' },
}


-- vim configs

vim.diagnostic.config({
  virtual_text = true,      -- Inline error messages
  signs = true,             -- Gutter symbols
  underline = true,         -- Underline problem code
  update_in_insert = false, -- Don't shift text while typing
  severity_sort = true,
})


-- clangd

 local clangd_opts = {
	 cmd = { 'clangd', '--background-index'}
 }


 if not vim.lsp.is_enabled('clangd') then
     vim.lsp.enable('clangd', clangd_opts)
 end

 -- md renderer
vim.pack.add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-mini/mini.nvim',            -- if you use the mini.nvim suite
    -- 'https://github.com/nvim-mini/mini.icons',        -- if you use standalone mini plugins
    -- 'https://github.com/nvim-tree/nvim-web-devicons', -- if you prefer nvim-web-devicons
    'https://github.com/MeanderingProgrammer/render-markdown.nvim',
})
