import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../services/center_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final l = AppLocalizations.of(context);
        final teachers = provider.teachers;
        final centerName = provider.centerName;

        return Scaffold(
          appBar: AppBar(
            title: Text(l.teacherReport),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sélecteur de mois ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCard,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month,
                          color: AppTheme.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.settlementPeriod,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              _monthLabel(_selectedMonth, l),
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Prev month
                      IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: AppTheme.textSecondary),
                        onPressed: () => setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                          );
                        }),
                      ),
                      // Next month
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: AppTheme.textSecondary),
                        onPressed: () => setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Liste des enseignants ──────────────────────────────────
                Text(
                  l.teachers,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (teachers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.glassCard,
                    child: Column(
                      children: [
                        Icon(Icons.person_off_outlined,
                            size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          l.noData,
                          style: GoogleFonts.outfit(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...teachers.map(
                    (teacher) => _TeacherReportCard(
                      teacher: teacher,
                      provider: provider,
                      selectedMonth: _selectedMonth,
                      centerName: centerName,
                      l: l,
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  String _monthLabel(DateTime d, AppLocalizations l) =>
      '${l.monthName(d.month)} ${d.year}';
}

// ─── Carte Enseignant ─────────────────────────────────────────────────────────
class _TeacherReportCard extends StatelessWidget {
  final Teacher teacher;
  final AppProvider provider;
  final DateTime selectedMonth;
  final String centerName;
  final AppLocalizations l;

  const _TeacherReportCard({
    required this.teacher,
    required this.provider,
    required this.selectedMonth,
    required this.centerName,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    // Groupes de cet enseignant
    final groups = provider.groups
        .where((g) => g.teacherId == teacher.id)
        .toList();
    final allStudents = provider.students;

    // Calculs rapides pour le mois
    double totalRevenue = 0;
    int totalSessions = 0;
    for (final g in groups) {
      final gs = allStudents.where((s) => s.groupId == g.id);
      for (final s in gs) {
        for (final p in s.payments) {
          if (p.date.year == selectedMonth.year &&
              p.date.month == selectedMonth.month) {
            totalRevenue += p.amount;
          }
        }
        for (final d in s.attendances) {
          if (d.year == selectedMonth.year && d.month == selectedMonth.month) {
            totalSessions++;
          }
        }
      }
    }
    final teacherShare =
        teacher.teacherShare(totalRevenue, sessionCount: totalSessions);
    final centerShare =
        teacher.centerShare(totalRevenue, sessionCount: totalSessions);

    final contractColor = _contractColor(teacher.contractType);
    final contractLabel = _contractLabel(teacher.contractType, l);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête enseignant
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [contractColor, contractColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?',
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
                      teacher.name,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: contractColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            contractLabel,
                            style: TextStyle(
                              color: contractColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${groups.length} ${l.groups}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.cardBorder),
          const SizedBox(height: 12),

          // Stats financières
          Row(
            children: [
              if (teacher.contractType != TeacherContractType.locateur)
                _StatChip(
                  label: l.grossRevenue,
                  value: '${totalRevenue.toInt()} ${l.currency}',
                  color: AppTheme.primary,
                )
              else
                _StatChip(
                  label: 'Séances effectuées',
                  value: '$totalSessions',
                  color: AppTheme.primary,
                ),
              const SizedBox(width: 8),
              _StatChip(
                label: teacher.contractType == TeacherContractType.locateur 
                    ? 'Bénéfice Professeur' 
                    : l.toTeacher,
                value: '${teacherShare.toInt()} ${l.currency}',
                color: AppTheme.success,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: teacher.contractType == TeacherContractType.locateur 
                    ? 'Loyer Centre' 
                    : l.toCenter,
                value: '${centerShare.toInt()} ${l.currency}',
                color: AppTheme.accent,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bouton Imprimer
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: Text(
                '${l.print} — ${l.teacherReport} & ${l.teacherPaymentReceipt}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              onPressed: () {
                PdfService.printTeacherReport(
                  context: context,
                  teacher: teacher,
                  groups: groups,
                  allStudents: allStudents,
                  centerName: centerName,
                  forMonth: selectedMonth,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _contractColor(TeacherContractType t) {
    switch (t) {
      case TeacherContractType.salarie:
        return const Color(0xFF00BCD4);
      case TeacherContractType.locateur:
        return const Color(0xFFFF9800);
      case TeacherContractType.pourcentage:
        return const Color(0xFF6C63FF);
    }
  }

  String _contractLabel(TeacherContractType t, AppLocalizations l) {
    switch (t) {
      case TeacherContractType.salarie:
        return l.contractSalarie;
      case TeacherContractType.locateur:
        return l.contractLocateur;
      case TeacherContractType.pourcentage:
        return l.contractPourcentage;
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
