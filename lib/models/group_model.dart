import 'package:hive/hive.dart';
import 'schedule_slot.dart';

part 'group_model.g.dart';

@HiveType(typeId: 1)
class Group extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(11)
  DateTime? lastModifiedAt;

  @HiveField(12)
  bool isLocalOnly;

  @HiveField(1)
  String name;

  @HiveField(2)
  String subject;

  @HiveField(3)
  String schedule;

  @HiveField(4)
  List<String> studentIds;

  @HiveField(5, defaultValue: '')
  String? teacherId;

  @HiveField(6, defaultValue: '')
  String? roomName;

  @HiveField(7, defaultValue: '')
  String? level;

  @HiveField(8, defaultValue: '')
  String? grade;

  @HiveField(9)
  List<ScheduleSlot> regularSlots;

  @HiveField(10)
  List<ScheduleSlot> holidaySlots;

  Group({
    required this.id,
    required this.name,
    this.subject = '',
    this.schedule = '',
    List<String>? studentIds,
    this.teacherId,
    this.roomName,
    this.level,
    this.grade,
    List<ScheduleSlot>? regularSlots,
    List<ScheduleSlot>? holidaySlots,
    this.lastModifiedAt,
    this.isLocalOnly = true,
  })  : studentIds = studentIds ?? [],
        regularSlots = regularSlots ?? [],
        holidaySlots = holidaySlots ?? [];
}
