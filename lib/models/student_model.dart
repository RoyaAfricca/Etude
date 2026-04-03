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
