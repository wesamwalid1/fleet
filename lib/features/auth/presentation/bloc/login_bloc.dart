import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/failures/auth_failure.dart';
import '../../domain/usecases/login_use_case.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase _login;

  /// When false, login is blocked after validation (no offline auth).
  final bool Function()? isOnline;

  LoginBloc(this._login, {this.isOnline}) : super(const LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted, transformer: droppable());
  }

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state is LoginLoading) return;

    final email = event.email.trim();
    final emailError = _validateEmail(email);
    final passwordError = event.password.isEmpty ? PasswordError.empty : null;

    if (emailError != null || passwordError != null) {
      emit(LoginFailure(emailError: emailError, passwordError: passwordError));
      return;
    }

    if (isOnline != null && !isOnline!()) {
      emit(const LoginFailure(authError: AuthError.offline));
      return;
    }

    emit(const LoginLoading());

    try {
      final user = await _login(email: email, password: event.password);
      emit(LoginSuccess(user));
    } on InvalidCredentialsFailure {
      emit(const LoginFailure(authError: AuthError.invalidCredentials));
    } on AuthFailure {
      emit(const LoginFailure(authError: AuthError.unexpected));
    }
  }

  EmailError? _validateEmail(String email) {
    if (email.isEmpty) return EmailError.empty;
    if (!_emailPattern.hasMatch(email)) return EmailError.invalidFormat;
    return null;
  }
}
