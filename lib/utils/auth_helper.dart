import 'package:flutter/material.dart';
import '../services/center_service.dart';
import '../theme/app_theme.dart';

class AuthHelper {
  static Future<bool> showPasswordConfirmation(BuildContext context) async {
    final passwordCtl = TextEditingController();
    final authService = AppAuthService();
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              const Text('Confirmation', 
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Veuillez saisir votre mot de passe pour confirmer cette action.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: passwordCtl,
                obscureText: true,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  errorText: errorText,
                  prefixIcon: const Icon(Icons.password, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                ),
                onSubmitted: (_) {
                  if (authService.verifyPassword(passwordCtl.text)) {
                    Navigator.pop(ctx, true);
                  } else {
                    setState(() => errorText = 'Mot de passe incorrect');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (authService.verifyPassword(passwordCtl.text)) {
                  Navigator.pop(ctx, true);
                } else {
                  setState(() => errorText = 'Mot de passe incorrect');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Vérifier'),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }
}
