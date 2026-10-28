import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemePreferenceState extends Equatable {
  /// Defaults to light when nothing is saved.
  final ThemeMode mode;

  const ThemePreferenceState({this.mode = ThemeMode.light});

  @override
  List<Object?> get props => [mode];
}
