import 'package:flutter/material.dart';

import '../features/home/playing_card.dart';

/// Draws a playing-card suit as a vector path in an arbitrary colour and size.
///
/// We paint the suits ourselves rather than rendering the Unicode glyphs,
/// because many Android devices force red *emoji* presentation for ♥/♦ and
/// ignore both our colour and the text variation selector.
class SuitIcon extends StatelessWidget {
  const SuitIcon({
    super.key,
    required this.suit,
    required this.color,
    this.size = 20,
  });

  final CardSuit suit;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SuitPainter(suit, color)),
    );
  }
}

class _SuitPainter extends CustomPainter {
  _SuitPainter(this.suit, this.color);
  final CardSuit suit;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    // Paths are authored in a 24×24 box; scale to the requested size.
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(_pathFor(suit), paint);
    canvas.restore();
  }

  Path _pathFor(CardSuit suit) {
    switch (suit) {
      case CardSuit.diamond:
        return Path()
          ..moveTo(12, 1.5)
          ..lineTo(20.5, 12)
          ..lineTo(12, 22.5)
          ..lineTo(3.5, 12)
          ..close();

      case CardSuit.heart:
        return Path()
          ..moveTo(12, 21)
          ..cubicTo(12, 21, 2.5, 14.2, 2.5, 8.2)
          ..cubicTo(2.5, 5.1, 4.6, 3, 7.3, 3)
          ..cubicTo(9.4, 3, 11.1, 4.5, 12, 6.2)
          ..cubicTo(12.9, 4.5, 14.6, 3, 16.7, 3)
          ..cubicTo(19.4, 3, 21.5, 5.1, 21.5, 8.2)
          ..cubicTo(21.5, 14.2, 12, 21, 12, 21)
          ..close();

      case CardSuit.spade:
        final p = Path()
          ..moveTo(12, 2.5)
          ..cubicTo(12, 2.5, 21.5, 9.5, 21.5, 15)
          ..cubicTo(21.5, 17.8, 19.6, 19.3, 17.2, 19.3)
          ..cubicTo(15.6, 19.3, 14.2, 18.4, 13.4, 17.2)
          ..cubicTo(13.5, 19, 14.1, 20.6, 15.4, 21.5)
          ..lineTo(8.6, 21.5)
          ..cubicTo(9.9, 20.6, 10.5, 19, 10.6, 17.2)
          ..cubicTo(9.8, 18.4, 8.4, 19.3, 6.8, 19.3)
          ..cubicTo(4.4, 19.3, 2.5, 17.8, 2.5, 15)
          ..cubicTo(2.5, 9.5, 12, 2.5, 12, 2.5)
          ..close();
        return p;

      case CardSuit.club:
        final p = Path()
          ..fillType = PathFillType.nonZero
          ..addOval(Rect.fromCircle(center: const Offset(12, 6.5), radius: 4))
          ..addOval(Rect.fromCircle(center: const Offset(7.5, 13), radius: 4))
          ..addOval(Rect.fromCircle(center: const Offset(16.5, 13), radius: 4));
        // Stem.
        p
          ..moveTo(10.8, 12.5)
          ..cubicTo(10.8, 16.5, 10, 20, 8.6, 21.5)
          ..lineTo(15.4, 21.5)
          ..cubicTo(14, 20, 13.2, 16.5, 13.2, 12.5)
          ..close();
        return p;
    }
  }

  @override
  bool shouldRepaint(_SuitPainter old) =>
      old.suit != suit || old.color != color;
}
