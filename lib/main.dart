import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'theme/theme.dart';
import 'routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission();

  runApp(const PawPalApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔙 Handling a background message: ${message.messageId}');
}

class PawPalApp extends StatefulWidget {
  const PawPalApp({super.key});

  @override
  State<PawPalApp> createState() => _PawPalAppState();
}

class _PawPalAppState extends State<PawPalApp> {
  @override
  void initState() {
    super.initState();
    _setupFirebaseMessagingHandlers();
  }

  void _setupFirebaseMessagingHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message received:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 Notification caused app to open.');
      print('Data: ${message.data}');
      // Handle navigation based on message data if needed
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('📨 App opened from terminated state via notification.');
        print('Data: ${message.data}');
        // Handle navigation based on message data if needed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawPal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}