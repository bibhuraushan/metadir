# MetaDir macOS app

MetaDir is a Swift-first macOS viewer for `.metadir.yml` files. The GUI, Finder Sync extension, and Finder Quick Action are contained in this directory and remain independent from the command-line tool in `../cli/`.

The app reads metadata only after the user chooses a folder or invokes a Finder command. It does not recursively scan folders, monitor file contents, upload metadata, or open metadata links; links are copy-only.

## Runtime call sequence

### Choose Folder in the app

1. `MetaDirApp` creates the shared `MetadataViewModel` and displays `ContentView`.
2. `ContentView.chooseFolder()` presents `NSOpenPanel` for one directory.
3. The selected security-scoped folder URL is passed to `MetadataViewModel.open(folderURL:)`.
4. `MetadataViewModel` starts read-only scoped access and calls `MetaDirMetadataLoader.load(from:)`.
5. `MetaDirMetadataLoader` checks the directory, filename, 1 MiB limit and UTF-8 encoding before decoding YAML with Yams.
6. The decoded `MetaDirMetadata` is published to SwiftUI and rendered by `MetadataDetailView`; failures are rendered by `MetadataErrorView`.

### Direct Finder Sync menu

1. `FinderSync` starts inside Finder and registers the roots compiled into `GeneratedLocalRoots.swift`.
2. Finder calls `menu(for:)` when the user opens a context menu inside one of those roots.
3. Selecting **Show Folder Metadata** calls `showMetadata(_:)`.
4. The extension asks `NSWorkspace` to open the selected folder with the containing MetaDir app.
5. SwiftUI receives the file URL through `MetaDirApp.onOpenURL` and passes it to `MetadataViewModel`.
6. The host app reads and displays the YAML locally.

The direct menu uses a machine-specific, read-only absolute-path entitlement generated from `LocalMonitoredRoots.yml`. Each person building the source must generate their own local configuration.

### Finder Quick Action

1. Finder sends the selected item to `QuickActionRequestHandler.beginRequest(with:)`.
2. The handler verifies that exactly one directory was supplied.
3. It temporarily accesses the selected security-scoped URL.
4. It asks `NSWorkspace` to open that folder with MetaDir.
5. The host app follows the same loading and rendering sequence described above.

### Local-root configuration

1. Edit `LocalMonitoredRoots.yml` and list one or more existing absolute directories.
2. Run `./Scripts/configure-local-roots.sh` from this directory.
3. The script validates every directory and regenerates `GeneratedLocalRoots.swift` and `MetaDirFinderSync.entitlements`.
4. Rebuild the app so the roots and their read-only permissions are compiled into Finder Sync.

## Project layout and file responsibilities

### Host app: `MetaDir/`

- `MetaDirApp.swift` — Defines the SwiftUI application, fixed-size main window, settings scene and incoming folder-URL handler.
- `ContentView.swift` — Provides the main toolbar, folder picker and state-based selection between empty, metadata and error views.
- `MetadataViewModel.swift` — Coordinates security-scoped access, metadata loading and published UI state.
- `MetadataDetailView.swift` — Renders metadata cards, copy-only links, file reveal actions and error presentation.
- `MonitoredFolderStore.swift` — Stores host-app security bookmarks used by the settings interface; it does not configure the unsigned Finder extension.
- `SettingsView.swift` — Displays the monitored-folder settings UI retained for future signed App Group integration.
- `MetaDir.entitlements` — Enables the app sandbox and read-only access to folders selected by the user.
- `Info.plist` — Declares the application identity, minimum macOS version and its ability to view folder URLs.

### Shared framework: `MetaDirCore/`

- `MetaDirCore.swift` — Defines shared filenames, preference keys and notification names.
- `MetaDirMetadata.swift` — Defines the Codable metadata schema, links and custom fields.
- `MetaDirMetadataLoader.swift` — Performs bounded local file reading, UTF-8 validation, YAML decoding and schema-version validation.
- `MetaDirRequest.swift` — Encodes and decodes the legacy path-only custom request format retained for compatibility tests.
- `MonitoredRootRules.swift` — Normalizes paths and determines whether one folder contains another.

### Finder Sync extension: `MetaDirFinderSync/`

- `FinderSync.swift` — Registers configured roots, supplies the direct Finder command and opens the selected folder in the host app.
- `GeneratedLocalRoots.swift` — Contains the compiled root URLs generated from `LocalMonitoredRoots.yml` and should not be edited manually.
- `MetaDirFinderSync.entitlements` — Contains the generated read-only absolute-path exceptions for the configured local roots.
- `Info.plist` — Declares the `com.apple.FinderSync` extension and its principal class.

### Quick Action extension: `MetaDirQuickAction/`

- `QuickActionRequestHandler.swift` — Validates a Finder folder selection and opens it in the containing app without reading or transferring metadata.
- `MetaDirQuickAction.entitlements` — Enables sandboxed, read-only access to the folder supplied by Finder.
- `Info.plist` — Declares the Finder service, its folder-only activation predicate and extension entry point.

### Tests and fixtures

- `MetaDirTests/MetaDirCoreTests.swift` — Tests valid and invalid YAML, versions, size limits, path containment and request encoding.
- `TestFixtures/MetaDirTest/.metadir.yml` — Supplies the primary valid metadata example used for manual Finder testing.
- `TestFixtures/MetaDirTest/data/sample.txt` — Confirms ordinary folder contents are ignored by the metadata reader.
- `TestFixtures/MetaDirTest/notes/readme.txt` — Provides another unrelated file for manual no-scan verification.
- `TestFixtures/MalformedMetaDirTest/.metadir.yml` — Supplies malformed YAML for manual error testing.
- `TestFixtures/QuickActionTest/.metadir.yml` — Supplies valid metadata for testing the Quick Action outside a configured direct-menu root.
- Other directories under `TestFixtures/MetaDirTest/` — Cover missing, malformed, unsupported and nested metadata scenarios during manual testing.

### Configuration, project and output

- `LocalMonitoredRoots.yml` — Is the human-edited list of absolute Finder Sync roots for the current build machine.
- `Scripts/configure-local-roots.sh` — Validates the YAML path list and generates matching Swift and entitlement files.
- `MetaDir.xcodeproj/project.pbxproj` — Defines targets, source membership, build settings, embedding and signing configuration.
- `MetaDir.xcodeproj/xcshareddata/xcschemes/MetaDir.xcscheme` — Defines the shared build, run and test scheme.
- `MetaDir.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` — Pins the exact Yams package version used by the build.
- Files under `xcuserdata/` — Store local Xcode UI state and should not be treated as project source.
- `dist/legacy/FolderMeta-1.0-universal.dmg` — Is the preserved pre-rename package and must not be treated as the current MetaDir build.

## Build locally

```text
cd /Users/bjha/agentic_codes/macapp/app
./Scripts/configure-local-roots.sh
open MetaDir.xcodeproj
```

In Xcode, select the internal **MetaDir** scheme and **My Mac**, then build or run. Enable the two MetaDir extensions under **System Settings → General → Login Items & Extensions**, and relaunch Finder after changing extension builds.

## Enable Finder extensions from Terminal

After copying `MetaDir.app` to `/Applications` and launching it once, enable both embedded extensions:

```text
pluginkit -e use -i com.example.MetaDir.FinderSync
pluginkit -e use -i com.example.MetaDir.QuickAction
killall Finder
```

Verify Finder Sync:

```text
pluginkit -m -A -D -v -i com.example.MetaDir.FinderSync
```

A leading `+` in the output means the extension is enabled. Finder should also be running the extension after it is first needed:

```text
pgrep -alf MetaDirFinderSync
```

The direct **Show in MetaDir** menu is supplied by Finder Sync and appears only within a root compiled through `LocalMonitoredRoots.yml`, including its subfolders. The Quick Action is registered separately and can operate on folder selections outside those roots.

macOS normally preserves the enabled setting across rebuilds when the bundle identifier remains unchanged. If the extension bundle identifier changes, macOS treats it as a new extension and it must be enabled once under its new identifier.

The current local configuration monitors:

```text
/Users/bjha/research/
```

## Metadata schema

```yaml
version: 1
title: Example Project
summary: Human-readable project description.
owner: Example Owner
status: active
created: "2026-10-31"
updated: "2026-10-31"
tags: [swift, metadata]
links:
  - label: Website
    url: https://example.com
notes: Optional longer notes.
custom:
  priority: High
```

Only schema version `1` is supported. Files must be UTF-8 and no larger than 1 MiB.

## Security and distribution

- The app and both extensions are sandboxed and have no network entitlement.
- Metadata links can only be copied; MetaDir never opens them.
- Local Finder roots are compiled as narrow read-only exceptions and must never be expanded to `/Users` or `/`.
- An ad-hoc build can be shared for manual installation, but another Mac will display Gatekeeper warnings.
- Warning-free public distribution requires Developer ID signing and Apple notarization.
