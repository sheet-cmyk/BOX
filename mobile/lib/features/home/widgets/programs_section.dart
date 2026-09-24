import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/jbb_card.dart';

class ProgramsSection extends StatelessWidget {
  const ProgramsSection({super.key});
  static const _textPrograms = [
    ('ic_boxing_glove', 'Boxing Training'),
    ('ic_dumbbell', 'Fitness Training'),
    ('ic_triple_glove', 'Strength & Conditioning'),
    ('ic_growth_chart', 'Weight Loss Training'),
    ('ic_shield_privacy', 'Self Defense Training'),
  ];
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Our Programs', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      for (final item in [
        (AppAssets.junior, 'Junior Boxing — Kids & Teens'),
        (AppAssets.group, 'Group Training — 3–4 People'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            button: true,
            label: 'View ${item.$2} schedule',
            child: InkWell(
              onTap: () => context.go('/schedule'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.$1,
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ),
      for (final item in _textPrograms)
        JbbCard(
          onTap: () => context.push(
            '/programs/${['boxing', 'fitness', 'strength', 'weight-loss', 'self-defense'][_textPrograms.indexOf(item)]}',
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/${item.$1}.svg',
                width: 26,
                height: 26,
                colorFilter: const ColorFilter.mode(
                  AppColors.red,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
    ],
  );
}
