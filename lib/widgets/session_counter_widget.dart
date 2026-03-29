import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SessionCounterWidget extends StatelessWidget {
  final int current;
  final int total;

  const SessionCounterWidget({
    super.key,
    required this.current,
    this.total = 4,
  });

  @override
  Widget build(BuildContext context) {
    final displayCurrent = current < 0 ? 0 : current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$displayCurrent',
              style: TextStyle(
                color: _getColor(),
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '/$total',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'séances',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(total, (index) {
            final isFilled = index < displayCurrent;
            final isOverflow = current > total && index == total - 1;
            return Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                height: 8,
                margin: EdgeInsets.only(right: index < total - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isFilled ? _getColor() : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: _getColor().withOpacity(0.4),
                            blurRadius: 4,
                          )
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        if (current < 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${-current} séance(s) payée(s) d\'avance',
              style: const TextStyle(
                color: AppTheme.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else if (current > total) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${current - total} séance(s) en dépassement',
              style: TextStyle(
                color: AppTheme.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getColor() {
    if (current <= 0) return AppTheme.success;
    if (current < 4) return AppTheme.warning;
    if (current == 4) return AppTheme.orange;
    return AppTheme.danger;
  }
}
