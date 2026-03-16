# Fluid Commerce Platform

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interfaces                          │
├─────────────┬─────────────┬─────────────┬──────────┬───────────┤
│ fluid-admin │fluid-checkout│ fluid-login │fluid-chat│fluid-mobile│
│  (Next.js)  │  (Next.js)   │  (Next.js)  │ (React)  │  (Expo)   │
└──────┬──────┴──────┬───────┴──────┬──────┴────┬─────┴─────┬─────┘
       │             │              │           │           │
       └─────────────┴──────────────┴───────────┴───────────┘
                                │
                    ┌───────────▼───────────┐
                    │        fluid          │
                    │   (Rails 7.2 Core)    │
                    │  E-commerce + MLM     │
                    └───────────┬───────────┘
                                │
       ┌────────────────────────┼────────────────────────┐
       │                        │                        │
┌──────▼──────┐    ┌────────────▼────────────┐   ┌──────▼──────┐
│fluid-middleware│ │   fluid-integrations    │   │fluid-connect│
│  (Rails 8)     │ │      (Rails 8)          │   │  (Bun/Ruby) │
│  Adapters      │ │  MLM Platform Sync      │   │Exigo Adapter│
└────────────────┘ └─────────────────────────┘   └─────────────┘
                                │
                   ┌────────────┴────────────┐
                   │  External MLM Systems   │
                   │ Exigo, Pillars, ByDesign│
                   │   Infotrax, ASEA        │
                   └─────────────────────────┘
```

## Repo Summary

| Repo | Purpose | Tech |
|------|---------|------|
| **fluid** | Core e-commerce + MLM engine | Rails 7.2, React |
| **fluid-admin** | Admin dashboard (iframe in fluid) | Next.js 16, React 19 |
| **fluid-checkout** | Customer checkout flow | Next.js 16, React 19 |
| **fluid-login** | Authentication UI | Next.js 15, JWT |
| **fluid-chat** | Customer chat component | React 17, MUI |
| **fluid-mobile** | iOS/Android apps (17+ MLM brands) | React Native, Expo |
| **fluid-integrations** | Bi-directional MLM platform sync | Rails 8 API |
| **fluid-middleware** | System adapters | Rails 8 |
| **fluid-connect** | Exigo-specific adapter | Bun + Ruby monorepo |
| **fluid-cli** | Developer CLI tool | Ruby gem |
| **fluid-static-pages** | Static site generator for brands | Node.js, Mustache |
| **fluid-valve** | Rails engine (in development) | Rails 8 |
| **fluid-reservoir** | Custom MCP code intelligence | Ruby |

## Key Data Flows

**Authentication:** `fluid-login` → `fluid` API → JWT → all frontends

**Orders:** `fluid-checkout` → `fluid` API → payment gateways (Stripe, Braintree, PayPal, Spreedly)

**Admin:** `fluid` embeds `fluid-admin` in iframe with `fluidUserToken` URL param

**MLM Sync:** External systems ↔ `fluid-integrations` (webhook/polling) ↔ `fluid`

## Shared Patterns

- **Frontend stack:** Radix UI + Tailwind + TanStack Query + Zod + React Hook Form
- **Backend stack:** Rails 7-8 + PostgreSQL + Sidekiq/SolidQueue + Redis
- **Auth header:** Bearer tokens via `x-fluid-client` or `Authorization`
- **Multi-tenancy:** Company-scoped operations throughout all repos
- **Toasts:** Use `fluidToast` from shared UI library (not direct `sonner`)

## API Endpoints (fluid core)

- `/api/v1/fluid_orchestration/*` - Payment orchestration
- `/api/v1/fluid_pay/*` - Payment account management
- `/api/v1/cart_items` - Shopping cart
- `/api/v1/orders` - Order management
- `/api/v1/sign_in` - Authentication

## Local Dev Ports

| Service | Port |
|---------|------|
| fluid-integrations backend | 12100 |
| fluid-integrations frontend | 12102 |

## GitHub Organization

`fluid-commerce`

## Integrations

### Linear
- Issue tracking via MCP plugin
- Prefixes: `DATA-*`, `INFRA-*`, `WEC-*`
- Branch names must reference Linear codes

### Slack
- Custom `slack-mcp` MCP server at `/Volumes/sourcecode/slack/`
- PR review requests: `#pr-review-request` (channel `C07EC3XHHT8`)
- Slack-native formatting (not GitHub markdown)

### Google Cloud
- Project: `fluid-417204`
- Account: `tad@fluid.app`
- Cloud SQL proxy: `prodproxy` alias
- Cloud Run service: `fluid-web-eu` (europe-west1)

### fluid-reservoir (Custom MCP)
- Semantic search: `search`, `search_code`, `search_docs`, `search_api`, `similar`
- Code intelligence: `definitions`, `callers`, `trace`, `impact`, `diff_impact`, `test_coverage`
- Rails-specific: `model_profile`, `model_graph`, `routes`, `controller_profile`, `concern_profile`, `hierarchy`, `request_trace`
- Repo info: `files`, `list_repos`, `config`, `health`, `status`, `metrics`, `churn`, `dead_code`

## Coding Standards (.rules/)

Both `fluid/` and `fluid-integrations/` have `.rules/` directories:

| Rule File | Applies To |
|-----------|-----------|
| `ruby-coding-standards.ai.md` | All Ruby files |
| `rspec-best-practices.ai.md` | Test files (`*_spec.rb`) |
| `rails-model-rules.ai.md` | `app/models/**/*` |
| `rails-api-rules.ai.md` | `app/controllers/**/*` |
| `rails-service-rules.ai.md` | `app/services/**/*` |
| `tsx-coding-standards.ai.md` | TypeScript/React (`*.tsx`) |
| `ai-documentation-standards.ai.md` | AI docs (`*.ai.md`) |
| `tracking-files.ai.md` | TASKS.md, PENDING.md, etc. |
| `api-mvc-best-practices.ai.md` | API design patterns |
| `cli-preferences.ai.md` | Preferred CLI tools |
| `feature-documentation.ai.md` | Feature documentation |
| `liquid-css-sync.ai.md` | Liquid template + CSS |

## CI Checks

PRs validated against: `rails-tests`, `models-tests`, `services-tests`, `lib-tests`, `commerce-tests`, `rubocop`

## Key RSpec Rules

**Never use:** `let`, `let!`, `before`, `after`, `subject`, `described_class`, `shared_context`, `shared_examples`, factories, mocking internal services

**Always:** Test observable behavior, Arrange-Act-Assert, explicit setup in test body, mock only external boundaries
