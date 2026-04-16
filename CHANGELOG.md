# Changelog

## Unreleased

### Changed
- Extracted the workbench UI styles into `custom-css/islands-dark.css`.
- Switched the custom CSS flow to depend on `be5invis.vscode-custom-css`.
- Simplified install scripts so they only install the native color theme helper and print manual CSS setup.
- Simplified uninstall scripts so they only remove the native color theme helper and print manual cleanup steps.

### Removed
- Removed the `subframe7536.custom-ui-style` install path.
- Removed Antigravity-specific scripts and Nix packaging from the default repo flow.
- Removed the old embedded `custom-ui-style.stylesheet` settings payload.

## 0.0.2 - 2026-02-19

### Fixed
- Fixed chat window colors.
- Fixed explorer pane clipping issues.
- Fixed commit message box clipping.
- Fixed primary sidebar truncation when moved right.
- Fixed selected explorer item styling.
- Fixed terminal border radius mismatch.
- Fixed window controls background color.
- Fixed default tab clipping when opening VS Code with no open files.
- Fixed notebook rendering and code block styling.
- Fixed split terminal overflow.
- Fixed editor tabs overlapping with floating header on Linux.
- Fixed markdown font rendering.

### Added
- Rounded chat input.
- Rounded system dialog styling.
- Configurable CSS variables for radius, spacing, and background colors.
- Larger primary sidebar icons.
- Sticky widget shadow.

### Removed
- Removed highlight boxes in selection windows that could not be rounded reliably.
