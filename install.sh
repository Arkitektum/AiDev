#!/usr/bin/env bash
# install.sh — set up aidev for the current user:
#   1. Check that a bash new enough to run aidev is available
#   2. Symlink aidev into ~/.local/bin
#   3. Put ~/.local/bin on PATH, if it is not already
#   4. Offer to install fzf (improves the app picker)
#
# Runs on Linux, WSL2 and macOS. This script itself stays bash 3.2-clean, so
# that it can report on an old bash rather than fail on one.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AIDEV_SRC="$SCRIPT_DIR/aidev"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/aidev"
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
OS="$(uname -s)"

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

modern_bash() {
    # Echo the path of the first bash 4+ among the arguments, if any. Each
    # candidate is asked for its own version, since the one on PATH need not
    # be the one this script is running under.
    local b
    for b in "$@"; do
        [ -n "$b" ] && [ -x "$b" ] || continue
        if "$b" -c '[ "${BASH_VERSINFO[0]}" -ge 4 ]' 2>/dev/null; then
            printf '%s\n' "$b"
            return 0
        fi
    done
    return 1
}

shell_rc_file() {
    # The startup file to add PATH to, for the user's login shell. Echoes
    # nothing when the shell is one we do not know well enough to edit.
    case "${SHELL##*/}" in
        zsh)
            # Read by every interactive zsh, login or not.
            printf '%s\n' "$HOME/.zshrc"
            ;;
        bash)
            # Terminal.app starts login shells, which read .bash_profile and
            # never .bashrc; elsewhere .bashrc is the one that always runs.
            if [ "$OS" = Darwin ]; then
                printf '%s\n' "$HOME/.bash_profile"
            else
                printf '%s\n' "$HOME/.bashrc"
            fi
            ;;
    esac
}

# --- 1. Sanity ----------------------------------------------------------------

[ -f "$AIDEV_SRC" ] || die "aidev script not found at $AIDEV_SRC"
[ -x "$AIDEV_SRC" ] || chmod +x "$AIDEV_SRC"

# --- 2. bash version ----------------------------------------------------------

# aidev needs bash 4 (associative arrays, ${x,,}). macOS ships 3.2 as
# /bin/bash and will not move off it, so a Mac without Homebrew's bash has
# nothing that can run aidev. aidev hands over to a newer bash by itself if
# one exists, which is why finding it anywhere is enough.
if ! modern_bash "$(command -v bash || true)" \
                 /opt/homebrew/bin/bash /usr/local/bin/bash >/dev/null; then
    echo "No bash 4 or newer found — aidev needs one."
    if [ "$OS" = Darwin ]; then
        echo "macOS ships bash 3.2 as /bin/bash; Homebrew installs a current"
        echo "bash beside it without replacing it."
        if command -v brew >/dev/null 2>&1; then
            if ask "Install it now via 'brew install bash'?" Y; then
                brew install bash
            else
                echo "Skipped — aidev will not run until bash 4+ is installed."
            fi
        else
            echo "Homebrew is not installed. Get it from https://brew.sh, then run:"
            echo "  brew install bash"
        fi
    else
        echo "Install bash 4+ via your package manager, then re-run this script."
    fi
    echo
fi

# --- 3. Symlink ---------------------------------------------------------------

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

# --- 4. PATH ------------------------------------------------------------------

case ":$PATH:" in
    *:"$INSTALL_DIR":*)
        ;;
    *)
        echo
        echo "Note: $INSTALL_DIR is not on your current PATH."
        if [ "$OS" != Darwin ]; then
            echo "On Ubuntu, ~/.profile adds it once the directory exists, so a"
            echo "new login shell may already have it."
        fi

        rc="$(shell_rc_file)"
        if [ -z "$rc" ]; then
            echo "Add this line to your shell's startup file:"
            echo "  $PATH_LINE"
        elif [ -f "$rc" ] && grep -qF '.local/bin' "$rc"; then
            # Something in there covers it already — possibly written in a
            # different form, or by an earlier run. Appending would only
            # duplicate it, so say so and let the user look.
            echo "$rc already mentions $INSTALL_DIR."
            echo "Open a new shell, or run: source $rc"
        else
            echo "This line, in $rc, fixes it for every new shell:"
            echo "  $PATH_LINE"
            if ask "Add it to $rc?" Y; then
                printf '\n# Added by aidev install.sh\n%s\n' "$PATH_LINE" >> "$rc"
                echo "Added. Open a new shell, or run: source $rc"
            else
                echo "Skipped — add it yourself when convenient."
            fi
        fi
        ;;
esac

# --- 5. fzf -------------------------------------------------------------------

echo
if command -v fzf >/dev/null 2>&1; then
    echo "fzf detected ($(fzf --version 2>/dev/null | awk '{print $1}')) — the aidev"
    echo "app picker will use arrow keys + fuzzy search."
else
    echo "fzf is not installed."
    echo "Installing it enables arrow-key navigation and fuzzy search in the"
    echo "aidev app picker. It is MIT-licensed."
    if [ "$OS" = Darwin ]; then
        if command -v brew >/dev/null 2>&1; then
            if ask "Install fzf now via 'brew install fzf'?" Y; then
                brew install fzf
            else
                echo "Skipped. aidev will fall back to a numbered picker."
            fi
        else
            echo "Homebrew is not installed — get it from https://brew.sh, then:"
            echo "  brew install fzf"
        fi
    elif command -v apt >/dev/null 2>&1; then
        if ask "Install fzf now via 'sudo apt install fzf'?" Y; then
            sudo apt update && sudo apt install -y fzf
        else
            echo "Skipped. aidev will fall back to a numbered picker."
        fi
    else
        echo "apt not found — install fzf via your package manager when convenient."
    fi
fi

# --- 6. Done ------------------------------------------------------------------

echo
echo "Done. Try: aidev -h"
