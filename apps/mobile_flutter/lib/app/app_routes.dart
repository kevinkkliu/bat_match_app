import 'package:flutter/material.dart';

class AppRoutePaths {
  const AppRoutePaths._();

  static const String home = '/games';
  static const String create = '/create';
  static const String myGames = '/my-games';
  static const String profile = '/profile';

  static String gameDetail(String gameId) => '$home/$gameId';
  static String gameRequests(String gameId) => '$myGames/$gameId/requests';
}

class AppRouteNames {
  const AppRouteNames._();

  static const String home = 'home';
  static const String create = 'create';
  static const String myGames = 'myGames';
  static const String profile = 'profile';
  static const String gameDetail = 'gameDetail';
  static const String gameRequests = 'gameRequests';
}

enum AppTab {
  home(
    label: 'Home',
    icon: Icons.sports_tennis,
    path: AppRoutePaths.home,
  ),
  create(
    label: 'Create',
    icon: Icons.add_circle_outline,
    path: AppRoutePaths.create,
  ),
  myGames(
    label: 'My Games',
    icon: Icons.event_note_outlined,
    path: AppRoutePaths.myGames,
  ),
  profile(
    label: 'Profile',
    icon: Icons.person_outline,
    path: AppRoutePaths.profile,
  );

  const AppTab({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}
