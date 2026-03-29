import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/activation_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final ActivationService _activationService = ActivationService();

  String _deviceId = '';
  String _errorMessage = '';
  bool _loading = true;
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await _activationService.getDeviceId();
    if (mounted) {
      setState(() {
        _deviceId = id;
        _loading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _errorMessage = '';
      _activating = true;
    });

    final success = await _activationService.activateWithCode(_codeController.text);
    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Code incorrect. Vérifiez le code envoyé par le développeur.';
        _activating = false;
      });
    }
  }

  void _copyDeviceId() {
    Clipboard.setData(ClipboardData(text: _deviceId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID copié dans le presse-papier'),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/21629403406');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir WhatsApp. Utilisez le +216 29 40 34 06'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_outline_rounded, size: 48, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Activation requise',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'La période d\'essai a expiré.\nContactez le développeur en lui fournissant votre ID d\'appareil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Text(
                    Platform.isWindows
                        ? 'Prix d\'activation PC : 123 DT'
                        : 'Prix d\'activation Mobile : 62 DT',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Bloc ID appareil ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Platform.isWindows
                            ? '🖥️ ID de votre machine'
                            : '📱 ID de votre appareil',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _loading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _deviceId,
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _copyDeviceId,
                                  icon: const Icon(Icons.copy_rounded,
                                      color: AppTheme.primary, size: 20),
                                  tooltip: 'Copier l\'ID',
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lisez cet ID au développeur par téléphone ou copiez-le par SMS.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 28),

                // ── Champ code ──────────────────────────────────────────────
                TextField(
                  controller: _codeController,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  decoration: InputDecoration(
                    hintText: 'XXXXXXXX',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.4),
                      letterSpacing: 3,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.textSecondary),
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 20),

                // ── Bouton Activer ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_loading || _activating) ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: _activating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Activer l\'application',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Info D17 ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Frais d\'activation pour 24 mois',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '62 DT',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Payable par mandat',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              'assets/d17.png',
                              height: 32,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback visuel si l'image n'est pas encore dans le dossier
                                return Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'D17',
                                      style: TextStyle(
                                        color: Color(0xFF003876), 
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contact WhatsApp
                InkWell(
                  onTap: _openWhatsApp,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: const Color(0xFF25D366).withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 22),
                        SizedBox(width: 12),
                        Text(
                          'Contacter sur WhatsApp',
                          style: TextStyle(
                            color: Color(0xFF25D366),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_rounded, color: AppTheme.textSecondary, size: 14),
                    SizedBox(width: 6),
                    Text(
                      '+216 29 40 34 06',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
