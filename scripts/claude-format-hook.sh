#!/bin/bash
# Auto-format hook for Claude Code
# Formats files after Edit/Write operations
#
# Installation:
#   1. Copy to ~/.local/bin/claude-format-hook.sh
#   2. chmod +x ~/.local/bin/claude-format-hook.sh
#   3. Add hook config to .claude/settings.json

FILE_PATH="$1"

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Get directory of the file to find project root
DIR=$(dirname "$FILE_PATH")

# Function to find project root (where package.json or Gemfile exists)
find_project_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/package.json" ] || [ -f "$dir/Gemfile" ]; then
            echo "$dir"
            return
        fi
        dir=$(dirname "$dir")
    done
    echo ""
}

PROJECT_ROOT=$(find_project_root "$DIR")

case "$EXT" in
    rb|rake|gemspec)
        # Ruby files - use rubocop
        if [ -n "$PROJECT_ROOT" ] && [ -f "$PROJECT_ROOT/Gemfile" ]; then
            cd "$PROJECT_ROOT" && bundle exec rubocop --autocorrect --fail-level=fatal "$FILE_PATH" 2>/dev/null || true
        elif command -v rubocop &> /dev/null; then
            rubocop --autocorrect --fail-level=fatal "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    ts|tsx|js|jsx|mjs|cjs|json|css|scss|md|yaml|yml)
        # JavaScript/TypeScript files - use prettier
        if [ -n "$PROJECT_ROOT" ]; then
            cd "$PROJECT_ROOT"
            if [ -f "pnpm-lock.yaml" ]; then
                pnpm prettier --write "$FILE_PATH" 2>/dev/null || true
            elif [ -f "bun.lockb" ]; then
                bun prettier --write "$FILE_PATH" 2>/dev/null || true
            elif [ -f "package-lock.json" ]; then
                npx prettier --write "$FILE_PATH" 2>/dev/null || true
            elif command -v prettier &> /dev/null; then
                prettier --write "$FILE_PATH" 2>/dev/null || true
            fi
        elif command -v prettier &> /dev/null; then
            prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
esac

exit 0
