import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class UpdateService {
  static const String _versionUrl = 'https://royaafricca.github.io/Etude/version.json';

  /// Vérifie si une mise à jour est disponible pour la plateforme actuelle.
  /// Retourne un Map avec les détails si une MàJ est trouvée, null sinon.
  static Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      // 1. Récupérer la version locale
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      // 2. Récupérer le fichier de version distant
      final response = await http.get(Uri.parse(_versionUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final platformKey = Platform.isAndroid ? 'android' : (Platform.isWindows ? 'windows' : null);
      
      if (platformKey == null || !data.containsKey(platformKey)) return null;

      final remoteData = data[platformKey];
      final remoteVersion = remoteData['version'] as String;
      final remoteBuild = remoteData['build_number'] as int;

      // 3. Comparer (priorité au build_number, puis à la chaîne version)
      if (remoteBuild > currentBuild || _isVersionGreater(remoteVersion, currentVersion)) {
        return {
          'version': remoteVersion,
          'url': remoteData['url'],
          'platform': platformKey,
        };
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  /// Télécharge la mise à jour en ouvrant le lien dans le navigateur par défaut.
  static Future<void> launchUpdate(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Comparaison simple de chaînes sémantiques (v1.1.0 > v1.0.0)
  static bool _isVersionGreater(String remote, String local) {
    try {
      final vRemote = remote.split('.').map(int.parse).toList();
      final vLocal = local.split('.').map(int.parse).toList();
      
      for (var i = 0; i < 3; i++) {
        final r = i < vRemote.length ? vRemote[i] : 0;
        final l = i < vLocal.length ? vLocal[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
    } catch (_) {}
    return false;
  }
}
