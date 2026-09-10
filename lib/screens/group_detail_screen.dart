import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../models/student_status.dart';
import '../theme/app_theme.dart';
import '../widgets/group_stats_card.dart';
import '../widgets/student_list_tile.dart';
import '../models/student_model.dart';
import 'student_detail_screen.dart';
import 'group_state_screen.dart';
import 'group_sessions_screen.dart';
import 'take_attendance_screen.dart';
import '../services/pdf_service.dart';
import '../models/schedule_slot.dart';
import '../widgets/group_edit_dialog.dart';
import '../widgets/group_notify_dialog.dart';
import '../l10n/app_localizations.dart';
import '../utils/phone_validator.dart';


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
            title: Text('${group.subject} - ${group.name}'),
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
              // Edit group button
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_rounded,
                      color: AppTheme.accent, size: 22),
                  tooltip: 'Modifier le groupe',
                  onPressed: () => GroupEditDialog.show(context, group),
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
                    const SizedBox(height: 12),
                    
                    // Button: Informer le groupe (Message/SMS)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send_rounded, size: 24),
                        label: const Text(
                          "Informer le groupe (Message/SMS)",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orange.withOpacity(0.15),
                          foregroundColor: AppTheme.orange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            side: const BorderSide(color: AppTheme.orange, width: 1.5),
                          ),
                        ),
                        onPressed: () {
                          final groupStudents = provider.getStudentsForGroup(widget.groupId);
                          GroupNotifyDialog.show(context, groupStudents, group.name);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Scheduling Section ──
                    if (provider.showRooms) ...[
                      _buildSchedulingSection(context, provider, group),
                      const SizedBox(height: 24),
                    ],

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
    final emailCtl = TextEditingController();
    final schoolCtl = TextEditingController();
    final priceCtl = TextEditingController(text: '100');
    final enrollmentFee = provider.enrollmentFee;
    final feeCtl = TextEditingController(text: enrollmentFee > 0 ? enrollmentFee.toStringAsFixed(0) : '0');
    bool chargeEnrollmentFee = enrollmentFee > 0;
    bool feeAutoExempted = false;
    String selectedPaymentMode = kPaymentModeCycle;

    // Labels dynamiques selon le mode
    String priceLabelFor(String mode) {
      switch (mode) {
        case kPaymentModeMonthly:    return 'Prix mensuel';
        case kPaymentModePerSession: return 'Prix par séance';
        default:                     return 'Prix par cycle (4 séances)';
      }
    }
    String defaultPriceFor(String mode) {
      switch (mode) {
        case kPaymentModeMonthly:    return '100';
        case kPaymentModePerSession: return '30';
        default:                     return '100';
      }
    }

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nouvel élève',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showSelectExistingStudentDialog(
                        context,
                        provider,
                        (selectedStudent) {
                          nameCtl.text = selectedStudent.name;
                          phoneCtl.text = selectedStudent.phone;
                          emailCtl.text = selectedStudent.email;
                          schoolCtl.text = selectedStudent.originSchool;
                          
                          if (enrollmentFee > 0) {
                            final val = selectedStudent.phone;
                            final nums = PhoneValidator.cleanAndSplit(val);
                            bool alreadyPaid = false;
                            for (var n in nums) {
                              if (provider.hasPaidEnrollmentFee(n)) {
                                alreadyPaid = true;
                                break;
                              }
                            }
                            setSt(() {
                              if (alreadyPaid) {
                                chargeEnrollmentFee = false;
                                feeAutoExempted = true;
                              } else {
                                chargeEnrollmentFee = enrollmentFee > 0;
                                feeAutoExempted = false;
                              }
                            });
                          } else {
                            setSt(() {});
                          }
                        },
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Élève existant'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                  onChanged: (val) {
                    if (enrollmentFee > 0) {
                      // Vérifier si AU MOINS UN des numéros a déjà payé les frais
                      final nums = PhoneValidator.cleanAndSplit(val);
                      bool alreadyPaid = false;
                      for (var n in nums) {
                        if (provider.hasPaidEnrollmentFee(n)) {
                          alreadyPaid = true;
                          break;
                        }
                      }
                      
                      if (alreadyPaid && chargeEnrollmentFee) {
                        setSt(() {
                          chargeEnrollmentFee = false;
                          feeAutoExempted = true;
                        });
                      } else if (!alreadyPaid && feeAutoExempted) {
                        setSt(() {
                          chargeEnrollmentFee = true;
                          feeAutoExempted = false;
                        });
                      }
                    }
                    setSt(() {}); // Pour canCreate
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email (optionnel)',
                    prefixIcon:
                        Icon(Icons.email_outlined, color: AppTheme.primary),
                  ),
                ),
                if (feeAutoExempted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 13, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Frais d\'inscription déjà payés dans une autre matière.',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // ── Mode de paiement ──────────────────────────────────
                const Text(
                  'Mode de paiement',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PayModeChip(
                      label: '4 Séances',
                      icon: Icons.repeat_rounded,
                      selected: selectedPaymentMode == kPaymentModeCycle,
                      onTap: () => setSt(() {
                        selectedPaymentMode = kPaymentModeCycle;
                        priceCtl.text = defaultPriceFor(kPaymentModeCycle);
                      }),
                    ),
                    const SizedBox(width: 8),
                    _PayModeChip(
                      label: 'Mensuel',
                      icon: Icons.calendar_month_rounded,
                      selected: selectedPaymentMode == kPaymentModeMonthly,
                      onTap: () => setSt(() {
                        selectedPaymentMode = kPaymentModeMonthly;
                        priceCtl.text = defaultPriceFor(kPaymentModeMonthly);
                      }),
                    ),
                    const SizedBox(width: 8),
                    _PayModeChip(
                      label: 'Par séance',
                      icon: Icons.looks_one_rounded,
                      selected: selectedPaymentMode == kPaymentModePerSession,
                      onTap: () => setSt(() {
                        selectedPaymentMode = kPaymentModePerSession;
                        priceCtl.text = defaultPriceFor(kPaymentModePerSession);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Prix selon mode ────────────────────────────────────
                TextField(
                  controller: priceCtl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: priceLabelFor(selectedPaymentMode),
                    prefixIcon:
                        const Icon(Icons.payments_outlined, color: AppTheme.primary),
                    suffixText: 'DT',
                  ),
                ),

                // ── Frais d'inscription (si configuré) ───────────────
                if (enrollmentFee > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.confirmation_number_outlined,
                                color: chargeEnrollmentFee
                                    ? AppTheme.primary
                                    : AppTheme.textMuted,
                                size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Frais d\'inscription',
                                style: TextStyle(
                                  color: chargeEnrollmentFee
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
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
                        if (chargeEnrollmentFee) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: feeCtl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Montant des frais d\'inscription',
                              prefixIcon: Icon(Icons.payments_outlined, size: 18),
                              suffixText: 'DT',
                              isDense: true,
                            ),
                          ),
                        ],
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
                      final name = nameCtl.text.trim();
                      final phone = phoneCtl.text.trim();
                      final phonesList = PhoneValidator.cleanAndSplit(phone);
                      
                      if (name.isEmpty) return;
                      // Validation: si téléphone présent, il doit être valide (8 chiffres)
                      if (phone.isNotEmpty && !PhoneValidator.isValidTunisianList(phonesList)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Chaque numéro doit faire 8 chiffres (Tunisie)')),
                        );
                        return;
                      }

                      final price = double.tryParse(priceCtl.text) ?? 100;
                      final finalEnrollmentFee = double.tryParse(feeCtl.text) ?? enrollmentFee;
                      provider.addStudent(
                        name,
                        phone,
                        widget.groupId,
                        selectedPaymentMode == kPaymentModeCycle ? price : 100,
                        enrollmentFeeAmount:
                            chargeEnrollmentFee ? finalEnrollmentFee : 0.0,
                        email: emailCtl.text.trim(),
                        originSchool: schoolCtl.text.trim(),
                        paymentMode: selectedPaymentMode,
                        pricePerMonth: selectedPaymentMode == kPaymentModeMonthly
                            ? price
                            : 100,
                        pricePerSession:
                            selectedPaymentMode == kPaymentModePerSession
                                ? price
                                : 30,
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

extension on _GroupDetailScreenState {
  Widget _buildSchedulingSection(BuildContext context, AppProvider provider, dynamic group) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.roomOccupation,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.edit_calendar, color: AppTheme.primary),
                onPressed: () => _showEditSchedulesDialog(context, provider, group),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildScheduleInfo(l.regularMode, group.regularSlots, provider.isAr),
          const SizedBox(height: 12),
          _buildScheduleInfo(l.holidayMode, group.holidaySlots, provider.isAr),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo(String title, List<ScheduleSlot> slots, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        if (slots.isEmpty)
          const Text('—', style: TextStyle(color: AppTheme.textMuted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: slots.map((s) => Chip(
              label: Text('${s.dayName(isAr)} ${s.timeRange}', style: const TextStyle(fontSize: 12)),
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
            )).toList(),
          ),
      ],
    );
  }

  void _showEditSchedulesDialog(BuildContext context, AppProvider provider, dynamic group) {
    List<ScheduleSlot> regular = List.from(group.regularSlots);
    List<ScheduleSlot> holiday = List.from(group.holidaySlots);
    final l = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Modifier les horaires', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              _buildEditableScheduleList(l.regularMode, regular, (s) => setSt(() => regular.add(s)), (s) => setSt(() => regular.remove(s)), provider.isAr),
              const Divider(height: 32),
              _buildEditableScheduleList(l.holidayMode, holiday, (s) => setSt(() => holiday.add(s)), (s) => setSt(() => holiday.remove(s)), provider.isAr),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    provider.updateGroupSchedules(group.id, regular, holiday);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableScheduleList(String title, List<ScheduleSlot> slots, Function(ScheduleSlot) onAdd, Function(ScheduleSlot) onRemove, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary), onPressed: () => _showAddSlotDialog(onAdd, isAr)),
          ],
        ),
        if (slots.isEmpty)
           const Padding(padding: EdgeInsets.only(left: 4), child: Text('Aucun créneau', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
        ...slots.map((s) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('${s.dayName(isAr)}: ${s.timeRange}', style: const TextStyle(color: AppTheme.textPrimary)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger), onPressed: () => onRemove(s)),
        )),
      ],
    );
  }

  void _showAddSlotDialog(Function(ScheduleSlot) onAdd, bool isAr) {
    int selectedDay = 1;
    TimeOfDay startTime = const TimeOfDay(hour: 14, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 16, minute: 0);

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Ajouter un créneau'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(
          value: selectedDay,
          dropdownColor: AppTheme.surface,
          items: List.generate(7, (i) => DropdownMenuItem(value: i+1, child: Text(_getDayName(i+1, isAr), style: const TextStyle(color: AppTheme.textPrimary)))),
          onChanged: (v) => setSt(() => selectedDay = v!),
          decoration: const InputDecoration(labelText: 'Jour'),
        ),
        const SizedBox(height: 12),
        ListTile(
          title: Text('Début: ${startTime.format(ctx)}', style: const TextStyle(color: AppTheme.textPrimary)),
          trailing: const Icon(Icons.access_time, color: AppTheme.primary),
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: startTime);
            if (t != null) setSt(() => startTime = t);
          },
        ),
        ListTile(
          title: Text('Fin: ${endTime.format(ctx)}', style: const TextStyle(color: AppTheme.textPrimary)),
          trailing: const Icon(Icons.access_time, color: AppTheme.primary),
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: endTime);
            if (t != null) setSt(() => endTime = t);
          },
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(onPressed: () {
          onAdd(ScheduleSlot(dayOfWeek: selectedDay, startHour: startTime.hour, startMinute: startTime.minute, endHour: endTime.hour, endMinute: endTime.minute));
          Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white), child: const Text('Ajouter')),
      ],
    )));
  }

  String _getDayName(int day, bool isAr) {
    if (isAr) {
      const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
      return days[day - 1];
    }
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[day - 1];
  }

  void _showSelectExistingStudentDialog(
      BuildContext context, AppProvider provider, Function(Student) onSelected) {
    final seen = <String>{};
    final uniqueStudents = <Student>[];
    for (final s in provider.students) {
      final key = '${s.name.toLowerCase().trim()}_${s.phone.trim()}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueStudents.add(s);
      }
    }

    final searchCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setSt) {
          final query = searchCtl.text.toLowerCase().trim();
          final filtered = uniqueStudents.where((s) {
            if (query.isEmpty) return true;
            return s.name.toLowerCase().contains(query) || s.phone.contains(query);
          }).toList();

          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Sélectionner un élève existant'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher par nom ou numéro...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (_) => setSt(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('Aucun élève trouvé',
                                style: TextStyle(color: AppTheme.textSecondary)))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final student = filtered[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                                  child: Text(
                                    student.name.isNotEmpty
                                        ? student.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: AppTheme.primary),
                                  ),
                                ),
                                title: Text(student.name,
                                    style: const TextStyle(color: AppTheme.textPrimary)),
                                subtitle: Text(student.phone,
                                    style: const TextStyle(color: AppTheme.textSecondary)),
                                onTap: () {
                                  _showConfirmAutomaticAddDialog(
                                    context,
                                    dialogCtx,
                                    provider,
                                    student,
                                    onSelected,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConfirmAutomaticAddDialog(
      BuildContext mainCtx,
      BuildContext dialogCtx,
      AppProvider provider,
      Student student,
      Function(Student) onSelected) {
    String selectedMode = student.paymentMode;
    double defaultPrice = student.effectivePrice;
    final priceCtl = TextEditingController(text: defaultPrice.toStringAsFixed(0));
    bool chargeEnrollmentFee = false;

    showDialog(
      context: dialogCtx,
      builder: (confirmCtx) => StatefulBuilder(
        builder: (confirmCtx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Ajouter ${student.name} ?', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inscrire automatiquement ${student.name} au groupe ? Ses informations seront copiées.',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Mode de paiement :', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PayModeChipConfirm(
                    label: '4 Séances',
                    selected: selectedMode == kPaymentModeCycle,
                    onTap: () => setSt(() {
                      selectedMode = kPaymentModeCycle;
                      priceCtl.text = '200';
                    }),
                  ),
                  const SizedBox(width: 8),
                  _PayModeChipConfirm(
                    label: 'Mensuel',
                    selected: selectedMode == kPaymentModeMonthly,
                    onTap: () => setSt(() {
                      selectedMode = kPaymentModeMonthly;
                      priceCtl.text = '200';
                    }),
                  ),
                  const SizedBox(width: 8),
                  _PayModeChipConfirm(
                    label: 'Par séance',
                    selected: selectedMode == kPaymentModePerSession,
                    onTap: () => setSt(() {
                      selectedMode = kPaymentModePerSession;
                      priceCtl.text = '50';
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceCtl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: selectedMode == kPaymentModeMonthly
                      ? 'Prix mensuel'
                      : selectedMode == kPaymentModePerSession
                          ? 'Prix par séance'
                          : 'Prix par cycle',
                  suffixText: 'DT',
                ),
              ),
              if (provider.enrollmentFee > 0) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Frais d\'inscription', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  subtitle: Text('${provider.enrollmentFee.toStringAsFixed(0)} DT (exempté par défaut)', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  value: chargeEnrollmentFee,
                  activeColor: AppTheme.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setSt(() => chargeEnrollmentFee = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                onSelected(student);
                Navigator.pop(confirmCtx);
                Navigator.pop(dialogCtx);
              },
              child: const Text('Remplir manuellement'),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceCtl.text) ?? 200;
                await provider.addStudent(
                  student.name,
                  student.phone,
                  widget.groupId,
                  selectedMode == kPaymentModeCycle ? price : 200,
                  enrollmentFeeAmount: chargeEnrollmentFee ? provider.enrollmentFee : 0.0,
                  email: student.email,
                  originSchool: student.originSchool,
                  paymentMode: selectedMode,
                  pricePerMonth: selectedMode == kPaymentModeMonthly ? price : 200,
                  pricePerSession: selectedMode == kPaymentModePerSession ? price : 50,
                );

                Navigator.pop(confirmCtx);
                Navigator.pop(dialogCtx);
                Navigator.pop(mainCtx); // Fermer le bottom sheet de création d'élève

                ScaffoldMessenger.of(mainCtx).showSnackBar(
                  SnackBar(
                    content: Text('✅ ${student.name} inscrit automatiquement !'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('Ajouter automatiquement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayModeChipConfirm extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PayModeChipConfirm({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withOpacity(0.15) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
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

/// Chip de sélection du mode de paiement
class _PayModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PayModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withOpacity(0.15)
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppTheme.primary : AppTheme.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
