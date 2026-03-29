import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/group_model.dart';
import '../models/schedule_slot.dart';
import '../services/center_service.dart';
import '../services/activation_service.dart';
import '../providers/app_provider.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivationService _activationService = ActivationService();
  
  StreamSubscription? _studentsSubscription;
  StreamSubscription? _groupsSubscription;
  StreamSubscription? _teachersSubscription;

  /// Clé unique de synchronisation pour ce centre
  String? _syncKey;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  /// Initialise la synchronisation pour le centre
  Future<void> initSync(AppProvider provider, {String? overrideKey}) async {
    try {
      // 1. Authentification anonyme si non connecté
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }

      // 2. Récupérer l'ID unique du centre
      if (overrideKey != null) {
        _syncKey = overrideKey;
      } else {
        // Chercher une clé enregistrée
        final settingsBox = Hive.box('settings');
        final savedKey = settingsBox.get('sync_key');
        
        if (savedKey != null) {
          _syncKey = savedKey;
        } else {
          // Générer une clé basée sur le Device ID (PC)
          final deviceId = await _activationService.getDeviceId();
          _syncKey = deviceId.replaceAll(':', '').replaceAll('-', '').substring(0, 10).toUpperCase();
          // Sauvegarder pour plus tard
          await settingsBox.put('sync_key', _syncKey);
        }
      }
      
      _isSyncing = true;
      
      // 3. Écouter les changements distants (Firestore -> Hive)
      _listenToRemoteChanges(provider);
      
      debugPrint('Sync initialized for Center Key: $_syncKey');
    } catch (e) {
      debugPrint('Error initializing sync: $e');
      _isSyncing = false;
    }
  }

  /// Arrête la synchronisation
  void stopSync() {
    _studentsSubscription?.cancel();
    _groupsSubscription?.cancel();
    _teachersSubscription?.cancel();
    _isSyncing = false;
  }

  /// Écoute les modifications réalisées sur d'autres appareils
  void _listenToRemoteChanges(AppProvider provider) {
    if (_syncKey == null) return;

    final centerRef = _firestore.collection('centers').doc(_syncKey);

    // Écouter les élèves
    _studentsSubscription = centerRef.collection('students').snapshots().listen((snapshot) {
      final box = Hive.box<Student>('students');
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null) {
            final remoteStudent = _mapToStudent(data);
            // On ne met à jour que si les données locales sont différentes or si c'est un nouvel étudiant
            final localStudent = box.get(remoteStudent.id);
            if (localStudent == null || localStudent.sessionsSincePayment != remoteStudent.sessionsSincePayment) {
              box.put(remoteStudent.id, remoteStudent);
              provider.refreshStudents(); // Notifier les UI
            }
          }
        }
      }
    });

    // Écouter les groupes
    _groupsSubscription = centerRef.collection('groups').snapshots().listen((snapshot) {
      final box = Hive.box<Group>('groups');
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null) {
            final remoteGroup = _mapToGroup(data);
            final localGroup = box.get(remoteGroup.id);
            if (localGroup == null) {
              box.put(remoteGroup.id, remoteGroup);
              provider.refreshGroups();
            }
          }
        }
      }
    });
  }

  Student _mapToStudent(Map<String, dynamic> data) {
    return Student(
      id: data['id'],
      name: data['name'],
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      originSchool: data['originSchool'] ?? '',
      groupId: data['groupId'],
      pricePerCycle: (data['pricePerCycle'] ?? 0).toDouble(),
      sessionsSincePayment: data['sessionsSincePayment'] ?? 0,
    );
  }

  Group _mapToGroup(Map<String, dynamic> data) {
    return Group(
      id: data['id'],
      name: data['name'],
      subject: data['subject'],
      schedule: data['schedule'] ?? '',
      teacherId: data['teacherId'],
      roomName: data['roomName'],
      level: data['level'],
      grade: data['grade'],
      regularSlots: (data['regularSlots'] as List? ?? []).map((s) => ScheduleSlot(
        dayOfWeek: s['dayOfWeek'],
        startHour: s['startHour'],
        startMinute: s['startMinute'],
        endHour: s['endHour'],
        endMinute: s['endMinute'],
      )).toList(),
      holidaySlots: (data['holidaySlots'] as List? ?? []).map((s) => ScheduleSlot(
        dayOfWeek: s['dayOfWeek'],
        startHour: s['startHour'],
        startMinute: s['startMinute'],
        endHour: s['endHour'],
        endMinute: s['endMinute'],
      )).toList(),
    );
  }

  /// Pousse un changement vers le Cloud
  Future<void> pushStudent(Student student) async {
    if (!_isSyncing || _syncKey == null) return;
    try {
      await _firestore
          .collection('centers')
          .doc(_syncKey)
          .collection('students')
          .doc(student.id)
          .set({
        'id': student.id,
        'name': student.name,
        'phone': student.phone,
        'email': student.email,
        'originSchool': student.originSchool,
        'groupId': student.groupId,
        'pricePerCycle': student.pricePerCycle,
        'sessionsSincePayment': student.sessionsSincePayment,
        'attendances': student.attendances.map((d) => d.toIso8601String()).toList(),
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error pushing student: $e');
    }
  }

  Future<void> pushAttendance(String studentId, int sessions) async {
    if (!_isSyncing || _syncKey == null) return;
    try {
      await _firestore
          .collection('centers')
          .doc(_syncKey)
          .collection('students')
          .doc(studentId)
          .update({
        'sessionsSincePayment': sessions,
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error pushing attendance: $e');
    }
  }

  Future<void> pushGroup(Group group) async {
    if (!_isSyncing || _syncKey == null) return;
    try {
      await _firestore
          .collection('centers')
          .doc(_syncKey)
          .collection('groups')
          .doc(group.id)
          .set({
        'id': group.id,
        'name': group.name,
        'subject': group.subject,
        'schedule': group.schedule,
        'teacherId': group.teacherId,
        'roomName': group.roomName,
        'level': group.level,
        'grade': group.grade,
        'regularSlots': group.regularSlots.map((s) => {
          'dayOfWeek': s.dayOfWeek,
          'startHour': s.startHour,
          'startMinute': s.startMinute,
          'endHour': s.endHour,
          'endMinute': s.endMinute,
        }).toList(),
        'holidaySlots': group.holidaySlots.map((s) => {
          'dayOfWeek': s.dayOfWeek,
          'startHour': s.startHour,
          'startMinute': s.startMinute,
          'endHour': s.endHour,
          'endMinute': s.endMinute,
        }).toList(),
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error pushing group: $e');
    }
  }

  Future<void> pushTeacher(Teacher teacher) async {
    if (!_isSyncing || _syncKey == null) return;
    try {
      await _firestore
          .collection('centers')
          .doc(_syncKey)
          .collection('teachers')
          .doc(teacher.id)
          .set({
        'id': teacher.id,
        'name': teacher.name,
        'contractType': teacher.contractType.index,
        'fixedAmount': teacher.fixedAmount,
        'percentage': teacher.percentage,
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error pushing teacher: $e');
    }
  }

  /// Pousse TOUTES les données locales vers le Cloud (utile à l'activation)
  Future<void> syncAll(AppProvider provider) async {
    if (!_isSyncing || _syncKey == null) return;
    
    debugPrint('Starting full sync to cloud...');
    
    // Push teachers
    for (var teacher in provider.teachers) {
      await pushTeacher(teacher);
    }
    
    // Push groups
    for (var group in provider.groups) {
      await pushGroup(group);
    }
    
    // Push students
    for (var student in provider.students) {
      await pushStudent(student);
    }
    
    debugPrint('Full sync completed.');
  }

  /// Pousse la liste des présences uniquement (optimisation)
  Future<void> pushStudentAttendances(String studentId, int sessions, List<DateTime> attendances) async {
    if (!_isSyncing || _syncKey == null) return;
    try {
      await _firestore
          .collection('centers')
          .doc(_syncKey)
          .collection('students')
          .doc(studentId)
          .update({
        'sessionsSincePayment': sessions,
        'attendances': attendances.map((d) => d.toIso8601String()).toList(),
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error pushing student attendances: $e');
    }
  }

  /// Récupère la clé de synchronisation à afficher en QR Code
  String getSyncKey() => _syncKey ?? 'NON_INITIALISÉ';
}
