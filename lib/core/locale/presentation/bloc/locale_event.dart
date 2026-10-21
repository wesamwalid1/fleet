import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

sealed class LocaleEvent extends Equatable {
  const LocaleEvent();

  @override
  List<Object?> get props => [];
}

final class LocaleStarted extends LocaleEvent {
  const LocaleStarted();
}

final class LocaleSelected extends LocaleEvent {
  final Locale locale;

  const LocaleSelected(this.locale);

  @override
  List<Object?> get props => [locale];
}
