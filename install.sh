#!/bin/bash
# FSTQ — установка и обновление одной командой (macOS, Apple Silicon):
#   curl -fsSL https://raw.githubusercontent.com/Shevmic/fstq-releases/main/install.sh | bash
# Берёт последнюю версию из GitHub Releases, ставит в /Applications, снимает карантин, запускает.
set -euo pipefail
REPO="${FSTQ_REPO:-Shevmic/fstq-releases}"
DEST="${FSTQ_DEST:-/Applications}"
APP="$DEST/FSTQ.app"

echo "FSTQ: ищу последнюю версию…"
URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep -o '"browser_download_url": *"[^"]*arm64\.dmg"' | head -1 | sed 's/.*"\(https[^"]*\)"/\1/')
[ -n "$URL" ] || { echo "Не нашёл установщик в $REPO"; exit 1; }
VER=$(echo "$URL" | sed -E 's/.*FSTQ-([0-9.]+)-arm64\.dmg/\1/')

TMP=$(mktemp -d)
trap 'hdiutil detach "$TMP/mnt" -quiet 2>/dev/null || true; rm -rf "$TMP"' EXIT
echo "FSTQ $VER: скачиваю…"
if [ -n "${FSTQ_DMG:-}" ]; then cp "$FSTQ_DMG" "$TMP/fstq.dmg"; else curl -fL --progress-bar "$URL" -o "$TMP/fstq.dmg"; fi
mkdir -p "$TMP/mnt"
hdiutil attach "$TMP/fstq.dmg" -nobrowse -quiet -mountpoint "$TMP/mnt"

# работающее приложение — закрыть (очередь сохранена и продолжится после запуска)
if pgrep -xq FSTQ; then
  echo "Закрываю FSTQ…"
  osascript -e 'quit app "FSTQ"' 2>/dev/null || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -xq FSTQ || break; sleep 1; done
  pkill -x FSTQ 2>/dev/null || true
fi

echo "Ставлю в ${DEST}…"
rm -rf "$APP"
ditto "$TMP/mnt/FSTQ.app" "$APP"
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

echo "Готово: FSTQ $VER. Запускаю."
[ "${FSTQ_NO_OPEN:-}" = 1 ] || open "$APP"
