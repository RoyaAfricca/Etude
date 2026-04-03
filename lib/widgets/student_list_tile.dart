import 'package:flutter/material.dart';
import '../models/student_model.dart';
// import '../models/student_status.dart';
import '../services/student_service.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class StudentListTile extends StatelessWidget {
  final Student student;
  final VoidCallback? onTap;
  final VoidCallback? onAttendance;

  const StudentListTile({
    super.key,
    required this.student,
    this.onTap,
    this.onAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final status = StudentService.computeStatus(student);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                // Status indicator
                StatusDot(status: status),
                const SizedBox(width: 12),
                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 13,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${student.sessionsSincePayment}/4 séances',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                StatusBadge(status: status, showLabel: true),
                const SizedBox(width: 8),
                // Quick attendance button
                if (onAttendance != null)
                  GestureDetector(
                    onTap: onAttendance,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.primary,
                        size: 20,
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
