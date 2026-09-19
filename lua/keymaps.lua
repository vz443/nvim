local M = {}

local function set(mode, lhs, rhs, desc, opts)
  opts = vim.tbl_extend('force', { desc = desc }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.setup_lsp(event)
  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if not client then
    return
  end

  local function set_buffer(mode, lhs, rhs, desc)
    set(mode, lhs, rhs, desc, {
      buffer = event.buf,
      silent = true,
    })
  end

  set_buffer('n', 'gd', vim.lsp.buf.definition, 'LSP: go to definition')
  set_buffer('n', 'gD', vim.lsp.buf.declaration, 'LSP: go to declaration')
  set_buffer('n', 'gi', vim.lsp.buf.implementation, 'LSP: go to implementation')
  set_buffer('n', 'gr', vim.lsp.buf.references, 'LSP: find references')
  set_buffer('n', 'K', vim.lsp.buf.hover, 'LSP: hover documentation')
  set_buffer('n', '<leader>rn', vim.lsp.buf.rename, 'LSP: rename symbol')
  set_buffer('n', '<leader>ca', vim.lsp.buf.code_action, 'LSP: code action')
  set_buffer('n', '<leader>cd', vim.diagnostic.open_float, 'Diagnostics: open float')

  if client.name == 'clangd' then
    set_buffer('n', '<leader>ch', '<cmd>LspClangdSwitchSourceHeader<cr>', 'Clangd: switch source/header')
  end

  if client:supports_method('textDocument/completion') then
    vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    set_buffer('i', '<C-Space>', vim.lsp.completion.get, 'LSP: trigger completion')
  end

  if client:supports_method('textDocument/formatting') then
    set_buffer('n', '<leader>cf', function()
      vim.lsp.buf.format({ async = true, bufnr = event.buf })
    end, 'LSP: format buffer')
  end

  if client:supports_method('textDocument/inlayHint') then
    set_buffer('n', '<leader>uh', function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
    end, 'LSP: toggle inlay hints')
  end
end

function M.setup(telescope_builtin, dap)
  set('n', '<leader>e', '<cmd>Ex<cr>', 'Open netrw explorer')
  set('n', '<leader>ff', telescope_builtin.find_files, 'Telescope: find files')
  set('n', '<leader>fg', telescope_builtin.live_grep, 'Telescope: live grep')
  set('n', '<leader>fb', telescope_builtin.buffers, 'Telescope: buffers')
  set('n', '<leader>fd', telescope_builtin.diagnostics, 'Telescope: diagnostics')

  set('n', '[d', vim.diagnostic.goto_prev, 'Diagnostics: previous')
  set('n', ']d', vim.diagnostic.goto_next, 'Diagnostics: next')
  set('n', '<leader>q', vim.diagnostic.setloclist, 'Diagnostics: location list')

  local pane_directions = {
    h = 'left',
    j = 'below',
    k = 'above',
    l = 'right',
  }

  for key, direction in pairs(pane_directions) do
    local description = 'Pane: focus ' .. direction
    set('n', '<C-' .. key .. '>', '<C-w>' .. key, description)
    set('t', '<C-' .. key .. '>', '<C-\\><C-N><C-W>' .. key, description)
  end

  local shifted_pane_directions = {
    H = 'h',
    L = 'l',
  }

  for key, direction in pairs(shifted_pane_directions) do
    local description = 'Pane: focus ' .. (direction == 'h' and 'left' or 'right')
    set('n', key, '<C-w>' .. direction, description)
    set('t', key, '<C-\\><C-N><C-W>' .. direction, description)
  end

  local pane_resize_mappings = {
    ['<C-Up>'] = { command = '<cmd>resize +2<cr>', description = 'Pane: increase height' },
    ['<C-Down>'] = { command = '<cmd>resize -2<cr>', description = 'Pane: decrease height' },
    ['<C-Left>'] = { command = '<cmd>vertical resize -2<cr>', description = 'Pane: decrease width' },
    ['<C-Right>'] = { command = '<cmd>vertical resize +2<cr>', description = 'Pane: increase width' },
  }

  for key, mapping in pairs(pane_resize_mappings) do
    set('n', key, mapping.command, mapping.description)
    set('t', key, '<C-\\><C-N>' .. mapping.command, mapping.description)
  end

  if not dap then
    return
  end

  set('n', '<F5>', dap.continue, 'Debug: continue')
  set('n', '<F10>', dap.step_over, 'Debug: step over')
  set('n', '<F11>', dap.step_into, 'Debug: step into')
  set('n', '<F12>', dap.step_out, 'Debug: step out')
  set({ 'n', 'v' }, '<leader>db', dap.toggle_breakpoint, 'Debug: toggle breakpoint')
  set('n', '<leader>dB', function()
    dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
  end, 'Debug: conditional breakpoint')
  set('n', '<leader>dc', dap.continue, 'Debug: continue')
  set('n', '<leader>dr', dap.repl.open, 'Debug: open REPL')
  set('n', '<leader>dx', dap.terminate, 'Debug: terminate')
end

return M
