#!/usr/bin/env bash
# Rebrands a termux-app checkout.
# Usage: rebrand.sh "App Name" com.your.package [termux-app-dir]
set -euo pipefail
APP_NAME="$1"; PKG="$2"; DIR="${3:-termux-app}"
cd "$DIR"

echo "==> Renaming app to $APP_NAME ($PKG)"
mapfile -t files < <(grep -rlE 'applicationId|TERMUX_PACKAGE_NAME|TERMUX_APP_NAME|targetPackage' \
  --include='*.gradle' --include='*.xml' --include='TermuxConstants.java' . || true)
for f in "${files[@]}"; do
  sed -i -E \
    -e "s/(applicationId[[:space:]]+)\"com\.termux\"/\1\"$PKG\"/" \
    -e "s/(TERMUX_PACKAGE_NAME[^\"]*)\"com\.termux\"/\1\"$PKG\"/" \
    -e "s/(TERMUX_APP_NAME[^\"]*)\"Termux\"/\1\"$APP_NAME\"/" \
    -e "s/(android:targetPackage=)\"com\.termux\"/\1\"$PKG\"/" \
    "$f"
done

echo "==> Pointing build at the custom bootstraps"
for arch in aarch64 arm i686 x86_64; do
  zip="app/src/main/cpp/bootstrap-$arch.zip"
  [ -f "$zip" ] || { echo "Missing $zip"; exit 1; }
  sha="$(sha256sum "$zip" | cut -d' ' -f1)"
  sed -i -E "s/(downloadBootstrap\(\"$arch\",[[:space:]]*\")[0-9a-f]{64}/\1$sha/g" app/build.gradle
  echo "   $arch  $sha"
done

echo "==> Checking"
grep -q "applicationId \"$PKG\"" app/build.gradle || { echo "applicationId was not updated"; exit 1; }
grep -rq "\"$PKG\"" termux-shared/src/main/java || { echo "TermuxConstants was not updated"; exit 1; }
echo "Leftover exact \"com.termux\" strings (namespace lines are expected):"
grep -rnE '"com\.termux"' --include='*.gradle' --include='*.xml' --include='*.java' . | grep -v namespace || echo "   none"
