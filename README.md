# AiDev

Quick-start wrapper for a Claude-in-Docker development loop on WSL2 or
native Linux: ensures Docker is running, then runs `claude-docker` inside
the project directory registered for the named app.

On native Linux, the active Docker context (`docker context show`)
decides which daemon to start — `desktop-linux` starts Docker Desktop's
user service, anything else starts the `docker` system service via
`sudo systemctl`.

## Install

```bash
./install.sh
```

This symlinks `aidev` into `~/.local/bin`, hints if that directory isn't
on your PATH, and offers to install [`fzf`](https://github.com/junegunn/fzf)
(optional — enables arrow keys and fuzzy search in the app picker;
without it, a numbered fallback picker is used).

Manual alternative:

```bash
mkdir -p ~/.local/bin
ln -s "$PWD/aidev" ~/.local/bin/aidev
```

## Usage

```
aidev [-r]                    # picker; with -r, forwards --resume to claude-docker
aidev <app-name> [-r]         # start Docker if needed, cd to the app, run claude-docker (-r → --resume)
aidev remove <app-name>       # remove an app from the config
aidev -h                      # help
```

If `<app-name>` is unknown, you'll be prompted to register it.

Config: `~/.config/aidev/apps.conf` — one `name=/absolute/path` entry per
line; safe to edit by hand.

---

Made by [Arkitektum AS](https://arkitektum.no).
