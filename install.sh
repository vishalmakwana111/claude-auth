#!/usr/bin/env bash
# Install claude-auth into ~/.local/bin
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SRC_DIR/bin/claude-auth"
DEST_DIR="$HOME/.local/bin"
DEST="$DEST_DIR/claude-auth"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "error: claude-auth supports macOS only (it uses the login Keychain)." >&2
  exit 1
fi

if [[ ! -f "$SRC" ]]; then
  echo "error: cannot find $SRC" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST"
chmod +x "$DEST"
echo "✓ installed claude-auth → $DEST"

# Warn if ~/.local/bin isn't on PATH
case ":$PATH:" in
  *":$DEST_DIR:"*)
    echo "✓ $DEST_DIR is already on your PATH"
    ;;
  *)
    echo
    echo "⚠  $DEST_DIR is not on your PATH. Add it:"
    echo "     echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
    echo "     source ~/.zshrc"
    ;;
esac

echo
echo "Done. Try:  claude-auth --help"
