# MetaDir Agent Guide

## Project layout

- `app/` contains the SwiftUI macOS app, MetaDirCore framework, Finder Sync extension, Finder Quick Action, tests, and fixtures.
- `cli/` contains the independent Swift Package Manager command-line tool.
- `build.zsh` is the supported entry point for builds and tests.

## Build and test

Run commands from the repository root:

```text
./build.zsh app
./build.zsh cli
./build.zsh test
./build.zsh
```

Use the complete Xcode toolchain at `/Applications/Xcode.app/Contents/Developer`. Keep the app and CLI independently buildable.

## Metadata contract

- Metadata is stored in `.metadir.yml`.
- Only schema version `1` is supported.
- Metadata must be UTF-8 and no larger than 1 MiB.
- Preserve validation, symbolic-link protection, and safe-write behavior.

## Privacy and security

- MetaDir must not access the network.
- Metadata links are copy-only and must never be opened automatically.
- Do not recursively scan folder contents.
- Keep the app and extensions sandboxed.
- Finder root entitlements must remain read-only and narrowly scoped. Never configure `/` or `/Users` as a monitored root.

## Finder integration

- Edit `app/LocalMonitoredRoots.yml` to change direct-menu roots.
- Run `app/Scripts/configure-local-roots.sh` after changing roots.
- Do not manually edit `app/MetaDirFinderSync/GeneratedLocalRoots.swift` or generated absolute-path entitlements.
- The direct Finder menu applies only to configured roots and their descendants. The Quick Action is registered separately.

## Development practices

- Keep Swift code simple, readable, and Swift-first.
- Make focused changes and preserve existing architecture unless a change clearly requires restructuring.
- Add or update focused tests for behavior changes.
- Run `./build.zsh test` and the relevant Release build before considering a change complete.
- Do not edit generated build products under `app/build/`, `app/build-tests/`, or `cli/.build/`.
