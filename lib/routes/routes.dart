// routes.dart

import 'package:flutter/material.dart';
import '../screens/user/login_screen.dart';
import '../screens/user/register_screen.dart';
import '../screens/user/forgot_password_screen.dart';
import '../screens/user/email_verification_screen.dart';
import '../screens/user/main_screen.dart';
import '../screens/user/discovery_screen.dart';
import '../screens/user/chat_screen.dart';
import '../screens/user/user_profile_screen.dart';
import '../screens/user/edit_user_profile_screen.dart';
import '../screens/user/user_settings_screen.dart';
import '../screens/user/user_faq_screen.dart';
import '../screens/user/user_privacy_policy_screen.dart';
import '../screens/user/user_terms_screen.dart';
import '../screens/user/about_the_app_screen.dart';
import '../screens/user/user_notifications_screen.dart';
import '../models/chat_detail_arguments.dart';
import '../screens/user/chat_detail_screen.dart';
import '../screens/user/animal_detail_screen.dart';

import '../screens/sanctuary/sanctuary_login_screen.dart';
import '../screens/sanctuary/sanctuary_register_screen.dart';
import '../screens/sanctuary/sanctuary_forgot_password_screen.dart';
import '../screens/sanctuary/sanctuary_email_verification_screen.dart';
import '../screens/sanctuary/sanctuary_main_screen.dart';
import '../screens/sanctuary/sanctuary_add_animal_screen.dart';
import '../screens/sanctuary/sanctuary_chat_screen.dart';
import '../screens/sanctuary/sanctuary_profile_screen.dart';
import '../screens/sanctuary/edit_sanctuary_profile_screen.dart';
import '../screens/sanctuary/sanctuary_settings_screen.dart';
import '../screens/sanctuary/sanctuary_faq_screen.dart';
import '../screens/sanctuary/sanctuary_privacy_policy_screen.dart';
import '../screens/sanctuary/sanctuary_terms_screen.dart';
import '../screens/sanctuary/sanctuary_about_the_app_screen.dart';
import '../screens/sanctuary/sanctuary_notifications_screen.dart';

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

  static const String sanctuaryLogin = '/sanctuary-login';
  static const String sanctuaryRegister = '/sanctuary-register';
  static const String sanctuaryForgotPassword = '/sanctuary-forgot-password';
  static const String sanctuaryEmailVerification = '/sanctuary-email-verification';
  static const String sanctuaryMainScreen = '/sanctuary-main-screen';
  static const String sanctuaryAddAnimal = '/sanctuary-add-animal';
  static const String sanctuaryChat = '/sanctuary-chat';
  static const String sanctuaryProfile = '/sanctuary-profile';
  static const String editSanctuaryProfile = '/edit-sanctuary-profile';
  static const String sanctuarySettings = '/sanctuary-settings';
  static const String sanctuaryFaq = '/sanctuary-faq';
  static const String sanctuaryPrivacyPolicy = '/sanctuary-privacy-policy';
  static const String sanctuaryTerms = '/sanctuary-terms';
  static const String sanctuaryAboutTheApp = '/sanctuary-about-the-app';
  static const String sanctuaryNotifications = '/sanctuary-notifications';

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

      case sanctuaryLogin:
        return MaterialPageRoute(builder: (_) => const SanctuaryLoginScreen());
      case sanctuaryRegister:
        return MaterialPageRoute(builder: (_) => const SanctuaryRegisterScreen());
      case sanctuaryForgotPassword:
        return MaterialPageRoute(builder: (_) => const SanctuaryForgotPasswordScreen());
      case sanctuaryEmailVerification:
        return MaterialPageRoute(builder: (_) => const SanctuaryEmailVerificationScreen());
      case sanctuaryMainScreen:
        return MaterialPageRoute(builder: (_) => const SanctuaryMainScreen());
      case sanctuaryAddAnimal:
        return MaterialPageRoute(builder: (_) => const SanctuaryAddAnimalScreen());
      case sanctuaryChat:
        return MaterialPageRoute(builder: (_) => const SanctuaryChatScreen());
      case sanctuaryProfile:
        return MaterialPageRoute(builder: (_) => const SanctuaryProfileScreen());
      case editSanctuaryProfile:
        return MaterialPageRoute(builder: (_) => const EditSanctuaryProfileScreen());
      case sanctuarySettings:
        return MaterialPageRoute(builder: (_) => const SanctuarySettingsScreen());
      case sanctuaryFaq:
        return MaterialPageRoute(builder: (_) => const SanctuaryFaqScreen());
      case sanctuaryPrivacyPolicy:
        return MaterialPageRoute(builder: (_) => const SanctuaryPrivacyPolicyScreen());
      case sanctuaryTerms:
        return MaterialPageRoute(builder: (_) => const SanctuaryTermsScreen());
      case sanctuaryAboutTheApp:
        return MaterialPageRoute(builder: (_) => const SanctuaryAboutTheAppScreen());
      case sanctuaryNotifications:
        return MaterialPageRoute(builder: (_) => const SanctuaryNotificationsScreen());

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