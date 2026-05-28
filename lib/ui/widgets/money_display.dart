import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';

final _currencyFmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');

class MoneyDisplay extends StatelessWidget {
  final double amount;
  final double fontSize;
  final bool showSign;

  const MoneyDisplay({
    super.key,
    required this.amount,
    this.fontSize = 18,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    Color color;
    if (!showSign) {
      color = AppColors.gold;
    } else {
      color = isPositive ? AppColors.success : AppColors.danger;
    }

    final prefix = showSign && isPositive ? '+' : '';
    return Text(
      '$prefix${_currencyFmt.format(amount)}',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor ?? AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          if (subtitle != null)
            Text(subtitle!,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
