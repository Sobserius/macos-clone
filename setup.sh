#!/usr/bin/env bash
# setup.sh — install the Meadow Linux rice.
# Port of https://github.com/gloceandotdev/dotfiles (macOS -> Linux)
#
# Run: bash ~/dotfiles/setup.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_ROOT="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

INSTALL_PACKAGES=1
INSTALL_FONTS=1

usage() {
    cat <<'EOF'
Usage: bash setup.sh [--no-packages] [--no-fonts]

  --no-packages  only link configs (packages already installed)
  --no-fonts     skip installing the font packages
EOF
}

for arg in "$@"; do
    case "$arg" in
        --no-packages) INSTALL_PACKAGES=0 ;;
        --no-fonts) INSTALL_FONTS=0 ;;
        -h | --help) usage; exit 0 ;;
        *)
            echo "setup.sh: unknown argument: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ "$(id -u)" -eq 0 ]; then
    echo "setup.sh: run as your normal user (sudo is used where needed)" >&2
    exit 1
fi

say() { printf '\n== %s ==\n' "$1"; }
warn() { printf 'warning: %s\n' "$*" >&2; }

# ── Distro ────────────────────────────────────────────────────────────────────
if command -v zypper >/dev/null 2>&1; then
    DISTRO="opensuse"
elif command -v pacman >/dev/null 2>&1; then
    DISTRO="arch"
elif command -v apt-get >/dev/null 2>&1; then
    DISTRO="debian"
else
    DISTRO="unknown"
fi

install_core() {
    case "$DISTRO" in
        opensuse)
            sudo zypper --non-interactive install --no-recommends \
                awesome fish btop rofi picom maim xclip jq curl unzip procps \
                xorg-x11-server xinit xauth
            ;;
        arch)
            sudo pacman -S --needed --noconfirm \
                awesome fish btop rofi picom maim xclip jq curl unzip \
                xorg-server xorg-xinit
            ;;
        debian)
            sudo apt-get update
            sudo apt-get install -y \
                awesome fish btop rofi picom maim xclip jq curl unzip \
                xserver-xorg xinit x11-xserver-utils
            ;;
        *)
            echo "setup.sh: unsupported distro (expected zypper, pacman or apt)" >&2
            echo "Install the packages manually, then re-run: bash setup.sh --no-packages" >&2
            exit 1
            ;;
    esac
}

install_one() {
    case "$DISTRO" in
        opensuse) sudo zypper --non-interactive install --no-recommends "$1" ;;
        arch) sudo pacman -S --needed --noconfirm "$1" ;;
        debian) sudo apt-get install -y "$1" ;;
    esac
}

install_optional() {
    local pkg
    for pkg in "$@"; do
        if install_one "$pkg" >/dev/null 2>&1; then
            echo "  + $pkg"
        else
            warn "optional package '$pkg' is not available; skipping"
        fi
    done
}

install_font_packages() {
    case "$DISTRO" in
        opensuse) install_optional jetbrains-mono-fonts nerdfonts-symbolsonly-fonts inter-fonts ;;
        arch) install_optional ttf-jetbrains-mono ttf-nerd-fonts-symbols inter-font ;;
        debian) install_optional fonts-jetbrains-mono fonts-nerd-fonts-symbols fonts-inter ;;
    esac
    fc-cache -f >/dev/null 2>&1 || true
    if ! fc-list 2>/dev/null | grep -i 'Symbols Nerd Font' >/dev/null; then
        warn "Symbols Nerd Font not found; bar icons may show as boxes"
    fi
}

# ── Backup + symlink helpers ──────────────────────────────────────────────────
backup() {
    local target="$1"
    [ -e "$target" ] || [ -L "$target" ] || return 0
    mkdir -p "$BACKUP_ROOT$(dirname "$target")"
    mv "$target" "$BACKUP_ROOT$target"
    echo "  backed up $target"
}

link() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [ -L "$dest" ]; then
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        backup "$dest"
    fi
    ln -s "$src" "$dest"
    echo "  $dest -> $src"
}

# ── Packages ─────────────────────────────────────────────────────────────────
if [ "$INSTALL_PACKAGES" -eq 1 ]; then
    say "Packages ($DISTRO)"
    install_core

    say "Optional packages"
    case "$DISTRO" in
        opensuse) install_optional ghostty starship keyd i3lock playerctl brightnessctl pavucontrol fastfetch papirus-icon-theme xsetroot ;;
        arch) install_optional ghostty starship keyd i3lock playerctl brightnessctl pavucontrol fastfetch papirus-icon-theme xorg-xsetroot ;;
        debian) install_optional ghostty starship keyd i3lock playerctl brightnessctl pavucontrol fastfetch papirus-icon-theme ;;
    esac

    if ! command -v starship >/dev/null 2>&1; then
        say "Starship (fallback installer)"
        mkdir -p "$HOME/.local/bin"
        curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" ||
            warn "starship install failed; the prompt will be plain until you install it"
    fi

    if ! command -v ghostty >/dev/null 2>&1; then
        warn "ghostty is not in your distro repos yet; install it from https://ghostty.org/download"
        warn "or run awesome with TERMINAL=xterm (or another terminal)"
    fi
fi

# ── Fonts ────────────────────────────────────────────────────────────────────
if [ "$INSTALL_FONTS" -eq 1 ]; then
    say "Fonts"
    install_font_packages
fi

# ── Config links ─────────────────────────────────────────────────────────────
say "Configs"
link "$DOTFILES/awesome" "$CONFIG/awesome"
link "$DOTFILES/fish" "$CONFIG/fish"
link "$DOTFILES/ghostty" "$CONFIG/ghostty"
link "$DOTFILES/btop" "$CONFIG/btop"
link "$DOTFILES/rofi" "$CONFIG/rofi"
link "$DOTFILES/picom" "$CONFIG/picom"

# Weather API key (optional; the widget shows a placeholder until it is set)
if [ ! -f "$CONFIG/awesome/meadow_env" ]; then
    cp "$DOTFILES/awesome/meadow_env.example" "$CONFIG/awesome/meadow_env"
    echo "  $CONFIG/awesome/meadow_env (edit this to enable the weather widget)"
fi

if [ -e "$CONFIG/starship.toml" ] || [ -L "$CONFIG/starship.toml" ]; then
    backup "$CONFIG/starship.toml"
fi
cp "$DOTFILES/starship.toml" "$CONFIG/starship.toml"
echo "  $CONFIG/starship.toml (copied)"

mkdir -p "$CONFIG/meadow"
if [ ! -f "$CONFIG/meadow/config" ]; then
    cp "$DOTFILES/meadow/config" "$CONFIG/meadow/config"
    echo "  $CONFIG/meadow/config (copied)"
fi

say "Local scripts"
mkdir -p "$HOME/.local/bin"
ln -sf "$DOTFILES/switch-theme.sh" "$HOME/.local/bin/switch-theme"
for script in awesome-session rofi-launcher power-menu screenshot; do
    ln -sf "$DOTFILES/bin/$script" "$HOME/.local/bin/$script"
done
chmod +x "$DOTFILES/setup.sh" "$DOTFILES/switch-theme.sh" "$DOTFILES/bin/"* \
    "$DOTFILES/awesome/scripts/"*.sh "$DOTFILES/lib/sun.py"

# ── Fish shell ───────────────────────────────────────────────────────────────
say "Fish shell"
FISH_PATH="$(command -v fish || true)"
if [ -n "$FISH_PATH" ]; then
    grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null ||
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    if [ "${SHELL:-}" != "$FISH_PATH" ]; then
        chsh -s "$FISH_PATH" || warn "could not change shell; run: chsh -s $FISH_PATH"
    fi
else
    warn "fish is not installed; skipping shell change"
fi

# ── Caps Lock (keyd) ─────────────────────────────────────────────────────────
say "Caps Lock -> Super / Escape (keyd)"
if command -v keyd >/dev/null 2>&1; then
    if [ -e /etc/keyd/default.conf ]; then
        sudo cp -a /etc/keyd/default.conf \
            "/etc/keyd/default.conf.bak.$(date +%Y%m%d-%H%M%S)"
        echo "  backed up /etc/keyd/default.conf"
    fi
    sudo install -Dm644 "$DOTFILES/keyd/default.conf" /etc/keyd/default.conf
    sudo systemctl enable --now keyd || warn "could not start keyd (reboot later)"
else
    warn "keyd is not installed. Fallback: setxkbmap -option caps:super"
fi

# ── Theme schedule ───────────────────────────────────────────────────────────
say "Theme schedule"
mkdir -p "$CONFIG/systemd/user"
cp "$DOTFILES/systemd/meadow-theme.service" "$CONFIG/systemd/user/"
cp "$DOTFILES/systemd/meadow-theme.timer" "$CONFIG/systemd/user/"
systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user enable --now meadow-theme.timer >/dev/null 2>&1 ||
    warn "enable the timer after your next graphical login: systemctl --user enable --now meadow-theme.timer"

# ── X session ────────────────────────────────────────────────────────────────
if [ ! -e "$HOME/.xinitrc" ] || grep -q '^exec awesome$' "$HOME/.xinitrc" 2>/dev/null; then
    printf '#!/bin/sh\nexec "$HOME/.local/bin/awesome-session"\n' >"$HOME/.xinitrc"
    chmod +x "$HOME/.xinitrc"
    echo "  ~/.xinitrc -> awesome-session"
else
    echo "  ~/.xinitrc exists; leaving it untouched"
fi

# Display-manager entry that starts Awesome through the logging wrapper.
if [ -d /usr/share/xsessions ] && command -v awesome >/dev/null 2>&1; then
    session_tmp="$(mktemp)"
    sed "s|@HOME@|$HOME|g" "$DOTFILES/awesome/awesome-session.desktop" >"$session_tmp"
    if sudo install -Dm644 "$session_tmp" /usr/share/xsessions/awesome-meadow.desktop 2>/dev/null; then
        echo "  /usr/share/xsessions/awesome-meadow.desktop"
    else
        warn "could not install the GDM session entry (log in and use startx instead)"
    fi
    rm -f "$session_tmp"
fi

sudo bash "$DOTFILES/system/fix-amdgpu.sh" >/dev/null 2>&1 ||
    warn "run: sudo bash $DOTFILES/system/fix-amdgpu.sh"

# ── Apply the right theme for the current time ───────────────────────────────
say "Initial theme"
"$DOTFILES/switch-theme.sh" auto --force || warn "could not apply the initial theme"

# ── Done ─────────────────────────────────────────────────────────────────────
say "Done"

cat <<'EOF'
Log out and pick the "Awesome (Meadow)" session at your display manager, or run:
  startx

`startx` runs `~/.local/bin/awesome-session`, which writes to
`~/.cache/meadow/session.log`.

Notes:
  - Weather: create ~/.config/awesome/meadow_env with
        API_KEY="your_openweathermap_key"
    (free key: https://home.openweathermap.org/api_keys)
  - Theme schedule: ~/.config/meadow/config
        switch-theme auto        follow the schedule
        switch-theme light|dark  force a theme
        switch-theme toggle      Mod4+Shift+T
  - keyd (Caps Lock -> hold Super, tap Escape) needs a reboot.
  - The theme timer runs every 10 minutes in your user session.
  - Fonts: JetBrains Mono + Symbols Nerd Font + Inter (install with --no-fonts to skip).

Meadow is a Linux port of https://github.com/gloceandotdev/dotfiles
EOF
