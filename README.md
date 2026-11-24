# AiDev

**One command to jump into any project with Claude running in Docker.**

```bash
aidev MyApp
```

starts Docker if it isn't running, `cd`s into the directory registered for
`MyApp`, and launches
[`claude-docker`](https://github.com/Arkitektum/claude-docker) there.

## Prerequisites

- [`claude-docker`](https://github.com/Arkitektum/claude-docker) on your
  `PATH`.
- **Docker** — Docker Desktop on WSL2 or macOS, Docker Desktop or Docker
  Engine on native Linux. AiDev starts it; it must be installed.
- **bash 4 or newer.** macOS ships bash 3.2, so a Mac needs
  `brew install bash`. It installs beside the system bash, your login shell
  stays as it is, and `aidev` switches to the newer bash by itself.
- [`fzf`](https://github.com/junegunn/fzf) *(optional)* — arrow keys and
  fuzzy search in the pickers. Without it you get a numbered list.

## Install

```bash
./install.sh
```

This symlinks `aidev` into `~/.local/bin`. Asking first each time, it also
offers to install a newer bash (macOS), to add `~/.local/bin` to your `PATH`
in your shell's startup file, and to install `fzf`.

Manual alternative: `ln -s "$PWD/aidev" ~/.local/bin/aidev`.

## Usage

| Command | What it does |
| --- | --- |
| `aidev` | Pick an app from the list, then launch it. |
| `aidev MyApp` | Launch `MyApp`; offers to register it if unknown. |
| `aidev MyApp -r` | Launch `MyApp` and pick a previous session to resume. |
| `aidev MyApp -r <session-id>` | Resume that session directly. |
| `aidev -r` | Pick an app, then pick one of its sessions. |
| `aidev MyApp -- <args>` | Pass `<args>` on to `claude-docker`. |
| `aidev remove [app]` | Remove an app (no name → picker). |
| `aidev rename [old [new]]` | Rename an app, keeping its directory. |
| `aidev config [app]` | Edit the app's extra domains and directories. |
| `aidev update` | Fast-forward aidev to the latest `origin/main`. |
| `aidev -h` | Help. |

For `-r <session-id>` the app name must come first: `aidev -r MyApp` picks
a session for `MyApp`.

The app list is ordered most recently used first. In the `fzf` picker, type
to filter and use the arrow keys; the counter (`3/10`) shows matches out of
total, and the list scrolls when there are more than fit.

### Registering an app

The first launch of an unknown name registers it:

```text
$ aidev MyApp
App 'MyApp' is not registered.
Register it now? [Y/n] y
dir for 'MyApp' >            # pick a suggestion, or enter a path
Registered: MyApp -> /home/you/code/myapp
Run claude-docker now? [Y/n] y
```

The suggestions are unregistered folders near the apps you already have:
their siblings and, two levels down, the subfolders of those. Inside a folder
that is a project of its own (`.git`, `package.json`, `pom.xml`, `*.sln`, …)
only sub-projects are offered, and build output such as `node_modules` is
skipped. Folders inside a registered app are still offered, so you can
register an app suite as one app and its apps individually.

- `AIDEV_SUGGEST_DEPTH=3 aidev MyApp` looks one level deeper, e.g. for the
  first app of a `client/suite/app` layout. Once one app there is
  registered, its siblings are suggested without it.
- `AIDEV_SUGGEST_DEBUG=1` explains on stderr which folders were looked at
  and why each was offered or held back. Use `2> >(tee aidev.log >&2)` to
  keep a copy; a plain `2>` redirect would hide the prompts too.

### Passing options on to claude-docker

Everything after `--` goes to `claude-docker` unchanged. It runs in the
app's directory, so relative paths are relative to the app:

```bash
aidev MyApp -- --add-dir ../shared-lib   # mount another directory
aidev MyApp -- bash                      # a shell in the container
aidev MyApp -- --rebuild                 # rebuild the image first
```

Environment variables also pass through, for example
`CLAUDE_DOCKER_ALLOW_DOMAINS=".example.com" aidev MyApp`.

## Config

`~/.config/aidev/apps.conf` holds one `name=/absolute/path` per line and can
be edited by hand. `remove`, `rename`, `config`, `update` and `help` are
reserved names.

### Per-app options

`aidev config MyApp` opens `~/.config/aidev/apps/MyApp.conf` in an editor,
for domains and directories the app gets on every launch:

```ini
# Domains the container may reach, on top of claude-docker's allowlist.
allow_domains = .example.com, .example.org

# Directories to mount. Relative paths are relative to the app directory.
add_dir = ../shared-lib
add_dir = ~/data/reference
```

Both keys can be repeated; comments go on lines of their own. The file is
checked when you save it and at every launch: an unknown key, a malformed
domain or a missing directory stops the launch, and after an edit AiDev
says what is wrong and lets you edit again or discard. To clear the options,
comment the settings out or leave them empty.

The editor is `VISUAL` or `EDITOR` if set, otherwise VS Code (close the tab
when done), `nano` or `vi`. Apps with options are marked `[has config]` in
the list, and AiDev prints the options it applies at launch.

## How Docker is started

- **WSL2:** `docker.exe desktop start` on the Windows side, using `docker.exe`
  from PATH, else from Docker Desktop's default install folder.
- **Linux:** by the active `docker context` — `desktop-linux` starts Docker
  Desktop's user service, anything else `sudo systemctl start docker`.
- **macOS:** `open -ga Docker`, without stealing focus.

AiDev then waits up to 120 seconds for Docker to be ready.

## Updates

On `main`, aidev checks `origin/main` in the background at most once a day
and tells you when new commits are available. `aidev update` fast-forwards
the checkout; it refuses if you have uncommitted changes or the history has
diverged. The symlink means the update applies on the next run.

---

Made by [Arkitektum AS](https://arkitektum.no).
