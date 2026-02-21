local M = {}

--- Build LSP-format completion items for Co-Authored-By trailer lines.
---@param cursor_info { line_text: string, line_number: number, cursor_col: number }
---  line_number and cursor_col are 0-indexed
---@return lsp.CompletionItem[]|nil
function M.build_items(cursor_info)
  local line = cursor_info.line_text
  local col = cursor_info.cursor_col

  local before_cursor = line:sub(1, col)

  local _, at_pos = before_cursor:find('^%s*Co%-Authored%-By:%s*@')
  if not at_pos then
    return nil
  end

  local handles = require('git-coauthors.handles').get()
  if not handles or vim.tbl_isempty(handles) then
    return nil
  end

  local items = {}
  for handle, name_and_email in pairs(handles) do
    table.insert(items, {
      filterText = handle .. ' ' .. name_and_email,
      label = name_and_email,
      textEdit = {
        newText = name_and_email,
        range = {
          start = {
            line = cursor_info.line_number,
            character = at_pos - 1,
          },
          ['end'] = {
            line = cursor_info.line_number,
            character = col,
          },
        },
      },
    })
  end

  return items
end

return M
