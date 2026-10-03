import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';

class DataManagementDialog extends StatelessWidget {
  const DataManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DataManagementDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cloud_sync_rounded,
                    color: AppTheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Données & Sauvegardes',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Exportation, importation et sauvegardes',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section: Excel
            _buildSectionHeader('Gestion Excel (Fichiers .xlsx)', Icons.table_chart_rounded),
            const SizedBox(height: 10),

            // Exporter Excel
            _buildActionTile(
              context: context,
              icon: Icons.file_download_outlined,
              iconColor: AppTheme.success,
              title: 'Exporter toutes les données (Excel)',
              subtitle: 'Élèves, numéros parents, groupes, paiements & présences',
              onTap: () async {
                final provider = context.read<AppProvider>();
                Navigator.pop(context);
                final path = await ImportService.exportToExcel(provider);
                if (path != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Données exportées avec succès vers Excel !'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),

            // Importer Excel
            _buildActionTile(
              context: context,
              icon: Icons.file_upload_outlined,
              iconColor: AppTheme.primary,
              title: 'Importer depuis Excel',
              subtitle: 'Ajouter élèves (avec n° parent) et groupes en masse',
              onTap: () async {
                final provider = context.read<AppProvider>();
                Navigator.pop(context);
                final stats = await ImportService.importFromExcel(provider);
                if (context.mounted) {
                  if (stats.values.every((v) => v == 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aucune donnée importée (fichier vide ou données déjà existantes)'),
                        backgroundColor: AppTheme.warning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: const Text('Importation terminée', style: TextStyle(color: AppTheme.textPrimary)),
                        content: Text(
                          'Importation réussie :\n'
                          '• ${stats['students']} élève(s)\n'
                          '• ${stats['groups']} groupe(s)\n'
                          '• ${stats['teachers']} enseignant(s)',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),

            // Modèle Excel
            _buildActionTile(
              context: context,
              icon: Icons.description_outlined,
              iconColor: AppTheme.accent,
              title: 'Télécharger le modèle Excel',
              subtitle: 'Modèle vierge avec toutes les colonnes requises (incluant N° Parent)',
              onTap: () async {
                Navigator.pop(context);
                final ok = await ImportService.generateTemplate();
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Modèle Excel enregistré avec succès !'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // Section: Sauvegarde complète
            _buildSectionHeader('Sauvegarde & Restauration Intégrale', Icons.shield_outlined),
            const SizedBox(height: 10),

            // Sauvegarde JSON
            _buildActionTile(
              context: context,
              icon: Icons.save_alt_rounded,
              iconColor: AppTheme.orange,
              title: 'Créer une sauvegarde complète (JSON)',
              subtitle: 'Sauvegarde totale de la base de données',
              onTap: () async {
                final provider = context.read<AppProvider>();
                Navigator.pop(context);
                final path = await ImportService.exportBackupJson(provider);
                if (path != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Sauvegarde intégrale enregistrée avec succès !'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),

            // Restauration JSON
            _buildActionTile(
              context: context,
              icon: Icons.settings_backup_restore_rounded,
              iconColor: AppTheme.danger,
              title: 'Restaurer une sauvegarde (JSON)',
              subtitle: 'Restaurer vos données depuis un fichier précédent',
              onTap: () async {
                final provider = context.read<AppProvider>();
                final navCtx = context;
                Navigator.pop(context);
                try {
                  final stats = await ImportService.importBackupJson(navCtx, provider);
                  if (stats != null && navCtx.mounted) {
                    showDialog(
                      context: navCtx,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: const Text('Restauration terminée',
                            style: TextStyle(color: AppTheme.textPrimary)),
                        content: Text(
                          'Données restaurées avec succès :\n'
                          '• ${stats['students']} élève(s)\n'
                          '• ${stats['groups']} groupe(s)',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (navCtx.mounted) {
                    ScaffoldMessenger.of(navCtx).showSnackBar(
                      SnackBar(
                        content: Text('Erreur de restauration : $e'),
                        backgroundColor: AppTheme.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
