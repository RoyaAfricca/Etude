import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../models/student_model.dart';
import '../theme/app_theme.dart';

class GroupSessionsScreen extends StatelessWidget {
  final String groupId;

  const GroupSessionsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final group = provider.groups.firstWhere((g) => g.id == groupId,
        orElse: () => provider.groups.first);
    final students = provider.getStudentsForGroup(groupId);

    // Aggregate attendances by Day to define "Sessions"
    // Map of 'yyyy-MM-dd' -> List of Students present
    final Map<String, List<Student>> sessionsMap = {};
    final Map<String, DateTime> sessionDates = {};

    for (final student in students) {
      for (final date in student.attendances) {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        if (!sessionsMap.containsKey(dateKey)) {
          sessionsMap[dateKey] = [];
          sessionDates[dateKey] = date;
        }
        // Avoid adding the same student twice for the same day if they double-clicked
        if (!sessionsMap[dateKey]!.any((s) => s.id == student.id)) {
          sessionsMap[dateKey]!.add(student);
        }
      }
    }

    // Sort sessions newest first
    final sortedSessionKeys = sessionsMap.keys.toList()
      ..sort((a, b) => sessionDates[b]!.compareTo(sessionDates[a]!));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text("Séances: ${group.subject} - ${group.name}"),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.cardBorder),
        ),
      ),
      body: sortedSessionKeys.isEmpty
          ? const Center(
              child: Text(
                'Aucune séance enregistrée pour ce groupe.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedSessionKeys.length,
              itemBuilder: (context, index) {
                final key = sortedSessionKeys[index];
                final date = sessionDates[key]!;
                final presentStudents = sessionsMap[key]!;
                
                // Sort students by name alphabetically within the session
                presentStudents.sort((a, b) => a.name.compareTo(b.name));

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Session Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppTheme.radiusLg),
                            topRight: Radius.circular(AppTheme.radiusLg),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.date_range, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${presentStudents.length} / ${students.length} présents',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Present Students List
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: presentStudents.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: AppTheme.success, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
