#!/usr/bin/env bash
# AndroidPocketTerm one-shot setup. Run in Termux:  bash setup.sh
set -euo pipefail

APP_NAME="AndroidPocketTerm"
REPO_NAME="androidpocketterm"
KEY_ALIAS="androidpocketterm"
KS_DIR="$HOME/.androidpocketterm"
KS="$KS_DIR/release.jks"
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

say "Installing tools"
pkg install -y git gh openjdk-17

say "GitHub login (needs the 'workflow' scope)"
if ! gh auth status >/dev/null 2>&1; then
  gh auth login -h github.com -s workflow
elif ! gh auth status 2>&1 | grep -q workflow; then
  gh auth refresh -h github.com -s workflow
fi
gh auth setup-git
OWNER="$(gh api user -q .login)"
SLUG="$OWNER/$REPO_NAME"

say "Signing key"
if [ -f "$KS" ]; then
  read -rsp "Keystore password: " KS_PASS; echo
else
  mkdir -p "$KS_DIR"
  while :; do
    read -rsp "New keystore password (6+ chars): " KS_PASS; echo
    read -rsp "Repeat: " KS_PASS2; echo
    [ "$KS_PASS" = "$KS_PASS2" ] && [ ${#KS_PASS} -ge 6 ] && break
    echo "Didn't match or too short, try again."
  done
  keytool -genkeypair -keystore "$KS" -storetype PKCS12 -alias "$KEY_ALIAS" \
    -keyalg RSA -keysize 4096 -validity 10000 \
    -storepass "$KS_PASS" -keypass "$KS_PASS" -dname "CN=$APP_NAME"
  echo "Keystore saved to $KS. Back it up: without it you can't ship updates."
fi
keytool -list -keystore "$KS" -storepass "$KS_PASS" >/dev/null || { echo "Wrong keystore password"; exit 1; }

say "Creating repo $SLUG"
cd "$KIT_DIR"
[ -d .git ] || git init -q -b main
git add -A
git -c user.name="$OWNER" -c user.email="$OWNER@users.noreply.github.com" \
  commit -qm "AndroidPocketTerm build pipeline" || true
if gh repo view "$SLUG" >/dev/null 2>&1; then
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$SLUG.git"
  git push -u origin main
else
  gh repo create "$REPO_NAME" --public --source . --remote origin --push \
    --description "$APP_NAME: a rebranded Termux fork (GPLv3)"
fi

say "Storing signing secrets"
base64 -w0 "$KS" | gh secret set KEYSTORE_B64 -R "$SLUG"
printf '%s' "$KS_PASS" | gh secret set KS_PASS -R "$SLUG"
printf '%s' "$KEY_ALIAS" | gh secret set KEY_ALIAS -R "$SLUG"

say "Starting the build"
for i in 1 2 3 4 5 6; do
  gh workflow run build.yml -R "$SLUG" && break
  echo "Waiting for GitHub to register the workflow..."; sleep 10
done
sleep 8
RUN_ID="$(gh run list -R "$SLUG" --workflow build.yml -L 1 --json databaseId -q '.[0].databaseId')"
echo "Progress: https://github.com/$SLUG/actions/runs/$RUN_ID"
echo "First build takes a few hours. You can close Termux and run 'bash fetch.sh' later."
command -v termux-wake-lock >/dev/null && termux-wake-lock || true
gh run watch "$RUN_ID" -R "$SLUG" --exit-status --interval 60
bash "$KIT_DIR/fetch.sh"
