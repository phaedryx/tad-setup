# Editor Extensions

## VS Code Extensions

```
anthropic.claude-code
huizhou.githd
kaiwood.endwise
kamikillerto.vscode-colorize
llvm-vs-code-extensions.lldb-dap
mateuszdrewniak.ruby-test-runner
mechatroner.rainbow-csv
mickey.code-copy-ruby-ref
misogi.ruby-rubocop
ms-azuretools.vscode-containers
ms-vscode-remote.remote-containers
ms-vsliveshare.vsliveshare
pkief.material-icon-theme
shardulm94.trailing-spaces
shopify.ruby-extensions-pack
shopify.ruby-lsp
sianglim.slim
skyapps.fish-vscode
sorbet.sorbet-vscode-extension
swiftlang.swift-vscode
usernamehw.errorlens
vadimcn.vscode-lldb
whizkydee.material-palenight-theme
```

## Cursor Extensions

```
anthropic.claude-code
anysphere.remote-containers
asciidoctor.asciidoctor-vscode
dbaeumer.vscode-eslint
github.vscode-github-actions
kaiwood.endwise
kamikillerto.vscode-colorize
mechatroner.rainbow-csv
mickey.code-copy-ruby-ref
ms-azuretools.vscode-docker
pkief.material-icon-theme
rubocop.vscode-rubocop
shardulm94.trailing-spaces
shd101wyy.markdown-preview-enhanced
shopify.ruby-extensions-pack
shopify.ruby-lsp
sianglim.slim
skyapps.fish-vscode
sorbet.sorbet-vscode-extension
tonybaloney.vscode-pets
usernamehw.errorlens
waderyan.gitblame
whizkydee.material-palenight-theme
```

## Common Between Both

Both editors share these core extensions:
- **Claude Code** (`anthropic.claude-code`)
- **Ruby LSP** (`shopify.ruby-lsp`) + Extensions Pack
- **Sorbet** (`sorbet.sorbet-vscode-extension`)
- **Rubocop** (different publishers)
- **Material Palenight Theme** (`whizkydee.material-palenight-theme`)
- **Material Icon Theme** (`pkief.material-icon-theme`)
- **Error Lens** (`usernamehw.errorlens`)
- **Trailing Spaces** (`shardulm94.trailing-spaces`)
- **Rainbow CSV** (`mechatroner.rainbow-csv`)
- **Endwise** (`kaiwood.endwise`) - auto-adds `end` in Ruby
- **Slim** (`sianglim.slim`) - Slim template support
- **Fish** (`skyapps.fish-vscode`) - Fish shell syntax
- **Colorize** (`kamikillerto.vscode-colorize`) - Color preview
- **Copy Ruby Ref** (`mickey.code-copy-ruby-ref`)

## Install Commands

```bash
# VS Code
cat vscode-extensions.txt | xargs -L 1 code --install-extension

# Cursor
cat cursor-extensions.txt | xargs -L 1 cursor --install-extension
```
