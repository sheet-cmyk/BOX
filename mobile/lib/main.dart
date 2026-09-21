import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as timezone;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/services/firebase_service.dart';
import 'data/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  timezone.initializeTimeZones();
  await Hive.initFlutter();
  await Hive.openBox('jbb_cache');
  await Hive.openBox('jbb_device');
  try {
    await FirebaseService.initialize();
    if (!FirebaseService.useEmulators) FirebaseMessaging.onBackgroundMessage(backgroundMessage);
    runApp(const ProviderScope(child: JbbApp()));
  } catch (_) {
    runApp(MaterialApp(theme: buildTheme(), home: const Scaffold(body: SafeArea(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('Junior Boy Boxing could not start. Check the Firebase configuration and rebuild the app. For local development, enable USE_FIREBASE_EMULATORS.')))))));
  }
}
class JbbApp extends ConsumerWidget {
  const JbbApp({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    NotificationService.instance.navigate = (path) => router.go(path);
    ref.listen(authProvider, (previous, next) { if (next.value != null && previous?.value?.uid != next.value?.uid) NotificationService.instance.register().catchError((Object error) {}); });
    return MaterialApp.router(title: 'Junior Boy Boxing', debugShowCheckedModeBanner: false, theme: buildTheme(), routerConfig: router);
  }
}
