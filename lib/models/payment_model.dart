import 'package:hive/hive.dart';

part 'payment_model.g.dart';

@HiveType(typeId: 2)
class Payment {
  @HiveField(0)
  String id;

  @HiveField(5)
  DateTime? lastModifiedAt;

  @HiveField(6)
  bool isLocalOnly;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double amount;

  @HiveField(3)
  int sessionsCount;

  @HiveField(4)
  String paymentType; // 'sessions' or 'month'

  Payment({
    required this.id,
    required this.date,
    required this.amount,
    this.sessionsCount = 4,
    this.paymentType = 'sessions',
    this.lastModifiedAt,
    this.isLocalOnly = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'sessionsCount': sessionsCount,
        'paymentType': paymentType,
        'lastModifiedAt': lastModifiedAt?.toIso8601String(),
        'isLocalOnly': isLocalOnly,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id']?.toString() ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        sessionsCount: json['sessionsCount'] as int? ?? 4,
        paymentType: json['paymentType']?.toString() ?? 'sessions',
        lastModifiedAt: json['lastModifiedAt'] != null
            ? DateTime.tryParse(json['lastModifiedAt'].toString())
            : null,
        isLocalOnly: json['isLocalOnly'] as bool? ?? true,
      );
}
