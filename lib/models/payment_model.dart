import 'package:hive/hive.dart';

part 'payment_model.g.dart';

@HiveType(typeId: 2)
class Payment {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double amount;

  @HiveField(3)
  int sessionsCount;

  Payment({
    required this.id,
    required this.date,
    required this.amount,
    this.sessionsCount = 4,
  });
}
