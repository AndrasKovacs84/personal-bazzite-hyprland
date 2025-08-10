#!/usr/bin/env bash
set -euo pipefail

# --- config you can override per machine/user ---
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/AndrasKovacs84/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
STAMP="$HOME/.cache/post_install_done"

# cheap guard: run once per deployment
CUR_DEPLOY="$(rpm-ostree status --json 2>/dev/null | jq -r '.deployments[0].checksum' || echo unknown)"
STAMP_DEPLOY="$(cat "$STAMP" 2>/dev/null || echo)"

# tools that live outside ostree layers (optional)
command -v brew >/dev/null && { brew update || true; brew upgrade || true; }

# dotfiles: clone if missing, else fetch
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone --depth=1 "$DOTFILES_REPO" "$DOTFILES_DIR" || true
else
  git -C "$DOTFILES_DIR" fetch --prune --quiet || true
fi

# only on new deployment, do “heavier” user tasks
if [ "$CUR_DEPLOY" != "$STAMP_DEPLOY" ]; then
  # Example: Doom Emacs bootstrap or upgrade (only if you want it automatic)
  if command -v emacs >/dev/null; then
    if [ ! -d "$HOME/.emacs.d" ]; then
      git clone --depth=1 https://github.com/doomemacs/doomemacs "$HOME/.emacs.d" || true
      "$HOME/.emacs.d/bin/doom" install || true
    else
      "$HOME/.emacs.d/bin/doom" upgrade || true
    fi
  fi

  mkdir -p "$(dirname "$STAMP")"
  echo "$CUR_DEPLOY" > "$STAMP"
fi
