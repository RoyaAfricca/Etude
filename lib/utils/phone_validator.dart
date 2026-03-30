import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PhoneValidator {
  /// Nettoie la chaîne pour ne garder que chiffres, espaces et virgules.
  /// Puis sépare en liste de numéros.
  static List<String> cleanAndSplit(String input) {
    if (input.isEmpty) return [];
    // Remplacer les caractères non autorisés par des virgules (sauf chiffres)
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), ',');
    return cleaned
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Vérifie si TOUS les numéros de la liste font 8 chiffres.
  static bool isValidTunisianList(List<String> numbers) {
    if (numbers.isEmpty) return false;
    for (var n in numbers) {
      if (n.length != 8 || !RegExp(r'^[0-9]{8}$').hasMatch(n)) {
        return false;
      }
    }
    return true;
  }

  /// Formate un numéro pour WhatsApp avec +216 si 8 chiffres.
  static String formatForWhatsApp(String number) {
    final clean = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 8) {
      return '216$clean';
    }
    return clean;
  }

  /// Affiche un sélecteur si plusieurs numéros sont présents,
  /// sinon exécute l'action directement.
  static void showPhoneSelector(
    BuildContext context, {
    required String phoneString,
    required String title,
    required Function(String) onSelected,
  }) {
    final list = cleanAndSplit(phoneString);
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun numéro de téléphone valide')),
      );
      return;
    }

    if (list.length == 1) {
      onSelected(list.first);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ...list.map((phone) => ListTile(
                  leading: const Icon(Icons.phone_iphone, color: AppTheme.primary),
                  title: Text(phone, style: const TextStyle(color: AppTheme.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelected(phone);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
