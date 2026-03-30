import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/sync_service.dart';

class QrSyncScreen extends StatefulWidget {
  const QrSyncScreen({super.key});

  @override
  State<QrSyncScreen> createState() => _QrSyncScreenState();
}

class _QrSyncScreenState extends State<QrSyncScreen> {
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.syncCloud),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: provider.cloudSyncEnabled 
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: provider.cloudSyncEnabled ? AppTheme.success : AppTheme.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    provider.cloudSyncEnabled ? Icons.cloud_done : Icons.cloud_off,
                    color: provider.cloudSyncEnabled ? AppTheme.success : AppTheme.textMuted,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.cloudSyncEnabled ? l.syncActive : l.syncDisabled,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: provider.cloudSyncEnabled ? AppTheme.success : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          l.syncDesc,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: provider.cloudSyncEnabled,
                    activeColor: AppTheme.success,
                    onChanged: (val) => provider.toggleCloudSync(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (isDesktop) _buildDesktopView(provider, l) else _buildMobileView(provider, l),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopView(AppProvider provider, AppLocalizations l) {
    return Column(
      children: [
        Text(
          l.linkMobile,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          l.scanOnPhone,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: QrImageView(
            data: provider.syncKey,
            version: QrVersions.auto,
            size: 240.0,
          ),
        ),
        const SizedBox(height: 24),
        Directionality(
          textDirection: TextDirection.ltr,
          child: SelectableText(
            '${l.syncKeyLabel} : ${provider.syncKey}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppTheme.accent,
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (provider.cloudSyncEnabled) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Synchroniser tout vers le Cloud'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final success = await _showConfirmSync(context);
                if (success) {
                   // ignore: use_build_context_synchronously
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⏳ Synchronisation en cours...')));
                   await SyncService().syncAll(provider);
                   // ignore: use_build_context_synchronously
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Données envoyées !'), backgroundColor: AppTheme.success));
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.send_to_mobile_rounded),
              label: const Text('Tester le lien avec le téléphone'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.orange,
                side: const BorderSide(color: AppTheme.orange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await SyncService().pushRemoteMessage('sms', '0000', 'Test de connexion Étude PC -> Android RÉUSSI !');
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📩 Test envoyé au téléphone !'), backgroundColor: AppTheme.orange));
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<bool> _showConfirmSync(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Synchronisation complète'),
        content: const Text('Cela va envoyer TOUTES vos données locales vers le cloud. Les données sur le cloud pour ce centre seront mises à jour.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuer')),
        ],
      ),
    ) ?? false;
  }

  Widget _buildMobileView(AppProvider provider, AppLocalizations l) {
    if (_isScanning) {
      return SizedBox(
        height: 400,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _isScanning = false);
                  
                  // Action : Appliquer la clé de synchro (Mobile)
                  provider.setSyncKey(barcode.rawValue!);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Succès : Centre lié'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  Navigator.pop(context); // Retour après connexion
                }
              }
            },
          ),
        ),
      );
    }

    return Column(
      children: [
        const Icon(Icons.qr_code_scanner, size: 64, color: AppTheme.primary),
        const SizedBox(height: 24),
        Text(
          l.scanQrCode,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _isScanning = true),
            icon: const Icon(Icons.camera_alt),
            label: Text(l.scanQrCode),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
