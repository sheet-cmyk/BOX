import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

abstract final class FirebaseService {
  static const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: true);
  static const project = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'demo-jbb');
  static const host = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      if (useEmulators || const String.fromEnvironment('FIREBASE_API_KEY').isNotEmpty) {
        await Firebase.initializeApp(options: const FirebaseOptions(apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'demo-api-key'), appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:123456789:android:demo'), messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '123456789'), projectId: project, storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'demo-jbb.appspot.com')));
      } else {
        await Firebase.initializeApp();
      }
    }
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
    if (useEmulators) {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    } else {
      await FirebaseAppCheck.instance.activate(providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider());
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) { FirebaseCrashlytics.instance.recordError(error, stack, fatal: true); return true; };
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(!kDebugMode);
    }
  }
}
