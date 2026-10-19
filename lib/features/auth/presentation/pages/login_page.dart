import 'package:flutter/material.dart';

import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const primaryColor = Color(0xFF6C60FF);
  static const backgroundColor = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final horizontalPadding =
                screenWidth < 400 ? 12.0 : 24.0;

            final cardWidth =
                screenWidth > 500 ? 420.0 : double.infinity;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 378,
                    width: double.infinity,
                    child: ColoredBox(
                      color: primaryColor,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 76),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: const LoginHeader(),
                        ),
                      ),
                    ),
                  ),

                  Transform.translate(
                    offset: const Offset(0, -188),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: cardWidth,
                          ),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(
                              24, 27, 24, 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.10,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: const LoginForm(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 0),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}