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
  local items = require('git-coauthors.items').build_items({
    line_text = context.line,
    line_number = context.cursor[1] - 1,
    cursor_col = context.cursor[2],
  })

  if items then
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
  else
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
  end

  return function() end
end

return source
