import 'package:hive/hive.dart';
import 'schedule_slot.dart';

part 'group_model.g.dart';

@HiveType(typeId: 1)
class Group extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(11)
  DateTime? lastModifiedAt;

  @HiveField(12, defaultValue: true)
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subject': subject,
        'schedule': schedule,
        'studentIds': studentIds,
        'teacherId': teacherId,
        'roomName': roomName,
        'level': level,
        'grade': grade,
        'regularSlots': regularSlots.map((s) => s.toJson()).toList(),
        'holidaySlots': holidaySlots.map((s) => s.toJson()).toList(),
        'lastModifiedAt': lastModifiedAt?.toIso8601String(),
        'isLocalOnly': isLocalOnly,
      };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        schedule: json['schedule']?.toString() ?? '',
        studentIds: (json['studentIds'] as List?)?.cast<String>() ?? [],
        teacherId: json['teacherId']?.toString(),
        roomName: json['roomName']?.toString(),
        level: json['level']?.toString(),
        grade: json['grade']?.toString(),
        regularSlots: (json['regularSlots'] as List?)
            ?.map((s) => ScheduleSlot.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
        holidaySlots: (json['holidaySlots'] as List?)
            ?.map((s) => ScheduleSlot.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
        lastModifiedAt: json['lastModifiedAt'] != null
            ? DateTime.tryParse(json['lastModifiedAt'].toString())
            : null,
        isLocalOnly: json['isLocalOnly'] as bool? ?? true,
      );
}
