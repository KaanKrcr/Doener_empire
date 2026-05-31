import 'package:flutter/material.dart';

import '../../core/theme.dart';

class PremiumMetricData {
  final String label;
  final String value;
  final Color color;

  const PremiumMetricData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class PremiumMetricStrip extends StatelessWidget {
  final List<PremiumMetricData> items;
  final bool dense;

  const PremiumMetricStrip({
    super.key,
    required this.items,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 14,
        vertical: dense ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: PremiumInlineMetric(data: items[i])),
            if (i < items.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class PremiumDecisionSheet extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const PremiumDecisionSheet({
    super.key,
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PremiumSectionLabel extends StatelessWidget {
  final String text;

  const PremiumSectionLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.label(
        size: 10,
        color: AppColors.textMuted,
        letterSpacing: 1.3,
      ),
    );
  }
}

class PremiumDecisionLine extends StatelessWidget {
  final String text;

  const PremiumDecisionLine({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.3,
      ),
    );
  }
}

class PremiumInlineMetric extends StatelessWidget {
  final PremiumMetricData data;

  const PremiumInlineMetric({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.value,
          style: AppText.display(
            size: 14,
            color: data.color,
            weight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          data.label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

enum PremiumStatusTone {
  success,
  warning,
  danger,
}

class PremiumStatusHint extends StatelessWidget {
  final String text;
  final PremiumStatusTone tone;

  const PremiumStatusHint({
    super.key,
    required this.text,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      PremiumStatusTone.success => AppColors.accent,
      PremiumStatusTone.warning => AppColors.warning,
      PremiumStatusTone.danger => AppColors.danger,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
