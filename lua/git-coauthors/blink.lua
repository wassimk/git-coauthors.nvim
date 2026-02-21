--- @class git-coauthors.BlinkSource : blink.cmp.Source
local source = {}

--- @param opts table
--- @param _config blink.cmp.SourceProviderConfig
function source.new(opts, _config)
  local self = setmetatable({}, { __index = source })

  local git_coauthors = require('git-coauthors')
  git_coauthors.setup(opts)

  return self
end

function source:get_trigger_characters()
  return { '@' }
end

function source:get_completions(context, callback)
  local handles = require('git-coauthors.handles')
  local build_items = require('git-coauthors.items').build_items
  local cursor_info = {
    line_text = context.line,
    line_number = context.cursor[1] - 1,
    cursor_col = context.cursor[2],
  }

  local items = build_items(cursor_info)

  if items then
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
  else
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
  end

  if handles.is_discovery_pending() then
    handles.on_discovery_complete(function()
      local updated_items = build_items(cursor_info)
      if updated_items then
        callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = updated_items })
      end
    end)
  end

  return function() end
end

return source
