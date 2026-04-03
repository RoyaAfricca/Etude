import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_model.dart';
import '../models/schedule_slot.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'slot_add_dialog.dart';

class GroupEditDialog {
  static void show(BuildContext context, Group group) {
    final nameCtl = TextEditingController(text: group.name);
    final provider = context.read<AppProvider>();
    final teachers = provider.teachers;
    final rooms = provider.rooms;

    // Convert empty Hive strings to null for better dropdown handling
    String? sLevel = (group.level == '' || group.level == null) ? null : group.level;
    String? sGrade = (group.grade == '' || group.grade == null) ? null : group.grade;
    String? sSubject = group.subject == '' ? null : group.subject;
    String? sTeacherId = (group.teacherId == '' || group.teacherId == null) ? null : group.teacherId;
    String? sRoom = (group.roomName == '' || group.roomName == null) ? null : group.roomName;
    List<ScheduleSlot> regularSlots = List.from(group.regularSlots);

    final levels = ['Primaire', 'Collège', 'Secondaire'];
    final gradesMap = {
      'Primaire': ['1ère', '2ème', '3ème', '4ème', '5ème', '6ème'],
      'Collège': ['7ème', '8ème', '9ème'],
      'Secondaire': ['1ère', '2ème', '3ème', '4ème (Bac)'],
    };
    final subjectsMap = {
      'Primaire': ['Arabe', 'Français', 'Anglais', 'Sciences (علوم)'],
      'Collège': ['Arabe', 'Anglais', 'Français', 'Maths', 'Technique', 'Sciences (علوم)', 'Physique'],
      'Secondaire': ['Maths', 'Français', 'Anglais', 'Arabe', 'Physique', 'Sciences', 'Économie', 'Gestion', 'Informatique', 'Électricité', 'Mécanique', 'Espagnol', 'Russe', 'Allemand', 'Chinois', 'Italien'],
    };

    // Safety check: ensure current values exist in predefined lists
    if (sLevel != null && !levels.contains(sLevel)) sLevel = null;
    if (sLevel != null) {
      final validGrades = gradesMap[sLevel] ?? [];
      if (sGrade != null && !validGrades.contains(sGrade)) sGrade = null;
      final validSubjects = subjectsMap[sLevel] ?? [];
      if (sSubject != null && !validSubjects.contains(sSubject)) sSubject = null;
    } else {
      sGrade = null;
      sSubject = null;
    }

    if (sTeacherId != null && !teachers.any((t) => t.id == sTeacherId)) sTeacherId = null;
    if (sRoom != null && !rooms.contains(sRoom)) sRoom = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          try {
            final grades = sLevel != null ? (gradesMap[sLevel] ?? []) : [];
            final subjects = sLevel != null ? (subjectsMap[sLevel] ?? []) : [];

            // Double check validity after state change
            if (sGrade != null && !grades.contains(sGrade)) sGrade = null;
            if (sSubject != null && !subjects.contains(sSubject)) sSubject = null;

            // Deduplicate teacher items to avoid "Duplicate items" crash
            final teacherItems = <String, String>{};
            for (var t in teachers) {
              if (t.id.isNotEmpty) teacherItems[t.id] = t.name;
            }

            // Deduplicate room items
            final roomItems = rooms.where((r) => r.isNotEmpty).toSet().toList();

            bool canSave = nameCtl.text.trim().isNotEmpty &&
                sLevel != null && sGrade != null && sSubject != null && sTeacherId != null;

            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Modifier le groupe', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameCtl,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Nom du groupe', prefixIcon: Icon(Icons.group, color: AppTheme.primary)),
                      onChanged: (_) => setSt(() {}),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: sLevel,
                      hint: const Text('Niveau scolaire'),
                      dropdownColor: AppTheme.surface,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Niveau scolaire', prefixIcon: Icon(Icons.layers, color: AppTheme.primary)),
                      items: levels.map((l) => DropdownMenuItem<String>(value: l, child: Text(l, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
                      onChanged: (v) => setSt(() {
                        sLevel = v;
                      }),
                    ),
                    if (sLevel != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: DropdownButtonFormField<String>(
                            value: sGrade,
                            hint: const Text('Classe'),
                            dropdownColor: AppTheme.surface,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(labelText: 'Classe'),
                            items: grades.map((g) => DropdownMenuItem<String>(value: g, child: Text(g, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
                            onChanged: (v) => setSt(() => sGrade = v),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: DropdownButtonFormField<String>(
                            value: sSubject,
                            hint: const Text('Matière'),
                            dropdownColor: AppTheme.surface,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(labelText: 'Matière'),
                            items: subjects.map((s) => DropdownMenuItem<String>(value: s, child: Text(s, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
                            onChanged: (v) => setSt(() => sSubject = v),
                          )),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: sTeacherId,
                      hint: const Text('Choisir un enseignant'),
                      dropdownColor: AppTheme.surface,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Enseignant', prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary)),
                      items: teacherItems.entries.map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
                      onChanged: (v) => setSt(() => sTeacherId = v),
                    ),
                    if (provider.showRooms) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: sRoom,
                        hint: const Text('Choisir une salle'),
                        dropdownColor: AppTheme.surface,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(labelText: 'Salle', prefixIcon: Icon(Icons.meeting_room_outlined, color: AppTheme.primary)),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('— Aucune —')),
                          ...roomItems.map((r) => DropdownMenuItem<String?>(value: r, child: Text(r, style: const TextStyle(color: AppTheme.textPrimary)))),
                        ],
                        onChanged: (v) => setSt(() => sRoom = v),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (regularSlots.isNotEmpty) ...[
                      const Text('Horaires :', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...regularSlots.map((slot) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text('${slot.dayName(provider.isAr)} ${slot.timeRange}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                              onPressed: () => setSt(() => regularSlots.remove(slot)),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                    ],
                    TextButton.icon(
                      onPressed: () => SlotAddDialog.show(ctx, (newSlot) => setSt(() => regularSlots.add(newSlot))),
                      icon: const Icon(Icons.add),
                      label: const Text('Modifier l\'horaire'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: canSave ? () {
                           // Check for room conflict
                           if (sRoom != null) {
                             final l = AppLocalizations.of(context);
                             final conflictGroup = provider.checkRoomConflict(sRoom!, regularSlots, excludeGroupId: group.id);
                             if (conflictGroup != null) {
                               showDialog(
                                 context: context,
                                 builder: (c) => AlertDialog(
                                   title: Text(l.conflictsFound, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                                   content: Text('${l.conflictWarning}\n\n${l.roomOccupiedBy} : ${conflictGroup.name}'),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(c), child: Text(l.close)),
                                   ],
                                 ),
                               );
                               return;
                             }
                           }

                           String generatedSchedule = regularSlots.isEmpty ? '' : regularSlots.map((s) => '${s.dayName(provider.isAr)} ${s.timeRange}').join(' , ');
                           provider.updateGroup(group.id, nameCtl.text.trim(), sSubject!, generatedSchedule, teacherId: sTeacherId, roomName: sRoom, level: sLevel, grade: sGrade);
                           provider.updateGroupSchedules(group.id, regularSlots, group.holidaySlots);
                           Navigator.pop(ctx);
                        } : null,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } catch (e) {
            return Container(
              padding: const EdgeInsets.all(32),
              child: SelectableText(
                'ERREUR DE MENU: \n\n$e',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            );
          }
        },
      ),
    );
  }
}
