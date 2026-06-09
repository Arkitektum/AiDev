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
    3/3 ──────────────────────────────────────────
    Type to filter | Up/Down to scroll | Enter to select
  > aidev      /home/you/code/aidev
    MyApp      /home/you/code/myapp
    MyWebSite  /home/you/code/webportal
  ```
  Start typing to fuzzy-filter; arrow keys move the `>` cursor; Enter launches
  the highlighted app. Apps are ordered most-recently-used first. The `3/3`
  counter is matches out of total — when it reads more than the rows on
  screen, the list scrolls. Without `fzf`, you get a numbered list to pick
  from instead.
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

The directory suggestions are the unregistered folders around apps you've
already registered — the folders next to them, each with its own subfolders
listed right underneath, most-used location first — so after your first app
or two, registering the next is usually a single keypress. If you keep repos
grouped under an org or client folder, that nesting is covered too:

```text
/home/you/code/Arkitektum
/home/you/code/Arkitektum/RepoB
/home/you/code/Personal
/home/you/code/Personal/Toy
```

The search stays out of the way: inside a folder that is a project of its own
(it has `.git`, `package.json`, a `pom.xml`, a `.sln`, ...) only sub-projects
are offered, so a repo's `src/` and `docs/` stay out of the list while an app
suite kept in a single repo — or a monorepo's packages — still shows up. Build
noise like `node_modules` is skipped outright. Set `AIDEV_SUGGEST_DEPTH` to
change how deep it looks (default `2`; `1` = siblings only).

Registering a folder does not close it off. If you register an app suite as
one app — handy when you want a session that can read across all of it — the
apps inside it stay on offer, so you can register them individually too:

```text
/home/you/code/IKA_Kongsberg/IKA_Innsyn/IKA_Innsyn_Cosdoc
/home/you/code/IKA_Kongsberg/IKA_Innsyn/IKA_Innsyn_Gerica
...
```

Registering the *first* app of a deeper layout — say `customer/appsuite/app`,
three levels below anything you have registered so far — reaches past that
default. Raise it for that one run:

```bash
AIDEV_SUGGEST_DEPTH=3 aidev MyApp
```

You only need that once per location: once one app in the suite is
registered, its siblings show up like any other candidate.

If a folder you expected is missing from the list, `AIDEV_SUGGEST_DEBUG=1`
makes the search explain itself on stderr — which folders it looked at, and
why each was offered or held back. Keep a copy, since the picker draws over
the terminal:

```bash
AIDEV_SUGGEST_DEBUG=1 aidev MyApp 2> >(tee /tmp/aidev-suggest.log >&2)
```

Copy rather than redirect: prompts share that stream, so a plain
`2>/tmp/aidev-suggest.log` hides the `Register it now?` question — and the
whole list, if you are on the numbered picker rather than `fzf`.

From then on, `aidev MyApp` takes you straight in.

## Usage

```text
aidev [-r]                    # interactive picker
aidev <app-name> [-r]         # start Docker if needed, cd to the app, run claude-docker
aidev remove [app-name]       # remove an app (no name → picker)
aidev rename [old [new]]      # rename an app, keeping its directory
aidev update                  # fast-forward aidev itself to the latest origin/main
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
| `aidev rename MyApp NewName` | Rename `MyApp` to `NewName`, keeping its directory. |
| `aidev rename` | Pick an app, then enter its new name. |
| `aidev update` | Fast-forward aidev itself to the latest `origin/main`. |

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
to edit by hand. (`remove`, `rename`, `update` and `help` are reserved and
can't be used as app names.)

## Staying up to date

When the checkout is on `main`, aidev quietly checks `origin/main` in the
background (at most once a day) and prints a one-line nudge on startup when
new commits are available:

```
aidev: update available — 2 commits behind origin/main. Run 'aidev update'.
```

`aidev update` fast-forwards the checkout (`git pull --ff-only`). It refuses
if the working tree has uncommitted changes or the history has diverged,
leaving you to resolve those manually. Because aidev is installed as a
symlink, the update takes effect on the next run — no reinstall needed.

---

Made by [Arkitektum AS](https://arkitektum.no).
