import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../models/student_status.dart';
import '../theme/app_theme.dart';
import '../widgets/group_stats_card.dart';
import '../widgets/student_list_tile.dart';
import 'student_detail_screen.dart';
import 'group_state_screen.dart';
import 'group_sessions_screen.dart';
import 'take_attendance_screen.dart';
import '../services/pdf_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  StudentStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final group = provider.groups.firstWhere(
          (g) => g.id == widget.groupId,
          orElse: () => provider.groups.first,
        );
        final stats = provider.getGroupStats(group);
        final students = provider.getStudentsForGroupFiltered(
            widget.groupId, _filterStatus);

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Mark all attendance
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.how_to_reg,
                      color: AppTheme.primary, size: 22),
                  tooltip: 'Marquer présence (tout le groupe)',
                  onPressed: () => _confirmGroupAttendance(context, provider),
                ),
              ),
            ],
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Group info header
                    Row(
                      children: [
                        if (group.subject.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.book_outlined,
                                    size: 14, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                Text(group.subject,
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (group.schedule.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule,
                                    size: 14, color: AppTheme.accent),
                                const SizedBox(width: 4),
                                Text(group.schedule,
                                    style: TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stats card
                    GroupStatsCard(stats: stats),
                    const SizedBox(height: 24),

                    // ── Main Action: Faire l'appel ──
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.fact_check_rounded, size: 26),
                        label: const Text(
                          "Faire l'appel (Nouvelle séance)",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TakeAttendanceScreen(groupId: widget.groupId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Button: État détaillé du groupe
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.analytics, size: 24),
                        label: const Text(
                          "État détaillé du groupe",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary.withOpacity(0.15),
                          foregroundColor: AppTheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            side: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupStateScreen(groupId: widget.groupId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Button: État détaillé par séance
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_month, size: 24),
                        label: const Text(
                          "État détaillé par séance",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary.withOpacity(0.15),
                          foregroundColor: AppTheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            side: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupSessionsScreen(groupId: widget.groupId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Button: Imprimer état PDF du groupe
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 24),
                        label: const Text(
                          "Imprimer état du groupe (PDF)",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
                          foregroundColor: const Color(0xFF6C63FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                          ),
                        ),
                        onPressed: () {
                          final groupStudents = provider.getStudentsForGroup(widget.groupId);
                          // Trouver le nom de l'enseignant si applicable
                          String? teacherName;
                          if (group.teacherId != null && group.teacherId!.isNotEmpty) {
                            try {
                              final t = provider.teachers.firstWhere(
                                  (t) => t.id == group.teacherId);
                              teacherName = t.name;
                            } catch (_) {}
                          }
                          PdfService.printGroupReport(
                            context: context,
                            group: group,
                            students: groupStudents,
                            teacherName: teacherName,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Tous',
                            isSelected: _filterStatus == null,
                            onTap: () =>
                                setState(() => _filterStatus = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '🔴 En retard',
                            isSelected:
                                _filterStatus == StudentStatus.overdue,
                            onTap: () => setState(() => _filterStatus =
                                _filterStatus == StudentStatus.overdue
                                    ? null
                                    : StudentStatus.overdue),
                            color: AppTheme.danger,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '🟠 À payer',
                            isSelected:
                                _filterStatus == StudentStatus.dueSoon,
                            onTap: () => setState(() => _filterStatus =
                                _filterStatus == StudentStatus.dueSoon
                                    ? null
                                    : StudentStatus.dueSoon),
                            color: AppTheme.orange,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '🟡 En cours',
                            isSelected:
                                _filterStatus == StudentStatus.inProgress,
                            onTap: () => setState(() => _filterStatus =
                                _filterStatus == StudentStatus.inProgress
                                    ? null
                                    : StudentStatus.inProgress),
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '🟢 À jour',
                            isSelected:
                                _filterStatus == StudentStatus.upToDate,
                            onTap: () => setState(() => _filterStatus =
                                _filterStatus == StudentStatus.upToDate
                                    ? null
                                    : StudentStatus.upToDate),
                            color: AppTheme.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Students header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Élèves (${students.length})',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Student list
                    if (students.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.person_add_outlined,
                                size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              _filterStatus != null
                                  ? 'Aucun élève avec ce statut'
                                  : 'Aucun élève dans ce groupe',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...students.map((student) => StudentListTile(
                            student: student,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentDetailScreen(
                                      studentId: student.id),
                                ),
                              );
                            },
                            onAttendance: () {
                              provider.markAttendance(student.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '✅ Présence marquée pour ${student.name}'),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                          )),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddStudentDialog(context, provider),
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }

  void _confirmGroupAttendance(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Marquer présence du groupe ?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Tous les élèves du groupe seront marqués présents pour cette séance.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.markGroupAttendance(widget.groupId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('✅ Présence marquée pour tout le groupe'),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, AppProvider provider) {
    final nameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final priceCtl = TextEditingController(text: '200');
    final enrollmentFee = provider.enrollmentFee;
    bool chargeEnrollmentFee = enrollmentFee > 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nouvel élève',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtl,
                  autofocus: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'élève',
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    prefixIcon:
                        Icon(Icons.phone_outlined, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Prix par cycle (4 séances)',
                    prefixIcon:
                        Icon(Icons.payments_outlined, color: AppTheme.primary),
                    suffixText: 'DT',
                  ),
                ),
                // ── Frais d'inscription (si configuré) ───────────────
                if (enrollmentFee > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: chargeEnrollmentFee
                          ? AppTheme.primary.withOpacity(0.1)
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: chargeEnrollmentFee
                            ? AppTheme.primary
                            : AppTheme.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.confirmation_number_outlined,
                            color: chargeEnrollmentFee
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                            size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Frais d\'inscription',
                                style: TextStyle(
                                  color: chargeEnrollmentFee
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${enrollmentFee.toStringAsFixed(0)} DT',
                                style: TextStyle(
                                  color: chargeEnrollmentFee
                                      ? AppTheme.primary
                                      : AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: chargeEnrollmentFee,
                          activeColor: AppTheme.primary,
                          onChanged: (v) =>
                              setSt(() => chargeEnrollmentFee = v),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtl.text.trim().isEmpty) return;
                      final price = double.tryParse(priceCtl.text) ?? 200;
                      provider.addStudent(
                        nameCtl.text.trim(),
                        phoneCtl.text.trim(),
                        widget.groupId,
                        price,
                        enrollmentFeeAmount:
                            chargeEnrollmentFee ? enrollmentFee : 0.0,
                      );
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ajouter l\'élève',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppTheme.primary).withOpacity(0.2)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppTheme.primary)
                : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (color ?? AppTheme.primary)
                : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
