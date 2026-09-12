vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.mouse = 'a'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.undofile = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'popup' }
vim.opt.clipboard = vim.fn.has('unnamedplus') == 1 and 'unnamed,unnamedplus' or 'unnamed'

vim.cmd('filetype plugin indent on')
vim.cmd('syntax enable')

vim.pack.add({
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/nvim-mini/mini.nvim',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/windwp/nvim-autopairs',
  'https://github.com/mfussenegger/nvim-dap',
})

vim.diagnostic.config({
  virtual_text = { spacing = 2, source = 'if_many' },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
})

vim.lsp.config('clangd', {
  cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '--completion-style=detailed',
    '--header-insertion=iwyu',
  },
})

vim.lsp.config('rust_analyzer', {
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        allFeatures = true,
      },
      check = {
        command = 'clippy',
      },
      procMacro = {
        enable = true,
      },
    },
  },
})

local editor_group = vim.api.nvim_create_augroup('user-editor', { clear = true })
local lsp_group = vim.api.nvim_create_augroup('user-lsp', { clear = true })

require('nvim-treesitter').setup({})

vim.api.nvim_create_autocmd('FileType', {
  group = editor_group,
  pattern = { 'c', 'cpp', 'rust' },
  callback = function(event)
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.tabstop = 4

    local started = pcall(vim.treesitter.start, event.buf)
    if not started then
      vim.bo[event.buf].syntax = vim.bo[event.buf].filetype
    end
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = lsp_group,
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        buffer = event.buf,
        silent = true,
        desc = desc,
      })
    end

    map('n', 'gd', vim.lsp.buf.definition, 'LSP: go to definition')
    map('n', 'gD', vim.lsp.buf.declaration, 'LSP: go to declaration')
    map('n', 'gi', vim.lsp.buf.implementation, 'LSP: go to implementation')
    map('n', 'gr', vim.lsp.buf.references, 'LSP: find references')
    map('n', 'K', vim.lsp.buf.hover, 'LSP: hover documentation')
    map('n', '<leader>rn', vim.lsp.buf.rename, 'LSP: rename symbol')
    map('n', '<leader>ca', vim.lsp.buf.code_action, 'LSP: code action')
    map('n', '<leader>cd', vim.diagnostic.open_float, 'Diagnostics: open float')

    if client.name == 'clangd' then
      map('n', '<leader>ch', '<cmd>LspClangdSwitchSourceHeader<cr>', 'Clangd: switch source/header')
    end

    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
      map('i', '<C-Space>', function()
        vim.lsp.completion.get()
      end, 'LSP: trigger completion')
    end

    if client:supports_method('textDocument/formatting') then
      map('n', '<leader>cf', function()
        vim.lsp.buf.format({ async = true, bufnr = event.buf })
      end, 'LSP: format buffer')
    end

    if client:supports_method('textDocument/inlayHint') then
      map('n', '<leader>uh', function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
      end, 'LSP: toggle inlay hints')
    end
  end,
})

local formatter_names = {
  clangd = true,
  rust_analyzer = true,
}

vim.api.nvim_create_autocmd('BufWritePre', {
  group = lsp_group,
  callback = function(event)
    local has_formatter = false

    for _, client in ipairs(vim.lsp.get_clients({ bufnr = event.buf })) do
      if formatter_names[client.name] and client:supports_method('textDocument/formatting') then
        has_formatter = true
        break
      end
    end

    if has_formatter then
      vim.lsp.buf.format({
        bufnr = event.buf,
        async = false,
        timeout_ms = 2000,
        filter = function(client)
          return formatter_names[client.name] and client:supports_method('textDocument/formatting')
        end,
      })
    end
  end,
})

vim.lsp.enable({ 'clangd', 'rust_analyzer' })

require('nvim-autopairs').setup({})

local telescope = require('telescope')
telescope.setup({})

local telescope_builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>e', '<cmd>Ex<cr>', { desc = 'Open netrw explorer' })
vim.keymap.set('n', '<leader>t', telescope_builtin.find_files, { desc = 'Telescope: find files' })
vim.keymap.set('n', '<leader>ff', telescope_builtin.find_files, { desc = 'Telescope: find files' })
vim.keymap.set('n', '<leader>fg', telescope_builtin.live_grep, { desc = 'Telescope: live grep' })
vim.keymap.set('n', '<leader>fb', telescope_builtin.buffers, { desc = 'Telescope: buffers' })
vim.keymap.set('n', '<leader>fd', telescope_builtin.diagnostics, { desc = 'Telescope: diagnostics' })

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Diagnostics: previous' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Diagnostics: next' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics: location list' })

local pane_directions = {
  h = 'left',
  j = 'below',
  k = 'above',
  l = 'right',
}

for key, direction in pairs(pane_directions) do
  local description = 'Pane: focus ' .. direction
  vim.keymap.set('n', '<C-' .. key .. '>', '<C-w>' .. key, { desc = description })
  vim.keymap.set('t', '<C-' .. key .. '>', '<C-\\><C-N><C-W>' .. key, { desc = description })
end

local pane_resize_mappings = {
  ['<C-Up>'] = { command = '<cmd>resize +2<cr>', description = 'Pane: increase height' },
  ['<C-Down>'] = { command = '<cmd>resize -2<cr>', description = 'Pane: decrease height' },
  ['<C-Left>'] = { command = '<cmd>vertical resize -2<cr>', description = 'Pane: decrease width' },
  ['<C-Right>'] = { command = '<cmd>vertical resize +2<cr>', description = 'Pane: increase width' },
}

for key, mapping in pairs(pane_resize_mappings) do
  vim.keymap.set('n', key, mapping.command, { desc = mapping.description })
  vim.keymap.set('t', key, '<C-\\><C-N>' .. mapping.command, { desc = mapping.description })
end

local dap_ok, dap = pcall(require, 'dap')
if dap_ok then
  vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: continue' })
  vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Debug: step over' })
  vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Debug: step into' })
  vim.keymap.set('n', '<F12>', dap.step_out, { desc = 'Debug: step out' })
  vim.keymap.set({ 'n', 'v' }, '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: toggle breakpoint' })
  vim.keymap.set('n', '<leader>dB', function()
    dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
  end, { desc = 'Debug: conditional breakpoint' })
  vim.keymap.set('n', '<leader>dc', dap.continue, { desc = 'Debug: continue' })
  vim.keymap.set('n', '<leader>dr', dap.repl.open, { desc = 'Debug: open REPL' })
  vim.keymap.set('n', '<leader>dx', dap.terminate, { desc = 'Debug: terminate' })

  local debugger = vim.fn.exepath('codelldb')
  local adapter_name = 'codelldb'

  if debugger == '' then
    debugger = vim.fn.exepath('lldb-dap')
    adapter_name = 'lldb-dap'
  end

  if debugger == '' then
    vim.notify_once('nvim-dap: install codelldb or lldb-dap to debug C, C++, and Rust', vim.log.levels.WARN)
  else
    dap.adapters[adapter_name] = {
      type = 'executable',
      command = debugger,
      name = adapter_name,
    }

    local launch_configuration = {
      name = 'Launch executable',
      type = adapter_name,
      request = 'launch',
      program = function()
        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = function()
        local input = vim.fn.input('Arguments: ')
        return vim.split(input, '%s+', { trimempty = true })
      end,
    }

    for _, filetype in ipairs({ 'c', 'cpp', 'rust' }) do
      dap.configurations[filetype] = { vim.deepcopy(launch_configuration) }
    end
  end
end
