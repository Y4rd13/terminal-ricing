# ---- Startup notices (must stay above the instant prompt block) ----
# Powerlevel10k buffers the console while zsh initializes: anything printed below the
# preamble raises "Console output during zsh initialization detected" on every shell.

# seneca: one line when Claude Code sessions were left open. No-op without `seneca`.
{ command -v seneca >/dev/null 2>&1 && seneca banner; } || true

# ---- Powerlevel10k instant prompt (must be near the top) ----
# Any initialization that may require console input, or print anything, goes above this.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---- Load Powerlevel10k theme (defines `p10k`) ----
source "$HOME/powerlevel10k/powerlevel10k.zsh-theme"

# ---- Load your p10k config ----
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# ————————————————————————————————
# EDITOR
# ————————————————————————————————
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
elif command -v micro >/dev/null 2>&1; then
  export EDITOR="micro"
  export VISUAL="micro"
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
  export VISUAL="vim"
else
  export EDITOR="nano"
  export VISUAL="nano"
fi

# ————————————————————————————————
# HISTORY
# ————————————————————————————————
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY_TIME HIST_IGNORE_SPACE SHARE_HISTORY APPEND_HISTORY

# ————————————————————————————————
# TAB COMPLETION
# ————————————————————————————————
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
setopt AUTO_CD GLOB_COMPLETE

# ————————————————————————————————
# fzf (keybindings + completion)
# ————————————————————————————————
if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi
if [[ -f /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

# ————————————————————————————————
# ZSH PLUGINS
# ————————————————————————————————

# zsh-autosuggestions (gray suggestions as you type)
if [[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  # Accept suggestion with Ctrl+F
  bindkey '^F' autosuggest-accept
fi

# zoxide (smart cd)
if [[ -o interactive ]] && command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias cd="z"
  alias cdi="zi"
fi

# ————————————————————————————————
# File listing (eza with colors + icons)
# ————————————————————————————————
if command -v eza >/dev/null 2>&1; then
  export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"

  if [[ -f "$EZA_CONFIG_DIR/theme.yml" ]]; then
    unset EZA_COLORS 2>/dev/null
  else
    export EZA_COLORS="di=34:fi=0:ex=32:ln=36:pi=33:so=35:bd=33;1:cd=33;1:su=31;1:sg=31;1:ur=31;1:uw=31;1:ux=31;1:gr=90:da=90:tm=90"
  fi

  alias ls='eza --group-directories-first --icons=auto --color=auto'
  alias la='eza -a  --group-directories-first --icons=auto --color=auto --git'
  alias ll='eza -lah --group-directories-first --icons=auto --color=auto --git --header --time-style=long-iso --color-scale=age,size'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah --color=auto'
  alias la='ls -A --color=auto'
fi

# ————————————————————————————————
# Terminal title (shows branch + worktree)
# ————————————————————————————————
precmd() {
  # OSC 7: tells WezTerm which directory this pane is in. Without it a new split does
  # not inherit the directory and saved layouts cannot be restored.
  print -Pn "\e]7;file://%m%d\a"

  local git_dir=$(command git rev-parse --git-dir 2>/dev/null)
  local common_dir=$(command git rev-parse --git-common-dir 2>/dev/null)
  local branch=$(command git branch --show-current 2>/dev/null)

  if [[ -n "$git_dir" && -n "$common_dir" && "$git_dir" != "$common_dir" ]]; then
    local wt=$(basename "$(pwd)")
    print -Pn "\e]0;🌳$wt [$branch]\a"
  elif [[ -n "$branch" ]]; then
    local wt=$(basename "$(pwd)")
    print -Pn "\e]0;$wt [$branch]\a"
  else
    print -Pn "\e]0;$(basename "$(pwd)")\a"
  fi
}

# ————————————————————————————————
# zsh-syntax-highlighting (MUST be at the end)
# ————————————————————————————————
if [[ -f "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ————————————————————————————————
# bun
# ————————————————————————————————
export BUN_INSTALL="$HOME/.local/share/reflex/bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# ————————————————————————————————
# Browser for terminal tools (gh, xdg-open)
# ————————————————————————————————
# Picks between Brave on Windows and Linux Chromium; BROWSER_PICK=brave|linux skips the
# prompt. The script ships in this repo at .local/bin/browser-pick.
export BROWSER="$HOME/.local/bin/browser-pick"

# ————————————————————————————————
# Local secrets (source your own secrets file here)
# ————————————————————————————————
# Prefer ~/.zshenv over this file for exports: .zshrc only runs for interactive shells,
# so anything launched without one (cron, systemd, a hook, `zsh -c`) loses them silently.
# [[ -f "$HOME/.config/mcp/secrets.env" ]] && source "$HOME/.config/mcp/secrets.env"
