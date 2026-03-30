import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../theme/app_theme.dart';
import 'group_notify_dialog.dart';

class MultiGroupNotifyDialog extends StatefulWidget {
  final List<Group> groups;
  final List<Student> allStudents;

  const MultiGroupNotifyDialog({
    super.key,
    required this.groups,
    required this.allStudents,
  });

  static void show(BuildContext context, List<Group> groups, List<Student> allStudents) {
    showDialog(
      context: context,
      builder: (ctx) => MultiGroupNotifyDialog(groups: groups, allStudents: allStudents),
    );
  }

  @override
  State<MultiGroupNotifyDialog> createState() => _MultiGroupNotifyDialogState();
}

class _MultiGroupNotifyDialogState extends State<MultiGroupNotifyDialog> {
  final Set<String> _selectedGroupIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        'Sélectionner les groupes',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisissez les groupes à informer. Tous les élèves de ces groupes seront inclus.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.groups.length,
                itemBuilder: (ctx, index) {
                  final group = widget.groups[index];
                  final isSelected = _selectedGroupIds.contains(group.id);
                  return CheckboxListTile(
                    title: Text(group.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                    subtitle: Text(group.subject, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    value: isSelected,
                    activeColor: AppTheme.primary,
                    checkColor: Colors.white,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedGroupIds.add(group.id);
                        } else {
                          _selectedGroupIds.remove(group.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _selectedGroupIds.isEmpty 
            ? null 
            : () {
                final selectedStudents = widget.allStudents
                    .where((s) => _selectedGroupIds.contains(s.groupId))
                    .toList();
                
                final names = widget.groups
                    .where((g) => _selectedGroupIds.contains(g.id))
                    .map((g) => g.name)
                    .join(', ');
                
                Navigator.pop(context);
                GroupNotifyDialog.show(context, selectedStudents, names);
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Continuer'),
        ),
      ],
    );
  }
}
