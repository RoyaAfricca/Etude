import 'package:flutter/material.dart';
import '../models/student_status.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final StudentStatus status;
  final bool showLabel;
  final bool large;

  const StatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(large ? 12 : 20),
        border: Border.all(
          color: status.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            color: status.color,
            size: large ? 20 : 14,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              status.label,
              style: TextStyle(
                color: status.color,
                fontSize: large ? 14 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  final StudentStatus status;
  final double size;

  const StatusDot({
    super.key,
    required this.status,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: status.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: status.color.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
