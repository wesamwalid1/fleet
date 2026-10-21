import 'package:flutter/widgets.dart';

abstract interface class LocaleRepository {
  Future<Locale?> read();

  Future<void> save(Locale locale);
}
