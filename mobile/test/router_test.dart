import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:junior_boy_boxing/core/router/app_router.dart';
import 'package:junior_boy_boxing/features/auth/providers/auth_provider.dart';
import 'package:junior_boy_boxing/features/profile/providers/profile_provider.dart';
void main() {
  testWidgets('profile updates preserve the existing router and navigation state', (tester) async {
    final profiles = StreamController<Map<String,dynamic>>();
    final container = ProviderContainer(overrides:[authProvider.overrideWith((ref)=>Stream<User?>.value(null)),profileProvider.overrideWith((ref)=>profiles.stream)]);
    final router = container.read(routerProvider);
    profiles.add({'id':'member','sessionsRemaining':3});await tester.pump();
    expect(identical(container.read(routerProvider),router),isTrue);
    profiles.add({'id':'member','sessionsRemaining':4});await tester.pump();
    expect(identical(container.read(routerProvider),router),isTrue);
    container.dispose();await profiles.close();
  });
}
