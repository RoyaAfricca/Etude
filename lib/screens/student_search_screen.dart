import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../models/student_model.dart';
import '../models/group_model.dart';
import '../models/student_status.dart';
import '../services/student_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../utils/auth_helper.dart';
import 'student_detail_screen.dart';

class StudentSearchScreen extends StatefulWidget {
  const StudentSearchScreen({super.key});

  @override
  State<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  final _searchCtl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Rechercher un élève'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          // Filter students based on search query
          final filteredStudents = provider.students.where((student) {
            final query = _searchQuery.toLowerCase().trim();
            if (query.isEmpty) return true;
            return student.name.toLowerCase().contains(query) ||
                student.phone.contains(query);
          }).toList();

          return Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchCtl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom ou numéro...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                            onPressed: () {
                              _searchCtl.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),

              // Search results
              Expanded(
                child: filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 64,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Saisissez un nom ou numéro'
                                  : 'Aucun élève trouvé',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          final status = StudentService.computeStatus(student);
                          final group = provider.groups.firstWhere(
                            (g) => g.id == student.groupId,
                            orElse: () => Group(id: '', name: 'Sans groupe', subject: ''),
                          );

                          final allRegs = student.phone.trim().isNotEmpty
                              ? provider.getRegistrationsByPhone(student.phone)
                              : [student];

                          final regGroupStatusList = allRegs.map((reg) {
                            final g = provider.groups.firstWhere(
                              (grp) => grp.id == reg.groupId,
                              orElse: () => Group(id: '', name: 'Sans groupe', subject: ''),
                            );
                            final s = StudentService.computeStatus(reg);
                            return MapEntry(g, s);
                          }).toList();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: status.color.withOpacity(0.15),
                                child: Text(
                                  student.name.isNotEmpty
                                      ? student.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: status.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                student.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Groupe : ${group.subject} - ${group.name}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (allRegs.length > 1) ...[
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Inscrit également dans :',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: regGroupStatusList.where((entry) => entry.key.id != group.id).map((entry) {
                                        final g = entry.key;
                                        final stat = entry.value;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: stat.color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: stat.color.withOpacity(0.3), width: 0.5),
                                          ),
                                          child: Text(
                                            '${g.subject} (${stat.label})',
                                            style: TextStyle(
                                              color: stat.color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  if (student.phone.isNotEmpty || student.email.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (student.phone.isNotEmpty) ...[
                                          const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            student.phone,
                                            style: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        if (student.email.isNotEmpty) ...[
                                          const Icon(Icons.email_outlined, size: 12, color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              student.email,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppTheme.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Quick pay button
                                  IconButton(
                                    icon: const Icon(Icons.payments_rounded,
                                        color: AppTheme.success),
                                    tooltip: 'Enregistrer un paiement',
                                    onPressed: () =>
                                        _showQuickPaymentDialog(context, provider, student),
                                  ),
                                  const Icon(Icons.arrow_forward_ios,
                                      size: 14, color: AppTheme.textMuted),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StudentDetailScreen(studentId: student.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQuickPaymentDialog(
      BuildContext context, AppProvider provider, Student student) {
    final defaultPrice = student.effectivePrice;
    final amountCtl = TextEditingController(text: defaultPrice.toStringAsFixed(0));
    bool isEnrollment = false;
    int monthsDuration = 1;
    final enrollmentFee = provider.enrollmentFee;

    String paymentEffect(String mode) {
      switch (mode) {
        case kPaymentModeMonthly:
          return 'L\'abonnement sera validé pour $monthsDuration mois.';
        case kPaymentModePerSession:
          return 'La séance en cours sera marquée comme payée.';
        default:
          return 'Le compteur de séances sera déduit de 4 séances.';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Paiement pour ${student.name}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
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
              if (student.paymentMode == kPaymentModeMonthly && !isEnrollment) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Durée :', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    ...List.generate(3, (i) => i + 1).map((m) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$m mois'),
                        selected: monthsDuration == m,
                        selectedColor: AppTheme.primary.withOpacity(0.2),
                        onSelected: (_) => setSt(() {
                          monthsDuration = m;
                          amountCtl.text = (defaultPrice * m).toStringAsFixed(0);
                        }),
                      ),
                    )),
                  ],
                ),
              ],
              if (enrollmentFee > 0) ...[
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
              ],
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
                            : paymentEffect(student.paymentMode),
                        style: const TextStyle(
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
                final authenticated = await AuthHelper.authenticate(context,
                    reason: 'Confirmez le paiement par PIN ou Empreinte');

                if (!context.mounted) return;

                if (authenticated) {
                  final amount = double.tryParse(amountCtl.text) ?? defaultPrice;
                  provider.markAsPaid(student.id, amount,
                      isEnrollment: isEnrollment,
                      monthsDuration: monthsDuration);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '💰 ${isEnrollment ? 'Inscription' : 'Paiement'} de ${amount.toStringAsFixed(0)} DT enregistré pour ${student.name}'),
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
}
