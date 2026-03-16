# Claude Code Legacy Commands

Legacy commands live in `~/.claude/commands/`. These predate the skills system.

## /review-it

**File:** `~/.claude/commands/review-it.md`

Comprehensive security and quality review of changed files in the current branch.

**Special behavior for `tad/` branches:** Automatically rebases with master and resolves conflicts before review, then reviews only YOUR changes vs master.

**Review areas:**
- Security: injection, auth, data exposure, rate limiting
- Quality: structure, readability, SOLID, error handling
- Performance: N+1 queries, caching, algorithms
- Standards: `.cursor/rules/` compliance

**Severity levels:** CRITICAL (must fix), WARNING (should fix), PASSING

## /spec-it

**File:** `~/.claude/commands/spec-it.md`

Creates and runs RSpec specs for all modified files, iterating until all pass.

**Process:**
1. Finds modified Ruby files in current branch
2. Analyzes dependencies to find all affected specs
3. Writes specs following `.cursor/rules/rspec-best-practices.mdc`
4. Runs all affected specs (direct + dependent)
5. Fixes failures and re-runs (up to 5 iterations)

**RSpec rules:** No `let`, `before`, `shared_context`, `subject`, `described_class`. No factories. Explicit setup in test body. Arrange-Act-Assert.

## /explain-this

**File:** `~/.claude/commands/explain-this.md`
**Usage:** `/explain-this <file_path>`

Comprehensive code explanation: file overview, architectural analysis, code breakdown, technical considerations, integration context.

## /refactor-this

**File:** `~/.claude/commands/refactor-this.md`
**Usage:** `/refactor-this <file_path>`

Risk-based refactoring with test-driven approach:
- High risk: characterization tests first, minimal changes
- Medium risk: add missing tests, small isolated changes
- Low risk: bold refactoring with confidence

## /document-it

**File:** `~/.claude/commands/document-it.md`

Updates `*.ai.md` files to reflect changes in current branch. Scans git for modified files, finds corresponding AI documentation files, updates them to match current implementation.

## /toml-this

**File:** `~/.claude/commands/toml-this.md`
**Usage:** `/toml-this <file_path>`

Adds TOML-style structured comments to Ruby files:
```ruby
# [file]
# purpose = "Processes user enrollment"
# dependencies = ["PaymentService", "NotificationService"]

# [method.process]
# params = ["user: User", "course: Course"]
# returns = "Result object"
# side_effects = ["Creates enrollment", "Sends notifications"]
```

## /nplus1-it

**File:** `~/.claude/commands/nplus1-it.md`

Analyzes modified Ruby files for N+1 query patterns:
- Controller actions missing `includes/preload/eager_load`
- Instance methods causing N+1 on collections
- View loops without eager loading
- Blueprint/serializer usage without proper includes

**Severity:** CRITICAL (definite N+1), WARNING (potential), CLEAN

## /resolve-it

**File:** `~/.claude/commands/resolve-it.md`

Automatically resolves merge conflicts across all files:
1. Detects conflicts via `git status`
2. Analyzes each conflicted file
3. Resolves intelligently (additive, modifications, deletions, imports)
4. Validates resolution (syntax, imports, conventions)
5. Stages resolved files
