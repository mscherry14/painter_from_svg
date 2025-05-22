<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

A Flutter CLI for generating icon files based on CustomPainter for `.svg` files.
Built to solve personal development challenges.

## Features

In current version:
- parses basic SVG files (supports multiple paths, fill/stroke properties) and generates `.dart` files with classes which extends CustomPainter and paints the icon
    Note: Currently supports a subset of SVG features (no groups, transforms, or basic shapes)
- generates general file with an abstract final class acting as a centralized icon provider and CustomIcon widget for seamless integration into Flutter UIs
  
`CustomIcon` automatically inherits IconThemeData from the build context, applying the same color, size, and styling as standard Flutter icons. This means that
your custom icons work like Flutter’s built-in Icon(), respects IconTheme and ThemeData settings.

## Getting started

### Install

You can run the command in terminal or add dependency to `pubspec.yaml`manually.

```shell
flutter pub add dev:painter_from_svg
```

## Usage

Simply run 
```shell
dart run painter_from_svg:generate_icons 
```
or 
```shell
flutter run painter_from_svg:generate_icons 
```
in the terminal

### Configuration

Default configuration:

- Source: `assets/icons/**.svg`
- Output: `lib/generated/` (`.g.dart` files)
  - `custom_icons.dart` (main registry)
  - `icons/` folder (individual painters)
  
You can customize build options via `icons.yaml` in project root or with CLI flags/arguments.
CLI flags and argument will override `icons.yaml` values.

#### Customizable settings:

- `.svg` source folder
- output folder for generation
- name of folder with individual painters
- include or not `.g.` in extension

##### For `build.yaml`:

- `input: <path-from-project-root>` -- for `.svg` source folder
- `output: <path-from-project-root>` -- for output folder 
- `output-icons: <folder-name>` -- name of folder with individual painters
- `gen: true` or `gen: false` for include or not `.g.` in extension

##### For CLI:

- `-i <path-from-project-root>` or `--input <path-from-project-root>` -- for `.svg` source folder
- `-o <path-from-project-root>` or `--output <path-from-project-root>` -- for output folder
- `-f <folder-name>` or `--output-icons <folder-name>` -- name of folder with individual painters
- `-g, --[no-]gen` flags for include or not `.g.` in extension
- `-h, --help` flag for help message

## Additional information

Built to solve personal development challenges. You don't need this generator more than `dev`-dependency.
I don't know yet about future maintenance of this package. 
