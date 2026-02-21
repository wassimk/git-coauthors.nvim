# git-coauthors.nvim

Autocomplete `Co-Authored-By` lines in git commits. Type a GitHub handle and
complete it to `Name <email>` format.

## Requirements

- **Neovim 0.10+**
- [blink.cmp](https://github.com/Saghen/blink.cmp) or [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

## Installation

### blink.cmp

```lua
{
  'saghen/blink.cmp',
  dependencies = {
    { 'wassimk/git-coauthors.nvim' },
  },
  opts = {
    sources = {
      per_filetype = {
        gitcommit = { 'buffer', 'snippets', 'git_coauthors' },
      },
      providers = {
        git_coauthors = {
          name = 'git_coauthors',
          module = 'git-coauthors.blink',
        },
      },
    },
  },
}
```

### nvim-cmp

The source auto-registers when nvim-cmp is detected:

```lua
{ 'wassimk/git-coauthors.nvim' }
```

Add `git_coauthors` to your nvim-cmp sources for the gitcommit filetype.

## Usage

1. In a git commit buffer, type `cab` to expand the `Co-Authored-By:` snippet
2. Type `@` to trigger handle completion
3. Select a handle to insert the full `Name <email>`

Handles are loaded from a JSON file at `~/.local/share/nvim/git-coauthors/handles.json`:

```json
{
  "@alice": "Alice Smith <alice@example.com>",
  "@bob": "Bob Jones <bob@example.com>"
}
```

Keys are GitHub handles (with `@` prefix), values are `Name <email>` strings
matching the format git expects for `Co-Authored-By` trailers.

## Configuration

Pass options via blink.cmp's provider `opts` or `require('git-coauthors').setup()`:

```lua
-- blink.cmp provider opts
git_coauthors = {
  name = 'git_coauthors',
  module = 'git-coauthors.blink',
  opts = {
    handles_path = '~/my/custom/handles.json',
    handles = {
      ['@user'] = 'User Name <user@example.com>',
    },
  },
}

-- or standalone setup (nvim-cmp users)
require('git-coauthors').setup({
  handles_path = '~/my/custom/handles.json',
  handles = {
    ['@user'] = 'User Name <user@example.com>',
  },
})
```

| Option | Default | Description |
| --- | --- | --- |
| `handles_path` | `~/.local/share/nvim/git-coauthors/handles.json` | Path to the JSON handles file |
| `handles` | `nil` | Inline handles (merged over file, inline wins on duplicates) |

## Snippet

The plugin ships a `cab` snippet for gitcommit files that expands to:

```
Co-Authored-By: @handle
```

This is distributed as a VSCode-format snippet via `package.json`, which works
with blink.cmp's built-in snippet source and LuaSnip's `from_vscode()` loader.
The plugin also registers the snippet directly with LuaSnip as a fallback for
lazy-loading timing issues.

## Development

Run tests and lint:

```shell
make test
make lint
```

Enable the local git hooks (one-time setup):

```shell
git config core.hooksPath .githooks
```
