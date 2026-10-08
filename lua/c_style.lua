local M = {}

local indent_width = 8
local column_limit = 80

M.editor_options = {
  cindent = true,
  colorcolumn = tostring(column_limit + 1),
  expandtab = false,
  shiftwidth = indent_width,
  softtabstop = indent_width,
  tabstop = indent_width,
  textwidth = column_limit,
}

M.clang_format = {
  BasedOnStyle = 'LLVM',
  AllowShortBlocksOnASingleLine = 'Never',
  AllowShortCaseLabelsOnASingleLine = false,
  AllowShortFunctionsOnASingleLine = 'None',
  AllowShortIfStatementsOnASingleLine = 'Never',
  AllowShortLoopsOnASingleLine = false,
  BreakBeforeBraces = 'Linux',
  BreakStringLiterals = false,
  ColumnLimit = column_limit,
  ContinuationIndentWidth = indent_width,
  DerivePointerAlignment = false,
  IndentCaseLabels = false,
  IndentGotoLabels = false,
  IndentWidth = indent_width,
  PointerAlignment = 'Right',
  ReflowComments = false,
  SortIncludes = false,
  SpaceAfterCStyleCast = false,
  TabWidth = indent_width,
  UseTab = 'Always',
}

function M.apply_editor_options()
  for option, value in pairs(M.editor_options) do
    vim.opt_local[option] = value
  end
end

function M.clang_format_style()
  return vim.json.encode(M.clang_format)
end

return M
