# AndroidPocketTerm

A rebranded fork of [Termux](https://github.com/termux/termux-app) (package `com.k1llagt.androidpocketterm`),
built entirely by GitHub Actions: custom bootstraps compiled for the new prefix, then the app is rebranded,
built, signed, and published as a release together with its full modified source.

Licensed under GPLv3, like upstream Termux. Not affiliated with the Termux project.

## Use
    bash setup.sh   # first time: login, signing key, repo, secrets, starts the build
    bash fetch.sh   # later: download and install the newest build

Rebuild any time from the Actions tab or with `gh workflow run build.yml`.
