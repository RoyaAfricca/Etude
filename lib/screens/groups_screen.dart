import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/auth_helper.dart';
import '../models/schedule_slot.dart';
import 'group_detail_screen.dart';
import '../widgets/group_edit_dialog.dart';
import '../widgets/group_notify_dialog.dart';
import '../widgets/slot_add_dialog.dart';
import '../widgets/multi_group_notify_dialog.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mes Groupes'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (provider.groups.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.broadcast_on_personal_rounded, color: AppTheme.orange),
                  tooltip: 'Informer plusieurs groupes',
                  onPressed: () => MultiGroupNotifyDialog.show(context, provider.groups, provider.students),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (provider.groups.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups_outlined, size: 64, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun groupe',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez sur + pour créer votre premier groupe',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: provider.groups.length,
                itemBuilder: (context, index) {
                  final group = provider.groups[index];
                  final stats = provider.getGroupStats(group);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupDetailScreen(groupId: group.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${group.subject} - ${group.name}',
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (group.schedule.isNotEmpty) ...[
                                              Icon(Icons.schedule, size: 14, color: AppTheme.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                group.schedule,
                                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                              ),
                                              const SizedBox(width: 12),
                                            ],
                                          ],
                                        ),
                                        if (group.teacherId != null && group.teacherId!.isNotEmpty)
                                          Builder(builder: (_) {
                                            final teacher = provider.teachers
                                                .where((t) => t.id == group.teacherId)
                                                .firstOrNull;
                                            if (teacher == null) return const SizedBox.shrink();
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.person_pin_rounded, size: 13, color: AppTheme.primary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    teacher.name,
                                                    style: const TextStyle(
                                                      color: AppTheme.primary,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, color: AppTheme.textMuted),
                                    color: AppTheme.surfaceLight,
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _showDeleteConfirm(context, provider, group.id, group.name);
                                      } else if (value == 'edit') {
                                        GroupEditDialog.show(context, group);
                                      } else if (value == 'notify') {
                                        final groupStudents = provider.getStudentsForGroup(group.id);
                                        GroupNotifyDialog.show(context, groupStudents, group.name);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Modifier', style: TextStyle(color: AppTheme.textPrimary)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'notify',
                                        child: Row(
                                          children: [
                                            Icon(Icons.send_rounded, color: AppTheme.orange, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Informer le groupe', style: TextStyle(color: AppTheme.orange)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, color: AppTheme.danger, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Supprimer', style: TextStyle(color: AppTheme.danger)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatItem(icon: Icons.people, value: '${stats.totalStudents}', label: 'Élèves'),
                                  _StatItem(icon: Icons.check_circle, value: '${stats.upToDate}', label: 'À jour', color: AppTheme.success),
                                  _StatItem(icon: Icons.error, value: '${stats.overdue}', label: 'En retard', color: AppTheme.danger),
                                  _StatItem(
                                    icon: Icons.payments,
                                    value: provider.showRevenue ? '${stats.totalRevenue.toStringAsFixed(0)}' : '••••',
                                    label: 'DT',
                                    color: AppTheme.accent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddGroupDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final nameCtl = TextEditingController();
    final provider = context.read<AppProvider>();
    final teachers = provider.teachers;
    final rooms = provider.rooms;

    String? selectedLevel;
    String? selectedGrade;
    String? selectedSubject;
    String? selectedTeacherId;
    String? selectedRoom;
    List<ScheduleSlot> regularSlots = [];

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final grades = selectedLevel != null ? gradesMap[selectedLevel]! : [];
          final subjects = selectedLevel != null ? subjectsMap[selectedLevel]! : [];

          // Deduplicate teacher items to avoid "Duplicate items" crash
          final teacherItems = <String, String>{};
          for (var t in teachers) {
            if (t.id.isNotEmpty) teacherItems[t.id] = t.name;
          }

          // Deduplicate room items
          final roomItems = rooms.where((r) => r.isNotEmpty).toSet().toList();

          bool canCreate = nameCtl.text.trim().isNotEmpty &&
              selectedLevel != null &&
              selectedGrade != null &&
              selectedSubject != null;


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
                  const Text('Nouveau groupe', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtl,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Nom du groupe', prefixIcon: Icon(Icons.group, color: AppTheme.primary)),
                    onChanged: (_) => setSt(() {}),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    dropdownColor: AppTheme.surface,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Niveau scolaire', prefixIcon: Icon(Icons.layers, color: AppTheme.primary)),
                    items: levels.map((l) => DropdownMenuItem<String>(value: l, child: Text(l, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
                    onChanged: (v) => setSt(() {
                      selectedLevel = v;
                      selectedGrade = null;
                      selectedSubject = null;
                    }),
                  ),
                  if (selectedLevel != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: DropdownButtonFormField<String>(
                          value: selectedGrade,
                          dropdownColor: AppTheme.surface,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'Classe'),
                          items: grades.map((g) => DropdownMenuItem<String>(value: g, child: Text(g, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
                          onChanged: (v) => setSt(() => selectedGrade = v),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: DropdownButtonFormField<String>(
                          value: selectedSubject,
                          dropdownColor: AppTheme.surface,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(labelText: 'Matière'),
                          items: subjects.map((s) => DropdownMenuItem<String>(value: s, child: Text(s, style: const TextStyle(color: AppTheme.textPrimary)))).toList(),
                          onChanged: (v) => setSt(() => selectedSubject = v),
                        )),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedTeacherId,
                    dropdownColor: AppTheme.surface,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Enseignant', prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary)),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('— Aucun —')),
                      ...teacherItems.entries.map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value, style: const TextStyle(color: AppTheme.textPrimary)))),
                    ],
                    onChanged: (v) => setSt(() => selectedTeacherId = v),
                  ),
                  if (provider.showRooms) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedRoom,
                      dropdownColor: AppTheme.surface,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Salle', prefixIcon: Icon(Icons.meeting_room_outlined, color: AppTheme.primary)),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('— Aucune —')),
                        ...roomItems.map((r) => DropdownMenuItem<String?>(value: r, child: Text(r, style: const TextStyle(color: AppTheme.textPrimary)))),
                      ],
                      onChanged: (v) => setSt(() => selectedRoom = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (regularSlots.isNotEmpty) ...[
                    const Text('Horaires sélectionnés :', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    label: const Text('Planifier un horaire'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: canCreate ? () {
                        // Check for room conflict
                        if (selectedRoom != null) {
                          final l = AppLocalizations.of(context);
                          final conflictGroup = provider.checkRoomConflict(selectedRoom!, regularSlots);
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
                        provider.addGroup(nameCtl.text.trim(), selectedSubject!, generatedSchedule, teacherId: selectedTeacherId, roomName: selectedRoom, level: selectedLevel, grade: selectedGrade, regularSlots: regularSlots);
                        Navigator.pop(ctx);
                      } : null,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Créer le groupe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, AppProvider provider, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Supprimer le groupe ?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Le groupe "$name" et tous ses élèves seront supprimés.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final authenticated = await AuthHelper.authenticate(context, reason: 'Confirmez la suppression par PIN ou Empreinte');
              if (!context.mounted) return;
              if (authenticated) {
                provider.deleteGroup(id);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? AppTheme.textMuted),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
