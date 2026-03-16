# Git Configuration

## ~/.gitconfig

```ini
[user]
    name = Tad Thorley
    email = phaedryx@gmail.com
[core]
    editor = code -w
    whitespace = trailing-space,space-before-tab
    autocrlf = input
    excludesfile = /Users/tad/.gitignore
    pager = delta
[alias]
    st = status
    ci = commit -m
    co = switch
    br = branch
    ls = diff --name-only
    unstage = reset HEAD --
    force = push -f origin
    dice = commit --allow-empty -m 'roll the CI dice'
    rfm = restore --source=master
    res = restore --source=main
    reb = rebase -i
    aliases = !git config --list | grep '^alias.' | sed 's/^alias\\.//'
    make = switch -c
    drop = branch -d
    list = worktree list
[init]
    defaultBranch = main
[pull]
    rebase = true
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true
    line-numbers = true
    side-by-side = false
[merge]
    conflictstyle = diff3
[diff]
    colorMoved = default
[fetch]
    prune = true
```

## ~/.gitignore (global)

```
.DS_Store

.vscode/
.claude/

Procfile.tad
CLAUDE.md
```

## Alias Cheat Sheet

| Alias | Command | Purpose |
|-------|---------|---------|
| `st` | `status` | Quick status |
| `ci` | `commit -m` | Quick commit |
| `co` | `switch` | Switch branches |
| `make` | `switch -c` | Create new branch |
| `drop` | `branch -d` | Delete branch |
| `list` | `worktree list` | List worktrees |
| `force` | `push -f origin` | Force push |
| `dice` | `commit --allow-empty -m 'roll the CI dice'` | Re-trigger CI |
| `rfm` | `restore --source=master` | Restore file from master |
| `res` | `restore --source=main` | Restore file from main |
| `reb` | `rebase -i` | Interactive rebase |
| `unstage` | `reset HEAD --` | Unstage files |
| `ls` | `diff --name-only` | List changed files |
| `aliases` | List all aliases | Show all git aliases |

## Key Settings

- **Pager:** `delta` with line numbers, navigate mode
- **Pull strategy:** Always rebase
- **Merge conflicts:** diff3 style (shows base version)
- **Fetch:** Auto-prune stale remote refs
- **Default branch:** `main`
