# Meadow — Linux dotfiles

A Linux port of [gloceandotdev/dotfiles](https://github.com/gloceandotdev/dotfiles):
a minimal, keyboard-driven rice with automatic **Meadow / Meadow Light**
switching.

The original rice is macOS-only (`yabai`, `skhd`, `SketchyBar`, JankyBorders).
This port keeps the same palette, fonts, spacing, wallpapers and workflow,
and maps the macOS pieces onto a Linux X11 stack.

## What changed

| macOS (upstream) | Linux (this repo) |
| --- | --- |
| yabai (tiling) | AwesomeWM (`awesome/rc.lua`) |
| skhd (hotkeys) | AwesomeWM keybindings |
| SketchyBar (bar) | AwesomeWM `wibar` + widgets |
| JankyBorders | AwesomeWM window borders |
| Karabiner-Elements (Caps Lock) | `keyd` (`keyd/default.conf`) |
| Raycast | rofi (`rofi/`) |
| dark-notify (auto theme) | `switch-theme.sh` + systemd user timer |
| Homebrew | zypper / pacman / apt |
| ghostty, fish, starship, btop | unchanged (Linux packages) |

Kept from upstream: the Meadow palette, Ghostty themes, Fish theme, Starship
config, btop config, the 10 "spaces", the Caps Lock modifier, and the
dark/light wallpapers.

## Install

```sh
git clone <your-fork> ~/dotfiles
bash ~/dotfiles/setup.sh
```

`setup.sh` supports **openSUSE Tumbleweed**, **Arch**, and **Debian/Ubuntu**.
It installs packages, links the configs into `~/.config`, installs the
JetBrains Mono + Symbols Nerd Font + Inter packages, sets fish as your shell,
installs the keyd Caps Lock mapping, and enables the theme timer.

Useful flags:

```sh
bash setup.sh --no-packages   # configs only
bash setup.sh --no-fonts      # skip the font packages
```

Then log out and choose **Awesome (Meadow)** at the login screen (installed by
`setup.sh`), or run `startx` (`~/.xinitrc` is created if you don't have one).

Both paths start Awesome through `bin/awesome-session`, which writes a
persistent startup log to `~/.cache/meadow/session.log` (previous run in
`session.log.old`). This survives a freeze or hard reboot, so it is the first
place to look if the session does not come up.

If Awesome itself starts but the machine freezes, try these switches (they can
be put in `~/.config/meadow/session-env`, one `KEY=value` per line, to apply to
both GDM and `startx`):

```sh
MEADOW_NO_PICOM=1     # start without the compositor (this is the default now)
MEADOW_NO_WALLPAPER=1 # skip the large PNG wallpaper
MEADOW_MINIMAL=1      # use the minimal diagnostic config
```

After a session works look at `~/.cache/meadow/session.log`; the last
`meadow:` line tells you how far startup got. To turn the compositor back on:

```sh
echo 'MEADOW_NO_PICOM=0' > ~/.config/meadow/session-env
```

Existing config files are moved to `~/.dotfiles-backup/<timestamp>/`, never
deleted.

## Theme switching

Light/dark follows a schedule, like `dark-notify` does on macOS:

```sh
switch-theme auto       # follow ~/.config/meadow/config (timer runs every 10 min)
switch-theme light
switch-theme dark
switch-theme toggle     # also Mod4+Shift+T
```

`~/.config/meadow/config`:

```sh
LIGHT_FROM=07:00
DARK_FROM=19:00

# Optional: real sunrise/sunset (needs python3)
# LAT=52.5200
# LON=13.4050
```

A switch updates AwesomeWM (including the wallpaper), Starship, Ghostty, Fish
colors, the GTK/portal color scheme, and XSettings-aware apps.

## Shortcuts

`Mod4` = Super. On Linux, hold **Caps Lock** (keyd) as the modifier; tapping it
sends Escape, same as the Karabiner rule upstream.

| Shortcut | Action |
| --- | --- |
| `Mod4 + h/j/k/l` | Focus left / down / up / right |
| `Mod4 + Shift + h/j/k/l` | Move window left / down / up / right |
| `Mod4 + 1…9, 0` | Focus tag 1…10 (yabai "spaces") |
| `Mod4 + Shift + 1…9, 0` | Send window to tag and follow it |
| `Mod4 + q` / `Mod4 + w` | Focus monitor 1 / 2 |
| `Mod4 + Shift + q/w` | Move window to monitor 1 / 2 |
| `Mod4 + u` / `p` | Resize left / right (master width) |
| `Mod4 + i` / `o` | Resize down / up (master count) |
| `Mod4 + e` | Equalize window sizes |
| `Mod4 + r` / `Shift + r` | Rotate layout / rotate backwards |
| `Mod4 + x` / `Shift + x` | Swap with next / previous window |
| `Mod4 + space` | Toggle floating + center |
| `Mod4 + Shift + space` | Toggle maximize |
| `Mod4 + f` | Toggle fullscreen |
| `Mod4 + Shift + c` | Close window |
| `Mod4 + Return` | Ghostty |
| `Mod4 + d` | Application launcher (rofi) |
| `Mod4 + Shift + d` | Run command (rofi) |
| `Mod4 + Tab` | Window switcher (rofi) |
| ``Mod4 + ` `` | Scratchpad terminal |
| `Mod4 + Shift + t` | Toggle light/dark |
| `Mod4 + Shift + s` | Screenshot (full) |
| `Mod4 + Ctrl + s` | Screenshot (region) |
| `Mod4 + Shift + e` / `Mod4 + Escape` | Power menu |
| `Mod4 + Ctrl + r` | Restart AwesomeWM |
| `Mod4 + Shift + /` | Shortcut help |
| Media keys | Volume, mute, play/pause, next/prev, brightness |

A few yabai actions have no AwesomeWM equivalent: BSP mirroring is replaced by
window swapping, and resizing tiled windows is done by changing the layout
split (master factor / master count).

## Weather

The bar uses OpenWeather, same as upstream:

```sh
mkdir -p ~/.config/awesome
echo 'export API_KEY="your_key_here"' > ~/.config/awesome/meadow_env
```

Get a free key at <https://home.openweathermap.org/api_keys>. Until then the
widget shows a cloud glyph and `--`.

## Layout

```
awesome/     rc.lua, theme palettes, bar widgets, weather script
fish/        config.fish + Meadow.theme
ghostty/     config + Meadow themes
btop/        btop.conf + rose-pine themes (as upstream)
rofi/        launcher themes (Meadow / Meadow Light)
picom/       compositor (rounded corners, no shadows, blur)
keyd/        Caps Lock -> Super / Escape
systemd/     meadow-theme service + timer
bin/         rofi-launcher, power-menu, screenshot
lib/sun.py   sunrise/sunset helper for `switch-theme auto`
switch-theme.sh
setup.sh
```

## Fonts

Installed from distro packages (no manual downloads):

| Purpose | Package | Family |
| --- | --- | --- |
| Interface | `inter-fonts` (Tumbleweed), `inter-font` (Arch), `fonts-inter` (Debian) | `Inter` |
| Monospace | `jetbrains-mono-fonts` / `ttf-jetbrains-mono` / `fonts-jetbrains-mono` | `JetBrains Mono` |
| Icons | `nerdfonts-symbolsonly-fonts` / `ttf-nerd-fonts-symbols` / `fonts-nerd-fonts-symbols` | `Symbols Nerd Font` (Mono in the terminal) |

Pango and Ghostty fall back to **Symbols Nerd Font** for the bar glyphs, so
the monospace family stays the normal JetBrains Mono. All icons are Nerd Font
glyphs; no emoji are used.

## Troubleshooting

- **Xorg / AMD freeze or crash**: the session wrapper
  `bin/awesome-session` and the startup log (`~/.cache/meadow/session.log`)
  are in place. For AMD GPUs (the barcelo/renoir class on newer Tumbleweed),
  run:

  ```sh
  sudo bash ~/dotfiles/system/fix-amdgpu.sh
  sudo reboot
  ```

  This installs `xf86-video-amdgpu`, writes
  `/etc/X11/xorg.conf.d/20-amdgpu.conf` (TearFree + software rendering via
  `AccelMethod none`), and appends `amdgpu.dcdebugmask=0x10` to the kernel
  cmdline (disables Panel Self Refresh).

- **Minimal config**: `MEADOW_MINIMAL=1 MEADOW_NO_PICOM=1 startx` to test the
  window manager without themes, widgets, wallpaper, or compositor.

## Credits

- Upstream dotfiles: [gloceandotdev/dotfiles](https://github.com/gloceandotdev/dotfiles) (MIT)
- Meadow color scheme: <https://glocean.dev/meadow>
- Wallpapers: from the upstream repo

Licensed under the MIT license; see [LICENSE](LICENSE).
