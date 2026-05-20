#!/usr/bin/env bash
# nix-uninstall.sh — Remove a multi-user Nix install from macOS or Linux.
# Follows the official procedure documented at
# https://nix.dev/manual/nix/2.31/installation/uninstall
#
# Idempotent: each step skips itself if its target state is already in place.
# Destructive: deletes /nix volume / dir, _nixbld users, /etc shims, ~/.nix-*.
#
# Usage:
#   scripts/nix-uninstall.sh            # DRY-RUN — print what would happen
#   scripts/nix-uninstall.sh --yes      # ACTUALLY execute (needs sudo)
#
# Phase 4 prep for v3-native: clears Nix from the host before the repo's
# own Nix surface is deleted. Safe to keep around afterward as a reference
# for users on other hosts.

set -u

DRY_RUN=1
if [ "${1:-}" = "--yes" ]; then
  DRY_RUN=0
fi

OS="$(uname)"

say()  { printf '%s\n' "$*"; }
note() { say "==> $*"; }
run() {
  if [ "$DRY_RUN" = "1" ]; then
    say "  would: $*"
  else
    say "  exec: $*"
    "$@" || say "  WARN: command exit $?"
  fi
}

# ------------------------------------------------------------------
# macOS — Step 1: stop launchd daemons
# ------------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
  note "1. stop launchd daemons"
  for plist in /Library/LaunchDaemons/org.nixos.nix-daemon.plist \
               /Library/LaunchDaemons/org.nixos.darwin-store.plist; do
    if [ -f "$plist" ]; then
      run sudo launchctl unload "$plist"
    else
      say "  already stopped: $plist absent"
    fi
  done
fi

# ------------------------------------------------------------------
# macOS — Step 2: remove launchd plists
# ------------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
  note "2. remove launchd plists"
  for plist in /Library/LaunchDaemons/org.nixos.nix-daemon.plist \
               /Library/LaunchDaemons/org.nixos.darwin-store.plist; do
    if [ -e "$plist" ]; then
      run sudo rm -f "$plist"
    else
      say "  already gone: $plist"
    fi
  done
fi

# ------------------------------------------------------------------
# Step 3: restore /etc shell-init backups left by the Nix installer
# ------------------------------------------------------------------
note "3. restore /etc shell-init shims"
for orig in /etc/zshenv /etc/zshrc /etc/bashrc /etc/bash.bashrc /etc/profile /etc/zprofile; do
  bak="${orig}.backup-before-nix"
  if [ -e "$bak" ]; then
    run sudo mv "$bak" "$orig"
  else
    say "  no backup at $bak"
  fi
done

# ------------------------------------------------------------------
# macOS — Step 4: clean /etc/synthetic.conf (removes /nix volume mount)
# ------------------------------------------------------------------
if [ "$OS" = "Darwin" ] && [ -f /etc/synthetic.conf ]; then
  note "4. clean /etc/synthetic.conf"
  if grep -q '^nix' /etc/synthetic.conf 2>/dev/null; then
    if [ "$(wc -l < /etc/synthetic.conf | tr -d ' ')" = "1" ] \
       && [ "$(tr -d '[:space:]' < /etc/synthetic.conf)" = "nix" ]; then
      run sudo rm -f /etc/synthetic.conf
    else
      run sudo cp /etc/synthetic.conf /etc/synthetic.conf.before-nix-removal
      run sudo sh -c "sed -i '' '/^nix$/d' /etc/synthetic.conf"
    fi
  else
    say "  already clean"
  fi
fi

# ------------------------------------------------------------------
# macOS — Step 5: clean /etc/fstab nix line
# ------------------------------------------------------------------
if [ "$OS" = "Darwin" ] && [ -f /etc/fstab ]; then
  note "5. clean /etc/fstab"
  if grep -qE '[[:space:]]/nix[[:space:]]+apfs' /etc/fstab 2>/dev/null; then
    run sudo cp /etc/fstab /etc/fstab.before-nix-removal
    run sudo sh -c "sed -i '' '/[[:space:]]\/nix[[:space:]]\\+apfs/d' /etc/fstab"
  else
    say "  already clean"
  fi
fi

# ------------------------------------------------------------------
# macOS — Step 6: delete the /nix APFS volume
# ------------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
  note "6. delete /nix APFS volume"
  if [ -d /nix ] && mount | grep -q ' on /nix '; then
    nix_disk="$(diskutil info /nix 2>/dev/null \
                | awk -F: '/Device Identifier/ {gsub(/[[:space:]]/,"",$2); print $2; exit}')"
    if [ -n "$nix_disk" ]; then
      run sudo diskutil apfs deleteVolume "$nix_disk"
    else
      say "  could not determine /nix disk identifier — skip; remove manually via Disk Utility"
    fi
  else
    say "  /nix not mounted (already removed or not mounted right now)"
  fi
fi

# ------------------------------------------------------------------
# macOS — Step 7: remove _nixbld* users + nixbld group
# ------------------------------------------------------------------
if [ "$OS" = "Darwin" ]; then
  note "7. remove _nixbld users + nixbld group"
  for i in $(seq 1 32); do
    user="_nixbld$i"
    if dscl . -read "/Users/$user" >/dev/null 2>&1; then
      run sudo dscl . -delete "/Users/$user"
    fi
  done
  for grp in nixbld _nixbld; do
    if dscl . -read "/Groups/$grp" >/dev/null 2>&1; then
      run sudo dscl . -delete "/Groups/$grp"
    fi
  done
fi

# ------------------------------------------------------------------
# Step 8: wipe user-level Nix dirs (cross-platform)
# ------------------------------------------------------------------
note "8. wipe user Nix dirs"
for d in "$HOME/.nix-profile" "$HOME/.nix-defexpr" "$HOME/.nix-channels" \
         "$HOME/.local/state/nix" "$HOME/.config/nix" "$HOME/.local/share/nix" \
         "$HOME/.config/home-manager" "$HOME/.local/share/home-manager"; do
  if [ -e "$d" ] || [ -L "$d" ]; then
    run rm -rf "$d"
  else
    say "  already gone: $d"
  fi
done

# ------------------------------------------------------------------
# Linux — Step 9: stop systemd units + remove /nix + /etc/nix
# ------------------------------------------------------------------
if [ "$OS" = "Linux" ]; then
  note "9. Linux systemd cleanup"
  for unit in nix-daemon.service nix-daemon.socket; do
    if systemctl is-enabled "$unit" >/dev/null 2>&1 \
       || systemctl is-active "$unit" >/dev/null 2>&1; then
      run sudo systemctl disable --now "$unit"
    fi
    for f in "/etc/systemd/system/$unit" "/lib/systemd/system/$unit"; do
      [ -e "$f" ] && run sudo rm -f "$f"
    done
  done
  for d in /nix /etc/nix; do
    [ -e "$d" ] && run sudo rm -rf "$d"
  done
fi

# ------------------------------------------------------------------
say ""
if [ "$DRY_RUN" = "1" ]; then
  say "DRY-RUN: nothing modified. Re-run with --yes to execute."
elif [ "$OS" = "Darwin" ]; then
  say "DONE. REBOOT REQUIRED so /etc/synthetic.conf changes take full effect."
else
  say "DONE."
fi
