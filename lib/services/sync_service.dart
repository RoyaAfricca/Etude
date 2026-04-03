import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/student_model.dart';
import '../models/group_model.dart';
import '../models/payment_model.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final String serverUrl = "http://localhost:3000/api/sync"; // À adapter selon l'IP du serveur
  bool _isSyncing = false;

  void init() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncData();
      }
    });
  }

  Future<void> syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final studentBox = Hive.box<Student>('students');
      
      // 1. Collecter les données modifiées localement
      final dirtyStudents = studentBox.values.where((s) => s.isLocalOnly).toList();

      if (dirtyStudents.isEmpty) {
        _isSyncing = false;
        return;
      }

      // 2. Envoyer au serveur Node.js
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "lastSyncTime": "2024-01-01T00:00:00.000Z", // À stocker localement
          "data": {
            "students": dirtyStudents.map((s) => {
              "id": s.id,
              "name": s.name,
              "phone": s.phone,
              "sessionsSincePayment": s.sessionsSincePayment,
              "paymentMode": s.paymentMode,
              "groupId": s.groupId,
              "updatedAt": s.lastModifiedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            }).toList(),
          }
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        
        // 3. Marquer comme synchronisés
        for (var s in dirtyStudents) {
          s.isLocalOnly = false;
          await s.save();
        }
        
        print("Synchronisation réussie !");
      }
    } catch (e) {
      print("Erreur de synchronisation : $e");
    } finally {
      _isSyncing = false;
    }
  }
}
