# Mise (Runtime Version Manager)

## Global Config: ~/.config/mise/config.toml

```toml
[settings]
idiomatic_version_file_enable_tools = ["ruby"]

[tools]
ruby = "4.0.0"
```

## Workspace Config: /Volumes/sourcecode/mise.toml

```toml
[tools]
node = "24.14.0"
ruby = "3.4.8"
```

## ~/.tool-versions (legacy asdf format)

```
rust 1.82.0
ruby 3.4.2
```

## Installed Versions

### Node.js
- 18.12.0, 18.18.0
- 20.18.0, 20.19.4
- 22.4.1, 22.11.0
- 23.8.0, 23.10.0
- **24.13.0, 24.14.0** (active for workspace)

### Ruby
- 3.2.2
- 3.3.0, 3.3.10
- 3.4.1, 3.4.2, 3.4.7, **3.4.8** (active for workspace)
- 4.0.0, 4.0.1

### Yarn
- 1.22.10
- 4.3.0, 4.7.0
- 9.12.3

### Rust
- 1.82.0 (from .tool-versions)

## Notes

- `mise` replaced `asdf` as the version manager
- Ruby version varies by project (3.4.x for most Fluid repos, 4.0.x for newer work)
- Claude Code requires Node.js and is run via `mise exec node@23 -- claude`
