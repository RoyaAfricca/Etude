import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../models/student_status.dart';
import '../services/student_service.dart';
import '../theme/app_theme.dart';

class GroupStateScreen extends StatelessWidget {
  final String groupId;

  const GroupStateScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final group = provider.groups.firstWhere((g) => g.id == groupId);
    final students = provider.getStudentsForGroupSorted(groupId);
    final stats = provider.getGroupStats(group);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text("État: ${group.subject} - ${group.name}"),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Info Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Horaire: ${group.schedule}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                   const SizedBox(height: 12),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Total élèves: ${stats.totalStudents}', style: const TextStyle(color: AppTheme.textSecondary)),
                       Text('À jour: ${stats.upToDate}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                       Text('En retard: ${stats.overdue}', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                     ],
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Students Table
            const Text(
              'Tableau récapitulatif des élèves',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (students.isEmpty)
              const Text('Aucun élève dans ce groupe.', style: TextStyle(color: AppTheme.textSecondary))
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
                    columnSpacing: 20,
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    columns: const [
                      DataColumn(label: Text('Nom')),
                      DataColumn(label: Text('Séances au compteur')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Total Payé')),
                    ],
                    rows: students.map((s) {
                      final status = StudentService.computeStatus(s);
                      return DataRow(
                        cells: [
                          DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
                          DataCell(Text('${s.sessionsSincePayment} / 4', style: const TextStyle(color: AppTheme.textSecondary))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.label,
                                style: TextStyle(
                                  color: status.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          ),
                          DataCell(
                            Text(
                              provider.showRevenue ? '${s.totalPaid.toStringAsFixed(0)} DT' : '•••• DT',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent),
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
}
