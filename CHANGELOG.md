# Changelog

All notable changes to this project appear in this file.
The format follows Keep a Changelog. Version numbers follow SemVer.

## [0.0.3] - 2026-10-14

### Added

- App icon (anvil with JSON braces) wired through the asset catalog.
- ASM JSON pane uses a native scroll view so the mouse wheel scrolls it.

## [0.0.2] - 2026-10-14

### Added

- Syntax highlight for ASM JSON viewer (keys, strings, numbers, literals).
- App delegate brings the window forward on launch.

## [0.0.1] - 2026-10-14

### Added

- Core engine: CSV parser (`,`, `;`, tab), date parser, synonym map, value checks.
- Fingerprint engine with parallel parse of 300 files in under 5 seconds.
- Mapper engine with auto-map of vendor headers to ASM paths.
- ASM JSON builder and 5-case VERA generator per file.
- VERA CSV, traceability matrix, PDF report, and ASM ZIP exports.
- Mac UI: 3-panel window, dashboard with charts, VERA table, drag-drop import.
- Watch Folder auto-convert for new CSV files.
- Test suite with dataset acceptance tests.
- Versioning: VERSION file, in-app version label, and this changelog.
