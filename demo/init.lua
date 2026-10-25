--
-- Minimal config for recording the README demo with VHS (see demo/git-coauthors.tape)
--

local demo_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local plugin_dir = vim.fn.fnamemodify(demo_dir, ':h')

local function clone(url, dir, ref)
  if vim.fn.isdirectory(dir) == 0 then
    local cmd = { 'git', 'clone', '--depth', '1' }
    if ref then
      vim.list_extend(cmd, { '--branch', ref })
    end
    vim.list_extend(cmd, { url, dir })
    vim.fn.system(cmd)
  end
end

local onedark_dir = os.getenv('ONEDARK_DIR') or '/tmp/onedark.nvim'
local blink_dir = os.getenv('BLINK_DIR') or '/tmp/blink.cmp-v1.10.2'

clone('https://github.com/navarasu/onedark.nvim', onedark_dir)
clone('https://github.com/saghen/blink.cmp', blink_dir, 'v1.10.2')

vim.opt.rtp:prepend(plugin_dir)
vim.opt.rtp:append(plugin_dir .. '/after')
vim.opt.rtp:append(onedark_dir)
vim.opt.rtp:append(blink_dir)

vim.opt.number = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.shortmess:append('I')
vim.opt.statusline = ' %f %m%=%l:%c '

require('onedark').setup({ style = 'darker' })
require('onedark').load()

-- Never read the personal handles file, so only the demo repo's authors appear.
-- Set before anything can trigger discovery; env.sh also points stdpath('data') at the sandbox.
local coauthors_opts = { handles_path = '/tmp/git-coauthors-demo/handles.json' }
require('git-coauthors').setup(coauthors_opts)

require('blink.cmp').setup({
  keymap = { preset = 'enter' },
  -- Pure Lua matcher, so no prebuilt binary is downloaded. Ties sort by label, so the
  -- menu order (and the demo's Down presses) is the same on every render
  fuzzy = { implementation = 'lua', sorts = { 'score', 'sort_text', 'label' } },
  completion = {
    -- Label only: VHS draws Nerd Font kind icons wider than one cell
    menu = { draw = { columns = { { 'label' } } } },
    documentation = { auto_show = false },
    list = { selection = { preselect = true, auto_insert = false } },
  },
  signature = { enabled = false },
  sources = {
    default = { 'snippets', 'git_coauthors' },
    providers = {
      snippets = {
        -- Hide the snippet from the `@` menu, which has no keyword typed yet
        min_keyword_length = 1,
        opts = { friendly_snippets = false, search_paths = { demo_dir .. '/snippets' } },
      },
      git_coauthors = {
        name = 'git_coauthors',
        module = 'git-coauthors.blink',
        opts = coauthors_opts,
      },
    },
  },
})
