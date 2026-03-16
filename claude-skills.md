# Claude Code Skills (Custom Slash Commands)

Skills live in `~/.claude/skills/` with each skill in its own directory.

## /my-reviews

**Location:** `~/.claude/skills/my-reviews/skill.md`
**Purpose:** Show PRs where I've been requested as a reviewer

**How it works:**
1. Reads `~/.claude/REVIEWS.md` for current state
2. Fetches recent messages from Slack `#pr-review-request` (channel `C07EC3XHHT8`)
3. Looks for messages mentioning Slack ID `<@U080F9F71J9>`
4. Checks each PR's GitHub status (open, approved, merged)
5. Updates REVIEWS.md and displays active reviews table

## /ask-review

**Location:** `~/.claude/skills/ask-review/SKILL.md`
**Usage:** `/ask-review <person> to review <linear-code>`
**Examples:** `/ask-review chris to review DATA-123`

**How it works:**
1. Parses person name and Linear code from input
2. Looks up person in `~/.claude/team.json` (fuzzy match)
3. Finds PR via Linear issue branch name
4. Checks CI status (must be SUCCESS — all of: rails-tests, models-tests, services-tests, lib-tests, commerce-tests, rubocop)
5. Assigns reviewer on GitHub via `gh pr edit --add-reviewer`
6. Sends Slack ping to `#pr-review-request` + threaded summary

## /bot-review

**Location:** `~/.claude/skills/bot-review/SKILL.md`
**Usage:** `/bot-review <linear-code>`

**How it works:**
1. Finds PR for Linear issue
2. Assigns `fluid-commerce/reviewer` bot team as GitHub reviewer

## /my-tasks

**Location:** `~/.claude/skills/my-tasks/SKILL.md`
**Purpose:** Show summary table of TASKS.md for the current repo

**How it works:**
1. Reads TASKS.md from repo root
2. Syncs with actual worktree state (removes stale entries)
3. Checks for open PRs matching each branch
4. Displays summary table with Linear ID, status, and PR link

## /shepherd-pr

**Location:** `~/.claude/skills/shepherd-pr/SKILL.md`
**Usage:** `/shepherd-pr <linear-code>`
**Purpose:** Watch a PR, fix CI failures and review feedback until ready to merge

**How it works:**
1. Finds PR for Linear issue
2. Checks CI status and review status
3. If CI failing: fetches logs, diagnoses failure, fixes code, pushes
4. If review feedback: evaluates each comment, fixes valid issues, replies to comments
5. If CI pending: waits up to 15 minutes
6. Loops until PR is green and approved (max 10 fix cycles)
7. Requests bot review as final step

## Team Directory (~/.claude/team.json)

```json
{
  "Andy Beutler": { "github": "andyb95", "slack": "U09825HSHQU" },
  "Brandon Southwick": { "github": "brs98", "slack": "U08CMMKP55Y" },
  "Chris Carlson": { "github": "cwcarlson10", "slack": "U08FZQP0VBN" },
  "Edu Depetris": { "github": "edudepetris", "slack": "U07F5LWJUJE" },
  "Jonathan Fox": { "github": "a-badger-llama", "slack": "U093GUU5TQT" },
  "Mike Moore": { "github": "blowmage", "slack": "U08CEG5NV2S" },
  "Mike Tingey": { "github": "tingeym", "slack": "U04CMCG5YS2" },
  "Ryan Gale": { "github": "Rgaliant", "slack": "U080J4RJ9LK" },
  "Seth Weinheimer": { "github": "sethgw", "slack": "U05S3UQ99HT" },
  "Jake Bliss": { "github": "jake-bliss", "slack": "U07F85U99V2" },
  "Briton Baker": { "slack": "U07PW7VF7H9" },
  "Shadrac Reyes": { "github": "ShadReyes", "slack": "U07D7F94X6C" },
  "Roman Khadka": { "github": "romankhadka", "slack": "U05RF3TKMT9" },
  "Tad Thorley": { "github": "phaedryx", "slack": "U080F9F71J9" },
  "Brayden Pay": { "github": "braypay", "slack": "U07TTREUVDY" }
}
```
