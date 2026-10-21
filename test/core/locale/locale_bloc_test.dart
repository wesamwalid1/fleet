import 'package:driver_portal_app/core/locale/domain/locale_repository.dart';
import 'package:driver_portal_app/core/locale/presentation/bloc/locale_bloc.dart';
import 'package:driver_portal_app/core/locale/presentation/bloc/locale_event.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup keeps the default when nothing is saved', () async {
    final repository = _MemoryLocaleRepository();
    final bloc = LocaleBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const LocaleStarted());
    await pumpEventQueue();

    expect(bloc.state.locale, isNull);
    expect(repository.saved, isNull);
  });

  test('startup restores the saved locale', () async {
    final repository = _MemoryLocaleRepository(const Locale('ar'));
    final bloc = LocaleBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const LocaleStarted());
    await bloc.stream.first;

    expect(bloc.state.locale, const Locale('ar'));
  });

  test('selecting a language updates state and storage', () async {
    final repository = _MemoryLocaleRepository(const Locale('ar'));
    final bloc = LocaleBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const LocaleSelected(Locale('en')));
    await bloc.stream.first;

    expect(bloc.state.locale, const Locale('en'));
    expect(repository.saved, const Locale('en'));
  });
}

class _MemoryLocaleRepository implements LocaleRepository {
  Locale? saved;

  _MemoryLocaleRepository([this.saved]);

  @override
  Future<Locale?> read() async => saved;

  @override
  Future<void> save(Locale locale) async {
    saved = locale;
  }
}
