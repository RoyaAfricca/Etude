import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/group_model.dart';
import '../models/schedule_slot.dart';
import '../models/payment_model.dart';
import '../services/center_service.dart';
import '../services/activation_service.dart';
import '../providers/app_provider.dart';

class SyncService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
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
      // 1. Récupérer l'ID unique du centre D'ABORD (pour que l'affichage QR fonctionne)
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

      // 2. Authentification anonyme si non connecté (Firebase)
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      
      _isSyncing = true;
      
      // 3. Écouter les changements distants (Firestore -> Hive)
      _listenToRemoteChanges(provider);
      
      debugPrint('Sync initialized for Center Key: $_syncKey');
    } catch (e) {
      debugPrint('Error initializing sync: $e');
      // La clé _syncKey a été générée, on la conserve, mais Firebase n'est pas prêt.
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
            // On met à jour Hive dès qu'une modification (Paiement, Présence, etc.) arrive du Cloud
            box.put(remoteStudent.id, remoteStudent);
            provider.refreshStudents(); // Notifier les UI
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
            box.put(remoteGroup.id, remoteGroup);
            provider.refreshGroups();
          }
        } else if (change.type == DocumentChangeType.removed) {
          box.delete(change.doc.id);
          provider.refreshGroups();
        }
      }
    });

    // Écouter les enseignants
    _teachersSubscription = centerRef.collection('teachers').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null) {
            final remoteTeacher = Teacher.fromJson(data);
            final configService = CenterConfigService();
            final teachers = configService.teachers;
            final idx = teachers.indexWhere((t) => t.id == remoteTeacher.id);
            if (idx == -1) {
              teachers.add(remoteTeacher);
            } else {
              teachers[idx] = remoteTeacher;
            }
            configService.saveTeachers(teachers);
            provider.refreshData(); // Utilise une nouvelle méthode publique pour tout rafraîchir
          }
        }
      }
    });

    // Écouter les réglages du centre (Nom, Salles, Frais)
    centerRef.snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final configService = CenterConfigService();
        if (data.containsKey('centerName')) configService.saveCenterName(data['centerName']);
        if (data.containsKey('rooms')) {
          final rooms = (data['rooms'] as List).cast<String>();
          configService.saveRooms(rooms);
        }
        if (data.containsKey('enrollmentFee')) {
          configService.saveEnrollmentFee((data['enrollmentFee'] as num).toDouble());
        }
        provider.refreshData();
      }
    });

    // Écouter les suppressions d'élèves
    _studentsSubscription?.onData((snapshot) {
      final box = Hive.box<Student>('students');
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          box.delete(change.doc.id);
          provider.refreshStudents();
        } else if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null) {
            final remoteStudent = _mapToStudent(data);
            box.put(remoteStudent.id, remoteStudent);
            provider.refreshStudents();
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
      attendances: (data['attendances'] as List? ?? []).map((e) => DateTime.parse(e as String)).toList(),
      payments: (data['payments'] as List? ?? []).map((p) => Payment(
        id: p['id'],
        date: DateTime.parse(p['date']),
        amount: (p['amount'] as num).toDouble(),
        sessionsCount: p['sessionsCount'] ?? 4,
      )).toList(),
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
        'payments': student.payments.map((p) => {
          'id': p.id,
          'date': p.date.toIso8601String(),
          'amount': p.amount,
          'sessionsCount': p.sessionsCount,
        }).toList(),
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
    
    // Push center settings
    await pushCenterSettings(
        provider.centerName, provider.rooms, provider.enrollmentFee);

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

  /// Pousse les réglages du centre
  Future<void> pushCenterSettings(String name, List<String> rooms, double enrollmentFee) async {
    if (!_isSyncing || _syncKey == null) return;
    try {
      await _firestore.collection('centers').doc(_syncKey).set({
        'centerName': name,
        'rooms': rooms,
        'enrollmentFee': enrollmentFee,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error pushing center settings: $e');
    }
  }

  Future<void> deleteStudentCloud(String studentId) async {
    if (!_isSyncing || _syncKey == null) return;
    try {
      await _firestore.collection('centers').doc(_syncKey).collection('students').doc(studentId).delete();
    } catch (e) {
      debugPrint('Error deleting student from cloud: $e');
    }
  }

  Future<void> deleteGroupCloud(String groupId) async {
    if (!_isSyncing || _syncKey == null) return;
    try {
      await _firestore.collection('centers').doc(_syncKey).collection('groups').doc(groupId).delete();
    } catch (e) {
      debugPrint('Error deleting group from cloud: $e');
    }
  }

  /// Récupère la clé de synchronisation à afficher en QR Code
  String getSyncKey() => _syncKey ?? 'NON_INITIALISÉ';

  // ── Remote Messaging Bridge (PC -> Android) ──

  /// Pousse une demande de message vers Firestore (utilisé par le PC)
  Future<void> pushRemoteMessage(String type, String recipient, String body) async {
    if (!_isSyncing || _syncKey == null) return;
    try {
      await _firestore
          .collection('centers')
          .doc(_syncKey)
          .collection('remote_messages')
          .add({
        'type': type,
        'recipient': recipient,
        'body': body,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error pushing remote message: $e');
    }
  }

  /// Écoute les demandes de messages (utilisé par l'Android)
  StreamSubscription? listenForRemoteMessages(Function(String id, String type, String recipient, String body) onMessage) {
    if (!_isSyncing || _syncKey == null) return null;
    
    return _firestore
        .collection('centers')
        .doc(_syncKey)
        .collection('remote_messages')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            onMessage(
              change.doc.id,
              data['type'] ?? 'sms',
              data['recipient'] ?? '',
              data['body'] ?? '',
            );
          }
        }
      }
    });
  }

  /// Supprime une demande de message après traitement
  Future<void> deleteRemoteMessage(String messageId) async {
    if (!_isSyncing || _syncKey == null) return;
    try {
      await _firestore
          .collection('centers')
          .doc(_syncKey)
          .collection('remote_messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting remote message: $e');
    }
  }
}
