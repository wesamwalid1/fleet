import '../../domain/entities/user.dart';

class UserModel {
  final String email;

  const UserModel({required this.email});

  User toEntity() => User(email: email);
}
