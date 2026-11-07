#!/bin/bash
# Workaround for AMD + Xorg freezes/hangs when starting a graphical session
# with AwesomeWM (and anything else Xorg-driven).
#
# Symptoms: Xorg starts, the WM config loads, then either (a) the machine
# locks up, (b) Xorg SIGSEGVs, or (c) cursor and keybinds stop working while
# the bar keeps rendering. On AMD Barcelo (renoir family) + kernel 7.x +
# Mesa 26 the amdgpu DDX / glamor / DRI3 pageflip / Panel Self Refresh
# combination triggers these states.
#
# Fixes applied:
#   1. Generic "modesetting" X driver (kernel modeset, no xf86-video-amdgpu
#      DDX) — avoids the AMD DDX code path entirely.
#   2. Kernel boot param amdgpu.dcdebugmask=0x10 -> disables Panel Self
#      Refresh.
#
# Run as root:  sudo bash ~/dotfiles/system/fix-amdgpu.sh
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCONF=/etc/X11/xorg.conf.d/20-amdgpu.conf
KCMDS=/etc/kernel/cmdline
GRUB_CFG=/etc/default/grub

write_xconf() {
    cat >"$XCONF" <<'XEOF'
# Xorg device config — maximally compatible fallback.
# Software rendering, no DRI3, software cursor. Targets the "cursor and
# keybinds stop working while the bar keeps rendering" failure on AMD Barcelo
# (renoir) + kernel 7.3.1 + Mesa 26 with the modesetting/amdgpu DDX paths.
Section "Device"
    Identifier "AMDGPU"
    Driver "modesetting"
    Option "AccelMethod" "none"
    Option "TearFree" "off"
    Option "DRI" "2"
    Option "SWcursor" "true"
EndSection
XEOF
}

if [ "$(id -u)" -ne 0 ]; then
    echo "fix-amdgpu.sh: run as root: sudo bash $0" >&2
    exit 1
fi

echo "== Xorg device config =="
mkdir -p /etc/X11/xorg.conf.d
write_xconf
echo "  wrote $XCONF (Driver modesetting)"

echo "== Kernel boot params =="
if [ -f "$KCMDS" ]; then
    if grep -q "amdgpu.dcdebugmask" "$KCMDS"; then
        echo "  amdgpu.dcdebugmask already set"
    else
        cp "$KCMDS" "$KCMDS.meadow-backup"
        echo "amdgpu.dcdebugmask=0x10" >>"$KCMDS"
        echo "  added amdgpu.dcdebugmask=0x10"
    fi
elif [ -f "$GRUB_CFG" ]; then
    if ! grep -q "amdgpu.dcdebugmask" "$GRUB_CFG"; then
        cp "$GRUB_CFG" "$GRUB_CFG.meadow-backup"
        sed -i -e 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 amdgpu.dcdebugmask=0x10"/' "$GRUB_CFG"
        sed -i -e 's/^GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 amdgpu.dcdebugmask=0x10"/' "$GRUB_CFG"
    fi
    echo "  grub cmdline updated"
else
    echo "  WARNING: could not find kernel cmdline file to update" >&2
fi

echo "== Reload bootloader =="
if command -v sdbootutil >/dev/null 2>&1; then
    sdbootutil update-entry "$(uname -r)" >/dev/null 2>&1 || true
    sdbootutil update-all-entries >/dev/null 2>&1 || true
    echo "  sdbootutil updated"
elif command -v grub2-mkconfig >/dev/null 2>&1; then
    grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1 || true
    echo "  grub2-mkconfig ran"
else
    echo "  NOTE: reboot manually to pick up new kernel args"
fi

echo "== Reboot =="
echo "  sudo reboot"
exit 0
