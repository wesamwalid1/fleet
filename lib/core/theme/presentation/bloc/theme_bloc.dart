import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/theme_repository.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemePreferenceState> {
  final ThemeRepository _repository;

  ThemeBloc(this._repository) : super(const ThemePreferenceState()) {
    on<ThemeStarted>(_onStarted);
    on<ThemeModeSelected>(_onSelected);
  }

  Future<void> _onStarted(
    ThemeStarted event,
    Emitter<ThemePreferenceState> emit,
  ) async {
    final saved = await _repository.read();
    if (saved == null) return;
    emit(ThemePreferenceState(mode: saved));
  }

  Future<void> _onSelected(
    ThemeModeSelected event,
    Emitter<ThemePreferenceState> emit,
  ) async {
    emit(ThemePreferenceState(mode: event.mode));
    await _repository.save(event.mode);
  }
}
