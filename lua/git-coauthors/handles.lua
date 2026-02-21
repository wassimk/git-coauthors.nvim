local M = {}

local _cached_handles = nil

function M.load(config)
  local handles = {}

  local json_path = vim.fn.expand(config.handles_path)
  if vim.fn.filereadable(json_path) == 1 then
    local ok, decoded = pcall(function()
      return vim.fn.json_decode(vim.fn.readfile(json_path))
    end)
    if ok and type(decoded) == 'table' then
      handles = decoded
    end
  end

  if config.handles and type(config.handles) == 'table' then
    handles = vim.tbl_extend('force', handles, config.handles)
  end

  _cached_handles = handles
  return handles
end

function M.get()
  if _cached_handles then
    return _cached_handles
  end

  local config = require('git-coauthors')._config
  return M.load(config)
end

function M._reset_cache()
  _cached_handles = nil
end

return M
