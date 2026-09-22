import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../providers/auth_provider.dart';
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override ConsumerState<WelcomeScreen> createState() => _WelcomeState();
}
class _WelcomeState extends ConsumerState<WelcomeScreen> {
  bool busy = false;
  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try { await action(); if (mounted) context.go('/home'); }
    catch (e) { if (mounted) showMessage(context, friendlyError(e)); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: Column(children: [Image.asset(AppAssets.welcome, width: double.infinity, fit: BoxFit.cover, semanticLabel: 'Junior Boy Boxing'), Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 28), child: Column(children: [const Text(AppStrings.tagline, style: TextStyle(fontSize: 11, letterSpacing: 2.4)), const SizedBox(height: 26), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [for (final item in [('TRAIN','boxing_glove'),('LEARN','book_open'),('GROW','growth_chart')]) Column(children: [SvgPicture.asset('assets/icons/ic_${item.$2}.svg', width: 34, height: 34, colorFilter: const ColorFilter.mode(AppColors.red, BlendMode.srcIn)), const SizedBox(height: 12), Text(item.$1, style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w600))])]), const SizedBox(height: 30), FilledButton(onPressed: busy ? null : () => context.go('/signup'), child: const Text('Get Started  ›')), const SizedBox(height: 12), OutlinedButton(onPressed: busy ? null : () => context.go('/signin'), child: const Text('Sign In')), const SizedBox(height: 12), OutlinedButton(onPressed: busy ? null : () => run(() => ref.read(authRepositoryProvider).googleSignIn()), child: const Text('Continue with Google')), const SizedBox(height: 16), TextButton(onPressed: busy ? null : () => run(() => ref.read(authRepositoryProvider).continueAsGuest()), child: const Text('Skip')), const SizedBox(height: 10), const Text('Stronger Kids • Brighter Futures', style: TextStyle(color: AppColors.muted, letterSpacing: 1.2, fontSize: 12))]))]))))));
}
