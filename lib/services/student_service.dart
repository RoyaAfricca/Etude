import '../models/student_model.dart';
import '../models/student_status.dart';
import '../models/group_model.dart';

class GroupStats {
  final int totalStudents;
  final int upToDate;
  final int inProgress;
  final int dueSoon;
  final int overdue;
  final int totalSessions;
  final double totalRevenue;

  GroupStats({
    required this.totalStudents,
    required this.upToDate,
    required this.inProgress,
    required this.dueSoon,
    required this.overdue,
    required this.totalSessions,
    required this.totalRevenue,
  });

  double get upToDatePercent =>
      totalStudents == 0 ? 0 : (upToDate / totalStudents) * 100;
  double get overduePercent =>
      totalStudents == 0 ? 0 : (overdue / totalStudents) * 100;
  double get inProgressPercent =>
      totalStudents == 0 ? 0 : (inProgress / totalStudents) * 100;
  double get dueSoonPercent =>
      totalStudents == 0 ? 0 : (dueSoon / totalStudents) * 100;
}

class StudentService {
  static StudentStatus computeStatus(Student student) {
    switch (student.paymentMode) {
      case kPaymentModeMonthly:
        // Abonnement mensuel : à jour si l'abonnement est actif
        return student.isMonthlyActive
            ? StudentStatus.upToDate
            : StudentStatus.overdue;

      case kPaymentModePerSession:
        // Par séance : doit payer après chaque séance
        if (student.sessionsSincePayment == 0) return StudentStatus.upToDate;
        return StudentStatus.overdue;

      default: // kPaymentModeCycle (4 séances)
        if (student.sessionsSincePayment == 0) {
          return StudentStatus.upToDate;
        } else if (student.sessionsSincePayment < 4) {
          return StudentStatus.inProgress;
        } else if (student.sessionsSincePayment == 4) {
          return StudentStatus.dueSoon;
        } else {
          return StudentStatus.overdue;
        }
    }
  }


  static GroupStats getGroupStats(Group group, List<Student> students) {
    final groupStudents =
        students.where((s) => s.groupId == group.id).toList();

    int upToDate = 0, inProgress = 0, dueSoon = 0, overdue = 0;
    int totalSessions = 0;
    double totalRevenue = 0;

    for (final student in groupStudents) {
      final status = computeStatus(student);
      switch (status) {
        case StudentStatus.upToDate:
          upToDate++;
          break;
        case StudentStatus.inProgress:
          inProgress++;
          break;
        case StudentStatus.dueSoon:
          dueSoon++;
          break;
        case StudentStatus.overdue:
          overdue++;
          break;
      }
      totalSessions += student.attendances.length;
      totalRevenue += student.totalPaid;
    }

    return GroupStats(
      totalStudents: groupStudents.length,
      upToDate: upToDate,
      inProgress: inProgress,
      dueSoon: dueSoon,
      overdue: overdue,
      totalSessions: totalSessions,
      totalRevenue: totalRevenue,
    );
  }

  static List<Student> sortByStatus(List<Student> students) {
    final sorted = List<Student>.from(students);
    sorted.sort((a, b) {
      final statusA = computeStatus(a).sortOrder;
      final statusB = computeStatus(b).sortOrder;
      return statusA.compareTo(statusB);
    });
    return sorted;
  }

  static List<Student> filterByStatus(
      List<Student> students, StudentStatus? status) {
    if (status == null) return students;
    return students.where((s) => computeStatus(s) == status).toList();
  }
}
