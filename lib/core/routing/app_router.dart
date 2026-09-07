import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/forgot_password/view/forgot_password_view.dart';
import '../../features/forgot_password/view_model/forgot_password_view_model.dart';
import '../../features/home/view/home_view.dart';
import '../../features/home/view_model/home_view_model.dart';
import '../../features/login/view/login_view.dart';
import '../../features/login/view_model/login_view_model.dart';
import '../../features/onboarding/view/onboarding_view.dart';
import '../../features/onboarding/view_model/onboarding_view_model.dart';
import '../../features/register/view/register_view.dart';
import '../../features/register/view_model/register_view_model.dart';
import '../../features/role_selection/model/user_role.dart';
import '../../features/role_selection/view/role_selection_view.dart';
import '../../features/role_selection/view_model/role_selection_view_model.dart';
import '../../features/splash/view/splash_view.dart';
import '../../features/splash/view_model/splash_view_model.dart';
import '../../features/verify_code/view/verify_code_view.dart';
import '../../features/verify_code/view_model/verify_code_view_model.dart';
import '../../features/welcome/view/welcome_view.dart';
import '../services/preferences_service.dart';
import 'app_routes.dart';
import 'unknown_route_view.dart';

/// Builds a page for every route name in [AppRoutes].
///
/// Each screen is paired with its view model here, so a view never has to know
/// how its view model is constructed and the view model is disposed together
/// with the route.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
        return _page(
          settings,
          create: (BuildContext context) =>
              OnboardingViewModel(context.read<PreferencesService>()),
          builder: (_) => const OnboardingView(),
        );
      case AppRoutes.welcome:
        // No view model: the screen holds no state, it only offers two routes.
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const WelcomeView(),
        );
      case AppRoutes.roleSelection:
        return _page(
          settings,
          create: (_) => RoleSelectionViewModel(),
          builder: (_) => const RoleSelectionView(),
        );
      case AppRoutes.register:
        // Role selection hands the chosen role over as the route argument; it
        // is saved with the account rather than on its own.
        final UserRole? role = settings.arguments as UserRole?;
        return _page(
          settings,
          create: (_) => RegisterViewModel(role: role),
          builder: (_) => const RegisterView(),
        );
      case AppRoutes.forgotPassword:
        return _page(
          settings,
          create: (_) => ForgotPasswordViewModel(),
          builder: (_) => const ForgotPasswordView(),
        );
      case AppRoutes.verifyCode:
        return _page(
          settings,
          create: (_) =>
              VerifyCodeViewModel(destination: settings.arguments as String?),
          builder: (_) => const VerifyCodeView(),
        );
      case AppRoutes.login:
        return _page(
          settings,
          create: (_) => LoginViewModel(),
          builder: (_) => const LoginView(),
        );
      case AppRoutes.splash:
        return _page(
          settings,
          create: (BuildContext context) =>
              SplashViewModel(context.read<PreferencesService>()),
          builder: (_) => const SplashView(),
        );
      case AppRoutes.home:
        return _page(
          settings,
          create: (_) => HomeViewModel(),
          builder: (_) => const HomeView(),
        );
      default:
        return onUnknownRoute(settings);
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => UnknownRouteView(routeName: settings.name),
    );
  }

  /// Wraps [builder] in a [ChangeNotifierProvider] holding its view model.
  static MaterialPageRoute<T> _page<T, V extends ChangeNotifier>(
    RouteSettings settings, {
    required Create<V> create,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (BuildContext context) => ChangeNotifierProvider<V>(
        create: create,
        child: Builder(builder: builder),
      ),
    );
  }
}
