vim.pack.add{
  { src = 'https://github.com/neovim/nvim-lspconfig' },
}

 -- `nvim-lspconfig` plugin. See |:h vim.lsp.Config| for all
 local clangd_opts = {}


 if not vim.lsp.is_enabled('clangd') then
     vim.lsp.enable('clangd', clangd_opts)
 end
