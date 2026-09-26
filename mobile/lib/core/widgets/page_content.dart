import 'package:flutter/material.dart';
import '../constants/app_assets.dart';

class PageContent extends StatelessWidget {
  const PageContent({
    super.key,
    required this.children,
    this.title,
    this.refresh,
    this.showHeader = true,
  });
  final List<Widget> children;
  final String? title;
  final Future<void> Function()? refresh;
  final bool showHeader;
  @override
  Widget build(BuildContext context) {
    final view = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        if (showHeader) ...[
          Image.asset(
            AppAssets.header,
            fit: BoxFit.fitWidth,
            semanticLabel: 'Junior Boy Boxing. Discipline builds champions.',
          ),
          const SizedBox(height: 24),
        ],
        if (title != null) ...[
          Text(title!, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
        ],
        ...children,
      ],
    );
    return refresh == null
        ? view
        : RefreshIndicator(onRefresh: refresh!, child: view);
  }
}
