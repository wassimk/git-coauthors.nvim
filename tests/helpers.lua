local M = {}

local _originals = {}
local _real_system = nil

M.test_handles = {
  ['@alice'] = 'Alice Smith <alice@example.com>',
  ['@bob'] = 'Bob Jones <bob@example.com>',
}

M.test_handles_json = vim.fn.json_encode({
  ['@alice'] = 'Alice Smith <alice@example.com>',
  ['@bob'] = 'Bob Jones <bob@example.com>',
})

function M.setup_mocks()
  _real_system = vim.fn.system

  _originals = {
    filereadable = rawget(vim.fn, 'filereadable'),
    readfile = rawget(vim.fn, 'readfile'),
    expand = rawget(vim.fn, 'expand'),
    system = rawget(vim.fn, 'system'),
    executable = rawget(vim.fn, 'executable'),
  }

  M.file_exists = true
  M.file_content = M.test_handles_json
  M.system_responses = {}
  M.executables = {}

  vim.fn.filereadable = function(_)
    return M.file_exists and 1 or 0
  end

  vim.fn.readfile = function(_)
    return { M.file_content }
  end

  vim.fn.expand = function(expr)
    return expr
  end

  vim.fn.system = function(cmd)
    local cmd_str = type(cmd) == 'table' and table.concat(cmd, ' ') or cmd
    for _, entry in ipairs(M.system_responses) do
      if cmd_str:find(entry[1], 1, true) then
        if (entry.exit_code or 0) ~= 0 then
          _real_system('false')
        else
          _real_system('true')
        end
        return entry[2] or ''
      end
    end
    _real_system('false')
    return ''
  end

  vim.fn.executable = function(name)
    return M.executables[name] and 1 or 0
  end
end

function M.teardown_mocks()
  rawset(vim.fn, 'filereadable', _originals.filereadable)
  rawset(vim.fn, 'readfile', _originals.readfile)
  rawset(vim.fn, 'expand', _originals.expand)
  rawset(vim.fn, 'system', _originals.system)
  rawset(vim.fn, 'executable', _originals.executable)
  _originals = {}
  _real_system = nil

  -- Reset module caches so each test starts fresh
  require('git-coauthors.handles')._reset_cache()
  require('git-coauthors')._setup_called = false
  require('git-coauthors')._config = {
    handles_path = vim.fn.stdpath('data') .. '/git-coauthors/handles.json',
    handles = nil,
    discover = true,
  }

  M.file_exists = true
  M.file_content = M.test_handles_json
  M.system_responses = {}
  M.executables = {}
end

return M
