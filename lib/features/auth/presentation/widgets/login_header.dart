import 'dart:math' as math;

import 'package:driver_portal_app/core/theme/app_surfaces.dart';
import 'package:driver_portal_app/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// The ticket's stub: the route mark, the product name, and the issue date as
/// a tabular field at the stub's end. When both cannot share one line, the
/// date moves under the name.
class LoginHeader extends StatelessWidget {
  final String title;

  /// Today's date, already formatted for the current locale.
  final String issued;

  /// Exact stub height; the ticket's tear line sits right below it.
  final double height;

  /// Whether the date sits at the stub's end ([fitsInline]) or under the name.
  final bool inline;

  const LoginHeader({
    super.key,
    required this.title,
    required this.issued,
    required this.height,
    required this.inline,
  });

  static const _markSize = 40.0;
  static const _markGap = 12.0;
  static const _fieldGap = 16.0;
  static const _horizontalPadding = 24.0;
  static const _verticalPadding = 16.0;
  static final _dateStyle = AppTextStyles.helper.copyWith(
    fontWeight: FontWeight.w600,
    fontFeatures: AppTextStyles.tabular,
  );

  /// Whether name and date fit side by side in a stub [width] wide.
  static bool fitsInline(
    BuildContext context, {
    required double width,
    required String title,
    required String issued,
  }) {
    final base = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: base.merge(style)),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final measured = painter.width;
      painter.dispose();
      return measured;
    }

    final available =
        width - _horizontalPadding * 2 - _markSize - _markGap - _fieldGap;
    return measure(title, AppTextStyles.brand) + measure(issued, _dateStyle) <=
        available;
  }

  /// Stub height for the text scale and layout, so the tear line never cuts
  /// text.
  static double heightFor(TextScaler scaler, {required bool inline}) {
    double line(TextStyle style) =>
        scaler.scale(style.fontSize!) * style.height!;
    final name = line(AppTextStyles.brand);
    final date = line(_dateStyle);
    final text = inline ? math.max(name, date) : name + date;
    return math.max(_markSize, text + 2) + _verticalPadding * 2;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final name = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.brand.copyWith(color: palette.title),
    );
    final date = Text(
      issued,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _dateStyle.copyWith(color: palette.body),
    );

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: Row(
          children: [
            ExcludeSemantics(
              child: CustomPaint(
                size: const Size.square(_markSize),
                painter: _RouteMarkPainter(
                  tile: palette.mark,
                  ink: palette.onMark,
                ),
              ),
            ),
            const SizedBox(width: _markGap),
            if (inline) ...[
              Expanded(child: name),
              const SizedBox(width: _fieldGap),
              date,
            ] else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [name, date],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A route from an origin dot to a destination ring on a rounded tile.
class _RouteMarkPainter extends CustomPainter {
  final Color tile;
  final Color ink;

  const _RouteMarkPainter({required this.tile, required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(12 * s)),
      Paint()..color = tile,
    );
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(12 * s, 14 * s)
      ..lineTo(21 * s, 14 * s)
      ..quadraticBezierTo(27 * s, 14 * s, 27 * s, 20 * s)
      ..lineTo(27 * s, 23.5 * s);
    canvas.drawPath(route, line);
    canvas.drawCircle(Offset(12 * s, 14 * s), 3.4 * s, Paint()..color = ink);
    canvas.drawCircle(Offset(27 * s, 27 * s), 3.4 * s, line);
  }

  @override
  bool shouldRepaint(_RouteMarkPainter oldDelegate) {
    return oldDelegate.tile != tile || oldDelegate.ink != ink;
  }
}
