setopt NO_BEEP                # Sounds are annoying.
setopt IGNORE_EOF             # Don't exit on Ctrl-D.
setopt INTERACTIVE_COMMENTS   # Allow comments even in interactive shells.
setopt NO_CORRECT             # Don't try to correct the spelling of commands.

setopt NO_CASE_GLOB           # Case-insensitive globbing.
setopt NUMERIC_GLOB_SORT      # Try to sort numerically when globbing.

setopt COMPLETE_ALIASES       # Enable alias completion.
setopt ALWAYS_TO_END          # Move to the end of the word after completion.
setopt AUTO_LIST              # Automatically list choices for ambiguous completions.
setopt LIST_AMBIGUOUS         # Insert as manny characters as possible for ambiguous completions.
setopt NO_MENU_COMPLETE       # Don't pick the first completion option automatically.

setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks from commands in history.
setopt HIST_IGNORE_ALL_DUPS   # Only keep the latter of duplicate commands in history.
setopt APPEND_HISTORY         # Append to the history file, rather than overwrite it.

HISTFILE=~/.zshhistory
HISTSIZE=1200
SAVEHIST=1000

# Use a very simple prompt.
precmd() {
  if [ -n "$SSH_CLIENT" ]; then
    PROMPT=`echo "\033[33m%n@%m\033[0m %# "`
  else
    PROMPT="%# "
  fi
}

# Enable emacs-style bindings.
bindkey -e

# Use sensible word characters.
export WORDCHARS='*?[]~=/&;!$%^(){}'

# Make completion of lowercase strings case-insensitive.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Pasted tabs shouldn't trigger completion.
zstyle ':completion:*' insert-tab pending

# Use arrow-driven completion menus.
zstyle ':completion:*' menu select

# Initialize autocomplete.
autoload -U compinit
compinit
