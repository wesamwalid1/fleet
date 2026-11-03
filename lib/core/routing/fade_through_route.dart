import 'package:flutter/material.dart';

/// A Material fade-through page route for moving between unrelated screens.
///
/// The incoming page's ground covers the old page first, then its content
/// fades in while settling from a slight zoom. Popping plays it in reverse.
/// With system animations turned off, the page appears instantly.
class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  /// [ground] is the cover colour; it should match the incoming page's own
  /// background. Defaults to the theme's scaffold background.
  FadeThroughRoute({
    required WidgetBuilder builder,
    Color Function(BuildContext context)? ground,
    super.settings,
  }) : super(
         transitionDuration: const Duration(milliseconds: 320),
         reverseTransitionDuration: const Duration(milliseconds: 260),
         pageBuilder: (context, _, _) => builder(context),
         transitionsBuilder: (context, animation, _, child) {
           if (MediaQuery.disableAnimationsOf(context)) return child;
           final content = animation.drive(_contentCurve);
           return Stack(
             children: [
               Positioned.fill(
                 child: FadeTransition(
                   opacity: animation.drive(_groundCurve),
                   child: ColoredBox(
                     color:
                         ground?.call(context) ??
                         Theme.of(context).scaffoldBackgroundColor,
                   ),
                 ),
               ),
               FadeTransition(
                 opacity: content,
                 child: ScaleTransition(
                   scale: content.drive(_zoom),
                   child: child,
                 ),
               ),
             ],
           );
         },
       );

  static final _groundCurve = CurveTween(
    curve: const Interval(0, 0.35, curve: Curves.easeOut),
  );
  static final _contentCurve = CurveTween(
    curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
  );
  static final _zoom = Tween<double>(begin: 0.96, end: 1);
}
