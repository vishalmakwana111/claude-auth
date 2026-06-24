#!/usr/bin/env bash
# Remove the claude-auth binary. Your saved accounts (Keychain items and
# ~/.claude-accounts) are left untouched unless you pass --purge.
set -euo pipefail

DEST="$HOME/.local/bin/claude-auth"
PURGE="${1:-}"

if [[ -f "$DEST" ]]; then
  rm -f "$DEST"
  echo "✓ removed $DEST"
else
  echo "claude-auth is not installed at $DEST"
fi

if [[ "$PURGE" == "--purge" ]]; then
  echo
  echo "Purging saved account data…"
  rm -rf "$HOME/.claude-accounts"
  echo "✓ removed ~/.claude-accounts"
  # Delete every namespaced backup item from the Keychain
  while security delete-generic-password -s "claude-auth-store" >/dev/null 2>&1; do :; done
  echo "✓ removed claude-auth-store Keychain items"
  echo
  echo "Note: your live Claude Code login (the 'Claude Code-credentials' item) was NOT touched."
else
  echo
  echo "Saved accounts kept. To also delete them, run:  ./uninstall.sh --purge"
fi
