import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../data/repositories/user_repository.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/phone_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/program_screen.dart';
import '../../features/profile/screens/waiver_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/booking/screens/book_class_screen.dart';
import '../../features/booking/screens/booking_confirmation_screen.dart';
import '../../features/membership/screens/membership_screen.dart';
import '../../features/profile/screens/more_screen.dart';
import '../../features/profile/screens/my_bookings_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/complete_profile_screen.dart';
import '../../features/profile/screens/notifications_screen.dart';
import '../../features/profile/screens/contact_screen.dart';
import '../../features/profile/screens/payments_screen.dart';
import '../widgets/jbb_bottom_nav.dart';
import '../constants/app_strings.dart';

final connectionProvider = StreamProvider(
  (ref) => Connectivity().onConnectivityChanged,
);
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, next) => refresh.value++);
  ref.listen(profileProvider, (_, next) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final profile = ref.read(profileProvider);
      final isAuth = [
        '/welcome',
        '/signin',
        '/signup',
        '/phone',
      ].contains(state.uri.path);
      if (auth.isLoading) return null;
      final user = auth.value;
      if (user == null && !isAuth) return '/welcome';
      final signedInWithGoogle =
          user != null &&
          !user.isAnonymous &&
          user.providerData.any((p) => p.providerId == 'google.com');
      if (signedInWithGoogle &&
          ![
            '/complete-profile',
            '/waiver',
            '/privacy',
            '/terms',
            '/contact',
          ].contains(state.uri.path) &&
          (profile.value != null && !isProfileComplete(profile.value!))) {
        return '/complete-profile';
}
      if (user != null && isAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/signin', builder: (c, s) => const SignInScreen()),
      GoRoute(path: '/signup', builder: (c, s) => const SignUpScreen()),
      GoRoute(path: '/phone', builder: (c, s) => const PhoneScreen()),
      ShellRoute(
        builder: (c, s, child) => _Shell(location: s.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(
            path: '/schedule',
            builder: (c, s) =>
                ScheduleScreen(programId: s.uri.queryParameters['program']),
          ),
          GoRoute(path: '/book', builder: (c, s) => const ScheduleScreen()),
          GoRoute(
            path: '/membership',
            builder: (c, s) => const MembershipScreen(),
          ),
          GoRoute(path: '/more', builder: (c, s) => const MoreScreen()),
        ],
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (c, s) => BookClassScreen(scheduleId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking-confirmed',
        builder: (c, s) => const BookingConfirmationScreen(),
      ),
      GoRoute(path: '/bookings', builder: (c, s) => const MyBookingsScreen()),
      GoRoute(path: '/profile', builder: (c, s) => const EditProfileScreen()),
      GoRoute(
        path: '/complete-profile',
        builder: (c, s) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (c, s) => const NotificationsScreen(),
      ),
      GoRoute(path: '/payments', builder: (c, s) => const PaymentsScreen()),
      GoRoute(path: '/contact', builder: (c, s) => const ContactScreen()),
      GoRoute(
        path: '/about',
        builder: (c, s) => const _InformationScreen(title: 'About Us'),
      ),
      GoRoute(
        path: '/privacy',
        builder: (c, s) => const _InformationScreen(
          title: 'Privacy Policy',
          text: AppStrings.privacy,
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (c, s) => const _InformationScreen(
          title: 'Terms of Service',
          text: AppStrings.terms,
        ),
      ),
      GoRoute(path: '/waiver', builder: (c, s) => const WaiverScreen()),
      GoRoute(
        path: '/programs/:id',
        builder: (c, s) => ProgramScreen(id: s.pathParameters['id']!),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _Shell extends ConsumerWidget {
  const _Shell({required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        ref
            .watch(connectionProvider)
            .value
            ?.contains(ConnectivityResult.none) ??
        false;
    final user = ref.watch(profileProvider).value;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (offline)
              Container(
                width: double.infinity,
                color: Colors.amber.shade900,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'Offline · Showing saved data',
                  textAlign: TextAlign.center,
                ),
              ),
            if (user?['isActive'] == false)
              const Expanded(
                child: Center(
                  child: Text('Your account is inactive. Contact the gym.'),
                ),
              )
            else
              Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: JbbBottomNav(location: location),
    );
  }
}

class _InformationScreen extends ConsumerWidget {
  const _InformationScreen({required this.title, this.text});
  final String title;
  final String? text;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        text ??
            ref.watch(settingsProvider).value?['aboutText'] ??
            'Discipline builds champions. Train, learn and grow at Junior Boy Boxing.',
        style: const TextStyle(height: 1.7),
      ),
    ),
  );
}
