import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A ticket outline: a rounded rectangle with a semicircular notch cut into
/// each side at [tearY], joined by a dashed perforation line.
///
/// Use it as the shape of a [ShapeDecoration] so the fill, shadow, and
/// hairline all follow the notches.
class TicketBorder extends ShapeBorder {
  /// Distance of the tear line from the top of the shape.
  final double tearY;
  final Color borderColor;
  final double radius;
  final double notchRadius;
  final double borderWidth;

  const TicketBorder({
    required this.tearY,
    required this.borderColor,
    this.radius = 20,
    this.notchRadius = 10,
    this.borderWidth = 1,
  });

  static const _dash = 6.0;
  static const _gap = 5.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  double _tear(Rect rect) {
    final min = radius + notchRadius;
    final max = math.max(min, rect.height - radius - notchRadius);
    return rect.top + tearY.clamp(min, max);
  }

  Path _outline(Rect rect) {
    final y = _tear(rect);
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final notches = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(rect.left, y), radius: notchRadius),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(rect.right, y), radius: notchRadius),
      );
    return Path.combine(PathOperation.difference, body, notches);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _outline(rect);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _outline(rect.deflate(borderWidth));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = borderColor;
    canvas.drawPath(_outline(rect.deflate(borderWidth / 2)), stroke);

    final y = _tear(rect);
    final end = rect.right - notchRadius - 8;
    for (var x = rect.left + notchRadius + 8; x < end; x += _dash + _gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + _dash, end), y),
        stroke,
      );
    }
  }

  @override
  ShapeBorder scale(double t) {
    return TicketBorder(
      tearY: tearY * t,
      borderColor: borderColor,
      radius: radius * t,
      notchRadius: notchRadius * t,
      borderWidth: borderWidth * t,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TicketBorder &&
        other.tearY == tearY &&
        other.borderColor == borderColor &&
        other.radius == radius &&
        other.notchRadius == notchRadius &&
        other.borderWidth == borderWidth;
  }

  @override
  int get hashCode =>
      Object.hash(tearY, borderColor, radius, notchRadius, borderWidth);
}
