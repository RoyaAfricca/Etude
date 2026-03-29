import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/student_service.dart';
import '../theme/app_theme.dart';

class GroupStatsCard extends StatelessWidget {
  final GroupStats stats;

  const GroupStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'État du groupe',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.people,
                label: '${stats.totalStudents}',
                subtitle: 'Élèves',
                color: AppTheme.accent,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.event_available,
                label: '${stats.totalSessions}',
                subtitle: 'Séances',
                color: AppTheme.primaryLight,
              ),
              const SizedBox(width: 12),
              Consumer<AppProvider>(
                builder: (_, provider, __) => _StatChip(
                  icon: Icons.payments,
                  label: provider.showRevenue
                      ? '${stats.totalRevenue.toStringAsFixed(0)} DT'
                      : '•••• DT',
                  subtitle: 'Revenus',
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          if (stats.totalStudents > 0) ...[
            const Text(
              'Répartition des statuts',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            _StatusProgressBar(stats: stats),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _LegendItem(
                  color: AppTheme.success,
                  label: 'À jour (${stats.upToDate})',
                ),
                _LegendItem(
                  color: AppTheme.warning,
                  label: 'En cours (${stats.inProgress})',
                ),
                _LegendItem(
                  color: AppTheme.orange,
                  label: 'À payer (${stats.dueSoon})',
                ),
                _LegendItem(
                  color: AppTheme.danger,
                  label: 'En retard (${stats.overdue})',
                ),
              ],
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Aucun élève dans ce groupe',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusProgressBar extends StatelessWidget {
  final GroupStats stats;

  const _StatusProgressBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalStudents.toDouble();
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            if (stats.upToDate > 0)
              Flexible(
                flex: stats.upToDate,
                child: Container(color: AppTheme.success),
              ),
            if (stats.inProgress > 0)
              Flexible(
                flex: stats.inProgress,
                child: Container(color: AppTheme.warning),
              ),
            if (stats.dueSoon > 0)
              Flexible(
                flex: stats.dueSoon,
                child: Container(color: AppTheme.orange),
              ),
            if (stats.overdue > 0)
              Flexible(
                flex: stats.overdue,
                child: Container(color: AppTheme.danger),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
