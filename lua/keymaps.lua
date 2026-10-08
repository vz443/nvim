local M = {}

local function set(mode, lhs, rhs, desc, opts)
  opts = vim.tbl_extend('force', { desc = desc }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.setup_lsp(event, formatting)
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

  if formatting.supports(client, event.buf) then
    set_buffer('n', '<leader>cf', function()
      formatting.format(event.buf)
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
  set({ 'i', 's' }, '<Tab>', function()
    if vim.fn.pumvisible() == 1 then
      return vim.fn.complete_info({ 'selected' }).selected == -1 and '<C-n><C-y>' or '<C-y>'
    end
    if vim.snippet.active({ direction = 1 }) then
      return '<Cmd>lua vim.snippet.jump(1)<CR>'
    end
    return '<Tab>'
  end, 'Completion: accept or jump to next snippet argument', { expr = true })

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
    ['<C-k>'] = { command = '<cmd>resize +2<cr>', description = 'Pane: increase height' },
    ['<C-j>'] = { command = '<cmd>resize -2<cr>', description = 'Pane: decrease height' },
    ['<C-h>'] = { command = '<cmd>vertical resize -2<cr>', description = 'Pane: decrease width' },
    ['<C-l>'] = { command = '<cmd>vertical resize +2<cr>', description = 'Pane: increase width' },
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
