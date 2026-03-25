import 'package:flutter/material.dart';

import 'section_card.dart';

class AuthRequiredCard extends StatelessWidget {
  const AuthRequiredCard({
    super.key,
    required this.title,
    required this.message,
    required this.onSignInPressed,
    this.buttonLabel = 'Go to profile',
  });

  final String title;
  final String message;
  final VoidCallback onSignInPressed;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      subtitle: 'Sign in required',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF55655B),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSignInPressed,
              icon: const Icon(Icons.login_rounded),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
