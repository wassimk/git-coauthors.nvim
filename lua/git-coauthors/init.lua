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
  require('git-coauthors.handles').load(M._config)
end

return M
