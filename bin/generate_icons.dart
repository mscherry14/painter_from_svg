import 'dart:io';
import 'package:args/args.dart';
import 'package:painter_from_svg/generate_custom_icons_file.dart';
import 'package:painter_from_svg/generate_single_icon.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart'; // обязательно

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
          help: 'Provide --no-gen if you want to generate files without .g. in extension',
        )
        ..addFlag(
          'help',
          abbr: 'h',
          negatable: false,
          help: 'Show this help message',
        );

  final results = parser.parse(args);

  if (results['help'] as bool) {
    print(parser.usage);
    exit(0);
  }

  final config = _loadYamlConfig();

  final bool isGenExt = results['gen'] ?? config['gen'] ?? true;
  final inputFolder = results['input'] ?? config['input'] ?? 'assets/icons';
  final outputFolder = results['output'] ?? config['output'] ?? 'lib/generated';
  final outputIconsPartFolder =
      results['output-icons'] ?? config['output-icons'] ?? 'icons';


  final outputIconsFolder = p.join(outputFolder, outputIconsPartFolder);
  final customIconsPath = p.join(outputFolder, isGenExt ? "custom_icons.g.dart" : "custom_icons.dart");

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

  print('Иконки сгенерированы:');
  print(' - Файлы с иконками: $outputFolder');
  print(' - Общий файл класса: $customIconsPath');
}

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

Map<String, dynamic> _loadYamlConfig() {
  final file = File('icons.yaml');
  if (!file.existsSync()) return {};
  final content = file.readAsStringSync();
  final yamlMap = loadYaml(content);
  return Map<String, dynamic>.from(yamlMap);
}

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
