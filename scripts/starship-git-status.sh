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
