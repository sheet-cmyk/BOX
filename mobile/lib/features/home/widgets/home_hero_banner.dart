import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// Full-screen-sized brand hero image for the top of Home, with the
/// welcome greeting overlaid on a dark gradient scrim, followed by the
/// gym's promotional banner strip directly beneath it.
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: double.infinity,
            height: screenHeight * 0.65,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AppAssets.homeHero,
                  fit: BoxFit.cover,
                  semanticLabel: 'Junior Boy Boxing',
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Welcome Back, ',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: '$name!',
                                style: const TextStyle(color: AppColors.red),
                              ),
                            ],
                          ),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Keep training. Keep improving.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            AppAssets.header,
            fit: BoxFit.fitWidth,
            semanticLabel: 'Junior Boy Boxing. Discipline builds champions.',
          ),
        ),
      ],
    );
  }
}
