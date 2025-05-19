// routes.dart

import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/discovery_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/email_verification_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String discovery = '/discovery';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case discovery:
        return MaterialPageRoute(builder: (_) => const DiscoveryScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case emailVerification:
        return MaterialPageRoute(builder: (_) => const EmailVerificationScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
