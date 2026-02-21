local M = {}

local _cached_handles = nil
local _discovery_pending = false
local _discovery_listeners = {}

function M.load_fast(config)
  local handles = {}

  local json_path = vim.fn.expand(config.handles_path)
  if vim.fn.filereadable(json_path) == 1 then
    local ok, decoded = pcall(function()
      return vim.fn.json_decode(vim.fn.readfile(json_path))
    end)
    if ok and type(decoded) == 'table' then
      handles = vim.tbl_extend('force', handles, decoded)
    end
  end

  if config.handles and type(config.handles) == 'table' then
    handles = vim.tbl_extend('force', handles, config.handles)
  end

  return handles
end

function M.get()
  if _cached_handles then
    return _cached_handles
  end

  local config = require('git-coauthors')._config
  _cached_handles = M.load_fast(config)

  if config.discover ~= false and not _discovery_pending then
    _discovery_pending = true
    require('git-coauthors.discover').discover_async(config, function(discovered)
      _discovery_pending = false
      if discovered and not vim.tbl_isempty(discovered) then
        _cached_handles = vim.tbl_extend('force', discovered, _cached_handles)
      end
      local listeners = _discovery_listeners
      _discovery_listeners = {}
      for _, fn in ipairs(listeners) do
        fn()
      end
    end)
  end

  return _cached_handles
end

function M.is_discovery_pending()
  return _discovery_pending
end

function M.on_discovery_complete(fn)
  table.insert(_discovery_listeners, fn)
end

function M._reset_cache()
  _cached_handles = nil
  _discovery_pending = false
  _discovery_listeners = {}
end

return M
