# Fish Shell Configuration

Shell: `/opt/homebrew/bin/fish`

## ~/.config/fish/config.fish

```fish
if status is-interactive
    # Commands to run in interactive sessions can go here
end

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/tad/google-cloud-sdk/path.fish.inc' ]; . '/Users/tad/google-cloud-sdk/path.fish.inc'; end
fish_add_path -g ~/.local/bin

# Added by Antigravity
fish_add_path /Users/tad/.antigravity/antigravity/bin
```

## conf.d/initialize.fish

```fish
eval (/opt/homebrew/bin/brew shellenv)

# Initialize zoxide (smart cd)
zoxide init fish | source
```

## conf.d/paths.fish

```fish
fish_add_path /opt/homebrew/bin
fish_add_path /Applications/Postgres.app/Contents/Versions/latest/bin
fish_add_path /opt/homebrew/share/fish/completions
fish_add_path /opt/homebrew/share/fish/vendor_completions.d
fish_add_path ~/.bun/bin
```

## conf.d/aliases.fish

```fish
# Modern CLI tools
alias ls="eza"
alias ll="eza -la"
alias la="eza -a"
alias lt="eza --tree"
alias cat="bat"

alias ..="cd .."
alias rmi="rm -i"
alias rmf="rm -rf"

alias prodproxy="/Users/tad/cloud-sql/proxy --port 5433 fluid-417204:europe-west1:fluid-web-eu"
alias claude="mise exec node@23 -- claude"
alias dangerous-claude="claude --dangerously-skip-permissions"

# Rails abbreviations (expand in-place for better history)
abbr -a br 'bin/rails'
abbr -a be 'bundle exec'
abbr -a bd './bin/dev'
abbr -a ovs 'overmind start'
abbr -a ovc 'overmind connect console'
abbr -a migrate 'bin/rails db:migrate'
abbr -a testmigrate 'RAILS_ENV=test bin/rails db:migrate'
abbr -a swaggerize "bundle exec rake rswag:specs:swaggerize PATTERN='{spec/{requests,api,integration}/**/*_spec.rb,../commerce/spec/**/*_spec.rb}'"
```

## conf.d/variables.fish

```fish
set -gx GREETING "Hello World!"
set -gx EDITOR "cursor -w"
set -gx OVERMIND_PROCFILE Procfile.tad
set -gx FONTAWESOME_AUTH_TOKEN 25E9FF39-F843-476F-992D-485E30E2AC8F
```

## conf.d/prompt.fish

```fish
starship init fish | source
```

## conf.d/fish_frozen_theme.fish

```fish
set --global fish_color_autosuggestion brblack
set --global fish_color_cancel -r
set --global fish_color_command blue
set --global fish_color_comment red
set --global fish_color_cwd green
set --global fish_color_cwd_root red
set --global fish_color_end green
set --global fish_color_error brred
set --global fish_color_escape brcyan
set --global fish_color_history_current --bold
set --global fish_color_host normal
set --global fish_color_host_remote yellow
set --global fish_color_normal normal
set --global fish_color_operator brcyan
set --global fish_color_param cyan
set --global fish_color_quote yellow
set --global fish_color_redirection cyan --bold
set --global fish_color_search_match white --background=brblack
set --global fish_color_selection white --bold --background=brblack
set --global fish_color_status red
set --global fish_color_user brgreen
set --global fish_color_valid_path --underline
set --global fish_pager_color_completion normal
set --global fish_pager_color_description yellow -i
set --global fish_pager_color_prefix normal --bold --underline
set --global fish_pager_color_progress brwhite --background=cyan
set --global fish_pager_color_selected_background -r
```

## conf.d/fish_frozen_key_bindings.fish

```fish
# Migration file from fish 4.3 upgrade
set --erase --universal fish_key_bindings
```

## functions/fish_greeting.fish

```fish
function fish_greeting
  set -l joke (curl -sS -H "Accept: text/plain" https://icanhazdadjoke.com/ 2>/dev/null)

  if test $status -eq 0 -a -n "$joke"
    set_color yellow
    echo $joke
    set_color normal
  else
    echo "That's no joke"
  end
end
```

## functions/uprails.fish

```fish
function uprails -d "Update all rails-related stuff"
  bundle install
  bin/migrate
  yarn install
  yarn build:sass
  yarn build:tailwind
  RAILS_ENV=test bin/rails db:migrate
  git rfm db/schema.rb
end
```

## Completions

Custom completions exist for:
- `bun.fish` (Bun package manager - large file, auto-generated)
- `git.fish`
- `just.fish`

The bun completion file is preserved in `scripts/bun-completions.fish`.
