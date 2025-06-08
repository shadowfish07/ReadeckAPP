import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/ui/settings/view_models/about_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/widgets/about_page.dart';
import 'package:readeck_app/ui/settings/widgets/settings_page.dart';

import 'routes.dart';

GoRouter router() => GoRouter(
      initialLocation: Routes.home,
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) {
            final viewModel = SettingsViewModel(context.read());
            return SettingsPage(viewModel: viewModel);
          },
          routes: [
            GoRoute(
                path: Routes.settingsRelative,
                builder: (context, state) {
                  final viewModel = SettingsViewModel(context.read());
                  return SettingsPage(viewModel: viewModel);
                },
                routes: [
                  GoRoute(
                      path: Routes.aboutRelative,
                      builder: (context, state) {
                        final viewModel = AboutViewModel();
                        return AboutPage(viewModel: viewModel);
                      }),
                ]),
          ],
        ),
      ],
    );

// TODO API 配置未定义就跳到定义页
// // From https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/redirection.dart
// Future<String?> _redirect(BuildContext context, GoRouterState state) async {
//   // if the user is not logged in, they need to login
//   final loggedIn = await context.read<AuthRepository>().isAuthenticated;
//   final loggingIn = state.matchedLocation == Routes.login;
//   if (!loggedIn) {
//     return Routes.login;
//   }

//   // if the user is logged in but still on the login page, send them to
//   // the home page
//   if (loggingIn) {
//     return Routes.home;
//   }

//   // no need to redirect at all
//   return null;
// }
