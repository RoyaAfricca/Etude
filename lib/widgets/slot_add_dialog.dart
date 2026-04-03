import 'package:flutter/material.dart';
import '../models/schedule_slot.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class SlotAddDialog {
  static void show(BuildContext context, Function(ScheduleSlot) onAdded) {
    final l = AppLocalizations.of(context);
    final daysFr = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    final daysAr = [
      'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
    ];
    
    int selectedDayIdx = 0; // 0-6
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(l.addSchedule, style: const TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: selectedDayIdx,
                dropdownColor: AppTheme.surface,
                isExpanded: true,
                items: List.generate(7, (i) => DropdownMenuItem(
                  value: i, 
                  child: Text(l.isAr ? daysAr[i] : daysFr[i], style: const TextStyle(color: AppTheme.textPrimary))
                )),
                onChanged: (v) => setSt(() => selectedDayIdx = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(l.startTime, style: const TextStyle(color: AppTheme.textPrimary)),
                trailing: Text(startTime.format(ctx)),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: startTime);
                  if (t != null) setSt(() => startTime = t);
                },
              ),
              ListTile(
                title: Text(l.endTime, style: const TextStyle(color: AppTheme.textPrimary)),
                trailing: Text(endTime.format(ctx)),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: endTime);
                  if (t != null) setSt(() => endTime = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: () {
                onAdded(ScheduleSlot(
                  dayOfWeek: selectedDayIdx + 1,
                  startHour: startTime.hour,
                  startMinute: startTime.minute,
                  endHour: endTime.hour,
                  endMinute: endTime.minute,
                ));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: Text(l.confirm, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
