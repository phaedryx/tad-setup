# Workspace Structure

## Overview

Two workspace roots:
- `/Volumes/sourcecode/` — Primary (Fluid Commerce + personal projects)
- `/Users/tad/repos/` — Secondary

Both use the same bare repo + worktrees pattern.

## Bare Repo + Worktrees Pattern

Instead of traditional `git clone`, repos use a bare repository with worktrees:

```
repo-name/
  .bare/           # Bare git repository (actual git data)
  .git             # File containing: gitdir: ./.bare
  .rules/          # Coding standards (shared across all worktrees)
  .claude/         # Claude Code settings and skills
  justfile         # Worktree management commands
  CLAUDE.md        # Repo-specific agent instructions
  TASKS.md         # Active work tracking
  DECISIONS.md     # Architectural decisions
  LEARNINGS.md     # Discoveries and gotchas
  main/            # Worktree for default branch
  tad_feature/     # Feature worktree
```

**Key principle:** All worktrees are peers. No "special" main checkout.

### Branch Naming

- Branch names and directory names are **identical**
- `_` separates username prefix: `tad_feature-name`
- Hyphens within task slug: `tad_infra-1331-refactor-cleanup`
- Branch names must contain a Linear issue code for CI

## Repos in Workspace

### Fluid Commerce (bare+worktrees)
- `fluid/` — Core Rails 7.2 monolith (default: `master`)
- `fluid-integrations/` — Third-party integrations Rails 8 (default: `main`)
- `fluid-admin/` — Admin dashboard Next.js 16 (default: `main`)
- `fluid-checkout/` — Customer checkout Next.js 16
- `fluid-login/` — Authentication UI Next.js 15
- `fluid-chat/` — Customer chat React 17
- `fluid-mobile/` — iOS/Android apps React Native/Expo
- `fluid-middleware/` — System adapters Rails 8
- `fluid-connect/` — Exigo adapter Bun+Ruby
- `fluid-cli/` — Developer CLI Ruby gem
- `fluid-static-pages/` — Static site generator Node.js
- `fluid-valve/` — Rails engine (in development)
- `fluid-reservoir/` — Custom MCP code intelligence server
- `fluid-mono/` — Monorepo experiment

### Personal Projects
- `agents/`
- `bruno-collections/`
- `claudacity/`
- `claude-status-line/`
- `dragonruby/` — Game dev
- `droplet-service/`
- `example-swift-app/`
- `learning-swift-ui/`
- `life-competes-client/`
- `purgastory/`
- `rubowar/`, `rubowar-web/`
- `screeps/`
- `simphiles/`
- `slack/` — Custom Slack MCP server
- `sunlit-passages/`
- `tad.thorley.dev/`
- `tributary/`
- `urug.github.io/`
- `valveness/`

## Workspace Justfile (/Volumes/sourcecode/justfile)

| Command | Description |
|---------|-------------|
| `just list` | List all repos and their type |
| `just status` | Git status across all repos |
| `just worktrees` | List all worktrees |
| `just branches` | Show local branches per repo |
| `just fetch` | Fetch all repos |
| `just pull` | Pull default branches (skips dirty) |
| `just convert <repo>` | Convert legacy to bare+worktrees |
| `just path <repo>` | Show path to default worktree |
| `just unpushed` | Find repos with unpushed commits |

## Repo Justfile (per-repo)

| Command | Description |
|---------|-------------|
| `just new tad_feature` | Create branch + worktree |
| `just review someone_branch` | Create worktree for PR review |
| `just list` | List all worktrees |
| `just del tad_feature` | Remove worktree and delete branch |

## Conversion Script

`scripts/convert-to-worktrees.sh` converts legacy repos:

1. Checks for uncommitted changes
2. Gets remote URL and default branch
3. Creates bare clone with `.git` pointer
4. Configures for worktrees
5. Creates default branch worktree
6. Generates template files (CLAUDE.md, TASKS.md, DECISIONS.md, TOPICS.md)
7. Removes old directory

See `scripts/convert-to-worktrees.sh` for the full script.

## Tracking Files

Each repo maintains at the root (not inside worktrees):

| File | Purpose |
|------|---------|
| `TASKS.md` | Active work per worktree, status, done/remaining |
| `DECISIONS.md` | Choices made with rationale |
| `LEARNINGS.md` | Discovered facts and gotchas |
| `PENDING.md` / `TOPICS.md` | Questions for later |
