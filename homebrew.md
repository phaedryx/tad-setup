# Homebrew Packages

## Formulas

Key development tools (highlighted):

### CLI Productivity
- **bat** - Better `cat` with syntax highlighting
- **difftastic** - Structural diffs
- **eza** - Better `ls` with git integration
- **fd** - Better `find`
- **fzf** - Fuzzy finder
- **gum** - Interactive terminal prompts
- **httpie** - Better `curl`
- **jq** - JSON processor
- **just** - Task runner (like make)
- **ripgrep** - Better `grep`
- **starship** - Cross-shell prompt
- **tokei** - Code statistics
- **yq** - YAML/TOML processor
- **zoxide** - Smart `cd`

### Git & GitHub
- **git** - Version control
- **git-delta** - Better git diffs
- **gh** - GitHub CLI

### Languages & Runtimes
- **crystal** - Crystal language
- **llvm** - LLVM toolchain
- **mise** - Runtime version manager (Ruby, Node, etc.)
- **node** - Node.js
- **pnpm** - Node package manager
- **ruby-build** - Ruby builder (used by mise)
- **yarn** - Node package manager

### AI/ML
- **mlx** - Apple ML framework
- **mlx-c** - MLX C bindings
- **ollama** - Local LLM runner
- **gemini-cli** - Google Gemini CLI

### Infrastructure
- **gcloud** (via Google Cloud SDK)
- **heroku** - Heroku CLI
- **ngrok** (cask)
- **overmind** - Process manager (Procfile runner)
- **redis** - In-memory data store
- **tmux** - Terminal multiplexer

### Database
- **freetds** - SQL Server/Sybase driver
- **unixodbc** - ODBC driver manager
- Postgres.app (separate install, not Homebrew)

### iOS/Swift Development
- **swiftformat** - Swift formatter
- **swiftlint** - Swift linter
- **xcbeautify** - Xcode build output formatter

### Misc
- **graphviz** - Graph visualization
- **pandoc** - Document converter
- **terminal-notifier** - macOS notifications from CLI
- **wdiff** - Word-level diff

### Full Formula List

```
ada-url aom autoconf bat bdw-gc brotli c-ares ca-certificates cairo certifi
crystal dav1d difftastic eza fd fish fmt fontconfig freetds freetype fribidi
fzf gd gdk-pixbuf gemini-cli gettext gh giflib git git-delta glib gmp gnupg
gnutls graphite2 graphviz gts gum harfbuzz hdrhistogram_c heroku highway
httpie icu4c@77 icu4c@78 imath jasper jpeg-turbo jpeg-xl jq just libassuan
libavif libdatrie libdeflate libevent libffi libgcrypt libgit2 libgpg-error
libiconv libidn2 libksba libnghttp2 libnghttp3 libngtcp2 libpng librsvg
libssh2 libtasn1 libthai libtiff libtool libunistring libusb libuv libvmaf
libx11 libxau libxcb libxdmcp libxext libxrender libyaml little-cms2
llhttp llvm lz4 lzo m4 mise mlx mlx-c mpdecimal ncurses netpbm nettle
node npth ollama oniguruma openexr openjph openssl@3 overmind p11-kit
pandoc pango pcre2 pinentry pixman pkgconf pnpm python-packaging
python@3.13 python@3.14 readline redis ripgrep ruby-build simdjson sqlite
starship swiftformat swiftlint terminal-notifier tmux tokei unbound
unixodbc usage utf8proc uvwasi wdiff webp xcbeautify xorgproto xz yarn yq
z3 zoxide zstd
```

## Casks

```
font-jetbrains-mono-nerd-font
ngrok
```

## Applications (Not from Homebrew)

- **Postgres.app** - PostgreSQL (paths configured in fish)
- **Cursor** - AI code editor (primary editor)
- **VS Code** - Secondary editor
- **Google Cloud SDK** - `gcloud` CLI
