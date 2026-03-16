# Starship Prompt Configuration

## ~/.config/starship.toml

```toml
add_newline = false
command_timeout = 8000
format = """
$username\
$nodejs\
$ruby\
${custom.git_info}\
$git_commit\
$git_state\
$time
$directory\
${custom.git_status_custom}\
${custom.file_count}\
$character\
"""

[character]
success_symbol = "[§](bold green)"
error_symbol = "[§](bold red)"

[directory]
truncate_to_repo = false
format="[$path]($style)[$read_only]($read_only_style) "

[nodejs]
symbol = "⬡"
format = "[$symbol ($version)]($style) "

[ruby]
symbol = "▼"
style = "bold red"
format = "[$symbol ($version)]($style) "

[git_branch]
disabled = true

[git_status]
disabled = true

[custom.git_info]
description = "Shows 'bare repo' for bare repo parents, branch name otherwise"
command = "test -d .bare && test -f .git && echo 'bare' || git branch --show-current || git rev-parse --short HEAD"
when = "git rev-parse --git-dir > /dev/null 2>&1"
format = "on  [$output](bold purple) "

[custom.git_status_custom]
description = "Git status, hidden for bare repo parents"
command = "~/.config/starship-git-status.sh"
when = "git rev-parse --git-dir > /dev/null 2>&1"
style = "bold green"
format = "[$output]($style)"

[time]
disabled = false
format = "[$time]($style)"

[custom.file_count]
command = "ls -a | wc -l"
style = "bold cyan"
format = "[\\($output\\)]($style) "
```

## ~/.config/starship-git-status.sh

```bash
#!/bin/bash
# Git status for Starship prompt
# Returns nothing for bare repo parents, detailed status otherwise

# Skip for bare repo parent directories
if [ -d .bare ] && [ -f .git ]; then
  exit 0
fi

status=""

# Staged changes
git diff --cached --quiet 2>/dev/null || status="${status}+"

# Unstaged changes (modified)
git diff --quiet 2>/dev/null || status="${status}Δ"

# Untracked files
if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null | head -1)" ]; then
  status="${status}?"
fi

# Deleted files
if [ -n "$(git ls-files --deleted 2>/dev/null | head -1)" ]; then
  status="${status}✘"
fi

# Ahead/behind upstream
ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null) || ahead=0
behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null) || behind=0
[ "$ahead" -gt 0 ] 2>/dev/null && status="${status}⇡${ahead}"
[ "$behind" -gt 0 ] 2>/dev/null && status="${status}⇣${behind}"

if [ -n "$status" ]; then
  echo "($status)"
fi
```

**Make executable:** `chmod +x ~/.config/starship-git-status.sh`

## Status Symbols

| Symbol | Meaning |
|--------|---------|
| `+` | Staged changes |
| `Δ` | Unstaged changes |
| `?` | Untracked files |
| `✘` | Deleted files |
| `⇡N` | N commits ahead of upstream |
| `⇣N` | N commits behind upstream |

## Prompt Character

- `§` (green) on success
- `§` (red) on error

## Notable Design Choices

- Built-in `git_branch` and `git_status` are **disabled** in favor of custom modules
- Custom `git_info` module handles bare repo detection (shows "bare" instead of branch name)
- Custom `git_status_custom` hides status for bare repo parent directories
- `command_timeout` set to 8000ms to accommodate slower git operations
