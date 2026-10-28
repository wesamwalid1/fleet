import 'package:driver_portal_app/core/theme/domain/theme_repository.dart';
import 'package:driver_portal_app/core/theme/presentation/bloc/theme_bloc.dart';
import 'package:driver_portal_app/core/theme/presentation/bloc/theme_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup keeps light when nothing is saved', () async {
    final repository = _MemoryThemeRepository();
    final bloc = ThemeBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const ThemeStarted());
    await pumpEventQueue();

    expect(bloc.state.mode, ThemeMode.light);
    expect(repository.saved, isNull);
  });

  test('startup restores the saved theme', () async {
    final repository = _MemoryThemeRepository(ThemeMode.dark);
    final bloc = ThemeBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const ThemeStarted());
    await bloc.stream.first;

    expect(bloc.state.mode, ThemeMode.dark);
  });

  test('selecting a theme updates state and storage', () async {
    final repository = _MemoryThemeRepository();
    final bloc = ThemeBloc(repository);
    addTearDown(bloc.close);

    bloc.add(const ThemeModeSelected(ThemeMode.dark));
    await bloc.stream.first;

    expect(bloc.state.mode, ThemeMode.dark);
    expect(repository.saved, ThemeMode.dark);

    bloc.add(const ThemeModeSelected(ThemeMode.light));
    await bloc.stream.first;

    expect(bloc.state.mode, ThemeMode.light);
    expect(repository.saved, ThemeMode.light);
  });
}

class _MemoryThemeRepository implements ThemeRepository {
  ThemeMode? saved;

  _MemoryThemeRepository([this.saved]);

  @override
  Future<ThemeMode?> read() async => saved;

  @override
  Future<void> save(ThemeMode mode) async {
    saved = mode;
  }
}
