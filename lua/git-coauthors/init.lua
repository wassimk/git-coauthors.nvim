local M = {}

M._config = {
  handles_path = vim.fn.stdpath('data') .. '/git-coauthors/handles.json',
  handles = nil,
  discover = true,
}

M._setup_called = false

function M.setup(opts)
  M._config = vim.tbl_deep_extend('force', M._config, opts or {})
  M._setup_called = true

  require('git-coauthors.handles')._reset_cache()
end

function M.is_coauthor_context()
  local line = vim.api.nvim_get_current_line()
  return line:find('^%s*Co%-Authored%-By:') ~= nil
end

return M
