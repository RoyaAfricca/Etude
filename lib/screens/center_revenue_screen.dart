import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/center_service.dart';
import '../theme/app_theme.dart';

class CenterRevenueScreen extends StatefulWidget {
  const CenterRevenueScreen({super.key});

  @override
  State<CenterRevenueScreen> createState() => _CenterRevenueScreenState();
}

class _CenterRevenueScreenState extends State<CenterRevenueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  static const _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final teachers = provider.teachers;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Revenus du Centre'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Mensuel'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Annuel'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthlyView(provider, teachers),
          _buildAnnualView(provider, teachers),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(AppProvider provider, List<Teacher> teachers) {
    final totalMonth = _getMonthRevenue(provider, _selectedYear, _selectedMonth);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SelectorDropdown(
                  label: 'Mois',
                  value: _selectedMonth,
                  items: List.generate(
                      12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i]))),
                  onChanged: (v) => setState(() => _selectedMonth = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SelectorDropdown(
                  label: 'Année',
                  value: _selectedYear,
                  items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                          value: DateTime.now().year - 2 + i,
                          child: Text((DateTime.now().year - 2 + i).toString()))),
                  onChanged: (v) => setState(() => _selectedYear = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _RevenueCard(
            title: '${_months[_selectedMonth - 1]} $_selectedYear',
            totalRevenue: totalMonth,
            subtitle: 'Total encaissé',
            icon: Icons.account_balance_wallet_rounded,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 20),
          if (teachers.isEmpty)
            _EmptyTeachersCard()
          else ...[
            Text('Par Enseignant',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            ...teachers.map((t) {
              final teacherRevenue = _getTeacherMonthRevenue(
                  provider, t.id, _selectedYear, _selectedMonth);
              final sessionCount = _getTeacherSessionCount(
                  provider, t.id, _selectedYear, _selectedMonth);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TeacherRevenueCard(
                  teacher: t,
                  totalRevenue: teacherRevenue,
                  sessionCount: sessionCount,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAnnualView(AppProvider provider, List<Teacher> teachers) {
    final totalYear = _getYearRevenue(provider, _selectedYear);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectorDropdown(
            label: 'Année',
            value: _selectedYear,
            items: List.generate(
                5,
                (i) => DropdownMenuItem(
                    value: DateTime.now().year - 2 + i,
                    child: Text((DateTime.now().year - 2 + i).toString()))),
            onChanged: (v) => setState(() => _selectedYear = v!),
          ),
          const SizedBox(height: 20),
          _RevenueCard(
            title: 'Année $_selectedYear',
            totalRevenue: totalYear,
            subtitle: 'Total annuel encaissé',
            icon: Icons.bar_chart_rounded,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 20),

          // Tableau mensuel
          Text('Détail par mois',
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: List.generate(12, (i) {
                final monthRev = _getMonthRevenue(provider, _selectedYear, i + 1);
                final isCurrentMonth = i + 1 == DateTime.now().month &&
                    _selectedYear == DateTime.now().year;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrentMonth
                        ? AppTheme.primary.withOpacity(0.08)
                        : Colors.transparent,
                    border: Border(
                      bottom: i < 11
                          ? const BorderSide(color: AppTheme.cardBorder, width: 0.5)
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_months[i],
                          style: GoogleFonts.outfit(
                              color: isCurrentMonth
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontWeight: isCurrentMonth
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      const Spacer(),
                      Text(
                        '${NumberFormat('#,###').format(monthRev.toInt())} DT',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: monthRev > 0
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Par enseignant annuel
          if (teachers.isNotEmpty) ...[
            Text('Par Enseignant (Annuel)',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            ...teachers.map((t) {
              final teacherRevenue =
                  _getTeacherYearRevenue(provider, t.id, _selectedYear);
              final sessionCount =
                  _getTeacherYearSessionCount(provider, t.id, _selectedYear);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TeacherRevenueCard(
                  teacher: t,
                  totalRevenue: teacherRevenue,
                  sessionCount: sessionCount,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  double _getMonthRevenue(AppProvider provider, int year, int month) {
    return provider.getMonthlyRevenuesForYear(year)[month] ?? 0.0;
  }

  double _getYearRevenue(AppProvider provider, int year) {
    return provider.getAnnualRevenue(year);
  }

  double _getTeacherMonthRevenue(
      AppProvider provider, String teacherId, int year, int month) {
    final groups = provider.groups.where((g) => g.teacherId == teacherId);
    double total = 0;
    for (final g in groups) {
      final students = provider.getStudentsForGroup(g.id);
      for (final s in students) {
        for (final p in s.payments) {
          if (p.date.year == year && p.date.month == month) {
            total += p.amount;
          }
        }
      }
    }
    return total;
  }

  /// Nombre de séances (jours uniques d'appel) pour un prof donné, dans un mois.
  int _getTeacherSessionCount(
      AppProvider provider, String teacherId, int year, int month) {
    final groups = provider.groups.where((g) => g.teacherId == teacherId);
    final Set<String> uniqueDays = {};
    for (final g in groups) {
      final students = provider.getStudentsForGroup(g.id);
      for (final s in students) {
        for (final date in s.attendances) {
          if (date.year == year && date.month == month) {
            // Clé unique : groupId + jour pour ne pas doubler
            uniqueDays.add('${g.id}_${date.year}${date.month}${date.day}');
          }
        }
      }
    }
    return uniqueDays.length;
  }

  double _getTeacherYearRevenue(
      AppProvider provider, String teacherId, int year) {
    final groups = provider.groups.where((g) => g.teacherId == teacherId);
    double total = 0;
    for (final g in groups) {
      final students = provider.getStudentsForGroup(g.id);
      for (final s in students) {
        for (final p in s.payments) {
          if (p.date.year == year) total += p.amount;
        }
      }
    }
    return total;
  }

  /// Nombre de séances (jours uniques d'appel) pour un prof donné, dans une année.
  int _getTeacherYearSessionCount(
      AppProvider provider, String teacherId, int year) {
    final groups = provider.groups.where((g) => g.teacherId == teacherId);
    final Set<String> uniqueDays = {};
    for (final g in groups) {
      final students = provider.getStudentsForGroup(g.id);
      for (final s in students) {
        for (final date in s.attendances) {
          if (date.year == year) {
            uniqueDays.add('${g.id}_${date.year}${date.month}${date.day}');
          }
        }
      }
    }
    return uniqueDays.length;
  }
}

// ── Widgets utilitaires ────────────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  final String title;
  final double totalRevenue;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _RevenueCard({
    required this.title,
    required this.totalRevenue,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 14, color: AppTheme.textSecondary)),
              Text(
                '${NumberFormat('#,###').format(totalRevenue.toInt())} DT',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherRevenueCard extends StatelessWidget {
  final Teacher teacher;
  final double totalRevenue;
  final int sessionCount;

  const _TeacherRevenueCard({
    required this.teacher,
    required this.totalRevenue,
    this.sessionCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final teacherShare = teacher.teacherShare(totalRevenue, sessionCount: sessionCount);
    final centerShare = teacher.centerShare(totalRevenue, sessionCount: sessionCount);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_rounded,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(teacher.name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(teacher.contractType.label,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Total
          _RevRow(
              label: 'Total Généré',
              amount: totalRevenue,
              color: AppTheme.textPrimary,
              isBold: true),
          const Divider(color: AppTheme.cardBorder, height: 18),
          _RevRow(
              label: '👨‍🏫 Part Enseignant',
              amount: teacherShare,
              color: AppTheme.success),
          const SizedBox(height: 6),
          _RevRow(
              label: '🏫 Part Centre',
              amount: centerShare,
              color: AppTheme.accent),
        ],
      ),
    );
  }
}

class _RevRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isBold;

  const _RevRow(
      {required this.label,
      required this.amount,
      required this.color,
      this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400)),
        const Spacer(),
        Text(
          '${NumberFormat('#,###').format(amount.toInt())} DT',
          style: GoogleFonts.outfit(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _EmptyTeachersCard extends StatelessWidget {
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
        children: [
          const Icon(Icons.person_add_alt_1_outlined,
              size: 40, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text('Aucun enseignant configuré',
              style: GoogleFonts.outfit(color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Text('Ajoutez-en via Gestion du Centre',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _SelectorDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SelectorDropdown(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppTheme.surface,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
