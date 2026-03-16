# DAM-Backed Theme System

**Rule Name:** dam-backed-theme-system
**Description:** The DAM-backed theme system renders storefront pages using assets stored in the Digital Asset Manager (`Dam::*` models) instead of the `ApplicationTheme` + GCS CDN pipeline. Core components: `Dam::VirtualFileSystem`, `Themes::Renderer`, `Themes::Compiler`, `Themes::DataLoader`.

## Table of Contents

- [Usage](#usage)
- [Architecture](#architecture)
  - [Why DAM-backed themes over GCS CDN](#why-dam-backed-themes-over-gcs-cdn)
  - [Component Map](#component-map)
  - [Component Status](#component-status)
  - [Query Architecture](#query-architecture)
- [Migrating Current System Concerns to DAM](#migrating-current-system-concerns-to-dam)
  - [Concern 1: Region-Specific Routing](#concern-1-region-specific-routing-themeregionrule)
  - [Concern 2: Git Sync](#concern-2-git-sync-applicationthemegitconnection)
  - [Concern 3: Theme Settings](#concern-3-theme-settings-and-customization)
  - [Concern 4: Distribution and Packaging](#concern-4-theme-distribution-and-packaging)
  - [Concern 5: Publishing Workflow](#concern-5-publishing-workflow)
  - [Concern 6: Data Binding and Variables](#concern-6-data-binding-and-variables)
  - [Concern 7: Cache Invalidation](#concern-7-cache-invalidation)
  - [Concern 8: Template Validation](#concern-8-template-validation)
  - [Concern 9: Debugging](#concern-9-debugging--why-is-this-rendering-the-wrong-thing)
  - [Concern 10: Page Type Extensibility](#concern-10-page-type-extensibility)
  - [Concern 11: Localization](#concern-11-localization)
  - [Migration Summary](#summary-migration-surface)
  - [Critical Path to Production](#critical-path-to-production)
- [Known Shortcomings and Mitigations](#known-shortcomings-and-mitigations)
- [Known Issues (INFRA-1499)](#known-issues-infra-1499)
- [Rules](#rules)
- [Examples](#examples)
- [Verification](#verification)
- [Future Work](#future-work)
- [Enforcement](#enforcement)

## Usage

```ruby
# Render a theme page (Renderer is a module, not a class)
html = Themes::Renderer.render(
  company: current_company,
  theme_path: "themes.my_theme.home_page",
  tags_string: "en;us;latest",
  page_context: { cart: current_cart, user: current_user },
  params: request.params
)

# Internally, Renderer builds a VirtualFileSystem, loads templates,
# resolves data specs, and renders Liquid with all variables merged.
```

## Architecture

### Why DAM-backed themes over GCS CDN

| Concern              | DAM-backed (this system)                                                                 | GCS CDN (theme team's current approach)                                                    |
| -------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Page type addressing | Hierarchical ltree paths                                                                 | Hardcoded 24-value `themeable_type` enum (needs migration for new types)                   |
| Variant dimensions   | Tag-based (`"en;us;rep123"`) via `tags_string`                                           | Logidze snapshots — affiliate/country/locale are combinatorial pre-renders                 |
| Data binding         | Declarative `data.json` specs per component                                              | Imperative 5-layer `Variables::Base` merge chain                                           |
| Validation           | `Themes::Compiler` validates templates, checks circular deps, cross-references variables | No equivalent                                                                              |
| Cache invalidation   | Touch-based (`AssetResolver`) — no explicit invalidation code                            | GCS glob-delete fan-out — explicit invalidation, stale data risk                           |
| HTML caching         | `Rails.cache` — lazy on first request                                                    | GCS CDN pre-rendering — eagerly renders millions of files per affiliate x country x locale |

**Key insight:** Affiliate, country, and locale are variant tags in `tags_string`, already part of the cache key. Session-specific data (cart, user) should be loaded client-side. This eliminates the combinatorial explosion that motivated the GCS approach.

### Component Map

| Class                                 | File                                                  | Purpose                                                            |
| ------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------ |
| `Dam::VirtualFileSystem`              | `app/services/dam/virtual_file_system.rb`             | Loads Liquid templates from DAM assets (resolve_with_defaults)     |
| `Dam::AssetResolver`                  | `app/services/dam/asset_resolver.rb`                  | Resolves assets by path + tags with ltree hierarchy + tag matching |
| `Themes::Renderer`                    | `app/services/themes/renderer.rb`                     | Parses and renders Liquid templates with registered tags/filters   |
| `Themes::Compiler`                    | `app/services/themes/compiler.rb`                     | Validates templates, checks deps, cross-references variables       |
| `Themes::DataLoader`                  | `app/services/themes/data_loader.rb`                  | Orchestrates data loading for template variables                   |
| `Themes::Data::AssetsLoader`          | `app/services/themes/data/assets_loader.rb`           | Resolves DAM assets for template use                               |
| `Themes::Data::PlatformLoader`        | `app/services/themes/data/platform_loader.rb`         | Loads platform resources (products, collections, etc.)             |
| `Themes::Data::CompanySettingsLoader` | `app/services/themes/data/company_settings_loader.rb` | Company-level settings (logo, name, etc.)                          |
| `Themes::Data::LocaleLoader`          | `app/services/themes/data/locale_loader.rb`           | Languages and countries for locale switching                       |
| `Themes::Data::PageContextLoader`     | `app/services/themes/data/page_context_loader.rb`     | Session/page-specific context (cart, user)                         |
| `Themes::Data::UrlLoader`             | `app/services/themes/data/url_loader.rb`              | URL building for storefront links                                  |
| `Themes::Liquid::Tags::Render`        | `app/services/themes/liquid/tags/render.rb`           | Custom render tag that auto-loads component config/data            |

### Component Status

| Component                               | Status    | Notes                                                                |
| --------------------------------------- | --------- | -------------------------------------------------------------------- |
| `Dam::VirtualFileSystem`                | Built     | Has INFRA-1499 Issue 2 (path flattening bug)                         |
| `Dam::AssetResolver`                    | Built     | Core resolution + `resolve_with_defaults` + `last_modified_for_path` |
| `Themes::Renderer`                      | Built     | Has INFRA-1499 Issues 1 (thread safety) and 7 (cache key)            |
| `Themes::Compiler`                      | Built     | Validates templates, data specs, circular deps                       |
| `Themes::DataLoader`                    | Built     | All 6 loaders complete                                               |
| `Themes::Data::AssetsLoader`            | Built     | Has INFRA-1499 Issue 4 (1-hour dumb cache)                           |
| `Themes::Data::PlatformLoader`          | Built     | Has INFRA-1499 Issue 3 (no caching / N+1)                            |
| `Themes::Data::CompanySettingsLoader`   | Built     | Has INFRA-1499 Issue 5 (no cache invalidation)                       |
| `Themes::Data::LocaleLoader`            | Built     | Has INFRA-1499 Issues 5 (no invalidation) and 6 (cache mutation)     |
| `Themes::Data::PageContextLoader`       | Built     | No known issues                                                      |
| `Themes::Data::UrlLoader`               | Built     | No known issues                                                      |
| `Themes::Liquid::Tags::Render`          | Built     | Has INFRA-1499 Issue 1 (thread-unsafe registration)                  |
| ThemeRendering controller concern (DAM) | Not built | Thin wrapper to auto-build `page_context` and `tags_string`          |
| Client-side hydration endpoints         | Not built | API endpoints for cart/user data; prerequisite for Issue 7 fix       |
| `ThemeRedirect` model                   | Proposed  | Replaces redirect subset of `ThemeRegionRule`                        |
| VersionManager / publishing             | Proposed  | Versioned snapshots with pointer-based publishing                    |
| `Themes::CacheWarmingJob`               | Proposed  | Pre-render common pages after deploy/publish                         |
| `Themes::RecompilationJob`              | Proposed  | Background recompilation on data changes                             |

### Query Architecture

Rendering has two distinct phases with very different query characteristics:

**Phase 1: Template loading (efficient).** `Dam::VirtualFileSystem` calls `AssetResolver.resolve_with_defaults` once at initialization with a wildcard path (e.g., `themes.nova_theme.home_page.*`). This executes 1 `last_modified_for_path` query (every request) + 1 ltree query + 2 variant queries on cache miss, returning **all** templates, configs, and data specs for the page as a hash keyed by filename. Results are cached for 5 minutes with a touch-based key.

**Phase 2: Data loading (unbatched).** Each `{% render 'component' %}` tag triggers an independent `Themes::DataLoader.load()` call for that component's `data.json` spec. If 10 components each reference a platform resource, that's 10 separate `PlatformLoader` queries. This is the primary query cost and the main target for optimization (see Known Shortcomings #2 and Future Work #3).

```
Page Render
├─ VirtualFileSystem.new(company:, path: "themes.nova_theme.home_page.*", tags_string: "en;v1")
│  └─ resolve_with_defaults → 1 bulk ltree query (cached 5min)
│     └─ @assets_by_name = { "layout.liquid" => ..., "hero.config.json" => ..., ... }
│
├─ Renderer reads layout + page templates (hash lookups, 0 queries)
├─ Renderer reads layout + page data specs (hash lookups, 0 queries)
├─ DataLoader.load(combined_data_spec) → 1-3 loader queries
│
└─ Liquid rendering
   ├─ {% render 'hero' %}
   │  ├─ read config/data from VFS (hash lookup, 0 queries)
   │  └─ DataLoader.load(hero_data_spec) → 0-2 loader queries
   ├─ {% render 'nav' %}
   │  ├─ read config/data from VFS (hash lookup, 0 queries)
   │  └─ DataLoader.load(nav_data_spec) → 0-2 loader queries
   └─ ... (repeated per component)
```

**Key design insight:** Template loading is O(1) queries regardless of page complexity. Data loading is O(n) where n = number of components with `data.json` specs. Fixing the data loading layer (PlatformLoader caching + DataLoader batching) would make the entire pipeline O(1).

## Migrating Current System Concerns to DAM

Every feature of the current `ApplicationTheme` system has a DAM-backed equivalent. This section maps each concern, explains how the DAM system handles it, and why the DAM approach is preferred.

### Concern 1: Region-Specific Routing (ThemeRegionRule)

**Current system:** `ThemeRegionRule` model + `Middleware::ThemeRegionRouter` + `ThemeRegionRuleService` + `Shares::ThemeRenderingConcern` + `Shares::ResourceLoadingConcern` + `ThemeRegionRuleController` (404 fallback). A middleware intercepts requests, detects region via cookie/param/IP/profile, runs raw SQL to find a matching rule, then either returns a 302 redirect or sets a `fluid.theme.region_rule_options` request header that controllers read to override template selection and resource binding.

**DAM equivalent:** Region is a tag dimension. Region-specific behavior is expressed as tagged variants of existing theme files — no separate model, middleware, or service needed.

**Template overrides** — tag a different `layout.liquid` variant per region:

```
themes.nova_theme.home_page/layout.liquid  (tagged: us)  → US-specific layout
themes.nova_theme.home_page/layout.liquid  (tagged: eu)  → EU-specific layout
themes.nova_theme.home_page/layout.liquid  (untagged)    → default fallback
```

The `tags_string` already includes the region. `Dam::AssetResolver` picks the right variant automatically via the standard fallback chain: specific tags → broader tags → untagged.

**Resource overrides** — tag a different `data.json` variant per region:

```json
// layout.data.json (tagged: us)
{
  "product": { "source": "platform", "resource": "products", "slug": "us-starter-kit" }
}

// layout.data.json (tagged: eu)
{
  "product": { "source": "platform", "resource": "products", "slug": "eu-starter-kit" }
}
```

The admin UI presents this as "pick a product for EU users" — the UI writes a tagged `data.json` variant. The admin never sees DAM internals.

**Redirects** — the one behavior that genuinely cannot be a DAM variant (a 302 is a routing concern, not a template concern). This requires a small `theme_redirects` routing table:

```ruby
# Proposed — replaces the redirect_type="redirect" subset of ThemeRegionRule
class ThemeRedirect < ApplicationRecord
  belongs_to :company
  validates :route_path, :region_code, :redirect_url, presence: true
  validates :region_code, uniqueness: { scope: [:company_id, :route_path] }
end
```

This is much simpler than `ThemeRegionRule` because it only handles redirects. Template overrides and resource swaps are entirely absorbed by DAM tag variants.

**Why DAM is better:**

- **One mechanism** for all variant dimensions (locale, region, version, affiliate, A/B test) instead of a separate system per dimension
- **Compile-time validation** — `Themes::Compiler` can verify that a region's `data.json` references a valid product, that all regions have coverage, and that fallbacks exist. `ThemeRegionRule` has no validation — you can point it at a deleted product and it silently breaks (`resource_object` returns nil, controller continues with nil)
- **Independent testability** — "What does EU resolve to?" is a single `DataLoader.load()` call. With `ThemeRegionRule`, debugging requires tracing through middleware → headers → concerns → cache across 6 layers
- **No middleware** — eliminates raw SQL in middleware, request header passing, and the separate 404 fallback controller

### Concern 2: Git Sync (ApplicationThemeGitConnection)

**Current system:** `ApplicationThemeGitConnection` model links an `ApplicationTheme` to a GitHub repo + branch via `GithubInstallation`. `GithubInstallations::WebhookAction` receives push webhooks, diffs commits, and applies file changes via `ApplicationThemeResource` (which writes to `ApplicationThemeTemplate` content columns and `FileResource` records).

**DAM equivalent:** The git connection model itself is storage-agnostic — it tracks which repo/branch to watch. The only coupling is in `WebhookAction#apply_changed_files!` and `#update_resource`, which currently write through `ApplicationThemeResource`.

The migration is to change the write target:

```ruby
# Current: writes to ApplicationThemeTemplate content / FileResource
resource&.update(content)

# DAM: writes to DAM asset variant at the theme's path
Dam::VariantBuilder.build(
  asset: asset,
  content: content,
  tags: [branch_tag]
)
```

The webhook logic (diff detection, `.fluidignore` filtering, rename handling) stays identical. `ApplicationThemeGitConnection` stays as-is. Only the write target changes.

**Why DAM is better:**

- File-to-asset mapping is more natural — git repos contain files, DAM stores files. The current system converts files to database text columns (`ApplicationThemeTemplate.content`), then back to file-like objects at render time
- DAM assets support tag-based versioning — a git branch can be a tag, enabling branch previews without publishing
- Binary assets (images, fonts) go directly into DAM instead of through the `FileResource` → ImageKit detour

### Concern 3: Theme Settings and Customization

**Current system:** Two-part pattern using `ApplicationThemeTemplate` records:

- `settings_schema` (themeable_type: "config", format: "json") — JSON schema defining available controls with types (color, color_scheme_group, text, image, range, select), defaults, and groupings
- `settings_data` (themeable_type: "config", format: "json") — current values with preset support

`ApplicationTheme#settings` merges these: iterates schema sections, looks up values from data (with preset indirection), and wraps special types (`ColorDrop`, `ColorSchemeDrop`). `ApplicationTheme#global_variables` merges settings into the variable chain.

**DAM equivalent:** Two-file split — schema is static, data is dynamic:

**`settings_schema.json`** — one untagged copy per theme. Defines the UI contract:

```json
[
  {
    "group": "Header",
    "settings": [
      { "id": "primary_color", "type": "color", "default": "#FF0000" },
      { "id": "hero_image", "type": "image" }
    ]
  },
  {
    "group": "Typography",
    "settings": [
      {
        "id": "font_size",
        "type": "range",
        "min": 12,
        "max": 48,
        "default": 16
      }
    ]
  }
]
```

**`settings_data.json`** — tagged per-locale, per-region, per-company. Stores runtime values:

```json
{
  "primary_color": "#3B82F6",
  "hero_image": "hero-bg.jpg",
  "font_size": 18
}
```

Three consumers, two files with clear roles:

- **Admin UI** reads `settings_schema.json` for control types, groups, and constraints. Reads `settings_data.json` for current values. Writes back to `settings_data.json` only.
- **Renderer** reads `settings_data.json` (falling back to defaults from schema) to populate template variables
- **Compiler** validates `settings_data.json` values against `settings_schema.json` type constraints

The schema is defined once (untagged) and never varies. The data has tagged variants for locale/region/company overrides. Changing a setting's type means editing one schema file, not every variant.

**Why DAM is better:**

- **Compiler validates settings** — checks that every value in `settings_data.json` matches its type constraint from `settings_schema.json`. The current system has no validation; invalid values silently render
- **Tag-variant-friendly** — locale-specific values are tagged variants of `settings_data.json`. Schema stays fixed.
- **No special Liquid Drops** — the current system wraps colors in `ColorDrop` and color schemes in `ColorSchemeDrop` at the model layer. In DAM, type-aware rendering is the Renderer's responsibility, keeping the data layer clean
- **No preset indirection** — the current system's `settings_data` has a `current` key that's either a preset name (string) or inline values. The DAM approach is direct key-value with tagged variants for overrides

### Concern 4: Theme Distribution and Packaging

**Current system:** `ApplicationThemeVersion` model with zip URLs, version strings, changelogs, and status workflow (draft/publishing/published/rejected). Root themes (`company_id: nil`) serve as marketplace templates. Companies "install" themes via clone. Import/export actions support zip-based distribution. `creator_id` tracks authorship.

**DAM equivalent:** A thin `ApplicationTheme` model for marketplace metadata only — not content:

```ruby
class ApplicationTheme < ApplicationRecord
  # Queryable metadata for marketplace listings
  # name, description, demo_url, creator_id, status, version, changelog
  # dam_path: "themes.nova_theme" — pointer to DAM content tree
end
```

**Install theme:** Copy the DAM asset tree from the source (root company or marketplace) into the target company's namespace. Create a metadata row with the new `company_id` pointing to the copied path.

**Export theme:** Walk the DAM asset tree at `themes.nova_theme.*`, zip the contents, attach to an `ApplicationThemeVersion` record. Same zip distribution as today.

**Upgrade theme:** Diff the installed company's asset tree against the new version. Apply changes while preserving company customizations (company-tagged config variants are not overwritten by theme updates).

```ruby
# Pseudocode for theme installation
def install_theme(source_theme:, target_company:)
  source_path = source_theme.dam_path  # e.g., "themes.nova_theme"
  target_path = "themes.nova_theme"    # same path, different company scope

  # Copy all assets from source company's tree to target company's tree
  Dam::AssetResolver.resolve_collection(company: source_theme.company, path: "#{source_path}.*").each do |asset|
    Dam::AssetBuilder.build(company: target_company, path: asset.path, name: asset.name, content: asset.content)
  end

  # Create metadata record
  ApplicationTheme.create!(
    company: target_company,
    name: source_theme.name,
    dam_path: target_path,
    creator_id: source_theme.creator_id,
    version: source_theme.version
  )
end
```

**Why DAM is better:**

- **Content and metadata are separated** — the `ApplicationTheme` model becomes a thin index for marketplace queries, not a content container. Same pattern as Product (metadata in Postgres, images in DAM)
- **Upgrades preserve customizations** — company-tagged config variants survive theme updates because the upgrade only overwrites untagged (default) variants
- **No zip required for internal installs** — asset tree copy is native DAM operation, zip is only needed for external distribution

### Concern 5: Publishing Workflow

**Current system:** `Publishable` mixin on `ApplicationTheme` and `ApplicationThemeTemplate`. Each has `published_data` (JSONB snapshot) and `published_version` (integer) columns. Publishing atomically snapshots the current state. `ApplicationThemeVersion` tracks releases with status workflow: draft → publishing → published → rejected.

**DAM equivalent:** Versioned snapshots. Instead of re-tagging existing variants (which risks partial state), create immutable version sets.

**How it works:**

1. Theme editing creates/updates variants tagged `draft`
2. Publishing creates a new version tag (e.g., `v3`) and copies all current draft variants into that version set
3. A pointer (on the `ApplicationTheme` metadata model or a dedicated tag) marks which version is live: `published:v3`
4. Rendering always resolves against the published version tag
5. Rollback changes the pointer: `published:v2`. The v3 variants still exist but are no longer resolved

```ruby
# Proposed — create versioned snapshot from current drafts
def publish_theme(company:, theme_path:, version_tag:)
  ApplicationRecord.transaction do
    drafts = Dam::AssetResolver.resolve_collection(
      company: company,
      path: "#{theme_path}.*",
      tags_string: "draft"
    )

    # Create versioned copies of all draft variants
    drafts.each do |variant|
      Dam::VariantBuilder.build(
        asset: variant.asset,
        content: variant.content,
        tags: (variant.tags - ["draft"]) + [version_tag]
      )
    end

    # Update the published pointer (single row update — atomic)
    theme = ApplicationTheme.find_by(company: company, dam_path: theme_path)
    theme.update!(published_version_tag: version_tag)
  end
end

# Rendering uses the published version tag
Themes::Renderer.render(
  company: company,
  theme_path: "themes.nova_theme.home_page",
  tags_string: "en;us;#{theme.published_version_tag}",
  ...
)

# Rollback: change the pointer — previous versions are never deleted
theme.update!(published_version_tag: "v2")
```

**Why DAM is better:**

- **Immutable versions** — published variants are never modified, only the pointer changes. No risk of partial state from interrupted tag operations
- **Instant rollback** — change one column (`published_version_tag`) instead of restoring JSONB snapshots
- **Full version history** — every published version's variants persist in DAM. Diff any two versions by comparing their variant sets
- **More granular** — can publish individual components by versioning subsets of the asset tree
- **No JSONB snapshots** — the current system duplicates entire template content into `published_data` columns. DAM versions are tagged references to the same assets

### Concern 6: Data Binding and Variables

**Current system:** Imperative 5-layer merge chain via `Variables::Base` subclasses. Each layer adds variables (theme defaults → company settings → template variables → resource-specific variables → request context). Lazy-loaded Liquid Drops (`ProductsDrop`, `CollectionsDrop`, etc.) resolve on access during rendering. Variable dependencies are implicit — no way to know what data a template needs without rendering it.

**DAM equivalent:** Declarative `data.json` specs per component:

```json
{
  "featured_products": {
    "source": "platform",
    "resource": "products",
    "scope": "featured",
    "limit": 8
  },
  "company_name": {
    "source": "company_settings",
    "key": "name"
  },
  "cart_count": {
    "source": "page_context",
    "key": "cart.items_count"
  }
}
```

Six data sources handle all variable resolution:

| Source             | Purpose                                                               | Caching (current)                                    | Caching (after INFRA-1499)                        |
| ------------------ | --------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------- |
| `company_settings` | Company config (name, logo, social URLs)                              | 1hr TTL, no invalidation (Issue 5)                   | Touch-based, 5min TTL                             |
| `page_context`     | Session data (cart, user, affiliate)                                  | None (per-request)                                   | None (per-request)                                |
| `locale`           | Languages, countries, currency                                        | 1hr TTL, no invalidation, mutates cache (Issues 5/6) | Touch-based, 5min TTL                             |
| `url`              | Request path, params, generated URLs, breadcrumbs, library navigation | None (per-request)                                   | None (per-request)                                |
| `platform`         | Database resources (products, collections, content, forms)            | **None** — zero caching (Issue 3)                    | Touch-based for singles, 5min TTL for collections |
| `assets`           | DAM assets (images, files, metadata)                                  | 1hr TTL, no invalidation (Issue 4)                   | Touch-based, 5min TTL                             |

**Why DAM is better:**

- **Explicit dependencies** — `Themes::Compiler` knows exactly what data every template needs before rendering. Can detect missing specs, unused variables, and invalid source references
- **No lazy-loaded Drops** — all data is pre-resolved, giving clear performance characteristics. No surprise N+1 queries during Liquid rendering
- **Independently testable** — each data source can be called and inspected in isolation:

```ruby
# Test what a single data spec resolves to
Themes::DataLoader.load(
  data_spec: { "product" => { "source" => "platform", "resource" => "products", "slug" => "blue-shirt" } },
  company: company,
  context: {},
  params: {}
)
# => { "product" => { "id" => 123, "title" => "Blue T-Shirt", ... } }
```

### Concern 7: Cache Invalidation

**Current system:** GCS CDN pre-rendering eagerly renders pages for every affiliate x country x locale combination. Cache invalidation uses GCS glob-delete fan-out — explicit, fragile, risk of stale data. `ThemeRegionRule` has separate cache busting via `after_commit` that touches associated templates.

**DAM equivalent:** Touch-based cache keys. Cache keys include `updated_at` timestamps, so they self-invalidate when the underlying data changes. No explicit invalidation code needed.

```ruby
# Cache key includes timestamp — automatically invalidates on change
updated_at = company.class.where(id: company.id).pick(:updated_at)&.to_i || 0
cache_key = "themes:data:settings:#{company.id}:#{updated_at}"

Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
  build_settings(company)
end
```

**Why DAM is better:**

- **No combinatorial explosion** — lazy rendering on first request instead of eagerly pre-rendering millions of combinations
- **Self-invalidating data caches** — no explicit cache-busting code, no glob-delete; data-layer caches include `updated_at` so changes propagate automatically. (Page-level cache still uses time-based TTL — see Issue 7b)
- **Simpler mental model** — if data changed, `updated_at` changed, cache key changed, old entry is unreachable (once Issue 7b adds `last_modified_for_path` to the page cache key)

### Concern 8: Template Validation

**Current system:** No validation. Broken Liquid syntax, references to nonexistent variables, circular `{% render %}` dependencies, and invalid settings values are all discovered at render time (or not at all). `ThemeRegionRule` can point at deleted products — `resource_object` returns nil, the controller continues with nil.

**DAM equivalent:** `Themes::Compiler` validates everything before rendering:

```ruby
result = Themes::Compiler.compile(
  company: company,
  theme_path: "themes.nova_theme.home_page",
  tags_string: "eu;en"
)

# result = {
#   valid: false,
#   errors: [
#     "Data spec references product slug 'eu-kit' but product does not exist",
#     "Circular dependency: layout → hero → sections/cta → layout",
#     "Liquid syntax error in navigation.liquid line 12: unknown tag 'rendor'"
#   ],
#   warnings: [
#     "Variable 'tagline' used in layout.liquid but no data spec found",
#     "Region 'fr' has no data.json variant and no untagged fallback"
#   ],
#   metadata: {
#     templates: ["layout", "hero", "navigation"],
#     data_sources: ["company_settings", "platform"],
#     variables: ["company_name", "product", "cart_count"]
#   }
# }
```

This runs at publish time or in a background job — not per-request. The Compiler is only possible because data requirements are declared in `data.json` files rather than imperatively assembled.

### Concern 9: Debugging — "Why Is This Rendering the Wrong Thing?"

The DAM system's declarative architecture makes every rendering decision inspectable. Each layer has a clear input/output contract and can be called independently in a Rails console, a spec, or a diagnostic endpoint. This section covers both proactive bug discovery (before users see problems) and reactive diagnosis (when something is already wrong).

#### Proactive: Catching Bugs Before They Reach Users

**1. Compile-time validation at publish**

Run `Themes::Compiler` when a theme is saved or published. It catches entire classes of bugs that the current system discovers only at render time (or never):

```ruby
result = Themes::Compiler.compile(
  company: company,
  theme_path: "themes.nova_theme.home_page",
  tags_string: "eu;en"
)
```

What the Compiler catches:

| Bug Class                | Example                                                                       | Current System                                                                      |
| ------------------------ | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Broken Liquid syntax     | `{% rendor 'hero' %}` (typo)                                                  | Discovered at render time — user sees error page                                    |
| Circular dependencies    | layout → hero → cta → layout                                                  | Infinite loop at render time                                                        |
| Missing data specs       | Template uses `{{ product.title }}` but no `data.json` defines `product`      | Variable renders as empty string — silent bug                                       |
| Unused data specs        | `data.json` fetches `featured_products` but no template uses it               | Wasted DB query every render — never discovered                                     |
| Invalid data sources     | `data.json` references `source: "inventory"` which doesn't exist              | Error at render time                                                                |
| Missing variant coverage | EU has a `data.json` variant but FR doesn't, and there's no untagged fallback | FR users get no data — silent bug                                                   |
| Dead product references  | `data.json` references `slug: "discontinued-kit"` — product is inactive       | User sees empty page — `ThemeRegionRule` has this exact bug today with no detection |
| Invalid settings values  | Config has `type: "color"` but `value: "not-a-color"`                         | Renders garbage — no validation in current system                                   |

**2. Cross-region validation**

Check that all expected regions have appropriate content:

```ruby
# Validate a page across all regions the company operates in
company.active_country_codes.each do |region|
  result = Themes::Compiler.compile(
    company: company,
    theme_path: "themes.nova_theme.home_page",
    tags_string: "#{region.downcase};en"
  )
  unless result[:valid]
    Rails.logger.warn("Theme validation failed for region #{region}: #{result[:errors]}")
  end
end
```

This catches gaps like "we added a JP region but never created a JP data.json variant, so JP users fall through to the untagged default which references a US-only product."

**3. Diff-based validation on publish**

When publishing theme changes, compile before and after to detect regressions:

```ruby
# Before publishing, check what changed
before = Themes::Compiler.compile(company: company, theme_path: path, tags_string: "published;en")
after  = Themes::Compiler.compile(company: company, theme_path: path, tags_string: "draft;en")

new_errors = after[:errors] - before[:errors]
if new_errors.any?
  # Block publish, show errors to theme author
end
```

#### Reactive: Diagnosing "Why Does EU See the Wrong Product?"

Each diagnostic step below is a single function call that can be run in a Rails console. No need to trace through middleware, headers, or concerns.

**Step 1: What tags is the request using?**

The first question is always "what tags_string is being constructed?" This determines which variants are selected for everything downstream.

```ruby
# In the DAM system, tags are explicit — built from the request
tags_string = "eu;en;published"
# Compare: in the current system, region detection happens in middleware via
# cookie → param → IP → profile → default, then stored in a request header
```

**Step 2: What template does this page resolve to?**

```ruby
vfs = Dam::VirtualFileSystem.new(
  company: company,
  path: "themes.nova_theme.home_page.*",
  tags_string: "eu;en"
)

# What layout is being used?
layout = vfs.read_template_file("layout")
# => "<!DOCTYPE html>..." or "" if missing

# Is it the EU-specific layout or the default?
# Check which variant was resolved — inspect the tags on the returned assets:
Dam::AssetResolver.resolve(
  company: company,
  path: "themes.nova_theme.home_page",
  name: "layout.liquid",
  tags_string: "eu;en"
)
# Returns array of asset hashes with variants — check the variant tags:
# Tags include "eu" → EU-specific variant was resolved
# Tags are empty   → EU variant is missing, fell back to default
```

**Step 3: What data spec is being used?**

```ruby
# Read the data.json for this page — which variant did we get?
data_json = vfs.read_data_file(template_path: "layout")
data_spec = JSON.parse(data_json)
# => { "product" => { "source" => "platform", "resource" => "products", "slug" => "eu-kit" } }

# Is this the EU-specific data spec or the default?
Dam::AssetResolver.resolve(
  company: company,
  path: "themes.nova_theme.home_page",
  name: "layout.data.json",
  tags_string: "eu;en"
)
# Inspect variant tags on the returned asset:
# Tags include "eu" → good, EU-specific data spec
# Tags are empty    → problem, fell back to untagged default
```

**Step 4: What does the data spec resolve to?**

```ruby
# Resolve the data independently — does the product exist?
resolved = Themes::DataLoader.load(
  data_spec: data_spec,
  company: company,
  context: {},
  params: {}
)
# => { "product" => { "id" => 456, "title" => "EU Starter Kit", ... } }  — correct
# => { "product" => nil }  — problem: product not found or inactive
```

**Step 5: What config values are being used?**

```ruby
config_json = vfs.read_config_file(template_path: "hero")
config = JSON.parse(config_json)
# => { "welcome_message" => { "type" => "text", "value" => "Welcome EU!" } }

# Is this the EU config or the default?
Dam::AssetResolver.resolve(
  company: company,
  path: "themes.nova_theme.home_page",
  name: "hero.config.json",
  tags_string: "eu;en"
)
```

**Step 6: What does the full render produce?**

```ruby
# Render with all resolved data — compare output to expected
html = Themes::Renderer.render(
  company: company,
  theme_path: "themes.nova_theme.home_page",
  tags_string: "eu;en",
  page_context: { cart: nil, user: nil },
  params: {}
)
# Inspect the HTML for the expected product, text, layout
```

**Step 7: Is it a cache issue?**

```ruby
# Check if a stale cached version is being served
# Cache keys are touch-based, so check the timestamp
Dam::AssetResolver.last_modified_for_path(
  company: company,
  path: "themes.nova_theme.home_page"
)
# => 2026-03-09 15:30:00 — when was this last updated?

# Force a fresh render (bypass page-level cache) to compare
html_fresh = Themes::Renderer.render_uncached(
  company: company,
  theme_path: "themes.nova_theme.home_page",
  tags_string: "eu;en",
  page_context: {},
  params: {}
)
# If fresh render is correct but cached is wrong, it's a cache invalidation bug
```

#### Diagnosis Decision Tree

```
Page renders wrong content
│
├─ Wrong template?
│  └─ Check: Dam::AssetResolver.resolve(path, name: "layout.liquid", tags_string:)
│     ├─ Returns variant with wrong tags → EU variant missing, fell back to default
│     └─ Returns expected variant → template is correct, problem is elsewhere
│
├─ Wrong data?
│  └─ Check: read data.json, then Themes::DataLoader.load(data_spec, company:)
│     ├─ data.json has wrong spec → wrong variant resolved (check tags on data.json)
│     ├─ data.json is correct but loader returns nil → resource doesn't exist or is inactive
│     └─ data.json is correct and loader returns data → data is fine, problem is elsewhere
│
├─ Wrong config/strings?
│  └─ Check: read config.json via VFS, inspect variant tags
│     ├─ Got default instead of locale-specific → locale variant missing
│     └─ Got correct variant → config is fine
│
├─ Stale cache?
│  └─ Check: render with Themes::Renderer.render_uncached
│     ├─ Fresh render is correct → cache invalidation bug (check updated_at in cache key)
│     └─ Fresh render is also wrong → not a cache issue
│
└─ Liquid rendering bug?
   └─ Check: render template with known-good variables
      ├─ Output is wrong → template logic bug (inspect Liquid conditionals)
      └─ Output is correct → variables were wrong (go back to data step)
```

#### Comparison: Current System Debugging

In the current system, the same question — "Why does EU see the wrong product?" — requires:

1. **Check middleware** — Did `Middleware::ThemeRegionRouter` detect the right region? It tries cookie → param → IP → profile → default. Which path did it take? No logging by default.
2. **Check raw SQL** — Did the middleware's SQL query find the right `ThemeRegionRule`? The query uses `route_path` which is a normalized path — is the normalization correct for this URL?
3. **Check request header** — Did the middleware set `fluid.theme.region_rule_options` correctly? This is an internal request header, not visible in browser devtools.
4. **Check controller concern** — Did `Shares::ThemeRenderingConcern` read the header? Did `Shares::ResourceLoadingConcern` apply the resource override?
5. **Check Themeable** — Did `set_theme_template_and_variables` pick the right template from the options hash? Template priority resolution has 5 levels.
6. **Check resource** — Does `ThemeRegionRule#resource_object` return the right product? If the product was deleted, it returns nil and the controller continues with nil — no error.
7. **Check cache** — Is a stale PageBuilder render cached? Cache key depends on `@theme_template.cache_key_with_version` which depends on `updated_at` — did `bust_theme_template_cache` run?

None of these steps can be tested in isolation. The middleware sets state that the controller reads. The controller sets instance variables that the concern reads. The concern's output depends on the template priority resolution. You have to reproduce the full request to diagnose.

#### Why the DAM System Is Easier to Debug

| Property                        | DAM System                                                                                              | Current System                                                                                                                |
| ------------------------------- | ------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Isolation**                   | Every layer callable independently in console                                                           | Layers coupled through middleware headers, instance variables, concern ordering                                               |
| **Proactive detection**         | Compiler catches broken references, missing variants, syntax errors before rendering                    | No validation — bugs discovered at render time or silently swallowed                                                          |
| **Cross-region coverage**       | Compile all regions in a loop, get a report                                                             | No way to check "do all regions have valid rules?" without querying the table and manually verifying each resource            |
| **Cache diagnosis**             | `render_uncached` method, touch-based keys are inspectable                                              | Cache key depends on template's `cache_key_with_version` — need to check `updated_at` on the right `ApplicationThemeTemplate` |
| **Nil safety**                  | Compiler flags dead references before rendering                                                         | `ThemeRegionRule#resource_object` returns nil for deleted products, controller continues with nil                             |
| **Variant fallback visibility** | `AssetResolver.resolve` returns the variant that was selected — inspect its tags to see if it fell back | No equivalent — you can't see which template resolution path was taken without adding logging                                 |
| **Reproducibility**             | Pass the same (company, path, tags_string) → get the same result. Pure function.                        | Result depends on request headers set by middleware, which depend on cookies/IP/user profile — hard to reproduce exactly      |

### Concern 10: Page Type Extensibility

**Current system:** `ApplicationThemeTemplate` uses a hardcoded `themeable_type` enum with 24 values (product, medium, enrollment_pack, shop_page, navbar, library, page, components, sections, locales, footer, layouts, category_page, collection_page, cart_page, config, home_page, mysite, join_page, collection, post, category, post_page, blocks). Adding a new page type requires a database migration.

**DAM equivalent:** Hierarchical ltree paths with no enum. New page types are just new paths:

```
themes.nova_theme.home_page/        # existing
themes.nova_theme.product_page/     # existing
themes.nova_theme.referral_page/    # new — no migration needed
themes.nova_theme.quiz_page/        # new — no migration needed
```

Adding a page type is creating a DAM path and uploading assets to it. No schema change, no deploy required.

### Concern 11: Localization

**Current system:** Mobility gem on `ApplicationThemeTemplate` translates the `content` column. `Image` has `image_url_i18n` JSONB column. Two different mechanisms for two different content types, both tightly coupled to ActiveRecord.

**DAM equivalent:** Tag-based locale variants. One mechanism for everything:

```
hero.liquid         (tagged: en)  → English template
hero.liquid         (tagged: fr)  → French template
hero.config.json    (tagged: en)  → English strings
hero.config.json    (tagged: fr)  → French strings
hero-bg.jpg         (tagged: en)  → English hero image
hero-bg.jpg         (tagged: fr)  → French hero image
```

Fallback chain handles missing locales automatically: `fr` → `en` → untagged.

### Summary: Migration Surface

| Current System Feature                        | DAM Equivalent                                                                             | Migration Effort                                           |
| --------------------------------------------- | ------------------------------------------------------------------------------------------ | ---------------------------------------------------------- |
| ThemeRegionRule (template/resource overrides) | Tagged `data.json` and `layout.liquid` variants                                            | Medium — admin UI writes DAM variants instead of DB rows   |
| ThemeRegionRule (redirects)                   | Small `ThemeRedirect` routing table                                                        | Low — extract redirect subset into simpler model           |
| ApplicationThemeGitConnection                 | Same model, change write target in `WebhookAction`                                         | Low — modify `apply_changed_files!` and `update_resource`  |
| Settings schema + data                        | Two-file split: `settings_schema.json` (untagged) + `settings_data.json` (tagged variants) | Medium — same pattern, DAM storage instead of DB templates |
| ApplicationThemeVersion (zip distribution)    | Same model for metadata, DAM for content                                                   | Medium — export walks DAM tree, import writes to DAM       |
| Publishing workflow                           | Versioned snapshots with pointer-based publishing                                          | Medium — version tag sets + single pointer update          |
| Themeable_type enum (24 page types)           | ltree paths (unlimited)                                                                    | Eliminated — no equivalent needed                          |
| Variables::Base merge chain                   | Declarative `data.json` + 6 DataLoaders                                                    | Already built (all 6 loaders complete)                     |
| Liquid Drops (lazy-loaded)                    | Pre-resolved data from DataLoaders                                                         | Already built — drops are replaced by explicit specs       |
| Mobility translations                         | Tag-based locale variants                                                                  | Simplified — one mechanism instead of two                  |

### Critical Path to Production

Only 3 items block production readiness:

1. **Fix 7 INFRA-1499 bugs** — targeted fixes (thread safety, cache correctness, N+1), not architectural changes
2. **Build ThemeRendering controller concern** — thin wrapper that auto-builds `page_context` and `tags_string` from controller helpers
3. **Client-side hydration endpoints** — API endpoints for cart/user data loaded via JS after cached HTML is served (required for Issue 7 fix)

Everything else (VersionManager, PreviewManager, import tools, visual builder, analytics) is valuable but not blocking.

## Known Shortcomings and Mitigations

Architectural shortcomings of the DAM-backed system, with concrete mitigations for each.

### 1. Tag Resolution Ambiguity

**Problem:** Tags are untyped strings. When a request has `tags_string: "fr;eu"` and variants exist tagged `[eu, en]`, `[en]`, and `[]` (untagged), the resolution order across multiple tag dimensions is not obvious. Theme authors can't predict which variant wins without understanding the `AssetResolver` algorithm internals.

**Mitigation:**

1. **Document the exact resolution algorithm** with precedence rules and worked examples. The algorithm should be: most specific tag match wins (count of matched tags), with ties broken by tag order in `tags_string`. Untagged is always the lowest-priority fallback.

2. **Compiler detects ambiguous resolutions.** When two variants match a `tags_string` with equal specificity, the Compiler flags it:

```ruby
# Compiler output:
{
  warnings: [
    "Ambiguous resolution: hero.liquid has variants [eu, en] and [fr, eu] — both match tags_string 'fr;eu;en' with 2 tag matches. Add a more specific variant or remove one."
  ]
}
```

3. **Typed tag dimensions** (future enhancement). Instead of flat strings, tag dimensions could be declared in theme config: `{ "dimensions": { "locale": ["en", "fr"], "region": ["us", "eu"], "version": ["v1", "v2"] } }`. The Compiler validates that variants only use declared dimensions and that each dimension resolves unambiguously.

### 2. Cold-Cache Query Volume

**Problem:** On cold cache, a page render triggers multiple database queries. However, the cost is **not** in template loading — `Dam::VirtualFileSystem` already bulk-loads all templates for a page in a single `resolve_with_defaults` call (1 ltree query + 1-2 variant queries, cached for 5 minutes). The actual query cost comes from two sources:

1. **`last_modified_for_path` runs on every request** — even cache hits pay a `MAX(updated_at)` query to compute the cache key
2. **`Themes::DataLoader.load()` is called independently per `{% render %}` tag** — each component's `data.json` spec triggers its own loader calls. `PlatformLoader` has zero caching (Issue 3), so a page with 10 components making platform queries fires 10+ uncached DB queries

**Actual query breakdown for a 10-section page:**

| Layer                              | Cold Cache        | Warm Cache                              | Notes                                                       |
| ---------------------------------- | ----------------- | --------------------------------------- | ----------------------------------------------------------- |
| VFS init (`resolve_with_defaults`) | 2-3 queries       | 1 query (`last_modified_for_path` only) | Bulk ltree + variant resolution, cached 5min                |
| `CompanySettingsLoader`            | 1 query           | 0                                       | Bulk-cached for 1hr, loads all 25 settings                  |
| `LocaleLoader`                     | 1 query           | 0                                       | Bulk-cached for 1hr                                         |
| `PageContextLoader`                | 0                 | 0                                       | Pure hash access, no DB                                     |
| `UrlLoader`                        | 0                 | 0                                       | Built from request, no DB                                   |
| `AssetsLoader` (per component)     | 0-10 queries      | 0                                       | Per-component `resolve` call, each cached 1hr independently |
| `PlatformLoader` (per component)   | 0-10+ queries     | 0-10+ queries                           | **Zero caching** — fires fresh queries every time (Issue 3) |
| **Total**                          | **~5-25 queries** | **~1-11 queries**                       | PlatformLoader dominates both cases                         |

The current system loads one `ApplicationThemeTemplate` per page — but it also fires lazy-loaded Liquid Drops during rendering, so the true query count is similarly variable (just hidden).

**Mitigation:**

1. **Fix PlatformLoader caching (Issue 3).** Touch-based caching for single-resource lookups, short-TTL for collections. This is the highest-impact fix — it eliminates the majority of per-request queries.

2. **DataLoader batching** (Future Work #3). Collect all `data.json` specs from a page's components before rendering, merge by source type, resolve once per source. This would reduce 10 separate `PlatformLoader` calls to 1 batched query. GraphQL dataloader pattern.

3. **Cache warming job.** After deploy or theme publish, a background job pre-renders the most common `(company, theme_path, tags_string)` combinations. The Compiler's metadata output provides the warm-up list — it knows which pages exist and which tag combinations are valid. This replaces the GCS pre-render pipeline without the combinatorial explosion because the job warms only what's actually used.

```ruby
# Proposed — warm caches for all pages x active locales after publishing
class Themes::CacheWarmingJob
  def perform(company_id, theme_path)
    company = Company.find(company_id)
    locales = company.active_locale_codes  # ["en", "fr", "de"]
    pages = Dam::AssetResolver.list_pages(company: company, theme_path: theme_path)

    pages.product(locales).each do |page, locale|
      Themes::Renderer.render(
        company: company,
        theme_path: "#{theme_path}.#{page}",
        tags_string: "#{locale};#{company.published_version_tag}",
        page_context: {},
        params: {}
      )
    end
  end
end
```

4. **Monitor cold-cache latency.** Add instrumentation to track cache hit/miss rates and cold-cache render times. Alert if P95 render time exceeds threshold.

### 3. Variant Disabling (Active/Inactive)

**Problem:** `ThemeRegionRule` has an `active` boolean for instant toggle. DAM variants don't have active/inactive — you'd have to untag and re-tag, which is destructive.

**Mitigation:** Archive and restore. "Disable EU override" = move the EU-tagged variant to an archived state (soft delete, or move to a `disabled` path/tag). "Re-enable" = restore it. The variant is preserved, just excluded from resolution.

```ruby
# Proposed pattern — add_tags/remove_tags exist on Dam::Variant,
# but AssetResolver does not yet filter out "archived" variants.

# Disable: archive the variant (excluded from resolution, but preserved)
eu_variant.add_tags(tags: ["archived"])
eu_variant.remove_tags(tags: ["eu"])
# AssetResolver would need to skip variants tagged "archived"

# Re-enable: restore
eu_variant.add_tags(tags: ["eu"])
eu_variant.remove_tags(tags: ["archived"])
```

The admin UI presents this as a toggle switch. The underlying operation is tag swap, but the variant is never deleted.

### 4. Continuous Validation (Compiler is Point-in-Time)

**Problem:** The Compiler validates at publish time. Between publishes, data changes: products get deactivated, resources are deleted. A product deactivated on Tuesday isn't caught until the next theme publish.

**Mitigation:** Background recompilation triggered by data changes.

**Trigger points:**

1. **`after_commit` on referenced resources** — When a Product, Collection, or EnrollmentPack is deactivated/deleted, enqueue recompilation for themes that reference it. The Compiler's metadata output tracks which resources each theme depends on, so the callback knows which themes to recompile.

```ruby
# Proposed — In Product model
after_commit :recompile_referencing_themes, if: -> { saved_change_to_active? || destroyed? }

def recompile_referencing_themes
  Themes::RecompilationJob.perform_async(
    resource_type: "Product",
    resource_slug: slug
  )
end
```

2. **`after_commit` on `Dam::Asset` and `Dam::Variant`** at `themes.*` paths — Recompile when theme files change outside the publish flow (e.g., git sync).

3. **Scheduled sweep** (daily) — Safety net for anything callbacks miss. Recompile all active themes and report errors.

**Error reporting:** Compilation failures between publishes should notify the theme admin (e.g., "Product 'eu-starter-kit' referenced by your EU home page was deactivated — EU users will see the default product instead"). This is proactive notification, not silent degradation.

### 5. Observability for Non-Developers

**Problem:** The console-based debugging workflow (VFS inspection, DataLoader calls, Compiler runs) requires Rails console access. Support teams can't diagnose theme issues without engineering help.

**Mitigation:** Admin diagnostic endpoint that wraps the console commands:

```
GET /admin/themes/diagnose?company_id=123&theme_path=themes.nova_theme.home_page&tags_string=eu;en
```

Returns:

```json
{
  "resolved_template": {
    "name": "layout.liquid",
    "tags": ["eu", "en"],
    "fell_back": false
  },
  "resolved_data_spec": {
    "name": "layout.data.json",
    "tags": ["eu"],
    "fell_back": false
  },
  "resolved_data": {
    "product": { "id": 456, "title": "EU Starter Kit", "active": true }
  },
  "resolved_config": {
    "name": "hero.config.json",
    "tags": ["eu", "en"],
    "fell_back": true,
    "fell_back_from": "fr"
  },
  "compilation": { "valid": true, "errors": [], "warnings": [] },
  "cache_status": {
    "cached": true,
    "cache_age_seconds": 142,
    "last_asset_update": "2026-03-09T15:30:00Z"
  }
}
```

Support team can see exactly what resolved, whether it fell back, and whether the cache is stale — without console access.

## Known Issues (INFRA-1499)

Seven correctness bugs that would surface under production traffic. Ordered by planned commit sequence.

**Status overview:**

- [ ] Issue 1: Thread-unsafe Liquid tag swap (High)
- [ ] Issue 2: VFS flattens hierarchical paths (Medium)
- [ ] Issue 3: PlatformLoader N+1 — no caching (High)
- [ ] Issue 4: AssetsLoader 1-hour dumb cache (Medium)
- [ ] Issue 5: CompanySettings/Locale cache no invalidation (Medium)
- [ ] Issue 6: LocaleLoader mutates cached arrays (Low)
- [ ] Issue 7: Page cache key broken for personalization (High)

### Issue 1: Thread-unsafe Liquid tag swap (Severity: High)

`Themes::Renderer.render_liquid` globally registers/unregisters `Themes::Liquid::Tags::Render` around each render call. `Liquid::Template.tags` is a class-level hash — this is a race condition under multi-threaded Puma.

**Fix:** Register `Themes::Liquid::Tags::Render` once globally in `config/initializers/liquid.rb`. The custom tag only activates when `context.registers[:file_system]` is set (guarded at line 20). Non-DAM renders don't set that register, so they fall through to parent behavior via `super`.

**Rollback note:** This changes behavior for all Liquid rendering. If non-DAM rendering breaks, revert the initializer change. Monitor Sentry for Liquid rendering errors for 24h after deploy.

**Files:** `config/initializers/liquid.rb`, `app/services/themes/renderer.rb`
**Specs:** `spec/services/themes/liquid/tags/render_spec.rb`, `spec/services/themes/renderer_spec.rb`

### Issue 2: VFS flattens hierarchical paths (Severity: Medium)

`VirtualFileSystem#extract_filename` strips directory prefixes — `{% render 'sections/hero' %}` resolves to just `hero.liquid`. Two assets named `hero.liquid` at different sub-paths collide.

**Fix:** Key assets by path-qualified name in `AssetResolver.resolve_with_defaults`. Convert Liquid's slash notation to dot notation for lookup. Fallback to bare name for backward compat.

**Files:** `app/services/dam/asset_resolver.rb`, `app/services/dam/virtual_file_system.rb`
**Specs:** `spec/services/dam/virtual_file_system_spec.rb`, `spec/services/dam/asset_resolver_spec.rb`

### Issue 3: PlatformLoader N+1 — no caching (Severity: High)

Zero caching. Every `{% render %}` with a `data.json` platform spec fires a fresh DB query. 20 components = 20+ queries per page.

**Fix:** Touch-based caching for single-resource lookups (key includes `pick(:updated_at)`). Short-TTL (5min) cache for collection queries — no touch-based invalidation since there's no single `updated_at` without scanning all rows.

**Tradeoff:** 20 extra `SELECT updated_at` queries per request even when cache is warm. These are single-column indexed lookups (fast), but worth monitoring. If this becomes a bottleneck, batch the lookups.

**Scope fix (included in this issue):** `scope` parameter is accepted by `resolve_resource_collection` but not included in the cache key. Two calls differing only by `scope` would share a cache entry — a correctness bug. The `scope` must be added to the collection cache key as part of this issue's fix.

**Files:** `app/services/themes/data/platform_loader.rb`
**Specs:** `spec/services/themes/data/platform_loader_spec.rb` (may need to be created)

### Issue 4: AssetsLoader 1-hour dumb cache with no invalidation (Severity: Medium)

Cache key contains `company_id`, `path`, `name`, `tags_string`, and `metadata` flag — but no timestamp. Asset updates are invisible for up to 1 hour.

**Fix:** Add `Dam::AssetResolver.last_modified_for_path` to the cache key. Reduce TTL from 1 hour to 5 minutes as safety net.

**Note:** `Dam::AssetResolver.last_modified_for_path` already exists (`asset_resolver.rb:367`) and is used by `resolve_with_defaults`. The fix integrates it into the AssetsLoader cache key.

**Files:** `app/services/themes/data/assets_loader.rb`
**Specs:** `spec/services/themes/data/assets_loader_spec.rb`

### Issue 5: CompanySettings/Locale caches have no invalidation (Severity: Medium)

Both loaders cache for 1 hour with keys that don't include timestamps. Company changes (logo, name) and locale changes (new language) are invisible for up to 1 hour.

**Fix:** Add touch-based cache keys — include `updated_at` in the key so it self-invalidates on change.

**Files:** `app/services/themes/data/company_settings_loader.rb`, `app/services/themes/data/locale_loader.rb`
**Specs:** `spec/services/themes/data/company_settings_loader_spec.rb`, `spec/services/themes/data/locale_loader_spec.rb`

### Issue 6: LocaleLoader mutates cached arrays (Severity: Low)

`LocaleLoader` mutates cached arrays in-place (the `selected` flag). Under memory-based cache stores this poisons the cache. Production uses Redis (serializes/deserializes so mutation doesn't persist), but the code is wrong-by-design.

**Fix:** `deep_dup` cached data before mutating.

**Files:** `app/services/themes/data/locale_loader.rb`
**Specs:** `spec/services/themes/data/locale_loader_spec.rb`

### Issue 7: Page cache key broken — personalization and invalidation (Severity: High)

Two problems with `Renderer.build_cache_key`:

**7a. Personalization:** `build_cache_key` hashes the presence of `page_context` keys, not their values. All users with a cart get the same cached page. The variant dimensions (affiliate, country, locale) already live in `tags_string` which is in the key. Session data (cart, user) should not be in the page cache — handle via client-side hydration.

**7b. No content invalidation:** `build_cache_key` does not include `last_modified_for_path` or any timestamp. The page-level cache has a 1-hour TTL (`CACHE_TTL = 1.hour`) as its sole invalidation mechanism. If a theme file or setting changes, users see the stale page for up to 1 hour. This violates Rule 1 (cache keys must be touch-based).

Note: the VFS layer _does_ use touch-based keys (via `AssetResolver.resolve_with_defaults`), but the Renderer's page cache wraps the entire render call — the VFS cache is never consulted when the page cache hits.

**Fix:**

- 7a: Remove `page_context` from `build_cache_key` entirely.
- 7b: Add `Dam::AssetResolver.last_modified_for_path(company:, path:)` to the page cache key. This makes the page cache self-invalidate when any theme asset changes.

**Prerequisite:** Client-side hydration endpoints (Future Work #5) must be deployed before 7a ships, or session-specific data (cart, user) will be unavailable on pages. Fix 7b has no prerequisites and can ship independently.

**Rollback note:** If hydration endpoints are not yet live when 7a deploys, revert the cache key change immediately. Monitor Sentry for missing cart/user data reports for 24h post-deploy.

**Files:** `app/services/themes/renderer.rb`
**Specs:** `spec/services/themes/renderer_spec.rb`

## Rules

1. **Cache keys must be touch-based** — include `updated_at` or equivalent timestamp so keys self-invalidate on change. Never use time-only TTL as the sole invalidation mechanism, **except for collection queries where no single cheap `updated_at` is available (see Rule 5)**.
2. **Never mutate cached data** — always `deep_dup` before modifying data retrieved from `Rails.cache.fetch`.
3. **Liquid tags must be registered globally** — never swap `Liquid::Template.tags` at render time. Register once in `config/initializers/liquid.rb`.
4. **VFS lookups must be path-qualified** — use dot-notation qualified keys (e.g., `sections.footer.liquid`) with bare-name fallback.
5. **Collection caches are time-based only** — for multi-row queries where no single `updated_at` is cheap, use short TTL (5min) and accept brief staleness.
6. **Session data is never in page cache keys** — cart, user, and other per-session data must be loaded client-side after cached HTML is served.

## Examples

### Touch-based cache key pattern

```ruby
def fetch_settings(company)
  updated_at = company.class.where(id: company.id).pick(:updated_at)&.to_i || 0
  cache_key = "themes:data:settings:#{company.id}:#{updated_at}"

  Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
    build_settings(company)
  end
end
```

### Safe mutation of cached data

```ruby
static_data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
  { "languages" => build_languages(company) }
end

# Deep-dup before mutating to prevent cache poisoning
static_data = static_data.deep_dup
static_data["languages"].each { |lang| lang["selected"] = (lang["code"] == current_locale) }
```

### Path-qualified VFS lookup

```ruby
# Liquid: {% render 'sections/footer' %}
# Tries "sections.footer.liquid" first, falls back to "footer.liquid"
def read_asset_file(template_path:, extension:)
  qualified_key = "#{template_path.tr('/', '.')}#{extension}"
  asset = find_asset_by_name(filename: qualified_key)

  if asset.nil? && template_path.include?("/")
    bare_key = "#{template_path.split('/').last}#{extension}"
    asset = find_asset_by_name(filename: bare_key)
  end

  asset ? extract_content(asset:) : ""
end
```

## Verification

```bash
# After fixing cache issues (Issues 3-6)
bundle exec rspec spec/services/themes/data/

# After fixing VFS path flattening (Issue 2)
bundle exec rspec spec/services/dam/virtual_file_system_spec.rb spec/services/dam/asset_resolver_spec.rb

# After fixing thread safety + cache key (Issues 1, 7)
bundle exec rspec spec/services/themes/liquid/tags/render_spec.rb spec/services/themes/renderer_spec.rb

# Full suite
bundle exec rspec spec/services/themes/ spec/services/dam/
```

## Future Work

Items not in scope for INFRA-1499 but needed to make the system production-ready:

1. **Check `require_dependency` compatibility** — `config/initializers/liquid.rb` uses `require_dependency` inside `to_prepare`, which is deprecated in Rails 7+ Zeitwerk mode (no-op but harmless). The Issue 1 initializer fix should use `require` instead (`autoload` is not valid for third-party gems).
2. **CacheManager service** — Centralized cache invalidation with model `after_save` callbacks. Eliminates the need for touch-based keys by proactively expiring caches on write.
3. **DataLoader batching** — `VirtualFileSystem` already bulk-loads all template files (liquid, config, data) in a single `resolve_with_defaults` call. The unbatched layer is `Themes::DataLoader` — each `{% render %}` tag independently calls `DataLoader.load()` for its component's `data.json` spec. The fix: collect all `data.json` specs from a page's components before rendering, merge by source type, resolve once per source (GraphQL dataloader pattern). This eliminates per-component PlatformLoader/AssetsLoader queries.
4. **Cache warming job** — Lightweight job to pre-hit common pages after deploy. Replaces the GCS pre-render pipeline without the combinatorial explosion.
5. **Client-side hydration endpoints** — API endpoints for cart/user data loaded via JS after cached HTML is served. Required for Issue 7's fix to be complete — without these, session-specific data has no way to reach the page.
6. **Monitor `pick(:updated_at)` query cost** — After PlatformLoader caching lands, monitor whether 20+ extra `SELECT updated_at` queries per request cause latency. If so, batch the lookups or short-TTL cache the timestamps.
7. **Collection cache invalidation** — PlatformLoader collections use time-based expiry only (5min). Admin users who publish a product won't see it for up to 5 minutes. Consider adding a write-through pattern or pub/sub invalidation for better admin UX.
8. **`resolve_collection` cost for AssetsLoader** — `last_modified_for_path` on collections does a `MAX(updated_at)` across all assets at a path. Could be expensive for large asset trees. Monitor and optimize if needed.

## Enforcement

- All changes to DAM theme caching must use touch-based keys (or document why time-based is acceptable)
- All changes to `Themes::Renderer` must not introduce per-render global state mutations
- All new data loaders must follow the patterns in this document
- Changes to `VirtualFileSystem` lookup must preserve path-qualified-first, bare-name-fallback ordering
