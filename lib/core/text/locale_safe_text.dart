import 'package:flutter/material.dart';

/// Removes unexpected RTL/Arabic/Hebrew codepoints from display strings.
String sanitizeLocaleText(String input) {
  if (input.isEmpty) return input;

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (_isAllowedRune(rune)) {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

bool _isAllowedRune(int rune) {
  // Bidi controls
  if (rune >= 0x200E && rune <= 0x200F) return false;
  if (rune >= 0x202A && rune <= 0x202E) return false;
  if (rune >= 0x2066 && rune <= 0x2069) return false;
  // Arabic
  if (rune >= 0x0600 && rune <= 0x06FF) return false;
  if (rune >= 0x0750 && rune <= 0x077F) return false;
  // Hebrew (Amatic SC includes Hebrew glyphs that break Cyrillic fallback)
  if (rune >= 0x0590 && rune <= 0x05FF) return false;
  return true;
}

/// User-facing text forced LTR with unsafe scripts stripped.
class LocaleSafeText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const LocaleSafeText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      sanitizeLocaleText(data),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
  }
}
