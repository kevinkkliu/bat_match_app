import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/create_game/presentation/create_game_page.dart';
import '../features/game_detail/presentation/game_detail_page.dart';
import '../features/game_discovery/presentation/game_discovery_page.dart';
import '../features/game_requests/presentation/game_requests_page.dart';
import '../features/my_games/presentation/my_games_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/profile/presentation/oauth_callback_page.dart';
import '../shared/widgets/app_shell.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutePaths.home,
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      redirect: (BuildContext context, GoRouterState state) =>
          AppRoutePaths.home,
    ),
    GoRoute(
      path: '/auth/callback',
      builder: (BuildContext context, GoRouterState state) {
        return OAuthCallbackPage(
          token: state.uri.queryParameters['token'],
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state,
          StatefulNavigationShell navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              name: AppRouteNames.home,
              path: AppTab.home.path,
              builder: (BuildContext context, GoRouterState state) =>
                  const GameDiscoveryPage(),
              routes: <RouteBase>[
                GoRoute(
                  name: AppRouteNames.gameDetail,
                  path: ':gameId',
                  builder: (BuildContext context, GoRouterState state) {
                    return GameDetailPage(
                        gameId: state.pathParameters['gameId']!);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              name: AppRouteNames.create,
              path: AppTab.create.path,
              builder: (BuildContext context, GoRouterState state) =>
                  const CreateGamePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              name: AppRouteNames.myGames,
              path: AppTab.myGames.path,
              builder: (BuildContext context, GoRouterState state) =>
                  const MyGamesPage(),
              routes: <RouteBase>[
                GoRoute(
                  name: AppRouteNames.gameRequests,
                  path: ':gameId/requests',
                  builder: (BuildContext context, GoRouterState state) {
                    return GameRequestsPage(
                      gameId: state.pathParameters['gameId']!,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              name: AppRouteNames.profile,
              path: AppTab.profile.path,
              builder: (BuildContext context, GoRouterState state) =>
                  const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
