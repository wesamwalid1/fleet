import 'package:driver_portal_app/core/locale/data/locale_repository_impl.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists only the supported language code', () async {
    SharedPreferences.setMockInitialValues({});
    const repository = LocaleRepositoryImpl();

    expect(await repository.read(), isNull);

    await repository.save(const Locale('ar'));
    expect(await repository.read(), const Locale('ar'));

    await repository.save(const Locale('en'));
    expect(await repository.read(), const Locale('en'));
  });

  test('ignores an unsupported saved code', () async {
    SharedPreferences.setMockInitialValues({
      LocaleRepositoryImpl.storageKey: 'fr',
    });

    expect(await const LocaleRepositoryImpl().read(), isNull);
  });
}
