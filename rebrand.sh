#!/usr/bin/env bash
# Rebrands a termux-app checkout (app side only; bootstraps are patched separately).
# Usage: rebrand.sh "App Name" com.newpkg [termux-app-dir]
set -euo pipefail
APP_NAME="$1"; PKG="$2"; DIR="${3:-termux-app}"
cd "$DIR"

# Package ID: namespace stays com.termux (Java code), applicationId becomes the new ID
grep -qE "^[[:space:]]*applicationId" app/build.gradle \
  || sed -i -E "s/^([[:space:]]*)(manifestPlaceholders\.TERMUX_PACKAGE_NAME)/\1applicationId \"$PKG\"\n\1\2/" app/build.gradle
sed -i -E \
  -e "s/(applicationId[[:space:]]+)\"com\.termux\"/\1\"$PKG\"/" \
  -e "s/(manifestPlaceholders\.TERMUX_PACKAGE_NAME = )\"com\.termux\"/\1\"$PKG\"/" \
  -e "s/(manifestPlaceholders\.TERMUX_APP_NAME = )\"Termux\"/\1\"$APP_NAME\"/" \
  app/build.gradle

# Constants the app computes every path from
sed -i -E \
  -e "s/(String TERMUX_PACKAGE_NAME = )\"com\.termux\"/\1\"$PKG\"/" \
  -e "s/(String TERMUX_APP_NAME = )\"Termux\"/\1\"$APP_NAME\"/" \
  termux-shared/src/main/java/com/termux/shared/termux/TermuxConstants.java

# XML entities (package name, prefix path, app name) and launcher shortcuts
for f in $(grep -rl "<!ENTITY" --include=strings.xml app termux-shared); do
  sed -i -E \
    -e "/<!ENTITY/ s/com\.termux/$PKG/g" \
    -e "s/(<!ENTITY TERMUX_APP_NAME )\"Termux\"/\1\"$APP_NAME\"/" "$f"
done
sed -i "s/android:targetPackage=\"com\.termux\"/android:targetPackage=\"$PKG\"/" app/src/main/res/xml/shortcuts.xml

# Checks
grep -q "applicationId \"$PKG\"" app/build.gradle || { echo "applicationId not set"; exit 1; }
grep -q "TERMUX_PACKAGE_NAME = \"$PKG\"" app/build.gradle || { echo "manifest placeholder not set"; exit 1; }
grep -q "TERMUX_PACKAGE_NAME = \"$PKG\"" termux-shared/src/main/java/com/termux/shared/termux/TermuxConstants.java || { echo "TermuxConstants not set"; exit 1; }
if grep -rnE '<!ENTITY[^>]*com\.termux|targetPackage="com\.termux"' --include=strings.xml --include=shortcuts.xml app termux-shared; then
  echo "Leftover com.termux references above"; exit 1
fi
echo "App rebranded to $APP_NAME ($PKG)"
