import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'section_card.dart';

class FeatureCardSection extends StatelessWidget {
  const FeatureCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'こんなことができます',
      child: Column(
        children: const [
          _FeatureRow(
            icon: Icons.calendar_month_rounded,
            color: AppTheme.primary,
            title: 'Google カレンダー連携',
            description: 'イベントを自動インポートして記録管理',
          ),
          SizedBox(height: AppTheme.spacingMd),
          _FeatureRow(
            icon: Icons.photo_library_rounded,
            color: Color(0xFF7C4DFF),
            title: '写真・メモを一括管理',
            description: 'イベントごとに記録を自動整理',
          ),
          SizedBox(height: AppTheme.spacingMd),
          _FeatureRow(
            icon: Icons.bar_chart_rounded,
            color: Color(0xFF00BCD4),
            title: '分析でパターン発見',
            description: '週次・月次の振り返りで習慣化',
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.titleMedium),
              const SizedBox(height: 2),
              Text(description, style: AppTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
