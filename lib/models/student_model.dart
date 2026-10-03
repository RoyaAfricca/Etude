import 'package:hive/hive.dart';
import 'payment_model.dart';

part 'student_model.g.dart';

/// Modes de paiement disponibles pour un élève.
/// - 'cycle'      : paiement par cycle de 4 séances (défaut)
/// - 'monthly'    : paiement mensuel (abonnement)
/// - 'perSession' : paiement à la séance
const kPaymentModeCycle      = 'cycle';
const kPaymentModeMonthly    = 'monthly';
const kPaymentModePerSession = 'perSession';

@HiveType(typeId: 0)
class Student extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(14)
  DateTime? lastModifiedAt;

  @HiveField(15)
  bool isLocalOnly;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(16, defaultValue: '')
  String parentPhone;

  @HiveField(3)
  int sessionsSincePayment;

  @HiveField(4)
  double pricePerCycle;

  @HiveField(10)
  double pricePerMonth;

  @HiveField(11)
  double pricePerSession;

  @HiveField(12)
  DateTime? monthlyExpiry;

  @HiveField(5)
  List<DateTime> attendances;

  @HiveField(6)
  List<Payment> payments;

  @HiveField(7)
  String groupId;

  @HiveField(8)
  String email;

  @HiveField(9)
  String originSchool;

  /// Mode de paiement : 'cycle' | 'monthly' | 'perSession'
  @HiveField(13)
  String paymentMode;

  Student({
    required this.id,
    required this.name,
    this.phone = '',
    this.parentPhone = '',
    this.sessionsSincePayment = 0,
    this.pricePerCycle = 100.0,
    this.pricePerMonth = 100.0,
    this.pricePerSession = 30.0,
    this.monthlyExpiry,
    List<DateTime>? attendances,
    List<Payment>? payments,
    required this.groupId,
    this.email = '',
    this.originSchool = '',
    this.paymentMode = kPaymentModeCycle,
    this.lastModifiedAt,
    this.isLocalOnly = true,
  })  : attendances = attendances ?? [],
        payments = payments ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'parentPhone': parentPhone,
        'sessionsSincePayment': sessionsSincePayment,
        'pricePerCycle': pricePerCycle,
        'pricePerMonth': pricePerMonth,
        'pricePerSession': pricePerSession,
        'monthlyExpiry': monthlyExpiry?.toIso8601String(),
        'attendances': attendances.map((d) => d.toIso8601String()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'groupId': groupId,
        'email': email,
        'originSchool': originSchool,
        'paymentMode': paymentMode,
        'lastModifiedAt': lastModifiedAt?.toIso8601String(),
        'isLocalOnly': isLocalOnly,
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        parentPhone: json['parentPhone']?.toString() ?? '',
        sessionsSincePayment: json['sessionsSincePayment'] as int? ?? 0,
        pricePerCycle: (json['pricePerCycle'] as num?)?.toDouble() ?? 100.0,
        pricePerMonth: (json['pricePerMonth'] as num?)?.toDouble() ?? 100.0,
        pricePerSession: (json['pricePerSession'] as num?)?.toDouble() ?? 30.0,
        monthlyExpiry: json['monthlyExpiry'] != null
            ? DateTime.tryParse(json['monthlyExpiry'].toString())
            : null,
        attendances: (json['attendances'] as List?)
                ?.map((d) => DateTime.tryParse(d.toString()))
                .whereType<DateTime>()
                .toList() ??
            [],
        payments: (json['payments'] as List?)
                ?.map((p) => Payment.fromJson(Map<String, dynamic>.from(p as Map)))
                .toList() ??
            [],
        groupId: json['groupId']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        originSchool: json['originSchool']?.toString() ?? '',
        paymentMode: json['paymentMode']?.toString() ?? kPaymentModeCycle,
        lastModifiedAt: json['lastModifiedAt'] != null
            ? DateTime.tryParse(json['lastModifiedAt'].toString())
            : null,
        isLocalOnly: json['isLocalOnly'] as bool? ?? true,
      );

  bool get isMonthlyActive {
    if (monthlyExpiry == null) return false;
    return monthlyExpiry!.isAfter(DateTime.now());
  }

  DateTime? get lastPaymentDate {
    if (payments.isEmpty) return null;
    payments.sort((a, b) => b.date.compareTo(a.date));
    return payments.first.date;
  }

  double get totalPaid {
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Prix effectif selon le mode de paiement
  double get effectivePrice {
    switch (paymentMode) {
      case kPaymentModeMonthly:
        return pricePerMonth;
      case kPaymentModePerSession:
        return pricePerSession;
      default:
        return pricePerCycle;
    }
  }

  /// Libellé du mode de paiement
  String get paymentModeLabel {
    switch (paymentMode) {
      case kPaymentModeMonthly:
        return 'Mensuel';
      case kPaymentModePerSession:
        return 'Par séance';
      default:
        return 'Par cycle (4 séances)';
    }
  }

  int get sessionsRemaining {
    switch (paymentMode) {
      case kPaymentModeMonthly:
        return isMonthlyActive ? 99 : 0;
      case kPaymentModePerSession:
        return sessionsSincePayment == 0 ? 1 : 0;
      default:
        if (isMonthlyActive) return 99;
        final remaining = 4 - sessionsSincePayment;
        return remaining > 0 ? remaining : 0;
    }
  }
}
