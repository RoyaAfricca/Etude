import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/group_model.dart';
import '../services/center_service.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ImportService {
  static const String sheetStudents = 'Élèves';
  static const String sheetGroups = 'Groupes';
  static const String sheetTeachers = 'Enseignants';
  static const String sheetPayments = 'Paiements';
  static const String sheetAttendances = 'Présences';

  /// Génère un modèle Excel vierge avec les bons en-têtes (incluant Numéro Parent)
  static Future<bool> generateTemplate() async {
    try {
      var excel = Excel.createExcel();

      // --- Feuille Élèves ---
      excel.rename('Sheet1', sheetStudents);
      var sheetSt = excel[sheetStudents];
      sheetSt.appendRow([
        TextCellValue('Nom Complet (Élève) *'),
        TextCellValue('Téléphone Élève'),
        TextCellValue('Téléphone Parent'),
        TextCellValue('Email'),
        TextCellValue('Établissement d\'origine'),
        TextCellValue('Niveau'),
        TextCellValue('Classe'),
        TextCellValue('Nom du Groupe *'),
        TextCellValue('Matière'),
        TextCellValue('Nom de l\'Enseignant'),
        TextCellValue('Jour(s) de la semaine'),
        TextCellValue('Salle'),
        TextCellValue('Horaire'),
        TextCellValue('Prix par Cycle (DT)'),
        TextCellValue('Séances déjà payées (0-4)'),
      ]);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le modèle Excel',
        fileName: 'modele_import_etude.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.xlsx')) {
          outputFile = '$outputFile.xlsx';
        }
        var bytes = excel.save();
        if (bytes != null) {
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error generating template: $e');
      return false;
    }
  }

  /// Exporte toutes les données de l'application vers un fichier Excel complet
  static Future<String?> exportToExcel(AppProvider provider) async {
    try {
      var excel = Excel.createExcel();

      // ── 1. Feuille Élèves ──
      excel.rename('Sheet1', sheetStudents);
      var sheetSt = excel[sheetStudents];
      sheetSt.appendRow([
        TextCellValue('ID Élève'),
        TextCellValue('Nom Complet'),
        TextCellValue('Téléphone Élève'),
        TextCellValue('Téléphone Parent'),
        TextCellValue('Email'),
        TextCellValue('Établissement'),
        TextCellValue('Groupe'),
        TextCellValue('Matière'),
        TextCellValue('Enseignant'),
        TextCellValue('Mode Paiement'),
        TextCellValue('Prix Cycle (DT)'),
        TextCellValue('Prix Mensuel (DT)'),
        TextCellValue('Prix Séance (DT)'),
        TextCellValue('Séances depuis paiement'),
        TextCellValue('Total Payé (DT)'),
        TextCellValue('Dernier Paiement'),
      ]);

      final groupsMap = {for (var g in provider.groups) g.id: g};
      final teachersMap = {for (var t in provider.teachers) t.id: t};

      for (var s in provider.students) {
        final grp = groupsMap[s.groupId];
        final teacher = grp?.teacherId != null ? teachersMap[grp!.teacherId] : null;

        sheetSt.appendRow([
          TextCellValue(s.id),
          TextCellValue(s.name),
          TextCellValue(s.phone),
          TextCellValue(s.parentPhone),
          TextCellValue(s.email),
          TextCellValue(s.originSchool),
          TextCellValue(grp?.name ?? '—'),
          TextCellValue(grp?.subject ?? '—'),
          TextCellValue(teacher?.name ?? '—'),
          TextCellValue(s.paymentModeLabel),
          DoubleCellValue(s.pricePerCycle),
          DoubleCellValue(s.pricePerMonth),
          DoubleCellValue(s.pricePerSession),
          IntCellValue(s.sessionsSincePayment),
          DoubleCellValue(s.totalPaid),
          TextCellValue(s.lastPaymentDate != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(s.lastPaymentDate!)
              : '—'),
        ]);
      }

      // ── 2. Feuille Groupes ──
      var sheetGrp = excel[sheetGroups];
      sheetGrp.appendRow([
        TextCellValue('ID Groupe'),
        TextCellValue('Nom du Groupe'),
        TextCellValue('Matière'),
        TextCellValue('Enseignant'),
        TextCellValue('Salle'),
        TextCellValue('Niveau'),
        TextCellValue('Classe'),
        TextCellValue('Horaire'),
        TextCellValue('Nombre d\'Élèves'),
      ]);

      for (var g in provider.groups) {
        final teacher = g.teacherId != null ? teachersMap[g.teacherId] : null;
        sheetGrp.appendRow([
          TextCellValue(g.id),
          TextCellValue(g.name),
          TextCellValue(g.subject),
          TextCellValue(teacher?.name ?? '—'),
          TextCellValue(g.roomName ?? '—'),
          TextCellValue(g.level ?? '—'),
          TextCellValue(g.grade ?? '—'),
          TextCellValue(g.schedule),
          IntCellValue(g.studentIds.length),
        ]);
      }

      // ── 3. Feuille Enseignants ──
      var sheetTch = excel[sheetTeachers];
      sheetTch.appendRow([
        TextCellValue('ID'),
        TextCellValue('Nom'),
        TextCellValue('Téléphone'),
        TextCellValue('Email'),
        TextCellValue('Matière'),
        TextCellValue('Type Contrat'),
        TextCellValue('Montant Fixe (DT)'),
        TextCellValue('Pourcentage (%)'),
      ]);

      for (var t in provider.teachers) {
        sheetTch.appendRow([
          TextCellValue(t.id),
          TextCellValue(t.name),
          TextCellValue(t.phone),
          TextCellValue(t.email),
          TextCellValue(t.subject),
          TextCellValue(t.contractType.label),
          DoubleCellValue(t.fixedAmount),
          DoubleCellValue(t.percentage),
        ]);
      }

      // ── 4. Feuille Paiements ──
      var sheetPay = excel[sheetPayments];
      sheetPay.appendRow([
        TextCellValue('ID Paiement'),
        TextCellValue('Élève'),
        TextCellValue('Téléphone Élève'),
        TextCellValue('Téléphone Parent'),
        TextCellValue('Groupe'),
        TextCellValue('Date'),
        TextCellValue('Montant (DT)'),
        TextCellValue('Séances Couvertes'),
        TextCellValue('Type'),
      ]);

      for (var s in provider.students) {
        final grp = groupsMap[s.groupId];
        for (var p in s.payments) {
          sheetPay.appendRow([
            TextCellValue(p.id),
            TextCellValue(s.name),
            TextCellValue(s.phone),
            TextCellValue(s.parentPhone),
            TextCellValue(grp?.name ?? '—'),
            TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(p.date)),
            DoubleCellValue(p.amount),
            IntCellValue(p.sessionsCount),
            TextCellValue(p.paymentType),
          ]);
        }
      }

      // ── 5. Feuille Présences ──
      var sheetAtt = excel[sheetAttendances];
      sheetAtt.appendRow([
        TextCellValue('Élève'),
        TextCellValue('Téléphone Élève'),
        TextCellValue('Téléphone Parent'),
        TextCellValue('Groupe'),
        TextCellValue('Date de Séance'),
      ]);

      for (var s in provider.students) {
        final grp = groupsMap[s.groupId];
        for (var d in s.attendances) {
          sheetAtt.appendRow([
            TextCellValue(s.name),
            TextCellValue(s.phone),
            TextCellValue(s.parentPhone),
            TextCellValue(grp?.name ?? '—'),
            TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(d)),
          ]);
        }
      }

      final dateStr = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter les données vers Excel',
        fileName: 'donnees_etude_$dateStr.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.xlsx')) {
          outputFile = '$outputFile.xlsx';
        }
        var bytes = excel.save();
        if (bytes != null) {
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes);
          return outputFile;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error exporting Excel: $e');
      return null;
    }
  }

  /// Importe les données depuis un fichier Excel (supporte ancien et nouveau format)
  static Future<Map<String, int>> importFromExcel(AppProvider provider) async {
    Map<String, int> stats = {'students': 0, 'teachers': 0, 'groups': 0};

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null) return stats;

      var bytes = result.files.first.bytes;
      if (bytes == null && result.files.first.path != null) {
        bytes = File(result.files.first.path!).readAsBytesSync();
      }

      if (bytes == null) return stats;

      var excel = Excel.decodeBytes(bytes);

      if (excel.tables.containsKey(sheetStudents)) {
        var sheet = excel.tables[sheetStudents]!;
        List<Teacher> currentTeachers = List.from(provider.teachers);
        bool teachersChanged = false;

        // Détection intelligente des colonnes selon la ligne d'en-tête (row 0)
        int colName = 0;
        int colPhone = 1;
        int colParentPhone = -1;
        int colEmail = 2;
        int colSchool = 3;
        int colLevel = 4;
        int colGrade = 5;
        int colGroupName = 6;
        int colSubject = 7;
        int colTeacherName = 8;
        int colDay = 9;
        int colRoom = 10;
        int colSchedule = 11;
        int colPrice = 12;
        int colSessions = 13;

        if (sheet.maxRows > 0) {
          final headerRow = sheet.rows[0];
          for (int c = 0; c < headerRow.length; c++) {
            final val = headerRow[c]?.value?.toString().toLowerCase().trim() ?? '';
            if (val.contains('parent')) {
              colParentPhone = c;
            } else if (val.contains('téléphone') || val.contains('telephone') || val.contains('tel')) {
              colPhone = c;
            } else if (val.contains('nom') && (val.contains('élève') || val.contains('eleve') || val.contains('complet'))) {
              colName = c;
            } else if (val.contains('email') || val.contains('courriel')) {
              colEmail = c;
            } else if (val.contains('établiss') || val.contains('ecole') || val.contains('école')) {
              colSchool = c;
            } else if (val.contains('niveau')) {
              colLevel = c;
            } else if (val.contains('classe')) {
              colGrade = c;
            } else if (val.contains('groupe')) {
              colGroupName = c;
            } else if (val.contains('matière') || val.contains('matiere')) {
              colSubject = c;
            } else if (val.contains('enseignant') || val.contains('prof')) {
              colTeacherName = c;
            } else if (val.contains('jour')) {
              colDay = c;
            } else if (val.contains('salle')) {
              colRoom = c;
            } else if (val.contains('horaire')) {
              colSchedule = c;
            } else if (val.contains('prix')) {
              colPrice = c;
            } else if (val.contains('séance') || val.contains('seance')) {
              colSessions = c;
            }
          }
        }

        String getCellVal(List<Data?> row, int colIndex) {
          if (colIndex < 0 || colIndex >= row.length) return '';
          return row[colIndex]?.value?.toString().trim() ?? '';
        }

        for (int i = 1; i < sheet.maxRows; i++) {
          var row = sheet.rows[i];
          if (row.isEmpty) continue;

          String name = getCellVal(row, colName);
          if (name.isEmpty) continue;

          String phone = getCellVal(row, colPhone);
          String parentPhone = colParentPhone >= 0 ? getCellVal(row, colParentPhone) : '';
          String email = getCellVal(row, colEmail);
          String school = getCellVal(row, colSchool);
          String level = getCellVal(row, colLevel);
          String grade = getCellVal(row, colGrade);
          String groupName = getCellVal(row, colGroupName);
          String subject = getCellVal(row, colSubject);
          String teacherName = getCellVal(row, colTeacherName);
          String day = getCellVal(row, colDay);
          String room = getCellVal(row, colRoom);
          String schedule = getCellVal(row, colSchedule);

          double price = double.tryParse(getCellVal(row, colPrice)) ?? 100.0;
          int sessionsPaid = int.tryParse(getCellVal(row, colSessions)) ?? 0;

          // 1. Gérer l'Enseignant
          String? teacherId;
          if (teacherName.isNotEmpty) {
            try {
              teacherId = currentTeachers
                  .firstWhere((t) => t.name.toLowerCase() == teacherName.toLowerCase())
                  .id;
            } catch (_) {
              Teacher newTeacher = Teacher(
                id: '${DateTime.now().millisecondsSinceEpoch}${i}T',
                name: teacherName,
                contractType: TeacherContractType.pourcentage,
                fixedAmount: 0,
                percentage: 50,
              );
              currentTeachers.add(newTeacher);
              teacherId = newTeacher.id;
              stats['teachers'] = stats['teachers']! + 1;
              teachersChanged = true;
            }
          }

          // 2. Gérer le Groupe
          String? groupId;
          if (groupName.isNotEmpty) {
            try {
              groupId = provider.groups
                  .firstWhere((g) => g.name.toLowerCase() == groupName.toLowerCase())
                  .id;
            } catch (_) {
              String generatedSchedule = schedule;
              if (day.isNotEmpty) {
                generatedSchedule = '$day $schedule'.trim();
              }

              Group newGroup = Group(
                id: '${DateTime.now().millisecondsSinceEpoch}${i}G',
                name: groupName,
                subject: subject,
                schedule: generatedSchedule,
                teacherId: teacherId,
                roomName: room,
                level: level,
                grade: grade,
              );
              await provider.addGroupObj(newGroup);
              groupId = newGroup.id;
              stats['groups'] = stats['groups']! + 1;
            }
          }

          if (groupId == null) continue;

          // Vérifier si élève existe déjà dans ce groupe
          if (provider.students.any((s) =>
              s.name.toLowerCase() == name.toLowerCase() && s.groupId == groupId)) {
            continue;
          }

          Student s = Student(
            id: '${DateTime.now().millisecondsSinceEpoch}${i}S',
            name: name,
            phone: phone,
            parentPhone: parentPhone,
            email: email,
            originSchool: school,
            groupId: groupId,
            pricePerCycle: price,
            sessionsSincePayment: sessionsPaid,
          );
          await provider.addStudentObj(s);
          stats['students'] = stats['students']! + 1;
        }

        if (teachersChanged) {
          await provider.saveCenterSettings(
              provider.centerName, currentTeachers, provider.rooms);
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error importing Excel: $e');
      return stats;
    }
  }

  /// Exporte une sauvegarde JSON intégrale de toutes les boîtes Hive
  static Future<String?> exportBackupJson(AppProvider provider) async {
    try {
      final backupData = {
        'version': 1,
        'appName': 'Gestion Etude',
        'exportDate': DateTime.now().toIso8601String(),
        'center': {
          'name': provider.centerName,
          'enrollmentFee': provider.enrollmentFee,
          'isHolidayMode': provider.isHolidayMode,
          'logoBase64': provider.centerLogo,
          'language': provider.language,
          'teachers': provider.teachers.map((t) => t.toJson()).toList(),
          'rooms': provider.rooms,
        },
        'groups': provider.groups.map((g) => g.toJson()).toList(),
        'students': provider.students.map((s) => s.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final dateStr = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer la sauvegarde intégrale',
        fileName: 'sauvegarde_etude_$dateStr.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.json')) {
          outputFile = '$outputFile.json';
        }
        File(outputFile)
          ..createSync(recursive: true)
          ..writeAsStringSync(jsonString, encoding: utf8);
        return outputFile;
      }
      return null;
    } catch (e) {
      debugPrint('Error exporting backup JSON: $e');
      return null;
    }
  }

  /// Restaure les données depuis un fichier de sauvegarde JSON
  static Future<Map<String, int>?> importBackupJson(
      BuildContext context, AppProvider provider) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null) return null;

      String jsonString;
      if (result.files.first.bytes != null) {
        jsonString = utf8.decode(result.files.first.bytes!);
      } else if (result.files.first.path != null) {
        jsonString = File(result.files.first.path!).readAsStringSync(encoding: utf8);
      } else {
        return null;
      }

      final Map<String, dynamic> data = json.decode(jsonString);
      if (!data.containsKey('groups') || !data.containsKey('students')) {
        throw Exception('Format de sauvegarde invalide');
      }

      final groupsJson = (data['groups'] as List?) ?? [];
      final studentsJson = (data['students'] as List?) ?? [];

      if (!context.mounted) return null;

      // Boîte de dialogue pour choisir le mode de restauration : Remplacer ou Fusionner
      final restoreMode = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Row(
            children: const [
              Icon(Icons.settings_backup_restore_rounded, color: AppTheme.primary),
              SizedBox(width: 10),
              Text('Restaurer la sauvegarde', style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cette sauvegarde contient :\n'
                '• ${studentsJson.length} élèves\n'
                '• ${groupsJson.length} groupes\n\n'
                'Comment souhaitez-vous effectuer la restauration ?',
                style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠️ « Remplacer tout » effacera la base actuelle pour la remplacer par la sauvegarde.',
                  style: TextStyle(color: AppTheme.danger, fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'merge'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
              ),
              child: const Text('Fusionner'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'overwrite'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remplacer tout'),
            ),
          ],
        ),
      );

      if (restoreMode == null || restoreMode == 'cancel') return null;

      final studentBox = Hive.box<Student>('students');
      final groupBox = Hive.box<Group>('groups');

      int studentsRestored = 0;
      int groupsRestored = 0;

      if (restoreMode == 'overwrite') {
        await studentBox.clear();
        await groupBox.clear();

        // Restaurer paramètres du centre si présents
        if (data.containsKey('center')) {
          final centerData = data['center'] as Map<String, dynamic>;
          final centerName = centerData['name']?.toString() ?? 'Mon Centre';
          final teachers = (centerData['teachers'] as List?)
                  ?.map((t) => Teacher.fromJson(Map<String, dynamic>.from(t as Map)))
                  .toList() ??
              [];
          final rooms = (centerData['rooms'] as List?)?.cast<String>() ?? [];
          final fee = (centerData['enrollmentFee'] as num?)?.toDouble() ?? 0.0;
          final logo = centerData['logoBase64']?.toString();

          await provider.saveCenterSettings(centerName, teachers, rooms,
              enrollmentFee: fee, logoBase64: logo);

          if (centerData.containsKey('isHolidayMode')) {
            await provider.setHolidayMode(centerData['isHolidayMode'] as bool? ?? false);
          }
        }
      }

      // Restaurer Groupes
      for (var gj in groupsJson) {
        final g = Group.fromJson(Map<String, dynamic>.from(gj as Map));
        if (restoreMode == 'merge' && groupBox.containsKey(g.id)) {
          continue;
        }
        await groupBox.put(g.id, g);
        groupsRestored++;
      }

      // Restaurer Élèves
      for (var sj in studentsJson) {
        final s = Student.fromJson(Map<String, dynamic>.from(sj as Map));
        if (restoreMode == 'merge' && studentBox.containsKey(s.id)) {
          continue;
        }
        await studentBox.put(s.id, s);
        studentsRestored++;
      }

      // Rafraîchir les données du Provider
      provider.refreshData();

      return {
        'students': studentsRestored,
        'groups': groupsRestored,
      };
    } catch (e) {
      debugPrint('Error restoring backup JSON: $e');
      rethrow;
    }
  }
}
