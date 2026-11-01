# MetaDir workspace

> This app was built with the help of OpenAI/ChatGPT Model 5.6 Sol.

This workspace keeps the graphical macOS app and command-line tool independent.

- `app/` — Contains the complete SwiftUI app, Finder extensions, shared app framework, tests, fixtures, local-root configuration and app distribution output.
- `cli/` — Contains the independent Swift command-line metadata editor and validator.

Open `app/README.md` for the GUI architecture, call sequence, security model and per-file guide. Open `cli/README.md` for CLI commands, installation and its package structure.

## Build from Terminal

`build.zsh` is the single entry point for command-line builds:

```text
./build.zsh          # build both app and CLI
./build.zsh app      # build only MetaDir.app
./build.zsh cli      # build only the metadir command
./build.zsh test     # run both test suites
./build.zsh help
```

The app is written to `app/build/Build/Products/Release/MetaDir.app`. The CLI is written to `cli/.build/release/metadir`.

The builder shows colored stage progress in an interactive terminal and keeps the full compiler output in log files under `app/build/logs/`, `app/build-tests/logs/`, and `cli/.build/logs/`. If a stage fails, it prints the final 40 log lines and the full log location. Run with `NO_COLOR=1` when plain output is preferred.
