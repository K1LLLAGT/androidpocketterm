#!/usr/bin/env bash
# Downloads the newest AndroidPocketTerm APK and opens the installer.
set -euo pipefail
REPO_NAME="androidpocketterm"
SLUG="$(gh api user -q .login)/$REPO_NAME"
DEST="$HOME/storage/downloads"
[ -d "$DEST" ] || DEST="$HOME"

TAG="$(gh release list -R "$SLUG" -L 1 --json tagName -q '.[0].tagName')"
[ -n "$TAG" ] || { echo "No release yet. Check https://github.com/$SLUG/actions"; exit 1; }

gh release download "$TAG" -R "$SLUG" -D "$DEST" --clobber --pattern '*arm64-v8a*.apk' \
  || gh release download "$TAG" -R "$SLUG" -D "$DEST" --clobber --pattern '*universal*.apk'

APK="$(ls -t "$DEST"/androidpocketterm*.apk | head -1)"
echo "Saved: $APK"
command -v termux-open >/dev/null && termux-open "$APK" || true
