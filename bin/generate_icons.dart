import 'dart:io';
import 'package:args/args.dart';
import 'package:painter_from_svg/generate_custom_icons_file.dart';
import 'package:painter_from_svg/generate_single_icon.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart'; // обязательно

/// Entry point for the SVG-to-Dart icon generator CLI tool.
///
/// Accepts command-line options or values from `icons.yaml`.
/// Generates Dart files for each SVG icon and an aggregated
/// `custom_icons.dart` file with accessors and a `CustomIcon` widget.
///
/// Options:
///   - `--input`, `-i`: Input folder with SVG files (default: `assets/icons`)
///   - `--output`, `-o`: Output folder for generated Dart files (default: `lib/generated`)
///   - `--output-icons`, `-f`: Subfolder in output folder to store icon files (default: `icons`)
///   - `--[no-]gen`, `-g`: Whether to include `.g.dart` suffix in filenames (default: true)
///   - `--help`, `-h`: Print help message
Future<void> main(List<String> args) async {
  final parser =
      ArgParser()
        ..addOption('input', abbr: 'i', help: 'Input folder with SVG files')
        ..addOption(
          'output',
          abbr: 'o',
          help: 'Output folder for code generation',
        )
        ..addOption(
          'output-icons',
          abbr: 'f',
          help: 'Name of svg-to-dart files folder into the output folder',
        )
        ..addFlag(
          'gen',
          abbr: 'g',
          negatable: true,
          help:
              'Provide --no-gen if you want to generate files without .g. in extension',
        )
        ..addFlag(
          'help',
          abbr: 'h',
          negatable: false,
          help: 'Show this help message',
        );

  final results = parser.parse(args);

  if (results['help'] as bool) {
    stdout.writeln(parser.usage);
    exit(0);
  }

  final config = _loadYamlConfig();

  final bool isGenExt = results['gen'] ?? config['gen'] ?? true;
  final inputFolder = results['input'] ?? config['input'] ?? 'assets/icons';
  final outputFolder = results['output'] ?? config['output'] ?? 'lib/generated';
  final outputIconsPartFolder =
      results['output-icons'] ?? config['output-icons'] ?? 'icons';

  final outputIconsFolder = p.join(outputFolder, outputIconsPartFolder);
  final customIconsPath = p.join(
    outputFolder,
    isGenExt ? "custom_icons.g.dart" : "custom_icons.dart",
  );

  final svgFiles = await _findSvgFiles(inputFolder);

  Directory(outputIconsFolder).createSync(recursive: true);

  final classNames = <String>[];
  final fileNames = <String>[];

  for (final svgFile in svgFiles) {
    final content = await svgFile.readAsString();
    final className = _getClassName(svgFile);
    final dartContent = generateIconFile(content, className);

    if (dartContent != null) {
      final outputPath = p.join(
        outputIconsFolder,
        '${p.basenameWithoutExtension(svgFile.path)}_icon.${isGenExt ? 'g.' : ''}dart',
      );
      File(outputPath).writeAsStringSync(dartContent);
      classNames.add(className);
      fileNames.add(p.basename(outputPath));
    }
  }

  final customIconsContent = generateCustomIconsFile(
    classNames: classNames,
    filesNames: fileNames,
    folder: outputIconsPartFolder,
  );

  File(customIconsPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(customIconsContent);

  stdout.writeln('Иконки сгенерированы:');
  stdout.writeln(' - Файлы с иконками: $outputFolder');
  stdout.writeln(' - Общий файл класса: $customIconsPath');
}

/// Finds all `.svg` files in the given [folder] using a glob pattern.
Future<List<File>> _findSvgFiles(String folder) async {
  final glob = Glob('$folder/*.svg');
  final matches = <File>[];

  await for (final entity in glob.list()) {
    if (entity is File) {
      matches.add(entity as File);
    }
  }

  return matches;
}

/// Loads configuration from a local `icons.yaml` file if it exists.
///
/// Returns a map of values that can override CLI arguments.
Map<String, dynamic> _loadYamlConfig() {
  final file = File('icons.yaml');
  if (!file.existsSync()) return {};
  final content = file.readAsStringSync();
  final yamlMap = loadYaml(content);
  return Map<String, dynamic>.from(yamlMap);
}

/// Converts a given [file] into a valid Dart class name in PascalCase.
///
/// Removes invalid characters and leading digits.
String _getClassName(File file) {
  final sanitizedName = p
      .basenameWithoutExtension(file.path)
      .split('.')[0]
      .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_') // Заменяем не-ASCII на _
      .replaceAll(RegExp(r'_+'), '_') // Убираем дубли _
      .replaceAll(RegExp(r'^[0-9]+'), ''); // Удаляем ведущие цифры

  final pascalCase = sanitizedName
      .split('_')
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            part.length > 1
                ? part[0].toUpperCase() + part.substring(1).toLowerCase()
                : part[0].toUpperCase(),
      )
      .join('');
  return pascalCase;
}
