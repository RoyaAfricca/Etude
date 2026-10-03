import 'package:hive/hive.dart';

part 'schedule_slot.g.dart';

@HiveType(typeId: 4)
class ScheduleSlot extends HiveObject {
  @HiveField(0)
  int dayOfWeek; // 1-7 (Lundi-Dimanche)

  @HiveField(1)
  int startHour;

  @HiveField(2)
  int startMinute;

  @HiveField(3)
  int endHour;

  @HiveField(4)
  int endMinute;

  ScheduleSlot({
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  int get startInMinutes => startHour * 60 + startMinute;
  int get endInMinutes => endHour * 60 + endMinute;

  bool overlapsWith(ScheduleSlot other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    // (StartA < EndB) and (EndA > StartB)
    return startInMinutes < other.endInMinutes && endInMinutes > other.startInMinutes;
  }

  String get timeRange => '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  String dayName(bool isAr) {
    if (isAr) {
      const daysAr = [
        'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
      ];
      return daysAr[dayOfWeek - 1];
    }
    const daysFr = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    return daysFr[dayOfWeek - 1];
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
        dayOfWeek: json['dayOfWeek'] as int? ?? 1,
        startHour: json['startHour'] as int? ?? 0,
        startMinute: json['startMinute'] as int? ?? 0,
        endHour: json['endHour'] as int? ?? 0,
        endMinute: json['endMinute'] as int? ?? 0,
      );
}
