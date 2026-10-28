# Contributing

This started as one person's personal setup for talking to Claude Code while
driving, cleaned up enough to share. PRs and issues are welcome, especially:

- Compatibility fixes for other dictation tools or other macOS versions.
- Better VAD tuning for noisy environments.
- Clearer docs for permission issues, since those are the most common snag.

## Before sending a PR

- Keep changes small and focused — this is a handful of shell/Swift/Python
  scripts, not a framework. Resist adding configuration knobs nobody asked
  for.
- Run the checks you have available: `bash -n` on every shell script,
  `shellcheck` if you have it, `python3 -m py_compile` on the Python script,
  and a `swiftc` build of `bin/wispr-handsfree.swift`.
- Test `install.sh` with `PREFIX` and `SKILLS_DIR` pointed at temp
  directories first, so you don't need to touch your real setup to verify a
  change.
- No telemetry, no network calls beyond installing the one Python dependency
  (`webrtcvad-wheels`). This stays a local, offline tool.

## Reporting a bug

Include your macOS version, whether Accessibility permission was granted,
and the output of the failing command. "Wispr didn't stop listening" and
"nothing was typed" are usually permission or timing issues — check the
README's troubleshooting section first.
