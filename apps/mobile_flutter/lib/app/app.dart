import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class BatDatingApp extends StatelessWidget {
  const BatDatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bat Dating App',
      theme: AppTheme.light(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
