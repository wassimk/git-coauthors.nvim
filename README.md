# git-coauthors.nvim

Autocomplete `Co-Authored-By` lines in git commits. Type a GitHub handle and
complete it to `Name <email>` format.

![demo](demo.gif)

## 📋 Requirements

- **Neovim 0.10+**
- [blink.cmp](https://github.com/Saghen/blink.cmp) or [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

## 🛠️ Installation

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

## 💻 Usage

The plugin provides a `cab` snippet and `@` handle completion in gitcommit
buffers:

1. Type `cab` and expand the snippet
2. The cursor lands on `@handle`. Type `@` to see all handles, or start typing
   to filter
3. Select an entry to replace the placeholder with the full `Name <email>`

```
feat: add dark mode support

Co-Authored-By: Alice Smith <alice@example.com>
```

### Auto-Discovery

Co-authors are discovered automatically with zero configuration:

1. **GitHub collaborators** (preferred): If the
   [`gh` CLI](https://cli.github.com/) is installed and authenticated,
   collaborators are pulled from the GitHub API (e.g., `@octocat`).

2. **Git log fallback**: When `gh` is unavailable, co-authors are read from
   `git log` history (e.g., `@Jane Smith`).

Discovery runs in the background and results are cached after the first
trigger. Set `discover = false` to disable it.

### Manual Handles

Define handles manually for people not yet in the repo, or to override a
discovered entry. Create a JSON file at
`~/.local/share/nvim/git-coauthors/handles.json`:

```json
{
  "@alice": "Alice Smith <alice@example.com>",
  "@bob": "Bob Jones <bob@example.com>"
}
```

Manual handles are merged on top of discovered ones. You can also pass handles
inline (see [Configuration](#-configuration)).

## 🔧 Configuration

```lua
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
```

nvim-cmp users can pass the same options to `require('git-coauthors').setup()`.

| Option | Default | Description |
| --- | --- | --- |
| `discover` | `true` | Auto-discover co-authors from GitHub/git log. Set `false` to use only file/inline handles. |
| `handles_path` | `~/.local/share/nvim/git-coauthors/handles.json` | Path to the JSON handles file |
| `handles` | `nil` | Inline handles (merged over file, inline wins on duplicates) |

## 🤝 Coexisting with Other `@` Sources

If another completion source also triggers on `@` (e.g.,
[blink-cmp-git](https://github.com/Kaiser-Yang/blink-cmp-git) for GitHub
mentions), both will fire on `Co-Authored-By:` lines.
`is_coauthor_context()` returns `true` when the cursor is on a
`Co-Authored-By:` line so you can conditionally suppress the other source:

```lua
-- blink.cmp + blink-cmp-git
git = {
  name = 'Git',
  module = 'blink-cmp-git',
  transform_items = function(_, items)
    if require('git-coauthors').is_coauthor_context() then
      return {}
    end
    return items
  end,
},

-- nvim-cmp + cmp-git
{ name = 'git', entry_filter = function(entry, ctx)
    return not require('git-coauthors').is_coauthor_context()
  end,
},
```

## 🔨 Development

Run tests and lint:

```shell
make test
make lint
```

Enable the local git hooks (one-time setup):

```shell
git config core.hooksPath .githooks
```
