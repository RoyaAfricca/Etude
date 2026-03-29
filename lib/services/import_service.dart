import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/group_model.dart';
import '../services/center_service.dart';
import '../providers/app_provider.dart';

class ImportService {
  static const String sheetStudents = 'Élèves';
  static const String sheetTeachers = 'Enseignants';
  static const String sheetGroups = 'Groupes';

  /// Génère un modèle Excel vierge avec les bons en-têtes
  static Future<bool> generateTemplate() async {
    try {
      var excel = Excel.createExcel();
      
      // --- Feuille Élèves ---
      excel.rename('Sheet1', sheetStudents);
      var sheetSt = excel[sheetStudents];
      sheetSt.appendRow([
        TextCellValue('Nom Complet *'),
        TextCellValue('Téléphone'),
        TextCellValue('Email'),
        TextCellValue('Établissement d\'origine'),
        TextCellValue('Nom du Groupe *'),
        TextCellValue('Prix par Cycle (DT)'),
        TextCellValue('Séances déjà payées (0-4)'),
      ]);

      // --- Feuille Enseignants ---
      var sheetTe = excel[sheetTeachers];
      sheetTe.appendRow([
        TextCellValue('Nom Complet *'),
        TextCellValue('Type de Contrat (Salarié / Locateur / Pourcentage) *'),
        TextCellValue('Montant Fixe (Salaire ou Loyer)'),
        TextCellValue('Pourcentage (%)'),
      ]);
      // Exemple de données pour aider l'utilisateur
      sheetTe.appendRow([
        TextCellValue('Exemple Prof'),
        TextCellValue('Pourcentage'),
        TextCellValue('0'),
        TextCellValue('50'),
      ]);

      // --- Feuille Groupes ---
      var sheetGr = excel[sheetGroups];
      sheetGr.appendRow([
        TextCellValue('Nom du Groupe *'),
        TextCellValue('Matière'),
        TextCellValue('Emploi du temps'),
        TextCellValue('Nom de l\'Enseignant'),
        TextCellValue('Salle'),
        TextCellValue('Niveau'),
        TextCellValue('Classe'),
      ]);

      // Sauvegarder le fichier via FilePicker
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le modèle Excel',
        fileName: 'modele_import_etude.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
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

  /// Importe les données depuis un fichier Excel sélectionné
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

      // 1. Importer les Enseignants d'abord (car les groupes en dépendent)
      if (excel.tables.containsKey(sheetTeachers)) {
        var sheet = excel.tables[sheetTeachers]!;
        List<Teacher> currentTeachers = List.from(provider.teachers);
        
        for (int i = 1; i < sheet.maxRows; i++) {
          var row = sheet.rows[i];
          if (row.isEmpty || row[0] == null) continue;

          String name = row[0]?.value?.toString() ?? '';
          if (name.isEmpty) continue;

          // Vérifier si existe déjà
          if (currentTeachers.any((t) => t.name.toLowerCase() == name.toLowerCase())) continue;

          String typeStr = row[1]?.value?.toString().toLowerCase() ?? '';
          TeacherContractType type = TeacherContractType.pourcentage;
          if (typeStr.contains('salar')) type = TeacherContractType.salarie;
          else if (typeStr.contains('locat')) type = TeacherContractType.locateur;

          double fixed = double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0;
          double pct = double.tryParse(row[3]?.value?.toString() ?? '50') ?? 50;

          Teacher t = Teacher(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            name: name,
            contractType: type,
            fixedAmount: fixed,
            percentage: pct,
          );
          currentTeachers.add(t);
          stats['teachers'] = stats['teachers']! + 1;
        }
        await provider.saveCenterSettings(provider.centerName, currentTeachers, provider.rooms);
      }

      // 2. Importer les Groupes
      if (excel.tables.containsKey(sheetGroups)) {
        var sheet = excel.tables[sheetGroups]!;
        for (int i = 1; i < sheet.maxRows; i++) {
          var row = sheet.rows[i];
          if (row.isEmpty || row[0] == null) continue;

          String name = row[0]?.value?.toString() ?? '';
          if (name.isEmpty) continue;

          // Vérifier si existe déjà
          if (provider.groups.any((g) => g.name.toLowerCase() == name.toLowerCase())) continue;

          String subject = row[1]?.value?.toString() ?? '';
          String schedule = row[2]?.value?.toString() ?? '';
          String teacherName = row[3]?.value?.toString() ?? '';
          String room = row[4]?.value?.toString() ?? '';
          String level = row[5]?.value?.toString() ?? '';
          String grade = row[6]?.value?.toString() ?? '';

          String? teacherId;
          if (teacherName.isNotEmpty) {
            try {
              teacherId = provider.teachers
                  .firstWhere((t) => t.name.toLowerCase() == teacherName.toLowerCase())
                  .id;
            } catch (_) {}
          }

          Group g = Group(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            name: name,
            subject: subject,
            schedule: schedule,
            teacherId: teacherId,
            roomName: room,
            level: level,
            grade: grade,
          );
          await provider.addGroupObj(g);
          stats['groups'] = stats['groups']! + 1;
        }
      }

      // 3. Importer les Élèves
      if (excel.tables.containsKey(sheetStudents)) {
        var sheet = excel.tables[sheetStudents]!;
        for (int i = 1; i < sheet.maxRows; i++) {
          var row = sheet.rows[i];
          if (row.isEmpty || row[0] == null) continue;

          String name = row[0]?.value?.toString() ?? '';
          if (name.isEmpty) continue;

          String phone = row[1]?.value?.toString() ?? '';
          String email = row[2]?.value?.toString() ?? '';
          String school = row[3]?.value?.toString() ?? '';
          String groupName = row[4]?.value?.toString() ?? '';
          double price = double.tryParse(row[5]?.value?.toString() ?? '200') ?? 200;
          int sessionsPaid = int.tryParse(row[6]?.value?.toString() ?? '0') ?? 0;

          // Trouver le groupe ID
          String? groupId;
          if (groupName.isNotEmpty) {
            try {
              groupId = provider.groups
                  .firstWhere((g) => g.name.toLowerCase() == groupName.toLowerCase())
                  .id;
            } catch (_) {}
          }
          
          if (groupId == null) continue;

          // Vérifier si élève existe déjà dans ce groupe
          if (provider.students.any((s) => 
              s.name.toLowerCase() == name.toLowerCase() && s.groupId == groupId)) {
            continue;
          }

          Student s = Student(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            name: name,
            phone: phone,
            email: email,
            originSchool: school,
            groupId: groupId,
            pricePerCycle: price,
            sessionsSincePayment: sessionsPaid,
          );
          await provider.addStudentObj(s);
          stats['students'] = stats['students']! + 1;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error importing Excel: $e');
      return stats;
    }
  }
}
