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
}
