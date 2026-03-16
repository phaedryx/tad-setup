# Claude Code Configuration

## ~/.claude/settings.json

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "statusLine": {
    "type": "command",
    "command": "~/.claude/status-line"
  },
  "enabledPlugins": {
    "linear@claude-plugins-official": true,
    "greptile@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true,
    "swift-lsp@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true,
    "ruby-lsp@claude-plugins-official": true
  },
  "effortLevel": "high",
  "voiceEnabled": false,
  "skipDangerousModePermissionPrompt": true,
  "customModels": [
    "claude-opus-4-6-20250205"
  ]
}
```

## Global CLAUDE.md (~/.claude/CLAUDE.md)

```markdown
# Global Claude Code Settings

User-level instructions that apply across all repositories.

## PR Summaries

When creating pull requests, use the template at `~/.claude/templates/pr-summary.md` (GitHub markdown):

1. **What changed** - Brief description of the changes
2. **Why it changed** - Context and motivation
3. **How to test** - Steps to verify the changes
4. **Linear** - Link to the Linear issue

Extract the Linear URL from the branch name or issue lookup.

## Slack Review Summaries

When sending PR summaries to Slack (e.g., via `/ask-review`), use the template at `~/.claude/templates/slack-review-summary.md` (Slack formatting). Do NOT send raw GitHub markdown to Slack — convert to Slack-native formatting:

- `*bold*` for section headers (not `## Heading`)
- Plain text bullets, no markdown links
- Paste URLs directly instead of `[text](url)`

## CLI Tools

Preferred command-line tools available across all projects.

| Instead of | Use | Notes |
|------------|-----|-------|
| `ls` | `eza` | Better formatting, git integration |
| `ls -R` / `tree` | `eza -T` | Tree view |
| `cat` | `bat` | Syntax highlighting (but prefer Read tool) |
| `grep` | `rg` | Faster, better defaults (but prefer Grep tool) |
| `find` | `fd` | Faster, simpler syntax (but prefer Glob tool) |
| `diff` | `difft` | Structural diffs that understand syntax |
| `curl` | `http` | HTTPie — simpler syntax for API calls |

Available tools: bat, delta, difft, eza, fd, fzf, gcloud, gh, gum, http, jq, just, rg, tokei, yq, zoxide

## MCP Servers

| Server | Config Location | Command | Notes |
|--------|----------------|---------|-------|
| `slack-mcp` | `~/.claude/settings.json` | `/Volumes/sourcecode/slack/bin/slack-mcp` | Ruby project — if it fails to connect, run `cd /Volumes/sourcecode/slack && bundle install` |
| `fluid-reservoir` | `~/.claude.json` | `cd /Volumes/sourcecode/fluid-reservoir/main && bundle exec ruby bin/fluid-reservoir` | Code search/analysis for fluid repo |
```

## PR Summary Template (~/.claude/templates/pr-summary.md)

See `scripts/pr-summary-template.md` for the full template. Key sections:

1. **Summary** - What and why (1-2 sentences)
2. **Context** - Problem, trigger, motivation
3. **Decisions & trade-offs** - Key choices and alternatives
4. **How it works** - Implementation walkthrough with mermaid diagrams
5. **Review guide** - Focus areas and skippable sections
6. **Verification** - Step-by-step testing table
7. **Files** - File purpose table
8. **Links** - Linear URL, related PRs

PR size target: ~400 lines of meaningful changes.

## Slack Review Summary Template (~/.claude/templates/slack-review-summary.md)

```
*Summary*
{1-2 sentences: what does this PR do and why}

*Context*
{Why are we doing this — problem, trigger, motivation}

*Decisions & trade-offs*
- {key choice and why}
- {alternative considered and why not}

*How it works*
{Brief explanation of the approach — no diagrams, just the key mechanics. Reference the PR description for diagrams.}

*Review guide*
Focus on:
- {core logic files/areas}
Skip:
- {boilerplate, mechanical changes}

*Links*
Linear: {LINEAR_URL}
PR: {PR_URL}
```

## Status Line Script (~/.claude/status-line)

A Ruby script that displays in the Claude Code interface:
- Current repo name
- Context window usage bar (green/yellow/red)
- Token counts (in/out)
- Model name
- All worktrees with dirty indicators and GitHub links

See `scripts/claude-status-line.rb` for the full script.

## Auto-Format Hook (~/.local/bin/claude-format-hook.sh)

A PostToolUse hook that auto-formats files after Edit/Write operations:
- **Ruby files** (`.rb`, `.rake`, `.gemspec`): `bundle exec rubocop --autocorrect`
- **JS/TS/CSS/JSON/YAML/MD**: `prettier --write` (via pnpm, bun, or npx)

See `scripts/claude-format-hook.sh` for the full script.

## Enabled Plugins

| Plugin | Purpose |
|--------|---------|
| **Linear** | Issue tracking integration |
| **Greptile** | Code review and PR analysis |
| **Frontend Design** | UI component generation |
| **Swift LSP** | Swift language support |
| **Superpowers** | Enhanced skills (TDD, brainstorming, debugging, etc.) |
| **Ruby LSP** | Ruby language support |

## Usage Stats (from ~/.claude.json)

- **1,483 startups** as of capture date
- **1,998 prompt queue uses**
- Install method: native
- Theme: dark-ansi
