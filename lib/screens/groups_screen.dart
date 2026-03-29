import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/auth_helper.dart';
import '../models/schedule_slot.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Groupes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_outlined,
                      size: 64, color: AppTheme.textMuted),
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
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
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
                          builder: (_) =>
                              GroupDetailScreen(groupId: group.id),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Group avatar
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    group.name.isNotEmpty
                                        ? group.name[0].toUpperCase()
                                        : '?',
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (group.subject.isNotEmpty) ...[
                                          Icon(Icons.book_outlined,
                                              size: 14,
                                              color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            group.subject,
                                            style: TextStyle(
                                              color:
                                                  AppTheme.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        if (group.schedule.isNotEmpty) ...[
                                          Icon(Icons.schedule,
                                              size: 14,
                                              color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            group.schedule,
                                            style: TextStyle(
                                              color:
                                                  AppTheme.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (group.teacherId != null &&
                                        group.teacherId!.isNotEmpty)
                                      Builder(builder: (_) {
                                        final teacher = provider.teachers
                                            .where((t) => t.id == group.teacherId)
                                            .firstOrNull;
                                        if (teacher == null) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.person_pin_rounded,
                                                  size: 13,
                                                  color: AppTheme.primary),
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
                              // Delete button
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert,
                                    color: AppTheme.textMuted),
                                color: AppTheme.surfaceLight,
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _showDeleteConfirm(
                                        context, provider, group.id, group.name);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            color: AppTheme.danger, size: 18),
                                        SizedBox(width: 8),
                                        Text('Supprimer',
                                            style: TextStyle(
                                                color: AppTheme.danger)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Stats row
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _StatItem(
                                icon: Icons.people,
                                value: '${stats.totalStudents}',
                                label: 'Élèves',
                              ),
                              _StatItem(
                                icon: Icons.check_circle,
                                value: '${stats.upToDate}',
                                label: 'À jour',
                                color: AppTheme.success,
                              ),
                              _StatItem(
                                icon: Icons.error,
                                value: '${stats.overdue}',
                                label: 'En retard',
                                color: AppTheme.danger,
                              ),
                              _StatItem(
                                icon: Icons.payments,
                                value: provider.showRevenue
                                    ? '${stats.totalRevenue.toStringAsFixed(0)}'
                                    : '••••',
                                label: 'DT',
                                color: AppTheme.accent,
                              ),
                            ],
                          ),
                          // Status progress bar
                          if (stats.totalStudents > 0) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 6,
                                child: Row(
                                  children: [
                                    if (stats.upToDate > 0)
                                      Flexible(
                                        flex: stats.upToDate,
                                        child: Container(
                                            color: AppTheme.success),
                                      ),
                                    if (stats.inProgress > 0)
                                      Flexible(
                                        flex: stats.inProgress,
                                        child: Container(
                                            color: AppTheme.warning),
                                      ),
                                    if (stats.dueSoon > 0)
                                      Flexible(
                                        flex: stats.dueSoon,
                                        child: Container(
                                            color: AppTheme.orange),
                                      ),
                                    if (stats.overdue > 0)
                                      Flexible(
                                        flex: stats.overdue,
                                        child: Container(
                                            color: AppTheme.danger),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
  }

  void _showAddGroupDialog(BuildContext context) {
    final nameCtl = TextEditingController();
    final scheduleCtl = TextEditingController();
    final provider = context.read<AppProvider>();
    final isCenter = provider.isCenterMode;
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
      'Primaire': ['Arabe', 'Français', 'Sciences (علوم)'],
      'Collège': [
        'Arabe',
        'Anglais',
        'Français',
        'Maths',
        'Technique',
        'Sciences (علوم)',
        'Physique'
      ],
      'Secondaire': [
        'Maths',
        'Français',
        'Anglais',
        'Arabe',
        'Physique',
        'Sciences',
        'Économie',
        'Gestion',
        'Informatique',
        'Électricité',
        'Mécanique',
        'Espagnol',
        'Russe',
        'Allemand',
        'Chinois',
        'Italien'
      ],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final grades = selectedLevel != null ? gradesMap[selectedLevel]! : [];
          final subjects =
              selectedLevel != null ? subjectsMap[selectedLevel]! : [];

          bool canCreate = nameCtl.text.trim().isNotEmpty &&
              selectedLevel != null &&
              selectedGrade != null &&
              selectedSubject != null &&
              selectedTeacherId != null;

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nouveau groupe',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtl,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    onChanged: (_) => setSt(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Nom du groupe (ex: Groupe A)',
                      prefixIcon: Icon(Icons.group, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Niveau ──
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    dropdownColor: AppTheme.surface,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Niveau scolaire',
                      prefixIcon: Icon(Icons.layers, color: AppTheme.primary),
                    ),
                    items: levels
                        .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary))))
                        .toList(),
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
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedGrade,
                            dropdownColor: AppTheme.surface,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Classe',
                              prefixIcon: Icon(Icons.school_outlined,
                                  color: AppTheme.primary),
                            ),
                            items: grades
                                .map((g) => DropdownMenuItem<String>(
                                    value: g as String,
                                    child: Text(g as String,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary))))
                                .toList(),
                            onChanged: (v) => setSt(() => selectedGrade = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedSubject,
                            dropdownColor: AppTheme.surface,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Matière',
                              prefixIcon: Icon(Icons.book_outlined,
                                  color: AppTheme.primary),
                            ),
                            items: subjects
                                .map((s) => DropdownMenuItem<String>(
                                    value: s as String,
                                    child: Text(s as String,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary))))
                                .toList(),
                            onChanged: (v) => setSt(() => selectedSubject = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: scheduleCtl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Horaire (Optionnel)',
                      prefixIcon: Icon(Icons.schedule, color: AppTheme.primary),
                    ),
                  ),
                  // ── Enseignant & Salle ──────────────────
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedTeacherId,
                    dropdownColor: AppTheme.surface,
                    isExpanded: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Enseignant (Obligatoire)',
                      errorText:
                          teachers.isEmpty ? 'Aucun enseignant créé' : null,
                      prefixIcon: const Icon(Icons.person_outline,
                          color: AppTheme.primary),
                    ),
                    items: teachers
                        .map((t) => DropdownMenuItem<String?>(
                            value: t.id,
                            child: Text(t.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary))))
                        .toList(),
                    onChanged: (v) => setSt(() => selectedTeacherId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedRoom,
                    dropdownColor: AppTheme.surface,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Salle (Optionnel)',
                      prefixIcon: Icon(Icons.meeting_room_outlined,
                          color: AppTheme.primary),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('— Aucune —')),
                      ...rooms.map((r) => DropdownMenuItem<String?>(
                          value: r,
                          child: Text(r,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary)))),
                    ],
                    onChanged: (v) => setSt(() => selectedRoom = v),
                  ),
                  const SizedBox(height: 12),
                  // ── Structured Schedules ──
                  const Text('Horaires structurés (Planification)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  ...regularSlots.map((slot) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${slot.dayName(provider.isAr)}: ${slot.timeRange}', style: const TextStyle(fontSize: 13))),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                            onPressed: () => setSt(() => regularSlots.remove(slot)),
                          ),
                        ],
                      ),
                    ),
                  )),
                  TextButton.icon(
                    onPressed: () => _showAddSlotDialog(ctx, (newSlot) => setSt(() => regularSlots.add(newSlot))),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter un horaire précis'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: canCreate
                          ? () {
                              context.read<AppProvider>().addGroup(
                                    nameCtl.text.trim(),
                                    selectedSubject!,
                                    scheduleCtl.text.trim(),
                                    teacherId: selectedTeacherId,
                                    roomName: selectedRoom,
                                    level: selectedLevel,
                                    grade: selectedGrade,
                                    regularSlots: regularSlots,
                                  );
                              Navigator.pop(ctx);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.cardBorder,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Créer le groupe',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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
              final authenticated = await AuthHelper.showPasswordConfirmation(context);

              if (!context.mounted) return;

              if (authenticated) {
                provider.deleteGroup(id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Groupe supprimé avec succès'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Suppression annulée'),
                    backgroundColor: AppTheme.warning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  void _showAddSlotDialog(BuildContext context, Function(ScheduleSlot) onAdd) {
    int selectedDay = 1;
    TimeOfDay startTime = const TimeOfDay(hour: 14, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 16, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Ajouter un horaire', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedDay,
                dropdownColor: AppTheme.surface,
                items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text(_getDayName(i + 1, false), style: const TextStyle(color: AppTheme.textPrimary)))),
                onChanged: (v) => setSt(() => selectedDay = v!),
                decoration: const InputDecoration(labelText: 'Jour'),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Début', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(startTime.format(ctx), style: const TextStyle(color: AppTheme.textSecondary)),
                trailing: const Icon(Icons.access_time, color: AppTheme.primary),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: startTime);
                  if (t != null) setSt(() => startTime = t);
                },
              ),
              ListTile(
                title: const Text('Fin', style: TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(endTime.format(ctx), style: const TextStyle(color: AppTheme.textSecondary)),
                trailing: const Icon(Icons.access_time, color: AppTheme.primary),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: endTime);
                  if (t != null) setSt(() => endTime = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                onAdd(ScheduleSlot(
                  dayOfWeek: selectedDay,
                  startHour: startTime.hour,
                  startMinute: startTime.minute,
                  endHour: endTime.hour,
                  endMinute: endTime.minute,
                ));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int day, bool isAr) {
    if (isAr) {
      const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
      return days[day - 1];
    }
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[day - 1];
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
    final c = color ?? AppTheme.textSecondary;
    return Column(
      children: [
        Icon(icon, color: c, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
