import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ActivationService {
  static const String _boxName = 'settings';
  static const String _isActivatedKey = 'is_activated';
  static const String _firstLaunchTimeKey = 'first_launch_time';
  static const String _deviceIdKey = 'device_id';
  static const String _activationTimeKey = 'activation_time';

  // Clé secrète HMAC — gardez-la confidentielle
  static const String _secretKey = 'ETUDE_SECRET_KEY_2024';

  // Durée d'activation (24 mois = 730 jours) et d'essai en jours
  static const int _activationDurationDays = 730;
  static const int _trialDurationDays = 32;

  final Box _box;

  ActivationService() : _box = Hive.box(_boxName);

  // ── Device ID ──────────────────────────────────────────────────────────────

  /// Récupère l'identifiant de l'appareil (Android ID ou adresse MAC sur Windows).
  Future<String> getDeviceId() async {
    // Si déjà en cache, on retourne directement
    final cached = _box.get(_deviceIdKey);
    if (cached != null && (cached as String).isNotEmpty) return cached;

    try {
      String id;
      if (Platform.isWindows) {
        // Récupérer l'adresse MAC via la commande getmac
        final result = await Process.run('getmac', ['/FO', 'CSV', '/NH']);
        final output = result.stdout.toString().trim();
        // La première ligne contient l'adresse MAC entre guillemets
        final match = RegExp(r'"([0-9A-Fa-f\-]{17})"').firstMatch(output);
        id = match != null ? match.group(1)! : 'UNKNOWN_MAC';
      } else {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id; // ANDROID_ID
      }
      await _box.put(_deviceIdKey, id);
      return id;
    } catch (_) {
      return 'UNKNOWN_DEVICE';
    }
  }

  // ── Trial ──────────────────────────────────────────────────────────────────

  /// Vérifie si l'app est toujours dans la période d'essai ou activée.
  bool isActive() {
    final isActivated = _box.get(_isActivatedKey, defaultValue: false) as bool;
    if (isActivated) {
      final activationTimestamp = _box.get(_activationTimeKey) as int?;
      if (activationTimestamp != null) {
        final activationTime = DateTime.fromMillisecondsSinceEpoch(activationTimestamp);
        final elapsed = DateTime.now().difference(activationTime);
        if (elapsed.inDays >= _activationDurationDays) {
          return false; // L'activation a expiré après 24 mois
        }
      } else {
        // Migration des anciens utilisateurs activés
        _box.put(_activationTimeKey, DateTime.now().millisecondsSinceEpoch);
      }
      return true;
    }

    final firstLaunchTimestamp = _box.get(_firstLaunchTimeKey) as int?;
    if (firstLaunchTimestamp == null) {
      _box.put(_firstLaunchTimeKey, DateTime.now().millisecondsSinceEpoch);
      return true;
    }

    final firstLaunchTime =
        DateTime.fromMillisecondsSinceEpoch(firstLaunchTimestamp);
    final elapsed = DateTime.now().difference(firstLaunchTime);
    return elapsed.inDays < _trialDurationDays;
  }

  /// Jours d'essai restants. -1 si activé à vie, 0 si expiré.
  int getRemainingTrialDays() {
    final isActivated = _box.get(_isActivatedKey, defaultValue: false) as bool;
    if (isActivated) return -1;

    final firstLaunchTimestamp = _box.get(_firstLaunchTimeKey) as int?;
    if (firstLaunchTimestamp == null) return _trialDurationDays;

    final firstLaunchTime =
        DateTime.fromMillisecondsSinceEpoch(firstLaunchTimestamp);
    final elapsed = DateTime.now().difference(firstLaunchTime).inDays;
    final remaining = _trialDurationDays - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  // ── Activation HMAC ────────────────────────────────────────────────────────

  /// Génère le code d'activation attendu pour un ID donné (usage interne).
  static String _generateExpectedCode(String deviceId) {
    final key = utf8.encode(_secretKey);
    final data = utf8.encode(deviceId.trim().toUpperCase());
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);
    return digest.toString().substring(0, 8).toUpperCase();
  }

  /// Tente d'activer l'app avec le code saisi par l'utilisateur.
  /// Retourne true si le code correspond au device ID courant.
  Future<bool> activateWithCode(String code) async {
    final deviceId = await getDeviceId();
    final expected = _generateExpectedCode(deviceId);
    if (code.trim().toUpperCase() == expected) {
      await _box.put(_isActivatedKey, true);
      await _box.put(_activationTimeKey, DateTime.now().millisecondsSinceEpoch);
      return true;
    }
    return false;
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  /// Génère le code de réinitialisation attendu pour un ID donné.
  static String _generateExpectedResetCode(String deviceId) {
    // On ajoute "_RESET" à la clé secrète pour générer un code différent de l'activation
    final key = utf8.encode(_secretKey + "_RESET");
    final data = utf8.encode(deviceId.trim().toUpperCase());
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);
    return digest.toString().substring(0, 8).toUpperCase();
  }

  /// Vérifie si le code de réinitialisation saisi est valide.
  Future<bool> verifyResetCode(String code) async {
    final deviceId = await getDeviceId();
    final expected = _generateExpectedResetCode(deviceId);
    return code.trim().toUpperCase() == expected;
  }
}
