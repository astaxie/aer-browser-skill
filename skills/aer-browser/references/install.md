# Install or locate AER

Read when the launcher cannot find the application, the CLI/guide is missing,
or the user asks to install the skill. Normal tasks start with the live guide.

## Prerequisites

This package targets the macOS AER application with its bundled native CLI.
AER must be installed and running to expose browser sessions. Installing the
skill alone does not install a browser. Use an AER build supplied by the user
or the project's verified distribution; this skill does not invent a download
URL or remove Gatekeeper protection. Windows and Linux are not supported by
this launcher/application contract.

## Install into Codex

From the unpacked skill folder, run:

```bash
bash scripts/install-codex.sh --app "/absolute/path/to/AER.app"
```

The default destination is `${CODEX_HOME:-$HOME/.codex}/skills/aer-browser`.
An optional `--dest` selects another absolute skill directory ending in
`/aer-browser`. This installs the instructions, references and launchers, and
saves the app location as plain text in `local-app-path`. It does not copy the
application or any browser profile. An existing aer-browser skill is backed up
outside the skills directory before replacement. Other skills are untouched.

If AER is installed in `/Applications/AER.app` or `~/Applications/AER.app`,
`--app` can be omitted. On this machine a development build may instead live
under a repository's `release/current/AER.app`; select that path explicitly.
The skill is available on the next Codex turn. Invoke it as `$aer-browser`.

## Application discovery

The launcher selects the native CLI in this order:

1. An explicit absolute `AER_BROWSER_APP` environment variable.
2. The app path saved by installation in `local-app-path`.
3. An `aer-browser` executable on PATH, resolving symlinks to its app bundle.
4. `/Applications/AER.app` or `~/Applications/AER.app`; ambiguous installs fail.

A selected but missing app causes an error rather than silently switching to
another installation. Temporarily choose an app with:

```bash
AER_BROWSER_APP="/absolute/path/to/AER.app" \
  bash "<this-skill-directory>/scripts/aer-browser.sh" --resolve
```

For a lasting change, rerun `install-codex.sh --app` from the source or installed
skill folder. No `.zshrc` edit or global symlink is required.

## Verify readiness

```bash
bash "<this-skill-directory>/scripts/aer-browser.sh" --resolve
bash "<this-skill-directory>/scripts/aer-browser.sh" skill
bash "<this-skill-directory>/scripts/aer-browser.sh" profiles
```

`--resolve` prints the native executable path. `skill` must succeed and end with
the completeness marker. `profiles` must return JSON; an empty array means no
running AER session was found, not that installation failed. Open the selected
application normally and retry. Do not import data, clear profiles, change the
default browser or modify AI settings as an installation workaround.

If `skill` is unknown or the app lacks the CLI/resources, report that the AER
build needs updating. AER currently has no documented `upgrade` CLI command;
use the user's normal application update process, then reread the live guide.
Return to the user's original browser task after setup.
