import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
  'focusnflow_default_channel',
  'FocusNFlow Notifications',
  description: 'General notifications for FocusNFlow',
  importance: Importance.max,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotifications.initialize(
    const InitializationSettings(android: androidSettings),
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_defaultChannel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

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

  Future<void> _syncInitialAndOpenedMessagesToBell() async {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _fcmService.storeIncomingMessageForBell(message);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _fcmService.storeIncomingMessageForBell(initialMessage);
    }
  }

  @override
  void initState() {
    super.initState();
    _fcmService.initialize();
    _syncInitialAndOpenedMessagesToBell();

    // Foreground messages are shown as local notifications so behavior matches
    // background/closed notifications and avoids SnackBars.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _fcmService.storeIncomingMessageForBell(message);
      final n = message.notification;
      if (n == null) return;
      final title = n.title ?? '';
      final body = n.body ?? '';
      _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'focusnflow_default_channel',
            'FocusNFlow Notifications',
            channelDescription: 'General notifications for FocusNFlow',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusNFlow',
      debugShowCheckedModeBanner: false,
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
