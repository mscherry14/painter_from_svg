import 'package:dart_style/dart_style.dart';
import 'package:code_builder/code_builder.dart';
import 'package:painter_from_svg/svg_parsing.dart';
import 'package:xml/xml.dart';

String? generateIconFile(String content, String className) {
  final document = XmlDocument.parse(content);

  final sizes = parseSvgSizeData(document.rootElement);

  if (sizes == null) {
    return null;
  }
  final sizeParams = [
    Field(
          (b) =>
      b
        ..name = "area"
        ..type = refer("double")
        ..modifier = FieldModifier.final$
        ..assignment = Code('${sizes.area}'),
    ),
    Field(
          (b) =>
      b
        ..name = "widthOffset"
        ..type = refer("double")
        ..modifier = FieldModifier.final$
        ..assignment = Code('${sizes.widthOffset}'),
    ),
    Field(
          (b) =>
      b
        ..name = "heightOffset"
        ..type = refer("double")
        ..modifier = FieldModifier.final$
        ..assignment = Code('${sizes.heightOffset}'),
    ),
  ];

  final paintingList =
  document.rootElement.children
      .where((node) => node is XmlElement)
      .toList();

  final cls = _corePainterClass(
    className: className,
    sizeParams: sizeParams,
    paintMethod: _generatePaintMethod(paintingList),
  );

  final lib = Library(
        (b) =>
    b
      ..directives.addAll([
        Directive.import('package:flutter/rendering.dart'),
        Directive.import('package:path_drawing/path_drawing.dart'),
        Directive.import('dart:math', show: ['sqrt']),
      ])
      ..body.addAll([cls]),
  );
  final emitter = DartEmitter();

  return DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  ).format('${lib.accept(emitter)}');
}

Method _generatePaintMethod(List<XmlNode> paints) {
  final List<Code> codeList = [];
  codeList.add(Code("canvas.scale(dimension / sqrt(area));"));

  for (final elem in paints) {
    if (elem is XmlElement && elem.name.local == 'path') {
      final paintOpt = parseStyle(elem);
      if (paintOpt != null) {
        codeList.addAll([
          Code('canvas.drawPath(parseSvgPathData('),
          Code('"""${elem.getAttribute('d')}"""'),
          Code(').shift(Offset(widthOffset, heightOffset)),'),
          Code("Paint()"),
          Code("..color = color"),
          ...paintOpt,
          Code(",);"),
        ]);
      }
    }
  }

  final code = Block.of(codeList);
  return Method.returnsVoid(
        (m) =>
    m
      ..name = "paint"
      ..annotations.add(refer('override'))
      ..requiredParameters.addAll([
        Parameter(
              (p) =>
          p
            ..name = "canvas"
            ..type = refer("Canvas"),
        ),
        Parameter(
              (p) =>
          p
            ..name = "size"
            ..type = refer("Size"),
        ),
      ])
      ..body = code,
  );
}

Class _corePainterClass({
  required String className,
  required List<Field> sizeParams,
  required Method paintMethod,
}) {
  final shouldRepaintMethod = Method(
        (a) =>
    a
      ..name = "shouldRepaint"
      ..returns = refer("bool")
      ..annotations.add(refer('override'))
      ..requiredParameters.add(
        Parameter(
              (p) =>
          p
            ..name = "oldDelegate"
            ..type = refer(
              "CustomPainter",
              'package:flutter/rendering.dart',
            ),
        ),
      )
      ..body = const Code('return true;'),
  );

  final painter = Class(
        (b) =>
    b
      ..name = "${className}IconPainter"
      ..extend = refer('CustomPainter')
      ..methods.addAll([paintMethod, shouldRepaintMethod])
      ..constructors.add(
        Constructor(
              (b) =>
          b
            ..constant = true
            ..optionalParameters.addAll([
              Parameter(
                    (b) =>
                b
                  ..required = true
                  ..toThis = true
                  ..name = "color"
                  ..named = true,
              ),
              Parameter(
                    (b) =>
                b
                  ..required = true
                  ..toThis = true
                  ..name = "dimension"
                  ..named = true,
              ),
            ]),
        ),
      )
      ..fields.addAll([
        Field(
              (b) =>
          b
            ..type = refer("Color")
            ..name = "color"
            ..modifier = FieldModifier.final$,
        ),
        Field(
              (b) =>
          b
            ..type = refer("double")
            ..name = "dimension"
            ..modifier = FieldModifier.final$,
        ),
        ...sizeParams,
      ]),
  );

  return painter;
}