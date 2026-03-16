#!/bin/bash
#
# Convert a repository from @worktrees wrapper pattern to bare repo + worktrees pattern.
#
# Usage:
#   ./scripts/convert-to-worktrees.sh <repo-name>
#
# Example:
#   ./scripts/convert-to-worktrees.sh fluid-admin
#
# This converts:
#   fluid-admin@worktrees/fluid-admin/  (regular clone)
# To:
#   fluid-admin/                        (bare repo + worktrees)
#     .bare/
#     .git
#     main/  (or master/)
#     CLAUDE.md
#     TASKS.md
#     DECISIONS.md
#     TOPICS.md
#
# Prerequisites:
# - The repo must exist at <repo>@worktrees/<repo>/
# - The repo must have no uncommitted changes
# - The repo must have a remote named 'origin'
#
# What this script does:
# 1. Checks for uncommitted changes (aborts if dirty)
# 2. Gets remote URL and default branch from existing clone
# 3. Creates new directory with bare clone
# 4. Configures bare repo for worktrees
# 5. If default branch is 'main', adds repo-local git new alias
# 6. Creates default branch worktree
# 7. Creates template documentation files
# 8. Removes old @worktrees directory

set -e

BASEDIR="/Volumes/sourcecode"
REPO_NAME="$1"

if [[ -z "$REPO_NAME" ]]; then
    echo "Usage: $0 <repo-name>"
    echo "Example: $0 fluid-admin"
    exit 1
fi

OLD_DIR="$BASEDIR/${REPO_NAME}@worktrees"
OLD_REPO="$OLD_DIR/$REPO_NAME"
NEW_DIR="$BASEDIR/$REPO_NAME"

# Check old directory exists
if [[ ! -d "$OLD_REPO" ]]; then
    echo "Error: $OLD_REPO does not exist"
    exit 1
fi

# Check new directory doesn't already exist
if [[ -d "$NEW_DIR" ]]; then
    echo "Error: $NEW_DIR already exists"
    exit 1
fi

# Check for uncommitted changes
cd "$OLD_REPO"
if [[ -n $(git status --porcelain) ]]; then
    echo "Error: $REPO_NAME has uncommitted changes"
    echo "Please commit or stash changes first, then re-run."
    git status --short
    exit 1
fi

# Get remote URL
REMOTE_URL=$(git remote get-url origin)
if [[ -z "$REMOTE_URL" ]]; then
    echo "Error: Could not get remote URL for origin"
    exit 1
fi

# Get default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [[ -z "$DEFAULT_BRANCH" ]]; then
    # Fallback: check if main or master exists
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        DEFAULT_BRANCH="main"
    elif git show-ref --verify --quiet refs/remotes/origin/master; then
        DEFAULT_BRANCH="master"
    else
        echo "Error: Could not determine default branch"
        exit 1
    fi
fi

echo "Converting $REPO_NAME..."
echo "  Remote: $REMOTE_URL"
echo "  Default branch: $DEFAULT_BRANCH"
echo ""

# Create new directory structure
echo "Creating bare clone..."
mkdir -p "$NEW_DIR"
git clone --bare "$REMOTE_URL" "$NEW_DIR/.bare"

# Create .git file pointing to bare repo
echo "gitdir: ./.bare" > "$NEW_DIR/.git"

# Configure bare repo
cd "$NEW_DIR"
git config core.bare false

# Point HEAD away from the default branch so we can create a worktree for it
# The bare repo's HEAD initially points to the default branch, which blocks worktree creation
git symbolic-ref HEAD refs/heads/_bare_placeholder

# Add fetch refspec (bare clones don't include this by default)
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

# Fetch to create remote tracking refs
echo "Fetching remote refs..."
git fetch origin

# If default branch is 'main', add repo-local git new alias
if [[ "$DEFAULT_BRANCH" == "main" ]]; then
    echo "Adding repo-local git new alias for 'main' branch..."
    git config alias.new '!f() { name=$(echo "$1" | tr "/" "_"); git fetch origin main && git worktree add "$name" -b "$name" origin/main; }; f'
fi

# Create default branch worktree tracking remote
echo "Creating $DEFAULT_BRANCH worktree..."
git worktree add -B "$DEFAULT_BRANCH" "$DEFAULT_BRANCH" "origin/$DEFAULT_BRANCH"

# Set up tracking for the branch
git config "branch.$DEFAULT_BRANCH.remote" origin
git config "branch.$DEFAULT_BRANCH.merge" "refs/heads/$DEFAULT_BRANCH"

# Create documentation files
echo "Creating documentation files..."

# Get today's date
TODAY=$(date +%Y-%m-%d)

# CLAUDE.md
cat > "$NEW_DIR/CLAUDE.md" << EOF
# ${REPO_NAME}

See the codebase within a worktree for the complete feature set.

## Directory Structure

\`\`\`
${REPO_NAME}/
  .bare/           # Bare git repository
  .git             # Points to .bare
  CLAUDE.md        # This file
  TASKS.md         # Active work per worktree
  DECISIONS.md     # Architectural choices
  TOPICS.md        # Future discussion items
  ${DEFAULT_BRANCH}/            # Worktree on ${DEFAULT_BRANCH} branch
  tad_feature/     # Branch and directory use the same name
\`\`\`

Branch names and directory names are identical, using \`_\` as separator (e.g., \`tad_feature\`).

This is the parent directory using a bare repo + worktrees structure. All worktrees are peers-work happens inside individual worktrees, not here.

## Working with Worktrees

Each worktree is an independent checkout. You can work in multiple worktrees simultaneously.

**Creating:**
- \`git new tad_feature-name\` - creates branch + worktree \`tad_feature-name/\`
- \`git review someone_branch\` - creates worktree \`someone_branch/\` for PR review

**Managing:**
- \`git wt\` - list all worktrees
- \`git del tad_feature-name\` - remove worktree and delete branch

**When to work from parent vs worktree:**
- Parent (\`${REPO_NAME}/\`) - worktree management, reviewing TASKS.md, multi-worktree coordination
- Worktree (\`${REPO_NAME}/${DEFAULT_BRANCH}/\`, etc.) - actual code work, running tests, making changes

## Coding Rules

Detailed coding standards are inside each worktree:
- \`<worktree>/.cursor/rules/\` - Project-specific rules
- \`<worktree>/**/*.ai.md\` - Domain-specific documentation

When editing code, work from inside the relevant worktree where those rules are accessible.

## Tracking Files

### TASKS.md
Tracks current worktrees and active work. For each worktree: what's been done, what's remaining. Use for multi-step features that span sessions.

Prompt when appropriate: "Add this to your tasks?"

### DECISIONS.md
Records decisions that have been made-architecture choices, conventions, patterns, tooling. Include rationale.

Prompt when appropriate: "Add this to your decisions?"

### TOPICS.md
Captures ideas, questions, and topics for future discussion. Not yet decided-just noted for later.

Prompt when appropriate: "Add this to your discussion topics?"

## Session Start

At the start of a session from this directory:
1. Read TASKS.md to understand current worktrees and active work
2. Run \`git wt\` to see actual worktree state
3. Ask what the user wants to work on
EOF

# TASKS.md
cat > "$NEW_DIR/TASKS.md" << EOF
# Active Tasks

## Current Worktrees

| Worktree | Branch | Status | Description |
|----------|--------|--------|-------------|
| ${DEFAULT_BRANCH} | ${DEFAULT_BRANCH} | reference | Main branch, kept up to date |

---

## In Progress

(none)

---

## Completed

(none)
EOF

# DECISIONS.md
cat > "$NEW_DIR/DECISIONS.md" << EOF
# Decisions

## ${TODAY}

### Bare Repo + Worktrees Structure

**Decision:** Use a bare git repo with worktrees instead of a traditional clone.

**Structure:**
\`\`\`
${REPO_NAME}/
  .bare/           # Bare git repository
  .git             # Points to .bare
  ${DEFAULT_BRANCH}/            # Worktree on ${DEFAULT_BRANCH}
  <feature>/       # Additional worktrees
\`\`\`

**Rationale:** All worktrees are peers-no "special" main worktree. Can delete/recreate any worktree freely. Clean mental model. Consistent with other repos in this workspace.
EOF

# TOPICS.md
cat > "$NEW_DIR/TOPICS.md" << EOF
# Topics to Discuss

Future ideas and topics to explore. Move to DECISIONS.md once decided.

---

(none yet)
EOF

# Remove old directory
echo "Removing old directory..."
rm -rf "$OLD_DIR"

echo ""
echo "Done! $REPO_NAME converted successfully."
echo ""
echo "New structure:"
ls -la "$NEW_DIR"
echo ""
echo "Worktrees:"
cd "$NEW_DIR" && git worktree list
