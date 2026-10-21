import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class LocaleState extends Equatable {
  /// Null means no saved choice, so the app keeps its default locale.
  final Locale? locale;

  const LocaleState({this.locale});

  @override
  List<Object?> get props => [locale];
}
