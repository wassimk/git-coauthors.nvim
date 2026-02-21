-- Register nvim-cmp source if cmp is present
local has_cmp, cmp = pcall(require, 'cmp')
if has_cmp then
  local git_coauthors = require('git-coauthors')
  if not git_coauthors._setup_called then
    git_coauthors.setup()
  end

  cmp.register_source('git_coauthors', require('git-coauthors.cmp').new())
end

-- Register LuaSnip snippet, deferred so LuaSnip is loaded regardless of plugin order.
-- Checks for existing registration to avoid duplicates when from_vscode also finds it.
vim.schedule(function()
  local has_ls, ls = pcall(require, 'luasnip')
  if not has_ls then
    return
  end

  for _, snip in ipairs(ls.get_snippets('gitcommit', { type = 'snippets' })) do
    if snip.trigger == 'cab' then
      return
    end
  end

  local s = ls.snippet
  local i = ls.insert_node
  local fmt = require('luasnip.extras.fmt').fmt

  ls.add_snippets('gitcommit', {
    s({ trig = 'cab', dscr = 'Add a co-author to this commit' }, fmt('Co-Authored-By: {}', { i(1, '@handle') })),
  })
end)
