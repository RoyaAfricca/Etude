import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Removed unused imports: provider and app_provider
import '../models/student_model.dart';
import '../services/notification_service.dart';
// import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/phone_validator.dart';

enum NotificationMethod { sms, email, whatsapp }

class GroupNotifyDialog extends StatefulWidget {
  final List<Student> students;
  final String groupName;

  const GroupNotifyDialog({
    super.key,
    required this.students,
    required this.groupName,
  });

  static void show(BuildContext context, List<Student> students, String groupName) {
    showDialog(
      context: context,
      builder: (ctx) => GroupNotifyDialog(students: students, groupName: groupName),
    );
  }

  @override
  State<GroupNotifyDialog> createState() => _GroupNotifyDialogState();
}

class _GroupNotifyDialogState extends State<GroupNotifyDialog> {
  final _messageController = TextEditingController();
  NotificationMethod _selectedMethod = NotificationMethod.email;
  bool _isSending = false;

  final List<Map<String, String>> _templates = [
    {
      'title': 'Séance annulée',
      'body': 'Bonjour, la séance d\'aujourd\'hui pour le groupe {group} est annulée. Merci de votre compréhension.',
    },
    {
      'title': 'Nouvel horaire',
      'body': 'Bonjour, l\'horaire du groupe {group} a été modifié. Le nouveau créneau est : {time}.',
    },
    {
      'title': 'Rappel paiement',
      'body': 'Bonjour, petit rappel pour le règlement de la séance du groupe {group}. Merci.',
    },
    {
      'title': 'Information',
      'body': 'Bonjour, une information importante concernant le groupe {group} : ',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      _selectedMethod = NotificationMethod.email;
    } else {
      _selectedMethod = NotificationMethod.whatsapp;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _applyTemplate(String templateBody) {
    String processed = templateBody.replaceAll('{group}', widget.groupName);
    setState(() {
      _messageController.text = processed;
    });
  }

  List<String> _getRecipients() {
    switch (_selectedMethod) {
      case NotificationMethod.email:
        return widget.students
            .map((s) => s.email)
            .where((e) => e.isNotEmpty && e.contains('@'))
            .toList();
      case NotificationMethod.sms:
      case NotificationMethod.whatsapp:
        final allPhones = <String>[];
        for (final s in widget.students) {
          if (s.phone.isNotEmpty) {
            allPhones.addAll(PhoneValidator.cleanAndSplit(s.phone));
          }
        }
        return allPhones;
    }
  }

  Future<void> _handleSend() async {
    final recipients = _getRecipients();
    final message = _messageController.text.trim();

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun destinataire valide avec cette méthode.')),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un message.')),
      );
      return;
    }

    setState(() => _isSending = true);

    bool success = false;

    try {
      switch (_selectedMethod) {
        case NotificationMethod.email:
          success = await NotificationService.sendBulkEmail(
            recipients,
            'Information Étude - ${widget.groupName}',
            message,
          );
          break;
        case NotificationMethod.sms:
          success = await NotificationService.sendBulkSMS(recipients, message);
          break;
        case NotificationMethod.whatsapp:
          if (recipients.length == 1) {
            success = await NotificationService.sendWhatsApp(recipients.first, message);
          } else {
            success = await NotificationService.sendBulkWhatsApp(recipients, message);
          }
          break;
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Application de messagerie ouverte !'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Échec de l\'ouverture de l\'application de messagerie.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipientsCount = _getRecipients().length;
    final canUseSms = !Platform.isWindows;
    final canUseWhatsapp = !Platform.isWindows;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informer le groupe',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          Text(
            '${widget.groupName} (${widget.students.length} élèves)',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Méthode d\'envoi',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                   _buildMethodOption(
                    method: NotificationMethod.email,
                    icon: Icons.email_outlined,
                    label: 'Email',
                    isSelected: _selectedMethod == NotificationMethod.email,
                  ),
                  if (canUseSms) ...[
                    const SizedBox(width: 8),
                    _buildMethodOption(
                      method: NotificationMethod.sms,
                      icon: Icons.sms_outlined,
                      label: 'SMS',
                      isSelected: _selectedMethod == NotificationMethod.sms,
                    ),
                  ],
                  if (canUseWhatsapp) ...[
                    const SizedBox(width: 8),
                    _buildMethodOption(
                      method: NotificationMethod.whatsapp,
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp',
                      isSelected: _selectedMethod == NotificationMethod.whatsapp,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Modèles rapides',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _templates.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(t['title']!),
                      onPressed: () => _applyTemplate(t['body']!),
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                maxLines: 5,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Saisissez votre message ici...',
                  fillColor: AppTheme.surfaceLight,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: recipientsCount > 0 ? AppTheme.primary.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      recipientsCount > 0 ? Icons.info_outline : Icons.warning_amber_rounded,
                      size: 16,
                      color: recipientsCount > 0 ? AppTheme.primary : AppTheme.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recipientsCount > 0 
                          ? '$recipientsCount élèves recevront ce message.'
                          : 'Aucun élève n\'a de coordonnée valide pour cette méthode.',
                        style: TextStyle(
                          fontSize: 12, 
                          color: recipientsCount > 0 ? AppTheme.primary : AppTheme.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _handleSend,
          icon: _isSending 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded, size: 18),
          label: Text(_isSending ? 'Ouverture...' : 'Envoyer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedMethod == NotificationMethod.email ? AppTheme.primary : AppTheme.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodOption({
    required NotificationMethod method,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.cardBorder, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}
