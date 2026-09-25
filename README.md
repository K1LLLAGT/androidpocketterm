# AndroidPocketTerm

A rebranded fork of [Termux](https://github.com/termux/termux-app), package ID `com.t3rmux`.

The package ID is exactly as long as `com.termux`, so the official prebuilt bootstraps are
patched byte-for-byte (`patch_bootstrap.py`) instead of recompiled. GitHub Actions rebrands the
app (`rebrand.sh`), patches the bootstraps, then builds, signs and publishes a release with the
full modified source attached.

Licensed under GPLv3, like upstream Termux. Not affiliated with the Termux project.

## Use
    bash setup.sh   # first time: login, signing key, repo, secrets, starts the build
    bash fetch.sh   # later: download and install the newest build
