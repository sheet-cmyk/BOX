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
  static const useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  static const project = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'box-jbb',
  );
  static const host = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );
  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: useEmulators ? const FirebaseOptions(apiKey:'demo-api-key',appId:'1:123456789:android:demo',messagingSenderId:'123456789',projectId:'demo-jbb',storageBucket:'demo-jbb.appspot.com') : FirebaseOptions(
          apiKey: const String.fromEnvironment(
            'FIREBASE_API_KEY',
            defaultValue: 'AIzaSyDbRtbKQKE_Lle6SYd3OeQcehFVnbte-uo',
          ),
          appId: const String.fromEnvironment(
            'FIREBASE_APP_ID',
            defaultValue: '1:772438105367:android:33effdddc1c2550aa66b52',
          ),
          messagingSenderId: const String.fromEnvironment(
            'FIREBASE_MESSAGING_SENDER_ID',
            defaultValue: '772438105367',
          ),
          projectId: project,
          storageBucket: const String.fromEnvironment(
            'FIREBASE_STORAGE_BUCKET',
            defaultValue: 'box-jbb.firebasestorage.app',
          ),
        ),
      );
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    if (useEmulators) {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    } else {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        !kDebugMode,
      );
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        !kDebugMode,
      );
    }
  }
}
