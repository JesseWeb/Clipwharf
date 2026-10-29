# CLAUDE.md

This repository's agent instructions live in **[AGENTS.md](AGENTS.md)**.

Read it before doing anything: it covers prerequisites, the build/install
sequence, how the Accessibility permission is granted and repaired, how to
verify auto-paste, and the rules for changing the project (no committed
binaries, no hard-coded signing identity, no telemetry, keep the README's six
languages in sync).

Quick summary for this repo:

- Build: `./scripts/make-app.sh release` → `dist/Clipwharf.app`
- Install: copy to `/Applications/Clipwharf.app`, then `open` it
- Test: `swift test` (31 core tests)
- Never commit `dist/`, `.build/`, `.app`, `.icns`, or signing material
