// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/router.dart';
import 'app/push/push_registration_service.dart';
import 'app/push/latest_notification_provider.dart';
import 'app/push/latest_notification_refresh.dart';
import 'core/api_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.setAutoInitEnabled(true);

  // ✅ Create container and init TokenStore BEFORE UI
  final container = ProviderContainer();
  await container.read(tokenStoreProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}


class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  static const _debugUserName = 'markcondi'; // TODO: replace with real user provider later

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ Foreground messages: update in-app + show SnackBar
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Pubs Financial';
      final body = message.notification?.body ?? '';

      ref.read(latestNotificationProvider.notifier).state = LatestNotification(
        title: title,
        body: body,
        receivedAt: DateTime.now(),
      );

      debugPrint('📩 onMessage title=$title body=$body data=${message.data}');

      if (mounted && (title.isNotEmpty || body.isNotEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title: $body')),
        );
      }
    });

    // ✅ User taps a notification while app is backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 onMessageOpenedApp data=${message.data}');
      _refreshLatestFromServer();
    });

    // ✅ App launched from terminated state via a notification tap
    Future.microtask(() async {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 getInitialMessage data=${initialMessage.data}');
        _refreshLatestFromServer();
      }
    });

    // ✅ Token fetch + backend registration + initial refresh
    Future.microtask(() async {
      try {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        debugPrint('🍎 APNs token: $apnsToken');
      } catch (e) {
        debugPrint('⚠️ getAPNSToken failed (can be normal early): $e');
      }

      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('🔑 FCM token: $fcmToken');
      } catch (e) {
        debugPrint('⚠️ getToken failed (can be normal early): $e');
      }

      await ref.read(pushRegistrationServiceProvider).registerIfPossible();

      // Initial load of server-backed latest
      _refreshLatestFromServer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ Refresh latest when app returns to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLatestFromServer();
    }
  }

  void _refreshLatestFromServer() {
    // Force the FutureProvider to re-run (so Home updates without needing rebuild timing)
    ref.invalidate(refreshLatestNotificationProvider(_debugUserName));
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp.router(
      title: 'Pubs Financial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
