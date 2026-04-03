import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'activation_service.dart';

/// Types de contrat pour un enseignant dans un centre
enum TeacherContractType {
  salarie,      // Salarié fixe mensuel
  locateur,     // Loyer de salle fixe par mois
  pourcentage,  // Pourcentage des revenus de ses groupes
}

extension TeacherContractTypeLabel on TeacherContractType {
  String get label {
    switch (this) {
      case TeacherContractType.salarie:
        return 'Recruté (Salarié)';
      case TeacherContractType.locateur:
        return 'Locateur (Loyer Salle)';
      case TeacherContractType.pourcentage:
        return 'Au pourcentage';
    }
  }

  String get description {
    switch (this) {
      case TeacherContractType.salarie:
        return 'Montant fixe mensuel versé au professeur';
      case TeacherContractType.locateur:
        return 'Le professeur paye un loyer fixe de salle au centre par séance';
      case TeacherContractType.pourcentage:
        return 'Le professeur reçoit un % des revenus de ses groupes';
    }
  }
}

/// Modèle d'un enseignant (stocké en JSON dans Hive settings)
class Teacher {
  final String id;
  String name;
  String phone;
  TeacherContractType contractType;
  double fixedAmount;    // Pour salarie ou locateur
  double percentage;     // Pour pourcentage (0-100)

  Teacher({
    required this.id,
    required this.name,
    this.phone = '',
    this.contractType = TeacherContractType.pourcentage,
    this.fixedAmount = 0.0,
    this.percentage = 50.0,
  });

  /// Part que reçoit le professeur d'un montant total généré par ses groupes
  /// [sessionCount] = nombre de séances données (utilisé uniquement pour le locateur)
  double teacherShare(double totalRevenue, {int sessionCount = 0}) {
    switch (contractType) {
      case TeacherContractType.salarie:
        return fixedAmount; // Il reçoit son salaire fixe
      case TeacherContractType.locateur:
        // Le locateur garde tout l'argent collecté sauf le loyer dû au centre
        return totalRevenue - (fixedAmount * sessionCount);
      case TeacherContractType.pourcentage:
        return totalRevenue * percentage / 100.0;
    }
  }

  /// Part que reçoit le centre d'un montant total généré par ses groupes
  /// [sessionCount] = nombre de séances données (utilisé uniquement pour le locateur)
  double centerShare(double totalRevenue, {int sessionCount = 0}) {
    switch (contractType) {
      case TeacherContractType.salarie:
        return totalRevenue - fixedAmount;
      case TeacherContractType.locateur:
        // Le centre reçoit le loyer par séance x nombre de séances
        return fixedAmount * sessionCount;
      case TeacherContractType.pourcentage:
        return totalRevenue * (1 - percentage / 100.0);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'contractType': contractType.index,
        'fixedAmount': fixedAmount,
        'percentage': percentage,
      };

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Sans nom',
        phone: json['phone']?.toString() ?? '',
        contractType: TeacherContractType
            .values[json['contractType'] as int? ?? 0],
        fixedAmount: (json['fixedAmount'] as num?)?.toDouble() ?? 0.0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 50.0,
      );

  static List<Teacher> listFromJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = json.decode(jsonStr) as List;
      return list.map((e) => Teacher.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<Teacher> teachers) {
    return json.encode(teachers.map((t) => t.toJson()).toList());
  }
}

/// Service Auth Login (login / mot de passe stocké dans Hive settings)
class AppAuthService {
  static const String _settingsBox = 'settings';
  static const String _loginKey = 'auth_login';
  static const String _passwordKey = 'auth_password';
  static const String _mustChangePasswordKey = 'must_change_password';

  static const String defaultLogin = 'Admin';
  static const String defaultPassword = 'admin';

  Box get _box => Hive.box(_settingsBox);

  String get currentLogin => _box.get(_loginKey, defaultValue: defaultLogin) as String;

  bool get mustChangePassword =>
      _box.get(_mustChangePasswordKey, defaultValue: true) as bool;

  bool verifyCredentials(String login, String password) {
    final storedLogin = _box.get(_loginKey, defaultValue: defaultLogin) as String;
    final storedPassword = _box.get(_passwordKey, defaultValue: defaultPassword) as String;
    return login.trim() == storedLogin && password == storedPassword;
  }

  bool verifyPassword(String password) {
    final storedPassword = _box.get(_passwordKey, defaultValue: defaultPassword) as String;
    return password == storedPassword;
  }

  Future<void> changeCredentials(String newLogin, String newPassword) async {
    await _box.put(_loginKey, newLogin.trim());
    await _box.put(_passwordKey, newPassword);
    await _box.put(_mustChangePasswordKey, false);
  }

  Future<bool> resetCredentials(String resetCode) async {
    final activationService = ActivationService();
    if (await activationService.verifyResetCode(resetCode)) {
      await changeCredentials(defaultLogin, defaultPassword);
      await _box.put(_mustChangePasswordKey, true); // Forcer le changement au prohain login
      return true;
    }
    return false;
  }
}

/// Service de configuration du Centre
class CenterConfigService {
  static const String _settingsBox = 'settings';
  static const String _appModeKey = 'app_mode';
  static const String _centerNameKey = 'center_name';
  static const String _teachersKey = 'teachers_json';
  static const String _roomsKey = 'rooms_json';
  static const String _modeSetKey = 'mode_configured';
  static const String _enrollmentFeeKey = 'enrollment_fee';
  static const String _logoKey = 'center_logo_base64'; // Logo du centre en base64
  static const String _syncVisibleKey = 'sync_visible'; // Visibilité de la sync (onboarding)

  Box get _box => Hive.box(_settingsBox);

  bool get isModeConfigured =>
      _box.get(_modeSetKey, defaultValue: false) as bool;

  bool get isCenterMode =>
      (_box.get(_appModeKey, defaultValue: 'teacher') as String) == 'center';

  String get centerName =>
      _box.get(_centerNameKey, defaultValue: 'Mon Centre') as String;

  List<Teacher> get teachers =>
      Teacher.listFromJson(_box.get(_teachersKey) as String?);

  List<String> get rooms {
    final str = _box.get(_roomsKey) as String?;
    if (str == null || str.isEmpty) return [];
    try {
      return (json.decode(str) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Frais d'inscription unique (0.0 = pas de frais)
  double get enrollmentFee =>
      (_box.get(_enrollmentFeeKey, defaultValue: 0.0) as num).toDouble();

  /// Logo du centre en base64
  String? get centerLogoBase64 => _box.get(_logoKey) as String?;

  bool get isSyncVisible =>
      _box.get(_syncVisibleKey, defaultValue: true) as bool;

  Future<void> setMode(bool isCenter) async {
    await _box.put(_appModeKey, isCenter ? 'center' : 'teacher');
    await _box.put(_modeSetKey, true);
  }

  Future<void> setSyncVisibility(bool visible) async {
    await _box.put(_syncVisibleKey, visible);
  }

  Future<void> saveCenterName(String name) async {
    await _box.put(_centerNameKey, name);
  }

  Future<void> saveTeachers(List<Teacher> teachers) async {
    await _box.put(_teachersKey, Teacher.listToJson(teachers));
  }

  Future<void> saveRooms(List<String> rooms) async {
    await _box.put(_roomsKey, json.encode(rooms));
  }

  Future<void> saveEnrollmentFee(double fee) async {
    await _box.put(_enrollmentFeeKey, fee);
  }

  Future<void> saveCenterLogo(String base64) async {
    await _box.put(_logoKey, base64);
  }

  Future<void> deleteCenterLogo() async {
    await _box.delete(_logoKey);
  }
}
