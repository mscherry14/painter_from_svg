import 'package:code_builder/code_builder.dart';
import 'package:xml/xml.dart';

/// Stores precomputed size and offset information extracted from an SVG.
class SvgSizeData {
  /// The overall area of the SVG viewport, used for scaling.
  final double area;

  /// Horizontal offset to apply to all paths.
  final double widthOffset;

  /// Vertical offset to apply to all paths.
  final double heightOffset;

  /// Creates a new [SvgSizeData] with the given [area], [widthOffset], and [heightOffset].
  SvgSizeData({
    required this.area,
    required this.widthOffset,
    required this.heightOffset,
  });
}

/// Parses the area and offsets from an SVG `<svg>` element's attributes.
///
/// This function first attempts to extract and parse the `viewBox` attribute.
/// If `viewBox` is missing or malformed, it falls back to `width` and `height`
/// attributes. If neither is usable, returns `null`.
///
/// Returns a [SvgSizeData] instance on success, or `null` if parsing fails.
SvgSizeData? parseSvgSizeData(XmlElement svg) {
  final viewBox = svg.getAttribute('viewBox');

  if (viewBox != null) {
    final parts = viewBox.split(' ');
    if (parts.length != 4) {
      return null;
    }
    final minX = double.tryParse(parts[0]);
    final minY = double.tryParse(parts[1]);
    final width = double.tryParse(parts[2]);
    final height = double.tryParse(parts[3]);
    if (minX == null || minY == null || width == null || height == null) {
      return null;
    }
    return SvgSizeData(
      area: width * height,
      widthOffset: -minX - width / 2,
      heightOffset: -minY - height / 2,
    );
  } else {
    final widthStr = svg.getAttribute('width');
    final heightStr = svg.getAttribute('height');
    if (widthStr == null || heightStr == null) {
      return null;
    }
    final width = double.tryParse(widthStr);
    final height = double.tryParse(widthStr);

    if (width == null || height == null) {
      return null;
    }
    return SvgSizeData(
      area: width * height,
      widthOffset: width / 2,
      heightOffset: height / 2,
    );
  }
}

/// Parses paint styles from an SVG element and returns a list of [Code] statements
/// to apply to a `Paint()` object.
///
/// Supports `fill`, `stroke`, `stroke-width`, `stroke-linecap`, and `stroke-linejoin`.
/// Returns `null` if no valid style attributes are found or if the style is unsupported.
///
/// Example output:
/// ```dart
/// ..style = PaintingStyle.stroke
/// ..strokeWidth = 2.0
/// ..strokeCap = StrokeCap.round
/// ```
List<Code>? parseStyle(XmlElement elem) {
  final List<Code> stylesCodes = [];
  if (elem.getAttribute("fill") != null &&
      elem.getAttribute("fill") != "none") {
    stylesCodes.add(Code("..style = PaintingStyle.fill"));
  } else if (elem.getAttribute("stroke") != null) {
    stylesCodes.add(Code("..style = PaintingStyle.stroke"));
  } else {
    return null;
  }
  if (elem.getAttribute("stroke-width") != null) {
    stylesCodes.add(
      Code("..strokeWidth = ${elem.getAttribute("stroke-width")}"),
    );
  }
  if (elem.getAttribute("stroke-linecap") != null) {
    switch (elem.getAttribute("stroke-linecap")) {
      case "round":
        stylesCodes.add(Code("..strokeCap = StrokeCap.round"));
      case "square":
        stylesCodes.add(Code("..strokeCap = StrokeCap.square"));
      case "butt":
        stylesCodes.add(Code("..strokeCap = StrokeCap.butt"));
    }
  }
  if (elem.getAttribute("stroke-linejoin") != null) {
    switch (elem.getAttribute("stroke-linejoin")) {
      case "miter":
        stylesCodes.add(Code("..strokeJoin = strokeJoin.miter"));
      case "round":
        stylesCodes.add(Code("..strokeJoin = strokeJoin.round"));
      case "bevel":
        stylesCodes.add(Code("..strokeJoin = strokeJoin.bevel"));
    }
  }
  return stylesCodes;
}
