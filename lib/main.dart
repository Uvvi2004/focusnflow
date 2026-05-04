import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/fcm_service.dart';

// This runs in a separate isolate when a notification arrives while the app
// is completely closed. It just re-initializes Firebase — we can't touch UI here.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// Global plugin instance for showing local notification banners.
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// Android notification channel — this is what makes the notification sound
// and shows the banner on Android 8+.
const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
  'focusnflow_default_channel',
  'FocusNFlow Notifications',
  description: 'General notifications for FocusNFlow',
  importance: Importance.max,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before anything else runs.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up local notifications so we can show banners when the app is open.
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotifications.initialize(
    const InitializationSettings(android: androidSettings),
  );

  // Create the Android notification channel so the OS knows where to route alerts.
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_defaultChannel);

  // Allow FCM to show a banner/sound even when the app is in the foreground.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Register the background message handler before the app runs.
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

  // Handles two edge cases:
  // 1. User taps a notification while the app is in the background → onMessageOpenedApp
  // 2. User taps a notification that launched the app from scratch → getInitialMessage
  // In both cases we write the message to Firestore so the bell icon picks it up.
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

    // Start the FCM token lifecycle (request permission, save token).
    _fcmService.initialize();
    _syncInitialAndOpenedMessagesToBell();

    // Handle messages when the app is open. We show a local notification banner
    // so the experience matches receiving a push when the app is closed.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Also save to Firestore so it appears in the bell notification list.
      _fcmService.storeIncomingMessageForBell(message);

      final n = message.notification;
      if (n == null) return;

      // Show the OS-style notification banner while the app is open.
      _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        n.title ?? '',
        n.body ?? '',
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
      // StreamBuilder listens to Firebase Auth state in real time.
      // If the user is logged in, show the home screen. Otherwise show login.
      // This also handles token expiration automatically.
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
