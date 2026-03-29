import 'package:flutter/material.dart';

enum StudentStatus {
  upToDate,    // 🟢 À jour
  inProgress,  // 🟡 En cours
  dueSoon,     // 🟠 À payer bientôt
  overdue,     // 🔴 En retard
}

extension StudentStatusExtension on StudentStatus {
  String get label {
    switch (this) {
      case StudentStatus.upToDate:
        return 'À jour';
      case StudentStatus.inProgress:
        return 'En cours';
      case StudentStatus.dueSoon:
        return 'À payer bientôt';
      case StudentStatus.overdue:
        return 'En retard';
    }
  }

  String get emoji {
    switch (this) {
      case StudentStatus.upToDate:
        return '🟢';
      case StudentStatus.inProgress:
        return '🟡';
      case StudentStatus.dueSoon:
        return '🟠';
      case StudentStatus.overdue:
        return '🔴';
    }
  }

  Color get color {
    switch (this) {
      case StudentStatus.upToDate:
        return const Color(0xFF4CAF50);
      case StudentStatus.inProgress:
        return const Color(0xFFFFC107);
      case StudentStatus.dueSoon:
        return const Color(0xFFFF9800);
      case StudentStatus.overdue:
        return const Color(0xFFF44336);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case StudentStatus.upToDate:
        return const Color(0xFF4CAF50).withOpacity(0.15);
      case StudentStatus.inProgress:
        return const Color(0xFFFFC107).withOpacity(0.15);
      case StudentStatus.dueSoon:
        return const Color(0xFFFF9800).withOpacity(0.15);
      case StudentStatus.overdue:
        return const Color(0xFFF44336).withOpacity(0.15);
    }
  }

  IconData get icon {
    switch (this) {
      case StudentStatus.upToDate:
        return Icons.check_circle;
      case StudentStatus.inProgress:
        return Icons.timelapse;
      case StudentStatus.dueSoon:
        return Icons.warning_amber;
      case StudentStatus.overdue:
        return Icons.error;
    }
  }

  int get sortOrder {
    switch (this) {
      case StudentStatus.overdue:
        return 0;
      case StudentStatus.dueSoon:
        return 1;
      case StudentStatus.inProgress:
        return 2;
      case StudentStatus.upToDate:
        return 3;
    }
  }
}
