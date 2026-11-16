import 'package:flutter/foundation.dart'
    show FlutterErrorDetails, kDebugMode;
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Calm Fleet surface painted in place of a failed widget subtree.
///
/// Used only via [installFriendlyErrorWidget] in profile/release. Does not
/// report, swallow, or recover the underlying error — presentation only.
class FriendlyErrorView extends StatelessWidget {
  const FriendlyErrorView({super.key, required this.details});

  /// Retained for API compatibility with [ErrorWidget.builder]; never shown
  /// in the release/profile UI or semantics.
  final FlutterErrorDetails details;

  static const _fallbackTitle = 'Something went wrong';
  static const _fallbackHint = "This section couldn't be shown.";
  static const _fallbackSemantics =
      "Something went wrong. This section couldn't be shown.";

  @override
  Widget build(BuildContext context) {
    // Safe lookup: Localizations.of returns null when delegates are absent
    // (unlike AppLocalizations.of, which asserts).
    final l10n = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    final title = l10n?.widgetErrorTitle ?? _fallbackTitle;
    final hint = l10n?.widgetErrorHint ?? _fallbackHint;
    final semantics = l10n?.widgetErrorSemantics ?? _fallbackSemantics;

    final hasTheme =
        context.getElementForInheritedWidgetOfExactType<InheritedTheme>() !=
        null;
    final hasMedia =
        context.getElementForInheritedWidgetOfExactType<MediaQuery>() != null;
    final Brightness brightness;
    if (hasTheme) {
      brightness = Theme.of(context).brightness;
    } else if (hasMedia) {
      brightness = MediaQuery.of(context).platformBrightness;
    } else {
      brightness = Brightness.light;
    }
    final dark = brightness == Brightness.dark;

    final titleColor = dark ? AppColors.mist50 : AppColors.ink950;
    final bodyColor = dark ? AppColors.slate300 : AppColors.ink800;
    final iconColor = dark ? AppColors.errorDark : AppColors.errorLight;
    final iconBg = dark
        ? AppColors.errorSurfaceDark
        : AppColors.errorSurfaceLight;

    final hasDirection =
        context.getElementForInheritedWidgetOfExactType<Directionality>() !=
        null;
    final textDirection = hasDirection
        ? Directionality.of(context)
        : TextDirection.ltr;

    // Self-host Directionality + Material so a broken ancestor cannot
    // prevent this fallback from painting.
    return Directionality(
      textDirection: textDirection,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          container: true,
          label: semantics,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boundedW = constraints.hasBoundedWidth;
              final boundedH = constraints.hasBoundedHeight;
              final w = boundedW ? constraints.maxWidth : 320.0;
              final h = boundedH ? constraints.maxHeight : 240.0;
              final compact =
                  (boundedH && h < 120) || (boundedW && w < 160);

              final content = compact
                  ? _CompactBody(
                      title: title,
                      titleColor: titleColor,
                      iconColor: iconColor,
                      iconBg: iconBg,
                    )
                  : _FullBody(
                      title: title,
                      hint: hint,
                      titleColor: titleColor,
                      bodyColor: bodyColor,
                      iconColor: iconColor,
                      iconBg: iconBg,
                    );

              return Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: boundedW ? w : 320,
                    maxHeight: boundedH ? h : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 16,
                      vertical: compact ? 4 : 12,
                    ),
                    child: content,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FullBody extends StatelessWidget {
  const _FullBody({
    required this.title,
    required this.hint,
    required this.titleColor,
    required this.bodyColor,
    required this.iconColor,
    required this.iconBg,
  });

  final String title;
  final String hint;
  final Color titleColor;
  final Color bodyColor;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IconBadge(size: 48, iconSize: 24, iconColor: iconColor, iconBg: iconBg),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontSize: 16,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: bodyColor,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CompactBody extends StatelessWidget {
  const _CompactBody({
    required this.title,
    required this.titleColor,
    required this.iconColor,
    required this.iconBg,
  });

  final String title;
  final Color titleColor;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconBadge(size: 28, iconSize: 16, iconColor: iconColor, iconBg: iconBg),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.size,
    required this.iconSize,
    required this.iconColor,
    required this.iconBg,
  });

  final double size;
  final double iconSize;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(
          Icons.error_outline_rounded,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}

ErrorWidgetBuilder? _frameworkErrorWidgetBuilder;

/// Installs Fleet's [ErrorWidget.builder].
///
/// - Debug: Flutter's default [ErrorWidget] (red diagnostics).
/// - Profile / release: [FriendlyErrorView].
///
/// Pass [forceFriendly] in tests to exercise the non-debug path while
/// `kDebugMode` is true. Pass `false` to force the default widget.
///
/// Does not assign [FlutterError.onError] or [PlatformDispatcher.onError].
void installFriendlyErrorWidget({bool? forceFriendly}) {
  _frameworkErrorWidgetBuilder ??= ErrorWidget.builder;
  final useFriendly = forceFriendly ?? !kDebugMode;
  final frameworkBuilder = _frameworkErrorWidgetBuilder!;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!useFriendly) {
      return frameworkBuilder(details);
    }
    return FriendlyErrorView(details: details);
  };
}
