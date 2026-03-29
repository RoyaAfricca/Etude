import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/student_model.dart';
import '../models/group_model.dart';
import '../models/payment_model.dart';
import '../models/student_status.dart';
import '../services/student_service.dart';
import '../services/center_service.dart';
import '../l10n/app_localizations.dart';

class AppProvider extends ChangeNotifier {
  List<Group> _groups = [];
  List<Student> _students = [];
  bool _showRevenue = true;

  bool _isCenterMode = false;
  final _langService = LanguageService();
  final _configService = CenterConfigService();
  final _uuid = const Uuid();
  String _language = 'fr';

  List<Group> get groups => _groups;
  List<Student> get students => _students;
  bool get showRevenue => _showRevenue;

  bool get isCenterMode => _isCenterMode;
  String get centerName => _configService.centerName;
  List<Teacher> get teachers => _configService.teachers;
  List<String> get rooms => _configService.rooms;
  double get enrollmentFee => _configService.enrollmentFee;
  String? get centerLogo => _configService.centerLogoBase64;
  String get language => _language;
  bool get isArabic => _language == 'ar';
  TextDirection get textDirection => _language == 'ar' ? TextDirection.rtl : TextDirection.ltr;

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

    notifyListeners();
  }

  // ── Center Config ──
  Future<void> saveAppMode(bool isCenter) async {
    await _configService.setMode(isCenter);
    _isCenterMode = isCenter;
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

  // ── Groups ──
  Future<void> addGroup(String name, String subject, String schedule, 
      {String? teacherId, String? roomName, String? level, String? grade}) async {
    final group = Group(
      id: _uuid.v4(),
      name: name,
      subject: subject,
      schedule: schedule,
      teacherId: teacherId,
      roomName: roomName,
      level: level,
      grade: grade,
    );
    final box = Hive.box<Group>('groups');
    await box.put(group.id, group);
    _groups.add(group);
    notifyListeners();
  }

  Future<void> updateGroup(
      String id, String name, String subject, String schedule) async {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index == -1) return;
    _groups[index].name = name;
    _groups[index].subject = subject;
    _groups[index].schedule = schedule;
    final box = Hive.box<Group>('groups');
    await box.put(id, _groups[index]);
    notifyListeners();
  }

  Future<void> deleteGroup(String id) async {
    // Delete all students in the group
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

  // ── Students ──
  Future<void> addStudent(
      String name, String phone, String groupId, double price,
      {double enrollmentFeeAmount = 0.0}) async {
    final student = Student(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      groupId: groupId,
      pricePerCycle: price,
    );
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
    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      _groups[groupIndex].studentIds.add(student.id);
      final groupBox = Hive.box<Group>('groups');
      await groupBox.put(groupId, _groups[groupIndex]);
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

  Future<void> recordSessionAttendance(String groupId, DateTime date, List<String> presentStudentIds) async {
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
  Future<void> markAsPaid(String studentId, double amount, {bool isEnrollment = false}) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) return;
    final payment = Payment(
      id: _uuid.v4(),
      date: DateTime.now(),
      amount: amount,
      sessionsCount: isEnrollment ? 0 : 4,
    );
    _students[index].payments.add(payment);
    if (!isEnrollment) {
      _students[index].sessionsSincePayment -= 4; // On déduit 4 de la dette
    }
    final box = Hive.box<Student>('students');
    await box.put(studentId, _students[index]);
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
          monthly[payment.date.month] = (monthly[payment.date.month] ?? 0) + payment.amount;
        }
      }
    }
    return monthly;
  }

  /// Revenu cumulé de l'année
  double getAnnualRevenue(int year) {
    return getMonthlyRevenuesForYear(year).values.fold(0.0, (sum, v) => sum + v);
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
}
