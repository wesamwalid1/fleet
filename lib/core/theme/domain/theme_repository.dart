import 'package:flutter/material.dart';

/// Persists the driver's theme preference (light/dark).
abstract class ThemeRepository {
  Future<ThemeMode?> read();

  Future<void> save(ThemeMode mode);
}
