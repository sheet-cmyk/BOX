import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
class JbbBottomNav extends StatelessWidget {
  const JbbBottomNav({super.key, required this.location});
  final String location;
  static const routes = ['/home', '/schedule', '/book', '/membership', '/more'];
  @override Widget build(BuildContext context) {
    final index = routes.indexWhere((p) => location == p || location.startsWith('$p/'));
    return NavigationBar(height: 64, backgroundColor: AppColors.background, indicatorColor: Colors.transparent, selectedIndex: index < 0 ? 4 : index, onDestinationSelected: (i) => context.go(routes[i]), destinations: [for (final item in [('Home','home'),('Schedule','schedule'),('Book','book'),('Membership','membership'),('More','more')]) NavigationDestination(icon: SvgPicture.asset('assets/icons/ic_nav_${item.$2}.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)), selectedIcon: SvgPicture.asset('assets/icons/ic_nav_${item.$2}.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(AppColors.red, BlendMode.srcIn)), label: item.$1)]);
  }
}
