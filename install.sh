#!/usr/bin/env bash
# install.sh — set up aidev for the current user:
#   1. Symlink aidev into ~/.local/bin
#   2. Warn if ~/.local/bin is not on PATH
#   3. Offer to install fzf (improves the app picker)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AIDEV_SRC="$SCRIPT_DIR/aidev"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/aidev"

die() { printf 'install: %s\n' "$*" >&2; exit 1; }

ask() {
    # ask "<prompt>" "<default Y|N>" → returns 0 for yes, 1 for no.
    local prompt="$1" default="$2" ans
    local hint
    case "$default" in
        Y) hint="[Y/n]" ;;
        N) hint="[y/N]" ;;
        *) die "ask(): default must be Y or N." ;;
    esac
    read -r -p "$prompt $hint " ans || ans=""
    : "${ans:=$default}"
    case "$ans" in
        [Yy]*) return 0 ;;
        *)     return 1 ;;
    esac
}

# --- 1. Sanity ----------------------------------------------------------------

[ -f "$AIDEV_SRC" ] || die "aidev script not found at $AIDEV_SRC"
[ -x "$AIDEV_SRC" ] || chmod +x "$AIDEV_SRC"

# --- 2. Symlink ---------------------------------------------------------------

mkdir -p "$INSTALL_DIR"

if [ -L "$INSTALL_PATH" ]; then
    existing="$(readlink "$INSTALL_PATH")"
    if [ "$existing" = "$AIDEV_SRC" ]; then
        echo "Symlink already in place: $INSTALL_PATH -> $AIDEV_SRC"
    else
        echo "$INSTALL_PATH currently points to: $existing"
        if ask "Replace with link to $AIDEV_SRC?" N; then
            ln -sfn "$AIDEV_SRC" "$INSTALL_PATH"
            echo "Updated symlink."
        else
            die "Aborted."
        fi
    fi
elif [ -e "$INSTALL_PATH" ]; then
    echo "$INSTALL_PATH exists and is not a symlink."
    if ask "Remove it and create a symlink to $AIDEV_SRC?" N; then
        rm -f "$INSTALL_PATH"
        ln -s "$AIDEV_SRC" "$INSTALL_PATH"
        echo "Replaced with symlink."
    else
        die "Aborted."
    fi
else
    ln -s "$AIDEV_SRC" "$INSTALL_PATH"
    echo "Symlinked: $INSTALL_PATH -> $AIDEV_SRC"
fi

# --- 3. PATH check ------------------------------------------------------------

case ":$PATH:" in
    *:"$INSTALL_DIR":*)
        ;;
    *)
        echo
        echo "Note: $INSTALL_DIR is not on your current PATH."
        echo "On Ubuntu, ~/.profile adds it automatically once the directory exists —"
        echo "open a new shell, or run: source ~/.profile"
        echo "If your ~/.bashrc overrides PATH, add this line to it:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac

# --- 4. fzf -------------------------------------------------------------------

echo
if command -v fzf >/dev/null 2>&1; then
    echo "fzf detected ($(fzf --version 2>/dev/null | awk '{print $1}')) — the aidev"
    echo "app picker will use arrow keys + fuzzy search."
else
    echo "fzf is not installed."
    echo "Installing it enables arrow-key navigation and fuzzy search in the"
    echo "aidev app picker. It is MIT-licensed."
    if ask "Install fzf now via 'sudo apt install fzf'?" Y; then
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y fzf
        else
            echo "apt not found — install fzf via your package manager when convenient."
        fi
    else
        echo "Skipped. aidev will fall back to a numbered picker."
    fi
fi

# --- 5. Done ------------------------------------------------------------------

echo
echo "Done. Try: aidev -h"
