import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/student_model.dart'; // inclut kPaymentModeCycle, etc.

import '../models/group_model.dart';
import '../models/schedule_slot.dart';
import '../models/payment_model.dart';
import '../models/student_status.dart';
import '../services/student_service.dart';
import '../services/center_service.dart';
import '../l10n/app_localizations.dart';
import 'dart:async';

class AppProvider extends ChangeNotifier {
  List<Group> _groups = [];
  List<Student> _students = [];
  bool _showRevenue = true;

  bool _isCenterMode = false;
  final _langService = LanguageService();
  final _configService = CenterConfigService();
  final _uuid = const Uuid();
  String _language = 'fr';
  bool _isHolidayMode = false;

  // Debouncing timers for refresh methods
  Timer? _studentsRefreshTimer;
  Timer? _groupsRefreshTimer;

  bool get isHolidayMode => _isHolidayMode;

  List<Group> get groups => _groups;
  List<Student> get students => _students;
  bool get showRevenue => _showRevenue;
  bool get isAr => _language == 'ar';

  bool get isCenterMode => _isCenterMode;
  String get centerName => _configService.centerName;
  List<Teacher> get teachers => _configService.teachers;
  List<String> get rooms => _configService.rooms;
  double get enrollmentFee => _configService.enrollmentFee;
  String? get centerLogo => _configService.centerLogoBase64;
  String get language => _language;
  bool get isArabic => _language == 'ar';
  TextDirection get textDirection =>
      _language == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  // ── Mode-specific UI visibility ──
  // Show rooms if Center mode OR on PC (as requested: "ne touche pas version pc")
  bool get showRooms => _isCenterMode || Platform.isWindows;

  // Show sync only on PC OR if user enabled it in Android onboarding
  bool get isSyncFeatureAvailable => false;

  void toggleRevenue() {
    _showRevenue = !_showRevenue;
    notifyListeners();
  }

  // ── Load Data ──
  void loadData() {
    final groupBox = Hive.box<Group>('groups');
    final studentBox = Hive.box<Student>('students');
    _groups = groupBox.values.toList();
    _students = studentBox.values.toList();

    _isCenterMode = _configService.isCenterMode;
    _language = _langService.language;
    _isHolidayMode = Hive.box('settings')
        .get('is_holiday_mode', defaultValue: false) as bool;

    notifyListeners();
  }

  void refreshData() {
    loadData();
  }

  void notifyChanges() {
    notifyListeners();
  }

  // ── Center Config ──
  Future<void> saveAppMode(bool isFirstSelectionCenter) async {
    await _configService.setMode(isFirstSelectionCenter);
    _isCenterMode = isFirstSelectionCenter;
    notifyListeners();
  }

  Future<void> saveCenterSettings(
      String name, List<Teacher> teachers, List<String> rooms,
      {double enrollmentFee = 0.0, String? logoBase64}) async {
    await _configService.saveCenterName(name);
    await _configService.saveTeachers(teachers);
    await _configService.saveRooms(rooms);
    await _configService.saveEnrollmentFee(enrollmentFee);
    if (logoBase64 != null) {
      await _configService.saveCenterLogo(logoBase64);
    } else if (logoBase64 == '') {
      await _configService.deleteCenterLogo();
    }

    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    await _langService.saveLanguage(lang);
    _language = lang;
    notifyListeners();
  }

  Future<void> setHolidayMode(bool enabled) async {
    _isHolidayMode = enabled;
    await Hive.box('settings').put('is_holiday_mode', enabled);
    notifyListeners();
  }

  Future<void> refreshStudents() async {
    final box = Hive.box<Student>('students');
    _students = box.values.toList();

    // Debounce notifyListeners to avoid excessive UI rebuilds
    _studentsRefreshTimer?.cancel();
    _studentsRefreshTimer = Timer(const Duration(milliseconds: 100), () {
      notifyListeners();
    });
  }

  Future<void> refreshGroups() async {
    final box = Hive.box<Group>('groups');
    _groups = box.values.toList();

    // Debounce notifyListeners to avoid excessive UI rebuilds
    _groupsRefreshTimer?.cancel();
    _groupsRefreshTimer = Timer(const Duration(milliseconds: 100), () {
      notifyListeners();
    });
  }

  // ── Groups ──
  Future<void> addGroup(String name, String subject, String schedule,
      {String? teacherId,
      String? roomName,
      String? level,
      String? grade,
      List<ScheduleSlot>? regularSlots,
      List<ScheduleSlot>? holidaySlots}) async {
    final group = Group(
      id: _uuid.v4(),
      name: name,
      subject: subject,
      schedule: schedule,
      teacherId: teacherId,
      roomName: roomName,
      level: level,
      grade: grade,
      regularSlots: regularSlots,
      holidaySlots: holidaySlots,
    );
    await addGroupObj(group);
  }

  Future<void> addGroupObj(Group group) async {
    final box = Hive.box<Group>('groups');
    await box.put(group.id, group);
    _groups.add(group);
    notifyListeners();
  }

  Future<void> updateGroup(
      String id, String name, String subject, String schedule,
      {String? teacherId,
      String? roomName,
      String? level,
      String? grade}) async {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index == -1) return;

    _groups[index].name = name;
    _groups[index].subject = subject;
    _groups[index].schedule = schedule;
    _groups[index].teacherId = teacherId;
    _groups[index].roomName = roomName;
    if (level != null) _groups[index].level = level;
    if (grade != null) _groups[index].grade = grade;

    final box = Hive.box<Group>('groups');
    await box.put(id, _groups[index]);
    notifyListeners();
  }

  Future<void> updateGroupSchedules(String groupId, List<ScheduleSlot> regular,
      List<ScheduleSlot> holiday) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;

    _groups[index].regularSlots = regular;
    _groups[index].holidaySlots = holiday;

    final box = Hive.box<Group>('groups');
    await box.put(groupId, _groups[index]);
    notifyListeners();
  }

  Future<void> deleteGroup(String id) async {
    final studentsToDelete = _students.where((s) => s.groupId == id).toList();
    final studentBox = Hive.box<Student>('students');
    for (final s in studentsToDelete) {
      await studentBox.delete(s.id);
      _students.removeWhere((st) => st.id == s.id);
    }
    final box = Hive.box<Group>('groups');
    await box.delete(id);
    _groups.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  // Helper for multi-subject students
  List<Student> getRegistrationsByPhone(String phone) {
    if (phone.trim().isEmpty) return [];
    return _students.where((s) => s.phone.trim() == phone.trim()).toList();
  }

  bool hasPaidEnrollmentFee(String phone) {
    if (phone.trim().isEmpty) return false;
    final regs = getRegistrationsByPhone(phone);
    for (final s in regs) {
      if (s.payments.any((p) => p.sessionsCount == 0 && p.amount > 0)) {
        return true;
      }
    }
    return false;
  }

  Future<void> updateStudent(
      String id, String name, String phone, String email) async {
    final index = _students.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _students[index].name = name;
    _students[index].phone = phone;
    _students[index].email = email;
    final box = Hive.box<Student>('students');
    await box.put(id, _students[index]);
    notifyListeners();
  }

  // ── Students ──
  Future<void> addStudent(
      String name, String phone, String groupId, double price,
      {double enrollmentFeeAmount = 0.0,
      String email = '',
      String originSchool = '',
      int sessionsSincePayment = 0,
      String paymentMode = kPaymentModeCycle,
      double pricePerMonth = 100.0,
      double pricePerSession = 30.0}) async {
    final student = Student(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      groupId: groupId,
      pricePerCycle: price,
      pricePerMonth: pricePerMonth,
      pricePerSession: pricePerSession,
      email: email,
      originSchool: originSchool,
      sessionsSincePayment: sessionsSincePayment,
      paymentMode: paymentMode,
    );
    await addStudentObj(student, enrollmentFeeAmount: enrollmentFeeAmount);
  }

  Future<void> updateStudentPaymentMode(
      String studentId, String mode, double price) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) return;
    _students[index].paymentMode = mode;
    switch (mode) {
      case kPaymentModeMonthly:
        _students[index].pricePerMonth = price;
        break;
      case kPaymentModePerSession:
        _students[index].pricePerSession = price;
        break;
      default:
        _students[index].pricePerCycle = price;
    }
    final box = Hive.box<Student>('students');
    await box.put(studentId, _students[index]);
    notifyListeners();
  }

  Future<void> addStudentObj(Student student,
      {double enrollmentFeeAmount = 0.0}) async {
    final box = Hive.box<Student>('students');
    // Si frais d'inscription, on l'enregistre comme paiement (sessionsCount = 0)
    if (enrollmentFeeAmount > 0) {
      student.payments.add(Payment(
        id: _uuid.v4(),
        date: DateTime.now(),
        amount: enrollmentFeeAmount,
        sessionsCount: 0, // 0 = frais d'inscription (pas de séances)
      ));
    }
    await box.put(student.id, student);
    _students.add(student);

    // Add student ID to group
    final groupIndex = _groups.indexWhere((g) => g.id == student.groupId);
    if (groupIndex != -1) {
      if (!_groups[groupIndex].studentIds.contains(student.id)) {
        _groups[groupIndex].studentIds.add(student.id);
        final groupBox = Hive.box<Group>('groups');
        await groupBox.put(student.groupId, _groups[groupIndex]);
      }
    }
    notifyListeners();
  }

  Future<void> deleteStudent(String id) async {
    final student = _students.firstWhere((s) => s.id == id);
    // Remove from group
    final groupIndex = _groups.indexWhere((g) => g.id == student.groupId);
    if (groupIndex != -1) {
      _groups[groupIndex].studentIds.remove(id);
      final groupBox = Hive.box<Group>('groups');
      await groupBox.put(student.groupId, _groups[groupIndex]);
    }
    final box = Hive.box<Student>('students');
    await box.delete(id);
    _students.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // ── Attendance ──
  Future<void> markAttendance(String studentId) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) return;
    _students[index].sessionsSincePayment++;
    _students[index].attendances.add(DateTime.now());
    final box = Hive.box<Student>('students');
    await box.put(studentId, _students[index]);
    notifyListeners();
  }

  Future<void> removeAttendance(String studentId, int index) async {
    final sIndex = _students.indexWhere((s) => s.id == studentId);
    if (sIndex == -1) return;

    final student = _students[sIndex];
    if (index >= 0 && index < student.attendances.length) {
      student.attendances.removeAt(index);
      student.sessionsSincePayment--;

      final box = Hive.box<Student>('students');
      await box.put(studentId, student);
      notifyListeners();
    }
  }

  Future<void> markGroupAttendance(String groupId) async {
    final groupStudents = _students.where((s) => s.groupId == groupId).toList();
    final box = Hive.box<Student>('students');
    for (final student in groupStudents) {
      student.sessionsSincePayment++;
      student.attendances.add(DateTime.now());
      await box.put(student.id, student);
    }
    notifyListeners();
  }

  Future<void> recordSessionAttendance(
      String groupId, DateTime date, List<String> presentStudentIds) async {
    final box = Hive.box<Student>('students');
    for (final id in presentStudentIds) {
      final index = _students.indexWhere((s) => s.id == id);
      if (index != -1) {
        _students[index].sessionsSincePayment++;
        _students[index].attendances.add(date);
        await box.put(id, _students[index]);
      }
    }
    notifyListeners();
  }

  // ── Payments ──
  Future<void> markAsPaid(String studentId, double amount,
      {bool isEnrollment = false, int? monthsDuration}) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) return;

    final student = _students[index];
    int sessionsCount;

    if (isEnrollment) {
      sessionsCount = 0;
    } else {
      switch (student.paymentMode) {
        case kPaymentModeMonthly:
          // Abonnement mensuel : prolonger ou démarrer l'expiration
          final months = monthsDuration ?? 1;
          sessionsCount = months * 30; // convention: 30 jours = 1 mois
          final base = student.monthlyExpiry != null &&
                  student.monthlyExpiry!.isAfter(DateTime.now())
              ? student.monthlyExpiry!
              : DateTime.now();
          student.monthlyExpiry =
              DateTime(base.year, base.month + months, base.day);
          student.sessionsSincePayment = 0;
          break;
        case kPaymentModePerSession:
          // Par séance : on remet le compteur à 0 (1 séance payée)
          sessionsCount = 1;
          student.sessionsSincePayment =
              (student.sessionsSincePayment - 1).clamp(0, 9999);
          break;
        default: // cycle de 4 séances
          sessionsCount = 4;
          student.sessionsSincePayment -= 4;
      }
    }

    student.payments.add(Payment(
      id: _uuid.v4(),
      date: DateTime.now(),
      amount: amount,
      sessionsCount: sessionsCount,
    ));

    final box = Hive.box<Student>('students');
    await box.put(studentId, student);

    notifyListeners();
  }

  // ── Queries ──
  List<Student> getStudentsForGroup(String groupId) {
    return _students.where((s) => s.groupId == groupId).toList();
  }

  List<Student> getStudentsForGroupSorted(String groupId) {
    return StudentService.sortByStatus(getStudentsForGroup(groupId));
  }

  List<Student> getStudentsForGroupFiltered(
      String groupId, StudentStatus? status) {
    final students = getStudentsForGroup(groupId);
    final filtered = StudentService.filterByStatus(students, status);
    return StudentService.sortByStatus(filtered);
  }

  GroupStats getGroupStats(Group group) {
    return StudentService.getGroupStats(group, _students);
  }

  // ── Global Stats ──
  double get totalRevenue {
    return _students.fold(0.0, (sum, s) => sum + s.totalPaid);
  }

  /// Retourne un map des revenus par mois (1 à 12) pour une année spécifique.
  Map<int, double> getMonthlyRevenuesForYear(int year) {
    final Map<int, double> monthly = {for (var i = 1; i <= 12; i++) i: 0.0};
    for (final student in _students) {
      for (final payment in student.payments) {
        if (payment.date.year == year) {
          monthly[payment.date.month] =
              (monthly[payment.date.month] ?? 0) + payment.amount;
        }
      }
    }
    return monthly;
  }

  /// Revenu cumulé de l'année
  double getAnnualRevenue(int year) {
    return getMonthlyRevenuesForYear(year)
        .values
        .fold(0.0, (sum, v) => sum + v);
  }

  double get monthlyRevenue {
    final now = DateTime.now();
    return getMonthlyRevenuesForYear(now.year)[now.month] ?? 0.0;
  }

  int get totalSessions {
    return _students.fold(0, (sum, s) => sum + s.attendances.length);
  }

  int get totalOverdueStudents {
    return _students
        .where((s) => StudentService.computeStatus(s) == StudentStatus.overdue)
        .length;
  }

  List<Group> get problematicGroups {
    return _groups.where((g) {
      final stats = getGroupStats(g);
      if (stats.totalStudents == 0) return false;
      return stats.overduePercent > 30;
    }).toList();
  }

  // ── Scheduling Queries ──
  List<Group> getGroupsForRoom(String roomName) {
    return _groups.where((g) => g.roomName == roomName).toList();
  }

  List<Group> getOccupyingGroupsAt(
      String roomName, int day, int hour, int minute) {
    return _groups.where((g) {
      if (g.roomName != roomName) return false;
      final slots = _isHolidayMode ? g.holidaySlots : g.regularSlots;
      final queryTime = hour * 60 + minute;

      return slots.any((slot) {
        if (slot.dayOfWeek != day) return false;
        return queryTime >= slot.startInMinutes && queryTime < slot.endInMinutes;
      });
    }).toList();
  }

  /// Vérifie si une salle est disponible pour une liste de créneaux.
  /// Retourne le groupe en conflit si occupation détectée.
  Group? checkRoomConflict(String roomName, List<ScheduleSlot> requestedSlots, {String? excludeGroupId}) {
    if (roomName.isEmpty) return null;
    
    for (final group in _groups) {
      if (group.id == excludeGroupId) continue;
      if (group.roomName != roomName) continue;

      final existingSlots = _isHolidayMode ? group.holidaySlots : group.regularSlots;
      for (final existing in existingSlots) {
        for (final requested in requestedSlots) {
          if (existing.overlapsWith(requested)) {
            return group;
          }
        }
      }
    }
    return null;
  }

  List<String> getFreeRoomsForSlots(List<ScheduleSlot> requestedSlots, {String? excludeGroupId}) {
    final allRooms = rooms;
    return allRooms.where((room) => checkRoomConflict(room, requestedSlots, excludeGroupId: excludeGroupId) == null).toList();
  }

  List<String> getFreeRoomsAt(int day, int hour, int minute) {
    final allRooms = rooms;
    final busyRooms = _groups.expand((g) {
      final slots = _isHolidayMode ? g.holidaySlots : g.regularSlots;
      final queryTime = hour * 60 + minute;
      if (slots.any((s) =>
          s.dayOfWeek == day &&
          (queryTime >= s.startInMinutes && queryTime < s.endInMinutes))) {
        return [g.roomName];
      }
      return [];
    }).toSet();

    return allRooms.where((r) => !busyRooms.contains(r)).toList();
  }

  /// Wipes all students and their data (payments + attendances).
  /// Groups are kept so the teacher doesn't need to re-create them.
  Future<void> resetNewYear() async {
    final studentBox = Hive.box<Student>('students');
    await studentBox.clear();
    _students.clear();

    final groupBox = Hive.box<Group>('groups');
    await groupBox.clear();
    _groups.clear();

    notifyListeners();
  }

  Future<void> hardReset() async {
    final studentBox = Hive.box<Student>('students');
    await studentBox.clear();
    _students.clear();

    final groupBox = Hive.box<Group>('groups');
    await groupBox.clear();
    _groups.clear();

    final settingsBox = Hive.box('settings');
    await settingsBox.clear();

    notifyListeners();
  }
}
