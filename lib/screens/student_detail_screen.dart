import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../models/student_status.dart';
import '../services/student_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/session_counter_widget.dart';
import 'student_state_screen.dart';
import '../utils/auth_helper.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        try {
          final student = provider.students.firstWhere(
            (s) => s.id == studentId,
            orElse: () => provider.students.first,
          );
        final status = StudentService.computeStatus(student);
        final group = provider.groups.firstWhere(
          (g) => g.id == student.groupId,
          orElse: () => provider.groups.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(student.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.textMuted),
                color: AppTheme.surfaceLight,
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirm(context, provider);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: AppTheme.danger, size: 18),
                        SizedBox(width: 8),
                        Text('Supprimer',
                            style: TextStyle(color: AppTheme.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: status.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: status.color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: status.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: status.color.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            student.name.isNotEmpty
                                ? student.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: status.color,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        student.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.name,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (student.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              student.phone,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      StatusBadge(status: status, large: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Button: État de l'élève
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.table_chart, size: 24),
                    label: const Text(
                      "État détaillé de l'élève",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent.withOpacity(0.15),
                      foregroundColor: AppTheme.accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        side: const BorderSide(color: AppTheme.accent, width: 1.5),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentStateScreen(studentId: studentId),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Session Counter ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school_outlined,
                              color: AppTheme.accent, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Compteur de séances',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SessionCounterWidget(
                          current: student.sessionsSincePayment),
                      const SizedBox(height: 8),
                      Text(
                        'Séances restantes avant paiement: ${student.sessionsRemaining}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Action Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.how_to_reg,
                        label: 'Marquer présent',
                        color: AppTheme.primary,
                        onTap: () {
                          provider.markAttendance(studentId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('✅ Présence marquée'),
                              backgroundColor: AppTheme.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.payments,
                        label: 'Marquer payé',
                        color: AppTheme.success,
                        onTap: () => _showPaymentDialog(
                            context, provider, student.pricePerCycle),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Boutons d'impression PDF
                Column(
                  children: [
                    // Bouton: Rapport complet élève
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                        label: const Text('Imprimer état complet de l\'élève'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        onPressed: () {
                          PdfService.printStudentReport(
                            context: context,
                            student: student,
                            group: group,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Bouton: Reçu dernier paiement
                    if (student.payments.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.receipt_rounded, size: 20),
                          label: const Text('Imprimer le reçu du dernier paiement'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            side: const BorderSide(color: AppTheme.accent, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                          onPressed: () {
                            final sortedPayments = List.of(student.payments)
                              ..sort((a, b) => b.date.compareTo(a.date));
                            PdfService.printStudentPaymentReceipt(
                              context: context,
                              student: student,
                              payment: sortedPayments.first,
                              group: group,
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Payment Info ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.payments_outlined,
                                  color: AppTheme.success, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Paiements',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              provider.showRevenue
                                  ? '${student.totalPaid.toStringAsFixed(0)} DT'
                                  : '•••• DT',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (student.lastPaymentDate != null)
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Dernier paiement: ${_formatDate(student.lastPaymentDate!)}',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Aucun paiement enregistré',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      if (student.payments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(color: AppTheme.cardBorder),
                        const SizedBox(height: 8),
                        ...student.payments
                            .reversed
                            .take(5)
                            .map((payment) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: AppTheme.success,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              provider.showRevenue
                                                  ? '${payment.amount.toStringAsFixed(0)} DT'
                                                  : '•••• DT',
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '${payment.sessionsCount} séances',
                                              style: TextStyle(
                                                color:
                                                    AppTheme.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _formatDate(payment.date),
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Attendance History ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.history,
                                  color: AppTheme.primaryLight, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Historique des présences',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryLight.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${student.attendances.length} total',
                              style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (student.attendances.isEmpty)
                        Text(
                          'Aucune présence enregistrée',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        )
                      else
                        ...List.generate(
                            student.attendances.length > 15
                                ? 15
                                : student.attendances.length, (index) {
                          final reversedIndex =
                              student.attendances.length - 1 - index;
                          final date = student.attendances[reversedIndex];
                          // The first 'sessionsSincePayment' items in the reversed list are unpaid
                          final isUnpaid =
                              index < student.sessionsSincePayment;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isUnpaid
                                  ? AppTheme.warning.withOpacity(0.08)
                                  : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: isUnpaid
                                  ? Border.all(
                                      color:
                                          AppTheme.warning.withOpacity(0.3))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isUnpaid
                                      ? Icons.timelapse
                                      : Icons.check_circle_outline,
                                  size: 16,
                                  color: isUnpaid
                                      ? AppTheme.warning
                                      : AppTheme.success,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _formatDate(date),
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: isUnpaid
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isUnpaid)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.warning.withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'À payer',
                                      style: TextStyle(
                                        color: AppTheme.warning,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  const Text(
                                    'Payée',
                                    style: TextStyle(
                                      color: AppTheme.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
        } catch (e, stackTrace) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erreur technique', style: TextStyle(color: Colors.white))),
            backgroundColor: Colors.black,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                'ERREUR DE LECTURE ELEVE:\n$e\n\nStack:\n$stackTrace',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          );
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'jan',
      'fév',
      'mars',
      'avr',
      'mai',
      'juin',
      'juil',
      'août',
      'sep',
      'oct',
      'nov',
      'déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showPaymentDialog(
      BuildContext context, AppProvider provider, double defaultPrice) {
    final amountCtl =
        TextEditingController(text: defaultPrice.toStringAsFixed(0));
    bool isEnrollment = false;
    final enrollmentFee = provider.enrollmentFee;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Confirmer le paiement',
              style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  suffixText: 'DT',
                  prefixIcon:
                      Icon(Icons.payments_outlined, color: AppTheme.success),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Frais d\'inscription',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                value: isEnrollment,
                activeColor: AppTheme.success,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) {
                  setSt(() {
                    isEnrollment = v;
                    if (isEnrollment) {
                      amountCtl.text = enrollmentFee.toStringAsFixed(0);
                    } else {
                      amountCtl.text = defaultPrice.toStringAsFixed(0);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnrollment
                      ? AppTheme.primary.withOpacity(0.1)
                      : AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isEnrollment
                          ? AppTheme.primary.withOpacity(0.2)
                          : AppTheme.success.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: isEnrollment ? AppTheme.primary : AppTheme.success,
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEnrollment
                            ? 'Le paiement sera enregistré comme frais d\'inscription.'
                            : 'Le compteur de séances sera déduit de 4 séances.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
                final authenticated =
                    await AuthHelper.showPasswordConfirmation(context);

                if (!context.mounted) return;

                if (authenticated) {
                  final amount = double.tryParse(amountCtl.text) ?? defaultPrice;
                  provider.markAsPaid(studentId, amount,
                      isEnrollment: isEnrollment);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '💰 ${isEnrollment ? 'Inscription' : 'Paiement'} de ${amount.toStringAsFixed(0)} DT enregistré'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Paiement annulé'),
                      backgroundColor: AppTheme.warning,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirmer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Supprimer l\'élève ?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Cet élève et tout son historique seront supprimés.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final authenticated = await AuthHelper.showPasswordConfirmation(context);

              if (!context.mounted) return;

              if (authenticated) {
                provider.deleteStudent(studentId);
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Élève supprimé avec succès'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Suppression annulée'),
                    backgroundColor: AppTheme.warning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
