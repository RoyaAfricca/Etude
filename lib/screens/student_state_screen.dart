import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/auth_helper.dart';

class StudentStateScreen extends StatelessWidget {
  final String studentId;

  const StudentStateScreen({super.key, required this.studentId});

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final student = provider.students.firstWhere((s) => s.id == studentId);
    final group = provider.groups.firstWhere((g) => g.id == student.groupId);

    // All sessions, newest first
    final sortedAttendances = List<DateTime>.from(student.attendances)
      ..sort((a, b) => b.compareTo(a));

    final hasPendingSessions = student.sessionsSincePayment > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(student.name),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cardBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Identity Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(group.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        'Séances non payées: ${student.sessionsSincePayment} / 4',
                        style: TextStyle(
                          color: student.sessionsSincePayment >= 4 ? AppTheme.danger : AppTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Pay Button ──
            if (hasPendingSessions)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payments_rounded, size: 22),
                  label: const Text(
                    'Confirmer le paiement (1 mois = 4 séances)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  onPressed: () => _showPaymentDialog(context, provider, student.pricePerCycle),
                ),
              ),

            if (hasPendingSessions) const SizedBox(height: 24),

            // ── Attendances Table (full year) ──
            Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Présences cette année (${student.attendances.length} séances)',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (sortedAttendances.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Center(
                  child: Text('Aucune présence enregistrée.',
                    style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 30,
                    headingRowColor: WidgetStateProperty.all(AppTheme.surfaceLight),
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('Date et Heure')),
                      DataColumn(label: Text('Situation')),
                    ],
                    rows: List.generate(sortedAttendances.length, (index) {
                      final date = sortedAttendances[index];
                      final isUnpaid = index < student.sessionsSincePayment;
                      return DataRow(
                        color: WidgetStateProperty.all(
                          isUnpaid ? AppTheme.danger.withOpacity(0.05) : Colors.transparent,
                        ),
                        cells: [
                          DataCell(Text('${sortedAttendances.length - index}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
                          DataCell(Text(_formatDate(date),
                            style: const TextStyle(color: AppTheme.textSecondary))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUnpaid
                                    ? AppTheme.danger.withOpacity(0.1)
                                    : AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isUnpaid ? '⏳ À payer' : '✅ Payée',
                                style: TextStyle(
                                  color: isUnpaid ? AppTheme.danger : AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // ── Payments Table ──
            Row(
              children: [
                const Icon(Icons.paid_rounded, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Paiements effectués (${student.payments.length})',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (student.payments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Center(
                  child: Text('Aucun paiement enregistré.',
                    style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 25,
                    headingRowColor: WidgetStateProperty.all(AppTheme.surfaceLight),
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    columns: const [
                      DataColumn(label: Text('Date du paiement')),
                      DataColumn(label: Text('Séances')),
                      DataColumn(label: Text('Montant')),
                    ],
                    rows: student.payments.reversed.map((p) {
                      return DataRow(
                        cells: [
                          DataCell(Text(_formatDate(p.date),
                            style: const TextStyle(color: AppTheme.textSecondary))),
                          DataCell(Text('${p.sessionsCount} séances',
                            style: const TextStyle(color: AppTheme.textSecondary))),
                          DataCell(
                            Text(
                              provider.showRevenue
                                  ? '${p.amount.toStringAsFixed(0)} DT'
                                  : '•••• DT',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: AppTheme.accent),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(
      BuildContext context, AppProvider provider, double defaultPrice) {
    final amountCtl = TextEditingController(
        text: defaultPrice.toStringAsFixed(0));
    final student = provider.students.firstWhere((s) => s.id == studentId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.success),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${student.sessionsSincePayment} séances seront marquées payées',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
              final authenticated = await AuthHelper.showPasswordConfirmation(context);

              if (!context.mounted) return;

              if (authenticated) {
                final amount = double.tryParse(amountCtl.text) ?? defaultPrice;
                await provider.markAsPaid(studentId, amount);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('💰 Paiement de ${amount.toStringAsFixed(0)} DT enregistré'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                        borderRadius: BorderRadius.circular(10)),
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
    );
  }
}
