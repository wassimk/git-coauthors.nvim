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

### Auto-Discovery (Default)

The plugin auto-discovers co-authors from your repository with zero
configuration:

1. **GitHub collaborators** (preferred): If the
   [`gh` CLI](https://cli.github.com/) is installed and authenticated,
   collaborators are pulled from the GitHub API with real `@handle` completions
   (e.g., `@molawson`).

2. **Git log fallback**: When `gh` is unavailable, co-authors are read from
   `git log` history using `@Full Name` format (e.g., `@Mo Lawson`).

Discovery runs in the background so it never blocks your editor. On the first
`@` trigger in a session, there may be a brief delay while the plugin fetches
collaborators from the GitHub API or parses your git log. The completion menu
will update automatically once results are ready. Subsequent triggers are
instant since results are cached. Your own name is automatically excluded from
results.

Set `discover = false` in [Configuration](#-configuration) to disable
auto-discovery and use only manually defined handles.

### Manual Handles (Optional Overrides)

For people not yet in the repo, or to override a discovered entry, you can
define handles manually. Create a JSON file that maps handles to names and
emails:

```json
{
  "@alice": "Alice Smith <alice@example.com>",
  "@bob": "Bob Jones <bob@example.com>"
}
```

Save this at `~/.local/share/nvim/git-coauthors/handles.json` (the default
location, which is Neovim's standard data directory). You can also pass handles
inline through your plugin config instead of using a file (see
[Configuration](#-configuration)).

The values are `Name <email>` strings matching the format git expects for
[`Co-Authored-By` trailers](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors).
Manual handles are merged on top of discovered ones, so a manual `@alice` entry
overrides any `@alice` found via GitHub or git log.

### Use in a Commit

The plugin provides two things in gitcommit buffers:

1. **A `cab` snippet** that expands to `Co-Authored-By: @handle`
2. **Handle completion** triggered by typing `@` after the `Co-Authored-By:` prefix

The typical flow:

1. Type `cab` and expand the snippet
2. The cursor lands on `@handle`. Type `@` to see all your handles, or start
   typing a name to filter
3. Select an entry to replace the placeholder with the full `Name <email>`

Your resulting commit message looks like:

```
feat: add dark mode support

Co-Authored-By: Alice Smith <alice@example.com>
```

## 🔧 Configuration

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
| `discover` | `true` | Auto-discover co-authors from GitHub/git log. Set `false` to use only file/inline handles. |
| `handles_path` | `~/.local/share/nvim/git-coauthors/handles.json` | Path to the JSON handles file |
| `handles` | `nil` | Inline handles (merged over file, inline wins on duplicates) |

### Snippet

The `cab` snippet is distributed as a VSCode-format snippet via `package.json`,
which works with blink.cmp's built-in snippet source and LuaSnip's
`from_vscode()` loader. The plugin also registers the snippet directly with
LuaSnip as a fallback for lazy-loading timing issues.

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
