import 'package:driver_portal_app/features/auth/logic/cubit/login_cubit.dart';
import 'package:driver_portal_app/features/auth/logic/cubit/login_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_text_field.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<LoginCubit>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome back!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Sign in to your driver account',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 18),

          LoginTextField(
            hintText: 'Driver Email',
            controller: _emailController,
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          LoginTextField(
            hintText: 'Password',
            controller: _passwordController,
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),

          BlocConsumer<LoginCubit, LoginState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == LoginStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed in successfully'),
                  ),
                );
              }

              if (state.status == LoginStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.errorMessage ?? 'Something went wrong',
                    ),
                  ),
                );
              }
            },
            buildWhen: (previous, current) =>
                previous.status != current.status,
            builder: (context, state) {
              final isLoading =
                  state.status == LoginStatus.loading;

              return SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C60FF),
                    disabledBackgroundColor:
                        const Color(0xFF6C60FF).withValues(alpha: 0.7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign In →',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Having trouble? Contact your vault manager',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8A94B8),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}