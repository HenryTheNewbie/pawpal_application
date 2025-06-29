// routes.dart

import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/main_screen.dart';
import '../screens/discovery_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/edit_user_profile_screen.dart';
import '../screens/user_settings_screen.dart';
import '../screens/user_faq_screen.dart';
import '../screens/user_privacy_policy_screen.dart';
import '../screens/user_terms_screen.dart';
import '../screens/about_the_app_screen.dart';
import '../screens/user_notifications_screen.dart';
import '../models/chat_detail_arguments.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/animal_detail_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String mainScreen = '/main-screen';
  static const String discovery = '/discovery';
  static const String chat = '/chat';
  static const String userProfile = '/user-profile';
  static const String editUserProfile = '/edit-user-profile';
  static const String userSettings = '/user-settings';
  static const String userFaq = '/user-faq';
  static const String userPrivacyPolicy = '/user-privacy-policy';
  static const String userTerms = '/user-terms';
  static const String aboutTheApp = '/about-the-app';
  static const String userNotifications = '/user-notifications';
  static const String chatDetail = '/chat-detail';
  static const String animalDetail = '/animal-detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case emailVerification:
        return MaterialPageRoute(builder: (_) => const EmailVerificationScreen());
      case mainScreen:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case discovery:
        return MaterialPageRoute(builder: (_) => const DiscoveryScreen());
      case chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case userProfile:
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());
      case editUserProfile:
        return MaterialPageRoute(builder: (_) => const EditUserProfileScreen());
      case userSettings:
        return MaterialPageRoute(builder: (_) => const UserSettingsScreen());
      case userFaq:
        return MaterialPageRoute(builder: (_) => const UserFaqScreen());
      case userPrivacyPolicy:
        return MaterialPageRoute(builder: (_) => const UserPrivacyPolicyScreen());
      case userTerms:
        return MaterialPageRoute(builder: (_) => const UserTermsScreen());
      case aboutTheApp:
        return MaterialPageRoute(builder: (_) => const AboutTheAppScreen());
      case userNotifications:
        return MaterialPageRoute(builder: (_) => const UserNotificationsScreen());
      case chatDetail:
        final args = settings.arguments as ChatDetailArguments;
        return MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: args.conversationId,
            animalId: args.animalId,
            animalName: args.animalName,
            animalDescription: args.animalDescription,
            sanctuaryName: args.sanctuaryName,
            sanctuaryEmail: args.sanctuaryEmail,
            sanctuaryImageUrl: args.sanctuaryImageUrl,
            profileImageUrl: args.profileImageUrl,
          ),
        );
      case animalDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AnimalDetailScreen(animalId: args['animalId']),
        );

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