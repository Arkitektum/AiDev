# AiDev

**One command to jump into any project with Claude running in Docker.**

```bash
aidev MyApp
```

That single command starts Docker if it isn't running, `cd`s into the
project directory registered for `MyApp`, and launches
[`claude-docker`](https://github.com/Arkitektum/claude-docker) there — no
more "which folder was that again?" or "is Docker up?".

## Why

- **Remembers your projects by name** — register each app once, then launch
  it from anywhere by name.
- **Starts Docker for you** — works on both WSL2 (Docker Desktop on Windows)
  and native Linux (Docker Desktop *or* Docker Engine), picking the right
  daemon automatically.
- **Interactive picker** — forget the name? Run `aidev` with no arguments and
  pick from a list (with fuzzy search if you have `fzf`):

  ```text
    aidev >
  > aidev      /home/you/code/aidev
    MyApp      /home/you/code/myapp
    MyWebSite  /home/you/code/webportal
  ```
  Start typing to fuzzy-filter; arrow keys move the `>` cursor; Enter launches
  the highlighted app. Apps are ordered most-recently-used first. Without
  `fzf`, you get a numbered list to pick from instead.
- **Resume sessions** — jump back into a previous Claude session with `-r`.

## Prerequisites

- [`claude-docker`](https://github.com/Arkitektum/claude-docker) on your
  `PATH` — AiDev is a wrapper around it (it runs Claude Code in a Docker
  container with restricted network access).
- **Docker** — Docker Desktop on WSL2, or Docker Desktop / Docker Engine on
  native Linux. AiDev starts it for you, but it must be installed.
- [`fzf`](https://github.com/junegunn/fzf) *(optional)* — enables arrow keys
  and fuzzy search in the picker. Without it, a numbered fallback is used.
  The installer can set this up for you.

## Install

```bash
./install.sh
```

This symlinks `aidev` into `~/.local/bin`, hints if that directory isn't on
your `PATH`, and offers to install `fzf`.

Manual alternative:

```bash
mkdir -p ~/.local/bin
ln -s "$PWD/aidev" ~/.local/bin/aidev
```

## Quick start

The first time you launch an unregistered app, AiDev walks you through setup:

```text
$ aidev MyApp
App 'MyApp' is not registered.
Register it now? [Y/n] y
dir for 'MyApp' >            # pick a suggested directory, or enter a path
Registered: MyApp -> /home/you/code/myapp
Run claude-docker now? [Y/n] y
Starting Docker Desktop...
Docker is ready.
Running claude-docker in /home/you/code/myapp
```

The directory suggestions are sibling folders of apps you've already
registered that aren't registered yet — most-used location first — so after
your first app or two, registering the next is usually a single keypress.

From then on, `aidev MyApp` takes you straight in.

## Usage

```text
aidev [-r]                    # interactive picker
aidev <app-name> [-r]         # start Docker if needed, cd to the app, run claude-docker
aidev remove [app-name]       # remove an app (no name → picker)
aidev -h                      # help
```

Examples:

| Command | What it does |
| --- | --- |
| `aidev` | Pick an app from the list, then launch it. |
| `aidev MyApp` | Launch `MyApp` (prompts to register if unknown). |
| `aidev MyApp -r` | Launch `MyApp` and pick a previous Claude session to resume. |
| `aidev MyApp -r <session-id>` | Resume that specific session directly. |
| `aidev -r` | Pick an app, then resume one of its sessions. |
| `aidev remove` | Pick an app to remove from the config. |

> **Note:** for `-r <session-id>`, the app name must come *before* `-r`.
> `aidev -r MyApp` treats `MyApp` as the app for the picker, not as a session id.

## How it works

On WSL2, AiDev starts Docker Desktop on the Windows side via
`docker.exe desktop start`.

On native Linux, the active Docker context (`docker context show`) decides
which daemon to start: `desktop-linux` starts Docker Desktop's user service,
anything else starts the `docker` system service via `sudo systemctl`.

Either way, AiDev waits until Docker is ready (up to 120s) before launching
`claude-docker`.

## Config

`~/.config/aidev/apps.conf` — one `name=/absolute/path` entry per line; safe
to edit by hand. (`remove` and `help` are reserved and can't be used as app
names.)

---

Made by [Arkitektum AS](https://arkitektum.no).
