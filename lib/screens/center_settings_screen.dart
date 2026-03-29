import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/center_service.dart';
import '../theme/app_theme.dart';
import '../utils/auth_helper.dart';

class CenterSettingsScreen extends StatefulWidget {
  const CenterSettingsScreen({super.key});

  @override
  State<CenterSettingsScreen> createState() => _CenterSettingsScreenState();
}

class _CenterSettingsScreenState extends State<CenterSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _centerNameCtrl = TextEditingController();
  final _enrollmentFeeCtrl = TextEditingController();
  bool _hasEnrollmentFee = false;
  late List<Teacher> _teachers;
  late List<String> _rooms;
  late TabController _tabController;
  String? _logoBase64;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final provider = context.read<AppProvider>();
    _centerNameCtrl.text = provider.centerName;
    _teachers = List.from(provider.teachers);
    _rooms = List.from(provider.rooms);
    _logoBase64 = provider.centerLogo;
    final fee = provider.enrollmentFee;
    _hasEnrollmentFee = fee > 0;
    _enrollmentFeeCtrl.text = fee > 0 ? fee.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _centerNameCtrl.dispose();
    _enrollmentFeeCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveAllChanges() async {
    final fee = _hasEnrollmentFee
        ? (double.tryParse(_enrollmentFeeCtrl.text) ?? 0.0)
        : 0.0;
    await context.read<AppProvider>().saveCenterSettings(
      _centerNameCtrl.text.trim(),
      _teachers,
      _rooms,
      enrollmentFee: fee,
      logoBase64: _logoBase64 ?? '',
    );
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.first.bytes != null) {
        final bytes = result.files.first.bytes!;
        // On limite la taille du logo (approx 1MB max pour stockage Hive)
        if (bytes.length > 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image trop grande (max 1Mo)')),
          );
          return;
        }
        setState(() {
          _logoBase64 = base64Encode(bytes);
        });
        await _saveAllChanges();
      }
    } catch (e) {
      debugPrint('Error picking logo: $e');
    }
  }

  Future<void> _saveCenterName() async {
    await _saveAllChanges();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nom du centre sauvegardé !'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addOrEditTeacher({Teacher? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    TeacherContractType contractType =
        existing?.contractType ?? TeacherContractType.pourcentage;
    final fixedCtrl = TextEditingController(
        text: existing?.fixedAmount.toStringAsFixed(0) ?? '');
    final pctCtrl = TextEditingController(
        text: existing?.percentage.toStringAsFixed(0) ?? '50');

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(
            existing == null ? 'Ajouter un enseignant' : 'Modifier un enseignant',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  Text('Type de contrat',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...TeacherContractType.values.map((type) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setSt(() => contractType = type),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: contractType == type
                                  ? AppTheme.primary.withOpacity(0.15)
                                  : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: contractType == type
                                    ? AppTheme.primary
                                    : AppTheme.cardBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<TeacherContractType>(
                                  value: type,
                                  groupValue: contractType,
                                  onChanged: (v) =>
                                      setSt(() => contractType = v!),
                                  activeColor: AppTheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(type.label,
                                          style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary)),
                                      Text(type.description,
                                          style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                  if (contractType == TeacherContractType.salarie)
                    TextField(
                      controller: fixedCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Salaire mensuel fixe (DT)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  if (contractType == TeacherContractType.locateur)
                    TextField(
                      controller: fixedCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Loyer par séance (DT)',
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  if (contractType == TeacherContractType.pourcentage)
                    TextField(
                      controller: pctCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Pourcentage du prof (%)',
                        prefixIcon: Icon(Icons.percent_rounded),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(existing == null ? 'Ajouter' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      final t = Teacher(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameCtrl.text.trim(),
        contractType: contractType,
        fixedAmount:
            double.tryParse(fixedCtrl.text) ?? existing?.fixedAmount ?? 0,
        percentage:
            double.tryParse(pctCtrl.text) ?? existing?.percentage ?? 50,
      );
      setState(() {
        if (existing == null) {
          _teachers.add(t);
        } else {
          final idx = _teachers.indexWhere((e) => e.id == existing.id);
          if (idx != -1) _teachers[idx] = t;
        }
      });
      await _saveAllChanges();
    });
  }

  Future<void> _deleteTeacher(Teacher t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Supprimer ${t.name} ?',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: const Text(
            'Cette action est irréversible. Les groupes associés ne seront pas supprimés.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () async {
                final authenticated = await AuthHelper.showPasswordConfirmation(context);
                if (authenticated) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _teachers.removeWhere((e) => e.id == t.id));
      await _saveAllChanges();
    }
  }

  Future<void> _addRoom() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Ajouter une salle',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nom de la salle',
            prefixIcon: Icon(Icons.meeting_room_outlined),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              setState(() => _rooms.add(ctrl.text.trim()));
              await _saveAllChanges();
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Gestion du Centre'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Centre'),
            Tab(icon: Icon(Icons.group), text: 'Enseignants'),
            Tab(icon: Icon(Icons.meeting_room), text: 'Salles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCenterTab(),
          _buildTeachersTab(),
          _buildRoomsTab(),
        ],
      ),
    );
  }

  Widget _buildCenterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ──────────────────────────────────────────────
          Text('Logo du Centre',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder, width: 2),
                    image: _logoBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(_logoBase64!)),
                            fit: BoxFit.contain,
                          )
                        : null,
                  ),
                  child: _logoBase64 == null
                      ? const Icon(Icons.business_rounded,
                          size: 50, color: AppTheme.textMuted)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: _pickLogo,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: AppTheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                if (_logoBase64 != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _logoBase64 = null);
                        _saveAllChanges();
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: AppTheme.danger, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text('Nom du Centre',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          TextField(
            controller: _centerNameCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Ex: Centre Excellence',
              prefixIcon: Icon(Icons.corporate_fare_rounded),
            ),
          ),
          const SizedBox(height: 28),

          // ── Frais d'inscription ─────────────────────────────────
          Text('Frais d\'inscription',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Activer les frais d\'inscription',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                          Text('Un montant unique payé à l\'inscription',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    StatefulBuilder(
                      builder: (_, setSt) => Switch(
                        value: _hasEnrollmentFee,
                        activeColor: AppTheme.primary,
                        onChanged: (v) {
                          setState(() => _hasEnrollmentFee = v);
                          if (!v) _enrollmentFeeCtrl.clear();
                        },
                      ),
                    ),
                  ],
                ),
                if (_hasEnrollmentFee) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _enrollmentFeeCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Montant des frais d\'inscription',
                      prefixIcon: Icon(Icons.confirmation_number_outlined),
                      suffixText: 'DT',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveCenterName,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersTab() {
    return Column(
      children: [
        Expanded(
          child: _teachers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_alt_1_outlined,
                          size: 50, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      Text('Aucun enseignant',
                          style: GoogleFonts.outfit(
                              fontSize: 16, color: AppTheme.textMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _teachers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final t = _teachers[i];
                    return _TeacherCard(
                      teacher: t,
                      onEdit: () => _addOrEditTeacher(existing: t),
                      onDelete: () => _deleteTeacher(t),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Ajouter un enseignant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _addOrEditTeacher,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsTab() {
    return Column(
      children: [
        Expanded(
          child: _rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.meeting_room_outlined,
                          size: 50, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      Text('Aucune salle enregistrée',
                          style: GoogleFonts.outfit(
                              fontSize: 16, color: AppTheme.textMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _RoomTile(
                    room: _rooms[i],
                    onDelete: () async {
                      setState(() => _rooms.removeAt(i));
                      await _saveAllChanges();
                    },
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_home_work_rounded),
              label: const Text('Ajouter une salle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _addRoom,
            ),
          ),
        ),
      ],
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherCard(
      {required this.teacher, required this.onEdit, required this.onDelete});

  Color get _contractColor {
    switch (teacher.contractType) {
      case TeacherContractType.salarie:
        return AppTheme.success;
      case TeacherContractType.locateur:
        return AppTheme.warning;
      case TeacherContractType.pourcentage:
        return AppTheme.primary;
    }
  }

  String get _contractDetail {
    switch (teacher.contractType) {
      case TeacherContractType.salarie:
        return '${teacher.fixedAmount.toStringAsFixed(0)} DT / mois';
      case TeacherContractType.locateur:
        return 'Loyer: ${teacher.fixedAmount.toStringAsFixed(0)} DT / séance';
      case TeacherContractType.pourcentage:
        return '${teacher.percentage.toStringAsFixed(0)}% des revenus';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _contractColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person_rounded, color: _contractColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teacher.name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _contractColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${teacher.contractType.label} • $_contractDetail',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: _contractColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppTheme.textSecondary, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final String room;
  final VoidCallback onDelete;

  const _RoomTile({required this.room, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.meeting_room_outlined,
              color: AppTheme.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(room,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.danger, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
