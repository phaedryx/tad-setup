# Tad's Development Setup

Everything needed to recreate my development environment. Captured 2026-03-16.

## Files

| File | Contents |
|------|----------|
| [git-config.md](git-config.md) | `.gitconfig`, `.gitignore`, aliases |
| [fish-shell.md](fish-shell.md) | Fish shell config, aliases, paths, variables, functions, completions, theme |
| [starship-prompt.md](starship-prompt.md) | Starship prompt config and custom git status script |
| [homebrew.md](homebrew.md) | All installed Homebrew formulas and casks |
| [mise-versions.md](mise-versions.md) | Runtime version manager config (Ruby, Node, Rust, Yarn) |
| [editor-extensions.md](editor-extensions.md) | VS Code and Cursor extensions |
| [claude-code.md](claude-code.md) | Claude Code settings, plugins, CLAUDE.md files, templates, status line |
| [claude-skills.md](claude-skills.md) | Custom slash command skills (`/my-reviews`, `/ask-review`, etc.) |
| [claude-commands.md](claude-commands.md) | Legacy slash commands (`/review-it`, `/spec-it`, `/explain-this`, etc.) |
| [workspace-structure.md](workspace-structure.md) | Bare repo + worktrees pattern, justfiles, repo list |
| [fluid-commerce.md](fluid-commerce.md) | Platform architecture, repo map, team directory, integrations |
| [scripts/](scripts/) | Actual config/script files preserved verbatim |

## Quick Rebuild Checklist

1. **Install Homebrew** and formulas/casks from [homebrew.md](homebrew.md)
2. **Configure Fish shell** from [fish-shell.md](fish-shell.md)
3. **Set up Git** from [git-config.md](git-config.md)
4. **Install Starship prompt** from [starship-prompt.md](starship-prompt.md)
5. **Install mise** and runtimes from [mise-versions.md](mise-versions.md)
6. **Install editor extensions** from [editor-extensions.md](editor-extensions.md)
7. **Configure Claude Code** from [claude-code.md](claude-code.md)
8. **Set up workspace** from [workspace-structure.md](workspace-structure.md)

## Identity

- **Name:** Tad Thorley
- **Email:** phaedryx@gmail.com
- **GitHub:** phaedryx
- **Slack ID:** U080F9F71J9
- **Machine:** macOS Darwin 25.3.0, Apple Silicon (arm64)
- **Shell:** Fish (`/opt/homebrew/bin/fish`)
- **Editor:** Cursor (with `code -w` as git editor)
- **Primary workspace:** `/Volumes/sourcecode/`
- **Secondary workspace:** `/Users/tad/repos/`
