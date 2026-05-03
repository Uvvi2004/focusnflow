import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/fcm_service.dart';

// Background handler runs in a separate isolate — must be a top-level
// function and must not reference any live UI state.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// Global key so the foreground FCM listener can show a SnackBar from
// outside the widget tree without needing a BuildContext.
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _fcmService = FCMService();

  @override
  void initState() {
    super.initState();
    _fcmService.initialize();

    // Foreground messages: the OS does not display a notification banner while
    // the app is open, so we surface it as an in-app SnackBar instead.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n == null) return;
      final title = n.title ?? '';
      final body = n.body ?? '';
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            [title, body].where((s) => s.isNotEmpty).join('\n'),
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusNFlow',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4F8EF7),
          secondary: Color(0xFF4F8EF7),
          surface: Color(0xFF1A1D2E),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F1117),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.hasData ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
