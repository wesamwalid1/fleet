import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/locale_repository.dart';

class LocaleRepositoryImpl implements LocaleRepository {
  static const storageKey = 'app_locale';

  const LocaleRepositoryImpl();

  @override
  Future<Locale?> read() async {
    final preferences = await _preferences();
    return _localeFrom(preferences?.getString(storageKey));
  }

  @override
  Future<void> save(Locale locale) async {
    final preferences = await _preferences();
    await preferences?.setString(storageKey, locale.languageCode);
  }

  Future<SharedPreferences?> _preferences() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Locale? _localeFrom(String? code) {
    return switch (code) {
      'en' => const Locale('en'),
      'ar' => const Locale('ar'),
      _ => null,
    };
  }
}
