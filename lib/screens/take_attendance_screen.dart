import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../models/group_model.dart';
import '../theme/app_theme.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final String groupId;

  const TakeAttendanceScreen({super.key, required this.groupId});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _attendanceState = {};
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final provider = context.read<AppProvider>();
      final students = provider.getStudentsForGroup(widget.groupId);
      // Par défaut, on suppose que tout le monde est présent.
      // Le professeur décoche les absents, ce qui est généralement plus rapide.
      for (var s in students) {
        _attendanceState[s.id] = true;
      }
      _isInit = true;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme,
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );
      });
    }
  }

  void _saveAttendance(AppProvider provider) async {
    final presentIds = _attendanceState.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    await provider.recordSessionAttendance(
        widget.groupId, _selectedDate, presentIds);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Appel enregistré pour ${presentIds.length} présents'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final group = provider.groups.firstWhere(
      (g) => g.id == widget.groupId,
      orElse: () => Group(id: '', name: 'Groupe Inconnu', schedule: ''),
    );
    final students = provider.getStudentsForGroup(widget.groupId);

    // Sort students alphabetically
    students.sort((a, b) => a.name.compareTo(b.name));

    final presentCount = _attendanceState.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Faire l'appel"),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Header: Group Info & Date Picker ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${students.length} élèves inscrits',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.date_range, color: AppTheme.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date de la séance',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary, fontSize: 12)),
                                Text(
                                  DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                                      .format(_selectedDate),
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(Icons.edit, color: AppTheme.primary, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Students List ──
          Expanded(
            child: students.isEmpty
                ? const Center(
                    child: Text('Aucun élève dans ce groupe.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final isPresent = _attendanceState[student.id] ?? false;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPresent
                              ? AppTheme.success.withOpacity(0.05)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPresent
                                ? AppTheme.success.withOpacity(0.3)
                                : AppTheme.cardBorder,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isPresent,
                          activeColor: AppTheme.success,
                          checkColor: Colors.white,
                          title: Text(
                            student.name,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: isPresent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            isPresent ? 'Présent(e)' : 'Absent(e)',
                            style: TextStyle(
                              color: isPresent
                                  ? AppTheme.success
                                  : AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _attendanceState[student.id] = val ?? false;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),

          // ── Bottom Action Bar ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Total présents:',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        Text(
                          '$presentCount / ${students.length}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveAttendance(provider),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Enregistrer l\'appel', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
