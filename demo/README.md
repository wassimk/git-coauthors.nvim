# Demo GIF

`demo.gif` in the repo root is generated from `git-coauthors.tape` with [VHS](https://github.com/charmbracelet/vhs). Regenerate it whenever the plugin's behavior or the README demo should change.

## Requirements

- [VHS](https://github.com/charmbracelet/vhs#installation) (`brew install vhs`)
- Neovim >= 0.10.0, git, and bash
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) (optional, the tape tries MonoLisaCode first and VHS falls back to a default font)
- Network access on the first run, to clone [onedark.nvim](https://github.com/navarasu/onedark.nvim) and [blink.cmp](https://github.com/saghen/blink.cmp) into `/tmp`

## Regenerate

From the repo root:

```shell
vhs demo/git-coauthors.tape
```

This overwrites `demo.gif`. Commit it along with any tape changes.

## How it works

- `setup.sh` builds a throwaway repo in `/tmp/git-coauthors-demo` whose history has commits from a small team, stages a change, and writes `env.sh` so `git commit` opens Neovim with the demo config.
- The repo has no GitHub remote, so co-authors are discovered from `git log`. Personal git config is ignored and Neovim's data directory points into the sandbox, so your own handles file never shows up in the demo.
- `init.lua` is a minimal config with blink.cmp (pinned, Lua matcher so no binary download), onedark, and the git_coauthors source. The completion menu shows labels only, because VHS draws Nerd Font kind icons wider than one cell. Ties sort by label so the menu order is the same on every render.
- `snippets/` provides the `cab` snippet through blink.cmp's built-in snippet support, so LuaSnip isn't needed.
- Steps wait on screen text (`Wait+Screen`), so if the plugin's behavior changes the render fails instead of recording a broken demo.
