local M = {}

local c_style = require('c_style')

local formatter_names = {
  rust_analyzer = true,
}

local function is_c_family(bufnr)
  local filetype = vim.bo[bufnr].filetype
  return filetype == 'c' or filetype == 'cpp'
end

local function clang_format_path()
  local path = vim.fn.exepath('clang-format')
  return path ~= '' and path or nil
end

local function format_c(bufnr, timeout_ms)
  local executable = clang_format_path()
  if not executable then
    vim.notify('clang-format is required to format C and C++', vim.log.levels.ERROR)
    return false
  end

  local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local input = table.concat(current_lines, '\n')
  if vim.bo[bufnr].endofline then
    input = input .. '\n'
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == '' then
    filename = vim.bo[bufnr].filetype == 'cpp' and 'buffer.cpp' or 'buffer.c'
  end

  local result = vim.system({
    executable,
    '--style=' .. c_style.clang_format_style(),
    '--assume-filename=' .. filename,
  }, {
    stdin = input,
    text = true,
  }):wait(timeout_ms)

  if result.code ~= 0 then
    local message = result.stderr and vim.trim(result.stderr) or 'unknown error'
    vim.notify('clang-format failed: ' .. message, vim.log.levels.ERROR)
    return false
  end

  local output = result.stdout or ''
  local has_endofline = output:sub(-1) == '\n'
  if has_endofline then
    output = output:sub(1, -2)
  end

  local formatted_lines = output == '' and {} or vim.split(output, '\n', { plain = true })
  if vim.deep_equal(current_lines, formatted_lines) and vim.bo[bufnr].endofline == has_endofline then
    return true
  end

  local views = {}
  for _, window in ipairs(vim.fn.win_findbuf(bufnr)) do
    views[window] = vim.api.nvim_win_call(window, vim.fn.winsaveview)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted_lines)
  vim.bo[bufnr].endofline = has_endofline

  for window, view in pairs(views) do
    if vim.api.nvim_win_is_valid(window) and vim.api.nvim_win_get_buf(window) == bufnr then
      vim.api.nvim_win_call(window, function()
        vim.fn.winrestview(view)
      end)
    end
  end

  return true
end

function M.supports(client, bufnr)
  if is_c_family(bufnr) then
    return client.name == 'clangd' and clang_format_path() ~= nil
  end

  return formatter_names[client.name] and client:supports_method('textDocument/formatting')
end

function M.available(bufnr)
  if is_c_family(bufnr) then
    return clang_format_path() ~= nil
  end

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if M.supports(client, bufnr) then
      return true
    end
  end

  return false
end

function M.format(bufnr, opts)
  opts = opts or {}

  if is_c_family(bufnr) then
    return format_c(bufnr, opts.timeout_ms or 2000)
  end

  vim.lsp.buf.format({
    bufnr = bufnr,
    async = opts.async or false,
    timeout_ms = opts.timeout_ms or 2000,
    filter = function(client)
      return M.supports(client, bufnr)
    end,
  })

  return true
end

return M
