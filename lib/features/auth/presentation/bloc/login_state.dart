import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

enum EmailError { empty, invalidFormat }

enum PasswordError { empty }

enum AuthError { invalidCredentials, unexpected }

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

final class LoginInitial extends LoginState {
  const LoginInitial();
}

final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {
  final User user;

  const LoginSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

final class LoginFailure extends LoginState {
  final EmailError? emailError;
  final PasswordError? passwordError;
  final AuthError? authError;

  const LoginFailure({this.emailError, this.passwordError, this.authError});

  @override
  List<Object?> get props => [emailError, passwordError, authError];
}
