# AlloForge Mac

Native macOS app. It forges crazy vendor CSV files into Allotrope ASM JSON plus VERA reports. It runs offline.

## Open the Project

1. Install Xcode 15 or later.
2. Open `Package.swift` in Xcode.
3. Select the `AlloForge` scheme.
4. Press Cmd+R to run.

Target: macOS 14 or later. Bundle ID: `com.ntufar.alloforge`.

## Use the App

1. Drop CSV files, a ZIP file, or a folder onto the main window.
2. Select a file in the sidebar to inspect it.
3. Use the center tabs to switch between the vendor table and the mapping editor.
4. Press Cmd+D to open the dashboard.
5. Use the Export menu to save VERA CSV, trace matrix, PDF report, or ASM ZIP.
6. Use File menu Watch Folder to auto-convert new CSV files.

## Test the Engine

Run this command from the project root:

```sh
swift test --filter AlloForgeCoreTests
```

The suite parses `data/crazy_vendor_dataset.zip` (300 files) in under 5 seconds. It checks delimiters, `Acid.` mapping to pH, pH range flags, 1500 VERA rows, and ASM JSON output.

## Layout

- `Sources/AlloForgeCore`: parser, fingerprint engine, mapper, ASM builder, VERA generator. No external deps.
- `Sources/AlloForge`: SwiftUI app (3-panel window, dashboard, exports, watch folder).
- `Tests/AlloForgeCoreTests`: unit plus dataset acceptance tests.
- `data/crazy_vendor_dataset.zip`: 300 sample vendor files.
- `docs/AlloForge-MAC-SPEC.md`: product spec.

## Versioning

Current version: see `VERSION` file. The app shows it in the status bar.

On each commit, increment the patch version:

1. Update `VERSION` (example: `0.0.1` to `0.0.2`).
2. Update `AppVersion.current` in `Sources/AlloForgeCore/AppVersion.swift` to the same value.
3. Add an entry to `CHANGELOG.md`.
4. Run `swift test` to confirm the version sync test passes.

## Notes

- V2 scope (not in MVP): menu bar extra, Quick Look extension, SwiftData persistence, ML mapping.
