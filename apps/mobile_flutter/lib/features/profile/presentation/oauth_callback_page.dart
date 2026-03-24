import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/profile_providers.dart';

class OAuthCallbackPage extends ConsumerStatefulWidget {
  const OAuthCallbackPage({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends ConsumerState<OAuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleCallback();
    });
  }

  Future<void> _handleCallback() async {
    if (widget.token == null || widget.token!.isEmpty) {
      context.go('/');
      return;
    }

    try {
      await ref.read(profileRepositoryProvider).saveToken(widget.token!);
      ref.invalidate(profileSessionProvider);
      await ref.read(profileSessionProvider.future);
    } catch (e) {
      // Ignore initial session errors
    }

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
