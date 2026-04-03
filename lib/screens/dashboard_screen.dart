import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:local_auth/local_auth.dart';

import '../providers/app_provider.dart';
import '../services/student_service.dart';
import '../models/student_status.dart';
import '../theme/app_theme.dart';
import 'groups_screen.dart';
import 'center_settings_screen.dart';
import 'center_revenue_screen.dart';
import 'login_screen.dart';
import 'teacher_reports_screen.dart';
import '../l10n/app_localizations.dart';
import 'room_occupation_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final l = AppLocalizations.of(context);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.background,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Consumer<AppProvider>(
                    builder: (context, provider, _) {
                      final l = AppLocalizations.of(context);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.appName.split(' ')[0],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            l.appName.contains('-') ? l.appName.split('-')[1].trim() : 'Gestion des séances',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                actions: [
                  // Bouton Centre (si mode Centre activé)
                  Builder(builder: (ctx) {
                    if (!provider.isCenterMode) return const SizedBox.shrink();
                    return PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.corporate_fare_rounded,
                            color: AppTheme.accent, size: 20),
                      ),
                      color: AppTheme.surface,
                      onSelected: (value) {
                        if (value == 'settings') {
                          Navigator.push(ctx,
                              MaterialPageRoute(builder: (_) => const CenterSettingsScreen()));
                        } else if (value == 'revenue') {
                          Navigator.push(ctx,
                              MaterialPageRoute(builder: (_) => const CenterRevenueScreen()));
                        } else if (value == 'reports') {
                          Navigator.push(ctx,
                              MaterialPageRoute(builder: (_) => const TeacherReportsScreen()));
                        }
                      },
                      itemBuilder: (_) {
                        final l = AppLocalizations.of(context);
                        return [
                          PopupMenuItem(
                            value: 'revenue',
                            child: Row(children: [
                              const Icon(Icons.bar_chart_rounded, color: AppTheme.primary, size: 18),
                              const SizedBox(width: 10),
                              Text('Revenus du Centre',
                                  style: TextStyle(color: AppTheme.textPrimary)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'reports',
                            child: Row(children: [
                              const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.success, size: 18),
                              const SizedBox(width: 10),
                              Text(l.teacherReport,
                                  style: TextStyle(color: AppTheme.textPrimary)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'settings',
                            child: Row(children: [
                              const Icon(Icons.manage_accounts_rounded, color: AppTheme.accent, size: 18),
                              const SizedBox(width: 10),
                              Text('Gestion du Centre',
                                  style: TextStyle(color: AppTheme.textPrimary)),
                            ]),
                          ),
                        ];
                      },
                    );
                  }),
                  // Mode Vacances Toggle
                  _buildHolidayToggle(context, provider),
                  // Reset button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.restart_alt_rounded,
                          color: AppTheme.danger),
                      tooltip: 'Nouvelle année scolaire',
                      onPressed: () => _showResetDialog(context, provider),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout_rounded,
                          color: AppTheme.textSecondary),
                      tooltip: 'Déconnexion',
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      ),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    // ── Revenue Card ──
                    _RevenueCard(
                      totalRevenue: provider.totalRevenue,
                      monthlyRevenue: provider.monthlyRevenue,
                      totalSessions: provider.totalSessions,
                      totalStudents: provider.students.length,
                      showRevenue: provider.showRevenue,
                      onToggleRevenue: provider.toggleRevenue,
                    ),
                    const SizedBox(height: 20),

                    // ── Quick Stats ──
                    _QuickStatsRow(provider: provider),
                    const SizedBox(height: 24),

                    // ── Financial Report ──
                    _FinancialReportCard(provider: provider),
                    const SizedBox(height: 24),

                    // ── Status Distribution ──
                    if (provider.students.isNotEmpty) ...[
                      _SectionTitle(title: 'Distribution des statuts'),
                      const SizedBox(height: 12),
                      _StatusPieChart(provider: provider),
                      const SizedBox(height: 24),
                    ],

                    // ── Problematic Groups ──
                    if (provider.problematicGroups.isNotEmpty) ...[
                      _SectionTitle(
                          title: 'Groupes en difficulté',
                          icon: Icons.warning_amber_rounded,
                          color: AppTheme.danger),
                      const SizedBox(height: 12),
                      ...provider.problematicGroups.map((group) {
                        final stats = provider.getGroupStats(group);
                        return _ProblematicGroupCard(
                          name: group.name,
                          subject: group.subject,
                          overdueCount: stats.overdue,
                          totalStudents: stats.totalStudents,
                          overduePercent: stats.overduePercent,
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // ── Room Occupation ──
                    if (provider.showRooms) ...[
                      _ActionCard(
                        title: l.roomOccupation,
                        subtitle: provider.isHolidayMode ? l.holidayMode : l.regularMode,
                        icon: Icons.meeting_room_rounded,
                        color: Colors.teal,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomOccupationScreen())),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Groups Overview ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(title: 'Mes groupes'),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const GroupsScreen()),
                            );
                          },
                          icon: const Text(
                            'Voir tout',
                            style: TextStyle(color: AppTheme.primary),
                          ),
                          label: const Icon(Icons.arrow_forward_ios,
                              size: 12, color: AppTheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (provider.groups.isEmpty)
                      _EmptyState(
                        icon: Icons.groups_outlined,
                        message: 'Aucun groupe créé',
                        subtitle: 'Commencez par créer votre premier groupe',
                        onAction: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const GroupsScreen()),
                          );
                        },
                        actionLabel: 'Créer un groupe',
                      )
                    else
                      ...provider.groups.take(3).map((group) {
                        final stats = provider.getGroupStats(group);
                        return _GroupMiniCard(
                          name: group.name,
                          subject: group.subject,
                          stats: stats,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const GroupsScreen()),
                            );
                          },
                        );
                      }),
                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroupsScreen()),
          );
        },
        icon: const Icon(Icons.groups),
        label: const Text('Groupes'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  void _showResetDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 26),
            const SizedBox(width: 10),
            const Text('Nouvelle année scolaire',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
              ),
              child: const Text(
                '⚠️ Tous les groupes, élèves, présences et paiements seront supprimés définitivement.\n\n'
                'Cette action est irréversible et sert à démarrer une nouvelle année scolaire à zéro !',
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx); // fermer le dialog de confirmation d'action
              bool confirmed = false;

              if (Platform.isWindows) {
                // Sur Windows : double confirmation par saisie de 'RESET'
                confirmed = await _showWindowsResetConfirmDialog(context);
              } else {
                // Sur Android : authentification biométrique
                final auth = LocalAuthentication();
                try {
                  confirmed = await auth.authenticate(
                    localizedReason:
                        'Confirmez la REMISE À ZÉRO par Code PIN / Empreinte',
                  );
                } catch (e) {
                  debugPrint('Reset auth error: $e');
                }
              }

              if (!context.mounted) return;

              if (confirmed) {
                await provider.resetNewYear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        '✅ Données effacées. Bonne nouvelle année scolaire !'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Remise à zéro annulée'),
                    backgroundColor: AppTheme.warning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Réinitialiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog de confirmation pour la remise à zéro sur Windows (sans biométrie).
  Future<bool> _showWindowsResetConfirmDialog(BuildContext context) async {
    final controller = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.danger, size: 26),
            const SizedBox(width: 10),
            const Text(
              'Confirmation finale',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tapez RESET pour confirmer la remise à zéro complète :',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'RESET',
                hintStyle: TextStyle(
                  color: AppTheme.textMuted,
                  letterSpacing: 2,
                ),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide:
                      const BorderSide(color: AppTheme.danger, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                  dialogCtx, controller.text.trim().toUpperCase() == 'RESET');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result ?? false;
  }

}

// ── Revenue Card ──
class _RevenueCard extends StatelessWidget {
  final double totalRevenue;
  final double monthlyRevenue;
  final int totalSessions;
  final int totalStudents;
  final bool showRevenue;
  final VoidCallback onToggleRevenue;

  const _RevenueCard({
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.totalSessions,
    required this.totalStudents,
    required this.showRevenue,
    required this.onToggleRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenus totaux',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  // 👁 Toggle visibility button
                  GestureDetector(
                    onTap: onToggleRevenue,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        showRevenue ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '💰 Total',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              showRevenue ? '${totalRevenue.toStringAsFixed(0)} DT' : '•••• DT',
              key: ValueKey(showRevenue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Monthly revenue highlight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Ce mois-ci: ',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  showRevenue
                      ? '${monthlyRevenue.toStringAsFixed(0)} DT'
                      : '•••• DT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                icon: Icons.people_outline,
                value: '$totalStudents',
                label: 'Élèves',
              ),
              const SizedBox(width: 24),
              _MiniStat(
                icon: Icons.calendar_today_outlined,
                value: '$totalSessions',
                label: 'Séances',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}

// ── Quick Stats Row ──
class _QuickStatsRow extends StatelessWidget {
  final AppProvider provider;

  const _QuickStatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    int upToDate = 0, inProgress = 0, dueSoon = 0, overdue = 0;
    for (final s in provider.students) {
      final status = StudentService.computeStatus(s);
      switch (status) {
        case StudentStatus.upToDate:
          upToDate++;
          break;
        case StudentStatus.inProgress:
          inProgress++;
          break;
        case StudentStatus.dueSoon:
          dueSoon++;
          break;
        case StudentStatus.overdue:
          overdue++;
          break;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            label: 'À jour',
            count: upToDate,
            color: AppTheme.success,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickStatCard(
            label: 'En cours',
            count: inProgress,
            color: AppTheme.warning,
            icon: Icons.timelapse,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickStatCard(
            label: 'À payer',
            count: dueSoon,
            color: AppTheme.orange,
            icon: Icons.warning_amber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickStatCard(
            label: 'En retard',
            count: overdue,
            color: AppTheme.danger,
            icon: Icons.error_outline,
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _QuickStatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Status Pie Chart ──
class _StatusPieChart extends StatelessWidget {
  final AppProvider provider;

  const _StatusPieChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    int upToDate = 0, inProgress = 0, dueSoon = 0, overdue = 0;
    for (final s in provider.students) {
      final status = StudentService.computeStatus(s);
      switch (status) {
        case StudentStatus.upToDate:
          upToDate++;
          break;
        case StudentStatus.inProgress:
          inProgress++;
          break;
        case StudentStatus.dueSoon:
          dueSoon++;
          break;
        case StudentStatus.overdue:
          overdue++;
          break;
      }
    }
    final total = provider.students.length.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 30,
                  sections: [
                    if (upToDate > 0)
                      PieChartSectionData(
                        value: upToDate.toDouble(),
                        color: AppTheme.success,
                        title:
                            '${(upToDate / total * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        radius: 50,
                      ),
                    if (inProgress > 0)
                      PieChartSectionData(
                        value: inProgress.toDouble(),
                        color: AppTheme.warning,
                        title:
                            '${(inProgress / total * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        radius: 50,
                      ),
                    if (dueSoon > 0)
                      PieChartSectionData(
                        value: dueSoon.toDouble(),
                        color: AppTheme.orange,
                        title: '${(dueSoon / total * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        radius: 50,
                      ),
                    if (overdue > 0)
                      PieChartSectionData(
                        value: overdue.toDouble(),
                        color: AppTheme.danger,
                        title: '${(overdue / total * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        radius: 50,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChartLegend(
                    color: AppTheme.success, label: 'À jour', count: upToDate),
                const SizedBox(height: 8),
                _ChartLegend(
                    color: AppTheme.warning,
                    label: 'En cours',
                    count: inProgress),
                const SizedBox(height: 8),
                _ChartLegend(
                    color: AppTheme.orange, label: 'À payer', count: dueSoon),
                const SizedBox(height: 8),
                _ChartLegend(
                    color: AppTheme.danger, label: 'En retard', count: overdue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _ChartLegend(
      {required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ── Problematic Group Card ──
class _ProblematicGroupCard extends StatelessWidget {
  final String name;
  final String subject;
  final int overdueCount;
  final int totalStudents;
  final double overduePercent;

  const _ProblematicGroupCard({
    required this.name,
    required this.subject,
    required this.overdueCount,
    required this.totalStudents,
    required this.overduePercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_rounded,
                color: AppTheme.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$subject - $name',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$overdueCount/$totalStudents en retard',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${overduePercent.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Group Mini Card ──
class _GroupMiniCard extends StatelessWidget {
  final String name;
  final String subject;
  final GroupStats stats;
  final VoidCallback onTap;

  const _GroupMiniCard({
    required this.name,
    required this.subject,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$subject - $name',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stats.totalStudents} élèves',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (stats.totalStudents > 0) ...[
                  // Mini status bar
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          children: [
                            if (stats.upToDate > 0)
                              Flexible(
                                  flex: stats.upToDate,
                                  child: Container(color: AppTheme.success)),
                            if (stats.inProgress > 0)
                              Flexible(
                                  flex: stats.inProgress,
                                  child: Container(color: AppTheme.warning)),
                            if (stats.dueSoon > 0)
                              Flexible(
                                  flex: stats.dueSoon,
                                  child: Container(color: AppTheme.orange)),
                            if (stats.overdue > 0)
                              Flexible(
                                  flex: stats.overdue,
                                  child: Container(color: AppTheme.danger)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    color: AppTheme.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section Title ──
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;

  const _SectionTitle({required this.title, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: color ?? AppTheme.textPrimary, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            color: color ?? AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Empty State ──
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Financial Report Card ──
class _FinancialReportCard extends StatelessWidget {
  final AppProvider provider;

  const _FinancialReportCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rapport Financier',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Revenus totaux: ${provider.showRevenue ? provider.totalRevenue.toStringAsFixed(0) : '••••'} DT',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Revenus mensuels: ${provider.showRevenue ? provider.monthlyRevenue.toStringAsFixed(0) : '••••'} DT',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

extension on DashboardScreen {
  Widget _buildHolidayToggle(BuildContext context, AppProvider provider) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: provider.isHolidayMode ? AppTheme.accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: provider.isHolidayMode ? AppTheme.accent : AppTheme.textMuted.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.isHolidayMode ? l.holidayMode : l.regularMode,
              style: TextStyle(
                fontSize: 10,
                color: provider.isHolidayMode ? AppTheme.accent : AppTheme.textSecondary,
                fontWeight: provider.isHolidayMode ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            SizedBox(
              height: 24,
              child: Switch(
                value: provider.isHolidayMode,
                onChanged: (val) => provider.setHolidayMode(val),
                activeColor: AppTheme.accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: color.withOpacity(0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
