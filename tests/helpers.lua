local M = {}

local _originals = {}

M.test_handles = {
  ['@alice'] = 'Alice Smith <alice@example.com>',
  ['@bob'] = 'Bob Jones <bob@example.com>',
}

M.test_handles_json = vim.fn.json_encode({
  ['@alice'] = 'Alice Smith <alice@example.com>',
  ['@bob'] = 'Bob Jones <bob@example.com>',
})

function M.setup_mocks()
  _originals = {
    filereadable = rawget(vim.fn, 'filereadable'),
    readfile = rawget(vim.fn, 'readfile'),
    expand = rawget(vim.fn, 'expand'),
  }

  M.file_exists = true
  M.file_content = M.test_handles_json

  vim.fn.filereadable = function(_)
    return M.file_exists and 1 or 0
  end

  vim.fn.readfile = function(_)
    return { M.file_content }
  end

  vim.fn.expand = function(expr)
    return expr
  end
end

function M.teardown_mocks()
  rawset(vim.fn, 'filereadable', _originals.filereadable)
  rawset(vim.fn, 'readfile', _originals.readfile)
  rawset(vim.fn, 'expand', _originals.expand)
  _originals = {}

  -- Reset module caches so each test starts fresh
  require('git-coauthors.handles')._reset_cache()
  require('git-coauthors')._setup_called = false
  require('git-coauthors')._config = {
    handles_path = vim.fn.stdpath('data') .. '/git-coauthors/handles.json',
    handles = nil,
  }

  M.file_exists = true
  M.file_content = M.test_handles_json
end

return M
