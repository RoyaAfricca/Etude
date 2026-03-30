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

  /// Génère un modèle Excel vierge avec les bons en-têtes
  static Future<bool> generateTemplate() async {
    try {
      var excel = Excel.createExcel();
      
      // --- Feuille Élèves ---
      excel.rename('Sheet1', sheetStudents);
      var sheetSt = excel[sheetStudents];
      sheetSt.appendRow([
        TextCellValue('Nom Complet (Élève) *'),
        TextCellValue('Téléphone'),
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

      if (excel.tables.containsKey(sheetStudents)) {
        var sheet = excel.tables[sheetStudents]!;
        List<Teacher> currentTeachers = List.from(provider.teachers);
        bool teachersChanged = false;
        
        for (int i = 1; i < sheet.maxRows; i++) {
          var row = sheet.rows[i];
          if (row.isEmpty || row[0] == null) continue;

          String name = row[0]?.value?.toString() ?? '';
          if (name.isEmpty) continue;

          String phone = row[1]?.value?.toString() ?? '';
          String email = row[2]?.value?.toString() ?? '';
          String school = row[3]?.value?.toString() ?? '';
          String level = row[4]?.value?.toString() ?? '';
          String grade = row[5]?.value?.toString() ?? '';
          String groupName = row[6]?.value?.toString() ?? '';
          String subject = row[7]?.value?.toString() ?? '';
          String teacherName = row[8]?.value?.toString() ?? '';
          String day = row[9]?.value?.toString() ?? '';
          String room = row[10]?.value?.toString() ?? '';
          String schedule = row[11]?.value?.toString() ?? '';
          
          double price = double.tryParse(row[12]?.value?.toString() ?? '200') ?? 200;
          int sessionsPaid = int.tryParse(row[13]?.value?.toString() ?? '0') ?? 0;

          // 1. Gérer l'Enseignant
          String? teacherId;
          if (teacherName.isNotEmpty) {
            try {
              teacherId = currentTeachers
                  .firstWhere((t) => t.name.toLowerCase() == teacherName.toLowerCase())
                  .id;
            } catch (_) {
              // Créer le prof par défaut s'il n'existe pas
              Teacher newTeacher = Teacher(
                id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString() + 'T',
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
               // Créer le groupe complet
               String generatedSchedule = schedule;
               if (day.isNotEmpty) {
                 generatedSchedule = '\$day \$schedule'.trim();
               }
               
               Group newGroup = Group(
                 id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString() + 'G',
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
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString() + 'S',
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

        if (teachersChanged) {
          await provider.saveCenterSettings(provider.centerName, currentTeachers, provider.rooms);
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error importing Excel: $e');
      return stats;
    }
  }
}
