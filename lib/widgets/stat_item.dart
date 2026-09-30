import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.violet),
          ),
        ],
      ),
    );
  }
}
