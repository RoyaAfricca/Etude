import 'package:hive/hive.dart';
import 'payment_model.dart';

part 'student_model.g.dart';

@HiveType(typeId: 0)
class Student extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  int sessionsSincePayment;

  @HiveField(4)
  double pricePerCycle;

  @HiveField(5)
  List<DateTime> attendances;

  @HiveField(6)
  List<Payment> payments;

  @HiveField(7)
  String groupId;

  Student({
    required this.id,
    required this.name,
    this.phone = '',
    this.sessionsSincePayment = 0,
    this.pricePerCycle = 200.0,
    List<DateTime>? attendances,
    List<Payment>? payments,
    required this.groupId,
  })  : attendances = attendances ?? [],
        payments = payments ?? [];

  DateTime? get lastPaymentDate {
    if (payments.isEmpty) return null;
    payments.sort((a, b) => b.date.compareTo(a.date));
    return payments.first.date;
  }

  double get totalPaid {
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  int get sessionsRemaining {
    final remaining = 4 - sessionsSincePayment;
    return remaining > 0 ? remaining : 0;
  }
}
