import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  final String title;

  const LoginHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 48),
      child: Column(
        children: [
          const Icon(Icons.work_outline_rounded, color: Colors.white, size: 52),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
