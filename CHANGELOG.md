## 0.0.1

### Initial release

- CLI tool to convert SVG files into `CustomPainter`-based Dart files.
- Supports `viewBox`, `width`, and `height` parsing to calculate size and offsets.
- Generates individual Dart files for each SVG icon.
- Aggregates generated painters into a `CustomIcons` class with static accessors.
- Includes reusable `CustomIcon` widget that adapts to `IconTheme`.
- Supports basic SVG attributes: `fill`, `stroke`, `stroke-width`, `stroke-linecap`, `stroke-linejoin`.
- Configurable via command-line arguments and optional `icons.yaml` file.

## 0.0.2

### Added

- Documentation comments.
- Minor formatting and code style improvements across the package.

### Fixed

- Lint issues related to missing documentation and formatting.