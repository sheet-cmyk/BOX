import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:junior_boy_boxing/core/theme/app_theme.dart';
import 'package:junior_boy_boxing/features/admin/domain/admin_repository.dart';
import 'package:junior_boy_boxing/features/admin/presentation/providers/admin_provider.dart';
import 'package:junior_boy_boxing/features/admin/presentation/screens/admin_bookings_screen.dart';
import 'package:junior_boy_boxing/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:junior_boy_boxing/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:junior_boy_boxing/features/admin/presentation/screens/admin_subscriptions_screen.dart';
import 'package:junior_boy_boxing/features/admin/presentation/screens/ad_editor_screen.dart';
import 'package:junior_boy_boxing/features/sessions/domain/session_repository.dart';
import 'package:junior_boy_boxing/features/sessions/presentation/providers/session_provider.dart';
import 'package:junior_boy_boxing/features/sessions/presentation/screens/session_editor_screen.dart';
import 'package:junior_boy_boxing/features/blog/presentation/screens/blog_screen.dart';
import 'package:junior_boy_boxing/features/home/presentation/screens/home_screen.dart';
import 'package:junior_boy_boxing/features/home/presentation/providers/home_provider.dart';
import 'package:junior_boy_boxing/features/home/presentation/widgets/home_ads_section.dart';
import 'package:junior_boy_boxing/features/home/data/home_ad_model.dart';
import 'package:junior_boy_boxing/features/membership/data/membership_plan_model.dart';
import 'package:junior_boy_boxing/features/membership/presentation/providers/membership_provider.dart';
import 'package:junior_boy_boxing/features/payments/presentation/providers/payments_provider.dart';
import 'package:junior_boy_boxing/features/booking/presentation/providers/booking_provider.dart';
import 'package:junior_boy_boxing/features/notifications/presentation/providers/notification_provider.dart';
import 'package:junior_boy_boxing/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:junior_boy_boxing/features/profile/presentation/providers/profile_provider.dart';
import 'package:junior_boy_boxing/features/profile/data/member_model.dart';
import 'package:junior_boy_boxing/features/profile/domain/gym_settings.dart';
import 'package:junior_boy_boxing/features/profile/domain/waiver.dart';
import 'package:junior_boy_boxing/features/profile/presentation/screens/complete_profile_screen.dart';
import 'package:junior_boy_boxing/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:junior_boy_boxing/features/profile/presentation/screens/information_screen.dart';
import 'package:junior_boy_boxing/features/profile/presentation/screens/my_bookings_screen.dart';
import 'package:junior_boy_boxing/features/profile/presentation/screens/waiver_screen.dart';
import 'package:junior_boy_boxing/features/reviews/presentation/providers/review_provider.dart';
import 'package:junior_boy_boxing/features/reviews/domain/review.dart';
import 'package:junior_boy_boxing/features/reviews/presentation/screens/reviews_screen.dart';
import 'package:junior_boy_boxing/features/store/domain/product_repository.dart';
import 'package:junior_boy_boxing/features/store/presentation/providers/store_provider.dart';
import 'package:junior_boy_boxing/features/store/presentation/screens/product_editor_screen.dart';
import 'package:junior_boy_boxing/features/store/presentation/screens/store_screen.dart';

class _AdminFake implements AdminRepository {
  @override
  String newId() => 'test-plan';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProductFake implements ProductRepository {
  @override
  String newId() => 'test-product';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SessionFake implements SessionRepository {
  @override
  String newId() => 'test-session-card';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  GoogleFonts.config.allowRuntimeFetching = false;
  final sampleAd = HomeAdModel.fromMap({'id': 'ad', 'title': 'Train this week'});
  final samplePlan = MembershipPlanModel.fromMap({'id': 'ten', 'name': 'Ten Sessions', 'price': 60000, 'priceLabel': '\$600', 'perSessionLabel': '\$60 per session', 'sessionCount': 10});

  final screens = <String, Widget>{
    'admin dashboard': const AdminDashboardScreen(),
    'admin orders': const AdminOrdersScreen(),
    'admin subscriptions': const AdminSubscriptionsScreen(),
    'admin bookings': const AdminBookingsScreen(),
    'ad editor': const AdEditorScreen(),
    'session editor': const SessionEditorScreen(),
    'blog': const BlogScreen(),
    'home': const Scaffold(body: HomeScreen()),
    'home ads': const Scaffold(body: HomeAdsSection()),
    'notifications': const NotificationsScreen(),
    'complete profile': const CompleteProfileScreen(),
    'edit profile': const EditProfileScreen(),
    'my bookings': const MyBookingsScreen(),
    'waiver': const WaiverScreen(),
    'information': const InformationScreen(title: 'About'),
    'product editor': const ProductEditorScreen(),
    'store': const StoreScreen(),
    'reviews': const ReviewsScreen(),
  };

  for (final (mode, theme) in [('light', lightTheme), ('dark', darkTheme)]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} pumps in $mode mode', (tester) async {
        tester.view.physicalSize = const Size(900, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              adminRepositoryProvider.overrideWithValue(_AdminFake()),
              productRepositoryProvider.overrideWithValue(_ProductFake()),
              sessionRepositoryProvider.overrideWithValue(_SessionFake()),
              sessionsProvider.overrideWith((ref) => Stream.value([])),
              adminPlansProvider.overrideWith((ref) => Stream.value([])),
              adminOrdersProvider.overrideWith((ref) => Stream.value([])),
              adminBookingsProvider.overrideWith((ref) => Stream.value([])),
              adminAdsProvider.overrideWith((ref) => Stream.value([sampleAd])),
              homeAdsProvider.overrideWith((ref) => Stream.value([sampleAd])),
              plansProvider.overrideWith((ref) => Stream.value([samplePlan])),
              paymentsProvider.overrideWith((ref) => Stream.value([])),
              productsProvider.overrideWith((ref) => Stream.value([])),
              productsAdminProvider.overrideWith((ref) => Stream.value([])),
              bookingsProvider.overrideWith((ref) => Stream.value([])),
              notificationsProvider.overrideWith((ref) => Stream.value([])),
              reviewsProvider.overrideWith((ref) => Stream.value([])),
              myReviewProvider.overrideWith((ref) => null),
              reviewStatsProvider.overrideWith(
                (ref) => Stream.value(ReviewStats.empty),
              ),
              profileProvider.overrideWith(
                (ref) => Stream.value(
                  MemberModel.fromMap({
                    'id': 'test-user',
                    'fullName': 'Test Member',
                  }),
                ),
              ),
              settingsProvider.overrideWith(
                (ref) => Stream.value(GymSettings.empty),
              ),
              waiverProvider.overrideWith(
                (ref) => Stream.value(
                  const Waiver(
                    version: null,
                    body: null,
                    published: false,
                    requiredOnBooking: false,
                  ),
                ),
              ),
            ],
            child: MaterialApp(theme: theme, home: entry.value),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
