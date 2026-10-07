# iSH-Setup ✦

A cool-looking [iSH](https://ish.app) in one paste. Gradient banner on open, a two-line git-aware prompt, handy aliases, and the tools you actually want, all set up in a minute.

```
   ___     _    ___  _  __
  |   \   /_\  | _ \| |/ /
  | |) | / _ \ |   /| ' <
  |___/ /_/ \_\|_|_\|_|\_\
   _  _   ___  __   __   _
  | \| | / _ \ \ \ / /  /_\
  | .` || (_) | \ V /  / _ \
  |_|\_| \___/   \_/  /_/ \_\
  ──────────────────────────────
  Good morning, Victor ✦
  Wed 07 Oct · 11:09

  ◆ sys  Alpine Linux 3.14 · up 2h 5m
  ◆ ram  210M/497M · disk 1.2G/4.0G
  ◆ web  mrdarknova.com
  ◆ git  github.com/MrDarkNova

  tip › gs        git status, short
```

## Install

Open iSH and paste this one line:

```sh
apk add --no-cache curl ca-certificates && curl -fsSL https://raw.githubusercontent.com/MrDarkNova/iSH-Setup/main/setup.sh | sh
```

Then close and reopen iSH (or run `exec bash -l`).

Short on space or patience? Skip the dev tools:

```sh
curl -fsSL https://raw.githubusercontent.com/MrDarkNova/iSH-Setup/main/setup.sh | sh -s -- --lite
```

## What you get

| Piece | Details |
| --- | --- |
| **Banner** | Gradient ASCII art, greeting by time of day, system info, a random tip. Sized for a phone in portrait (37 columns). |
| **Prompt** | Two lines, git branch (read straight from `.git/HEAD`, so it stays fast on iSH), red `✘ code` when a command fails. |
| **Core tools** | bash, git, curl, wget, nano (with syntax colours), jq, tzdata |
| **Dev tools** | nodejs, npm, python3, pip, openssh-client, tmux, htop (skipped with `--lite`) |
| **Aliases** | `ll` `la` `..` `c` `gs` `ga` `gaa` `gc` `gp` `gl` `gd` `update` `serve` `mkcd` `myip` `weather` |
| **Clean login** | Clears the stock welcome text so the banner is the first thing you see. |

Package install is fault tolerant: if one package is missing from your Alpine release, it is skipped and the rest still install. Details go to `/tmp/nova-setup.log`.

## The `nova` command

```
nova            show the banner again
nova update     re-run the installer
nova config     edit name, timezone, city and links
nova uninstall  remove the Nova look (packages stay)
```

## Make it yours

Settings live in `~/.nova/config`:

```sh
NOVA_NAME="Victor"
NOVA_TZ="Africa/Lagos"
NOVA_CITY="Kaduna"
NOVA_SITE="mrdarknova.com"
NOVA_GITHUB="github.com/MrDarkNova"
NOVA_BANNER="1"   # 0 turns the opening banner off
```

You can also set them before installing, for example `NOVA_NAME=Sam sh setup.sh`. Your config is kept when you update. To use your own ASCII art, replace `~/.nova/art.txt` (up to 8 gradient colour steps; about 38 columns fits a phone in portrait).

Set `NOVA_FAST=1` to skip the small reveal animation. The colours are mid-tone purples, so they read on light and dark terminal themes. If the banner ever stalls, press `^` then `c`, and set `NOVA_BANNER="0"` in `~/.nova/config`.

## Notes

- Re-running the installer is safe. Everything it adds to `~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.inputrc` and `~/.nanorc` sits between `# >>> nova-ish >>>` markers and is replaced, never duplicated.
- It never sets your git name or email. After install, run `git config --global user.name "..."` and `git config --global user.email "..."`.
- Made for iSH (Alpine on iOS). It needs `apk`, so it will refuse to run elsewhere.

---

Made by [Victor Kumba](https://mrdarknova.com) · [@MrDarkNova](https://github.com/MrDarkNova)
