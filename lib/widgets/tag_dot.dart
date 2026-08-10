import 'package:flutter/material.dart';

/// The six optional tag identifying-dot hues (TAGS_HANDOFF §1.3). Deliberately
/// no green and no orange-red, so a dot can never be misread as profit/loss.
/// Stored as the enum name (never an ARGB int) so a theme swap resolves right.
class TagDot {
  const TagDot._();

  static const double diameter = 6;

  /// Ordered swatch list offered in tag management (plus "no colour").
  static const List<String> names = [
    'blue',
    'indigo',
    'violet',
    'plum',
    'ochre',
    'slate',
  ];

  static const Map<String, Color> _light = {
    'blue': Color(0xFF3B5F9E),
    'indigo': Color(0xFF4E4E8F),
    'violet': Color(0xFF6F5675),
    'plum': Color(0xFF9A3B63),
    'ochre': Color(0xFF8A6D1F),
    'slate': Color(0xFF4A6572),
  };

  static const Map<String, Color> _dark = {
    'blue': Color(0xFFA8C4FF),
    'indigo': Color(0xFFB6B7F2),
    'violet': Color(0xFFDDBCE0),
    'plum': Color(0xFFF3A0C0),
    'ochre': Color(0xFFDFC169),
    'slate': Color(0xFF9FB6C2),
  };

  /// Resolves a stored dot [name] to its colour for [brightness], or null when
  /// the tag has no dot (or an unknown name).
  static Color? color(String? name, Brightness brightness) {
    if (name == null) return null;
    return (brightness == Brightness.dark ? _dark : _light)[name];
  }
}
