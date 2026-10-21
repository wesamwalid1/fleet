import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/locale_repository.dart';
import 'locale_event.dart';
import 'locale_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  final LocaleRepository _repository;

  LocaleBloc(this._repository) : super(const LocaleState()) {
    on<LocaleStarted>(_onStarted);
    on<LocaleSelected>(_onSelected);
  }

  Future<void> _onStarted(
    LocaleStarted event,
    Emitter<LocaleState> emit,
  ) async {
    final saved = await _repository.read();
    if (saved == null || state.locale != null) return;
    emit(LocaleState(locale: saved));
  }

  Future<void> _onSelected(
    LocaleSelected event,
    Emitter<LocaleState> emit,
  ) async {
    emit(LocaleState(locale: event.locale));
    await _repository.save(event.locale);
  }
}
