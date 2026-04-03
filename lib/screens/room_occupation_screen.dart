import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/schedule_slot.dart';

class RoomOccupationScreen extends StatefulWidget {
  const RoomOccupationScreen({super.key});

  @override
  State<RoomOccupationScreen> createState() => _RoomOccupationScreenState();
}

class _RoomOccupationScreenState extends State<RoomOccupationScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String? _selectedRoomWeekly;

  // Synchronized scroll controllers for global view
  final ScrollController _hScroll = ScrollController(); // horizontal (header + body)
  final ScrollController _vScrollNames = ScrollController(); // vertical (room names column)
  final ScrollController _vScrollBody = ScrollController(); // vertical (body grid)

  bool _syncing = false;

  final List<int> _hours = List.generate(13, (i) => 8 + i); // 8:00 → 20:00

  static const double _roomColWidth = 100.0;
  static const double _hourColWidth = 130.0;
  static const double _rowHeight = 90.0;
  static const double _headerHeight = 48.0;

  @override
  void initState() {
    super.initState();
    _vScrollNames.addListener(_syncVertical);
    _vScrollBody.addListener(_syncVertical);
  }

  void _syncVertical() {
    if (_syncing) return;
    _syncing = true;
    if (_vScrollNames.hasClients &&
        _vScrollBody.hasClients &&
        _vScrollNames.position.pixels != _vScrollBody.position.pixels) {
      if (_vScrollNames.position.isScrollingNotifier.value) {
        _vScrollBody.jumpTo(_vScrollNames.position.pixels);
      } else if (_vScrollBody.position.isScrollingNotifier.value) {
        _vScrollNames.jumpTo(_vScrollBody.position.pixels);
      }
    }
    _syncing = false;
  }

  @override
  void dispose() {
    _hScroll.dispose();
    _vScrollNames.dispose();
    _vScrollBody.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final l = AppLocalizations.of(context);
    final rooms = provider.rooms;

    if (_selectedRoomWeekly == null && rooms.isNotEmpty) {
      _selectedRoomWeekly = rooms.first;
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            l.roomOccupation,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.surface,
          elevation: 0,
          actions: [
            // Holiday mode badge
            if (provider.isHolidayMode)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wb_sunny_rounded, color: AppTheme.warning, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      l.holidayMode,
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.search_rounded, color: AppTheme.primary),
              onPressed: () => _showFindFreeRoomDialog(context, provider),
              tooltip: l.findFreeRoom,
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
              ),
              child: const TabBar(
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(icon: Icon(Icons.view_module_rounded, size: 18), text: 'Vue Globale'),
                  Tab(icon: Icon(Icons.view_week_rounded, size: 18), text: 'Vue Hebdo'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildGlobalView(provider, rooms, l),
            _buildWeeklyView(provider, rooms, l),
          ],
        ),
      ),
    );
  }

  // ─── Date Selector ───────────────────────────────────────────────────────────

  Widget _buildDateSelector(AppLocalizations l) {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final dateStr =
        DateFormat.yMMMMEEEEd(l.isAr ? 'ar' : 'fr').format(_selectedDate);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Previous day
          _NavButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => setState(
                () => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
          ),

          // Date display (tappable)
          Expanded(
            child: InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: now.subtract(const Duration(days: 365)),
                  lastDate: now.add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primary,
                        surface: AppTheme.surface,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _selectedDate = d);
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            color: AppTheme.accent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Aujourd'hui",
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Today shortcut
          if (!isToday)
            InkWell(
              onTap: () => setState(() => _selectedDate = DateTime.now()),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Auj.",
                  style: TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w700),
                ),
              ),
            ),

          // Next day
          _NavButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () => setState(
                () => _selectedDate = _selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  // ─── Global View ─────────────────────────────────────────────────────────────

  Widget _buildGlobalView(AppProvider provider, List<String> rooms, AppLocalizations l) {
    if (rooms.isEmpty) {
      return _buildEmptyRooms(l);
    }

    final weekday = _selectedDate.weekday;

    return Column(
      children: [
        _buildDateSelector(l),
        // Legend
        _buildLegend(),
        // Grid
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Sticky Room Names Column ────────────────────────────────────
              Column(
                children: [
                  // Corner cell (aligned with hour header)
                  Container(
                    width: _roomColWidth,
                    height: _headerHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      border: Border(
                        right: BorderSide(color: AppTheme.cardBorder, width: 1.5),
                        bottom: BorderSide(color: AppTheme.cardBorder, width: 1.5),
                      ),
                    ),
                    child: const Text(
                      'SALLE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  // Room names list
                  Expanded(
                    child: SizedBox(
                      width: _roomColWidth,
                      child: ListView.builder(
                        controller: _vScrollNames,
                        physics: const ClampingScrollPhysics(),
                        itemCount: rooms.length,
                        itemBuilder: (_, i) => _RoomNameCell(
                          name: rooms[i],
                          height: _rowHeight,
                          isEven: i % 2 == 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Scrollable Grid (horizontal + vertical) ──────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _hScroll,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: _hourColWidth * _hours.length,
                    child: Column(
                      children: [
                        // Hour header (fixed)
                        _buildHourHeader(),
                        // Body rows (scroll vertically, synced with names)
                        Expanded(
                          child: ListView.builder(
                            controller: _vScrollBody,
                            physics: const ClampingScrollPhysics(),
                            itemCount: rooms.length,
                            itemBuilder: (_, rIdx) => _buildRoomRow(
                              provider, rooms[rIdx], weekday, rIdx,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHourHeader() {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1.5)),
      ),
      child: Row(
        children: _hours.map((h) {
          final isNow = DateTime.now().hour == h &&
              _selectedDate.year == DateTime.now().year &&
              _selectedDate.month == DateTime.now().month &&
              _selectedDate.day == DateTime.now().day;
          return Container(
            width: _hourColWidth,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: AppTheme.cardBorder.withOpacity(0.4))),
              color: isNow ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${h.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isNow ? AppTheme.accent : AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isNow)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoomRow(AppProvider provider, String roomName, int weekday, int rowIdx) {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: rowIdx % 2 == 0
            ? AppTheme.surface.withOpacity(0.4)
            : Colors.transparent,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder.withOpacity(0.3))),
      ),
      child: Row(
        children: _hours.map((h) {
          final groups = provider.getOccupyingGroupsAt(roomName, weekday, h, 0);
          return _SlotCell(
            groups: groups,
            width: _hourColWidth,
            hour: h,
            provider: provider,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _LegendBadge(
            color: Colors.green,
            label: 'Libre',
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 16),
          _LegendBadge(
            color: AppTheme.primary,
            label: 'Occupée',
            icon: Icons.meeting_room_rounded,
          ),
          const Spacer(),
          // Scroll hint
          Row(
            children: [
              const Icon(Icons.swipe_rounded, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              const Text(
                'Glisser',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Weekly View ─────────────────────────────────────────────────────────────

  Widget _buildWeeklyView(AppProvider provider, List<String> rooms, AppLocalizations l) {
    if (rooms.isEmpty) return _buildEmptyRooms(l);

    return Column(
      children: [
        // Room picker
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: DropdownButton<String>(
            value: _selectedRoomWeekly,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppTheme.surface,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
            items: rooms
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.meeting_room_rounded,
                                size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            r,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedRoomWeekly = v),
          ),
        ),

        // Day headers
        _buildWeeklyHeader(l),

        // Hour rows
        Expanded(
          child: ListView.builder(
            itemCount: _hours.length,
            itemBuilder: (_, hIdx) => _buildWeeklyRow(provider, _hours[hIdx], l),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyHeader(AppLocalizations l) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Time column header
          Container(
            width: 56,
            alignment: Alignment.center,
            child: const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textMuted),
          ),
          // Day headers
          ...List.generate(7, (i) {
            final dayNum = i + 1;
            final isToday = DateTime.now().weekday == dayNum;
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                  border: Border(left: BorderSide(color: AppTheme.cardBorder.withOpacity(0.3))),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l.dayName(dayNum).substring(0, 3).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isToday ? AppTheme.primary : AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isToday)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeeklyRow(AppProvider provider, int hour, AppLocalizations l) {
    if (_selectedRoomWeekly == null) return const SizedBox.shrink();
    final isCurrentHour = DateTime.now().hour == hour;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isCurrentHour ? AppTheme.primary.withOpacity(0.04) : Colors.transparent,
        border:
            Border(bottom: BorderSide(color: AppTheme.cardBorder.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          // Time label
          Container(
            width: 56,
            alignment: Alignment.center,
            child: Text(
              '${hour.toString().padLeft(2, '0')}h',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isCurrentHour ? AppTheme.accent : AppTheme.textMuted,
              ),
            ),
          ),
          // Day cells
          ...List.generate(7, (i) {
            final day = i + 1;
            final groups = provider.getOccupyingGroupsAt(_selectedRoomWeekly!, day, hour, 0);
            final isEmpty = groups.isEmpty;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isEmpty
                      ? Colors.green.withOpacity(0.04)
                      : AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isEmpty
                        ? Colors.green.withOpacity(0.08)
                        : AppTheme.primary.withOpacity(0.35),
                    width: isEmpty ? 1 : 1.5,
                  ),
                ),
                child: isEmpty
                    ? Center(
                        child: Icon(Icons.event_available_rounded,
                            color: Colors.green.withOpacity(0.25), size: 14),
                      )
                    : Tooltip(
                        message: '${groups.first.name} — ${groups.first.subject}',
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                groups.first.subject.length > 4
                                    ? groups.first.subject.substring(0, 4)
                                    : groups.first.subject,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                groups.first.name.split(' ').first,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmptyRooms(AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.meeting_room_outlined,
                color: AppTheme.textMuted, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune salle configurée',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des salles dans les\nParamètres du Centre',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Find Free Room Dialog ───────────────────────────────────────────────────

  void _showFindFreeRoomDialog(BuildContext context, AppProvider provider) {
    final l = AppLocalizations.of(context);
    int selectedDay = _selectedDate.weekday;
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final freeRooms = provider.getFreeRoomsForSlots([
            ScheduleSlot(
              dayOfWeek: selectedDay,
              startHour: startTime.hour,
              startMinute: startTime.minute,
              endHour: endTime.hour,
              endMinute: endTime.minute,
            )
          ]);

          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              side: BorderSide(color: AppTheme.cardBorder),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  l.findFreeRoom,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Day selector
                  DropdownButtonFormField<int>(
                    value: selectedDay,
                    dropdownColor: AppTheme.surface,
                    decoration: InputDecoration(
                      labelText: l.dayOfWeek,
                      prefixIcon: const Icon(Icons.event_rounded, color: AppTheme.primary),
                    ),
                    items: List.generate(
                      7,
                      (i) => DropdownMenuItem(value: i + 1, child: Text(l.dayName(i + 1))),
                    ),
                    onChanged: (v) => setSt(() => selectedDay = v!),
                  ),
                  const SizedBox(height: 12),

                  // Start time
                  _TimePickerTile(
                    label: l.startTime,
                    time: startTime,
                    onTap: () async {
                      final t = await showTimePicker(context: ctx, initialTime: startTime);
                      if (t != null) setSt(() => startTime = t);
                    },
                  ),
                  const SizedBox(height: 8),

                  // End time
                  _TimePickerTile(
                    label: l.endTime,
                    time: endTime,
                    onTap: () async {
                      final t = await showTimePicker(context: ctx, initialTime: endTime);
                      if (t != null) setSt(() => endTime = t);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppTheme.cardBorder),
                  ),

                  // Results
                  Row(
                    children: [
                      Icon(
                        freeRooms.isNotEmpty
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: freeRooms.isNotEmpty ? Colors.green : AppTheme.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${freeRooms.length} ${l.freeRooms}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: freeRooms.isNotEmpty ? Colors.green : AppTheme.danger,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (freeRooms.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: freeRooms
                          .map((r) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green.withOpacity(0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.meeting_room_rounded,
                                        color: Colors.green, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      r,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                      ),
                      child: Text(
                        l.noFreeRoom,
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.close,
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: AppTheme.primary, size: 16),
      ),
    );
  }
}

class _RoomNameCell extends StatelessWidget {
  final String name;
  final double height;
  final bool isEven;

  const _RoomNameCell({
    required this.name,
    required this.height,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isEven ? AppTheme.surface.withOpacity(0.4) : Colors.transparent,
        border: Border(
          right: BorderSide(color: AppTheme.cardBorder, width: 1.5),
          bottom: BorderSide(color: AppTheme.cardBorder.withOpacity(0.3)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppTheme.primary,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SlotCell extends StatelessWidget {
  final List groups;
  final double width;
  final int hour;
  final AppProvider provider;

  const _SlotCell({
    required this.groups,
    required this.width,
    required this.hour,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = groups.isEmpty;

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      decoration: isEmpty
          ? BoxDecoration(
              color: Colors.green.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.07)),
            )
          : BoxDecoration(
              color: AppTheme.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
      child: isEmpty ? _buildEmptySlot() : _buildOccupiedSlot(groups.first),
    );
  }

  Widget _buildEmptySlot() {
    return Center(
      child: Icon(
        Icons.event_available_rounded,
        color: Colors.green.withOpacity(0.2),
        size: 18,
      ),
    );
  }

  Widget _buildOccupiedSlot(dynamic group) {
    final teacher = provider.teachers
        .where((t) => t.id == group.teacherId)
        .firstOrNull;
    final initials = teacher != null && teacher.name.isNotEmpty
        ? teacher.name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              group.subject,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppTheme.accent,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          // Group name
          Text(
            group.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // Teacher
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 7,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  teacher?.name ?? '',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendBadge extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _LegendBadge({
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppTheme.primary, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const Spacer(),
            Text(
              time.format(context),
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
