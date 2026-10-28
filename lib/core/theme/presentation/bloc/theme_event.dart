import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

sealed class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

final class ThemeStarted extends ThemeEvent {
  const ThemeStarted();
}

final class ThemeModeSelected extends ThemeEvent {
  final ThemeMode mode;

  const ThemeModeSelected(this.mode);

  @override
  List<Object?> get props => [mode];
}
