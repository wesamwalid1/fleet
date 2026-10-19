import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository repository;

  LoginCubit(this.repository) : super(const LoginState());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      emit(const LoginState(
        status: LoginStatus.error,
        errorMessage: 'Please enter your email and password.',
      ));
      return;
    }

    emit(const LoginState(status: LoginStatus.loading));

    try {
      await repository.login(
        email: email.trim(),
        password: password,
      );

      emit(const LoginState(status: LoginStatus.success));
    } catch (_) {
      emit(const LoginState(
        status: LoginStatus.error,
        errorMessage: 'Unable to sign in. Please try again.',
      ));
    }
  }
}