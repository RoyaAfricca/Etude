import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class RoomOccupationScreen extends StatefulWidget {
  const RoomOccupationScreen({super.key});

  @override
  State<RoomOccupationScreen> createState() => _RoomOccupationScreenState();
}

class _RoomOccupationScreenState extends State<RoomOccupationScreen> {
  String? _selectedRoom;
  int _selectedDay = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final l = AppLocalizations.of(context);
    final rooms = provider.rooms;

    if (_selectedRoom == null && rooms.isNotEmpty) {
      _selectedRoom = rooms.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l.roomOccupation, style: const TextStyle(fontSize: 18, color: AppTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Row(
            children: [
              Text(
                provider.isHolidayMode ? l.holidayMode : l.regularMode,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
              Switch(
                value: provider.isHolidayMode,
                onChanged: (val) => provider.setHolidayMode(val),
                activeColor: AppTheme.accent,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Rooms & Days Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedRoom,
                  decoration: InputDecoration(
                    labelText: l.room,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: rooms.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => _selectedRoom = val),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final isSelected = _selectedDay == day;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(_getDayName(day, l.isAr)),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedDay = day);
                          },
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          
          // Occupation List
          Expanded(
            child: _selectedRoom == null
                ? Center(child: Text(l.noData))
                : _buildOccupationList(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupationList(AppProvider provider) {
    final l = AppLocalizations.of(context);
    // Times from 08:00 to 20:00
    final hours = List.generate(13, (index) => index + 8);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hours.length,
      itemBuilder: (context, index) {
        final hour = hours[index];
        final groups = provider.getOccupyingGroupsAt(_selectedRoom!, _selectedDay, hour, 0);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: groups.isEmpty ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: groups.isEmpty ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
            ),
          ),
          child: ListTile(
            leading: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            title: Text(
              groups.isEmpty ? 'Libre' : groups.map((g) => '${g.name} (${g.subject})').join(', '),
              style: TextStyle(
                color: groups.isEmpty ? Colors.green : Colors.orange.shade900,
                fontWeight: groups.isEmpty ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: groups.isEmpty ? null : Text(l.roomOccupiedBy),
            trailing: groups.isEmpty ? const Icon(Icons.check_circle_outline, color: Colors.green) : const Icon(Icons.block, color: Colors.orange),
          ),
        );
      },
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
