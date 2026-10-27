import 'package:flutter/material.dart';

/// Circular mark that identifies what a row is about: a tinted circle with
/// an asset icon or a Material icon at its center.
class TypeAvatar extends StatelessWidget {
  final Color tint;
  final Widget child;
  final double size;

  const TypeAvatar({
    super.key,
    required this.tint,
    required this.child,
    this.size = 46,
  });

  /// [asset] drawn at about half the circle's size.
  TypeAvatar.asset(
    String asset, {
    super.key,
    required this.tint,
    this.size = 46,
    double opacity = 1,
  }) : child = Opacity(
         opacity: opacity,
         child: Image.asset(
           asset,
           width: size * 0.52,
           height: size * 0.52,
           fit: BoxFit.contain,
           excludeFromSemantics: true,
         ),
       );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
      child: child,
    );
  }
}
