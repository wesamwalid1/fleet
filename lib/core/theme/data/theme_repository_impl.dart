import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/theme_repository.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  static const storageKey = 'app_theme_mode';

  const ThemeRepositoryImpl();

  @override
  Future<ThemeMode?> read() async {
    final preferences = await _preferences();
    return _modeFrom(preferences?.getString(storageKey));
  }

  @override
  Future<void> save(ThemeMode mode) async {
    final preferences = await _preferences();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await preferences?.setString(storageKey, value);
  }

  Future<SharedPreferences?> _preferences() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  ThemeMode? _modeFrom(String? value) {
    return switch (value) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => null,
    };
  }
}
