# MetaDir CLI

`metadir` is an independent Swift command-line tool for creating, editing, validating, and displaying `.metadir.yml`. It does not depend on the MetaDir GUI app or Finder extensions.

## Commands

```text
metadir init <folder> [--title <title>]
metadir edit <folder>
metadir validate <folder>
metadir show <folder>
metadir help
```

- `init` creates a valid metadata document and refuses to overwrite an existing file.
- `edit` opens a temporary copy in `$VISUAL`, `$EDITOR`, or the default macOS text editor; it updates the real file only after successful validation.
- `validate` checks the file type, 1 MiB size limit, UTF-8 encoding, YAML syntax, schema version, and nonempty title.
- `show` prints validated metadata without opening links or accessing the network.

Metadata symlinks are rejected so a command targeting one folder cannot silently read or overwrite a file elsewhere.

## Build and test

```text
cd /Users/bjha/agentic_codes/macapp/cli
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build -c release
```

The release executable is produced at `.build/release/metadir`.
The explicit `DEVELOPER_DIR` uses Xcode's complete Swift toolchain even when macOS is currently configured to use the standalone Command Line Tools.

## Install manually

Install for the current user without administrator access:

```text
mkdir -p "$HOME/.local/bin"
cp .build/release/metadir "$HOME/.local/bin/metadir"
```

Ensure `$HOME/.local/bin` is present in `PATH`. Alternatively, copy the binary to `/usr/local/bin/metadir` with administrator approval.

## Examples

```text
metadir init /Users/bjha/research/example --title "Example Research"
metadir validate /Users/bjha/research/example
metadir show /Users/bjha/research/example
EDITOR=vim metadir edit /Users/bjha/research/example
```

## Package structure

- `Package.swift` defines the independent executable, reusable CLI library, tests, and pinned Yams dependency.
- `Sources/MetaDirCLIKit/MetaDirMetadata.swift` defines the metadata schema.
- `Sources/MetaDirCLIKit/MetaDirMetadataStore.swift` implements safe creation, bounded reading, validation, and atomic replacement.
- `Sources/MetaDirCLIKit/MetadataEditor.swift` manages temporary-copy editing and validation-before-save.
- `Sources/MetaDirCLIKit/MetadataRenderer.swift` formats metadata for terminal output.
- `Sources/metadir/main.swift` contains the `metadir` executable entry point, parses commands, prints results, and maps failures to a nonzero exit status.
- `Tests/MetaDirCLIKitTests/MetaDirMetadataStoreTests.swift` covers creation, overwrite protection, validation, safe replacement, and rendering.
