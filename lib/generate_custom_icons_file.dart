import 'package:dart_style/dart_style.dart';
import 'package:code_builder/code_builder.dart';
import 'package:path/path.dart' as p;

/// Generates a Dart file containing a class `CustomIcons` with static icon painters
/// and a `CustomIcon` widget that can be used to render them.
///
/// Each icon painter is expected to be a class with the name `<ClassName>IconPainter`
/// that implements `CustomPainter`.
///
/// [classNames] is a list of base class names (e.g. "Search") that map to painters like `SearchIconPainter`.
/// [filesNames] is a list of Dart files to import where these painters are defined.
/// [folder] is an optional subfolder where those files are located.
///
/// Returns the source code as a formatted Dart string.
String generateCustomIconsFile({
  required List<String> classNames,
  required List<String> filesNames,
  String folder = '',
}) {
  final List<Directive> iconsImports = [];
  for (final fName in filesNames) {
    if (folder.isNotEmpty) {
      iconsImports.add(Directive.import(p.join(folder, fName)));
    } else {
      iconsImports.add(Directive.import(fName));
    }
  }

  final iconFuncParams = [
    Parameter(
      (b) =>
          b
            ..required = true
            ..type = refer("double")
            ..name = "size"
            ..named = true,
    ),
    Parameter(
      (b) =>
          b
            ..required = true
            ..type = refer("Color")
            ..name = "color"
            ..named = true,
    ),
  ];

  final List<Method> iconMethods = [];
  for (final cName in classNames) {
    final mName = cName[0].toLowerCase() + cName.substring(1);

    iconMethods.add(
      Method(
        (m) =>
            m
              ..static = true
              ..returns = refer('CustomPainter')
              ..optionalParameters.addAll(iconFuncParams)
              ..name = mName
              ..lambda = true
              ..body =
                  refer("${cName}IconPainter").newInstance([], {
                    "dimension": refer('size'),
                    "color": refer('color'),
                  }).code,
      ),
    );
  }

  final iconsDataClass = Class(
    (a) =>
        a
          ..name = "CustomIcons"
          ..abstract = true
          ..modifier = ClassModifier.final$
          ..constructors.add(Constructor((b) => b..name = '_'))
          ..methods.addAll(iconMethods),
  );

  final iconDrawerBuildFunc = Method(
    (m) =>
        m
          ..name = 'build'
          ..returns = refer("Widget")
          ..requiredParameters.add(
            Parameter(
              (p) =>
                  p
                    ..name = "context"
                    ..type = refer("BuildContext"),
            ),
          )
          ..annotations.add(refer('override'))
          ..body = Code("""
            final IconThemeData iconTheme = IconTheme.of(context).merge(style);

    return SizedBox.square(
      dimension: iconTheme.size,
      child: Center(
        child: CustomPaint(
          painter: iconPainter(
            size: iconTheme.size ?? 24.0,
            color:
            iconTheme.color ??
                Theme.of(context).textTheme.bodyMedium?.color ??
                Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
        """),
  );

  final iconDrawerClass = Class(
    (c) =>
        c
          ..name = "CustomIcon"
          ..extend = refer("StatelessWidget")
          ..methods.add(iconDrawerBuildFunc)
          ..constructors.add(
            Constructor(
              (b) =>
                  b
                    ..constant = true
                    ..optionalParameters.addAll([
                      Parameter(
                        (b) =>
                            b
                              ..toSuper = true
                              ..name = "key"
                              ..named = true,
                      ),
                      Parameter(
                        (b) =>
                            b
                              ..toThis = true
                              ..name = "style"
                              ..named = true,
                      ),
                      Parameter(
                        (b) =>
                            b
                              ..required = true
                              ..toThis = true
                              ..name = "iconPainter"
                              ..named = true,
                      ),
                    ]),
            ),
          )
          ..fields.addAll([
            Field(
              (b) =>
                  b
                    ..type = FunctionType(
                      (f) =>
                          f
                            ..returnType = refer("CustomPainter")
                            ..namedRequiredParameters.addAll({
                              'size': refer('double'),
                              'color': refer('Color'),
                            }),
                    )
                    ..name = "iconPainter"
                    ..modifier = FieldModifier.final$,
            ),
            Field(
              (b) =>
                  b
                    ..type = refer("IconThemeData?")
                    ..name = "style"
                    ..modifier = FieldModifier.final$,
            ),
          ]),
  );

  final lib = Library(
    (b) =>
        b
          ..directives.addAll([
            Directive.import('package:flutter/material.dart'),
            ...iconsImports,
          ])
          ..body.addAll([iconsDataClass, iconDrawerClass]),
  );
  final emitter = DartEmitter();

  return DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format('${lib.accept(emitter)}');
}
