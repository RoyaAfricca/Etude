import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../utils/phone_validator.dart';

class NotificationService {
  static Future<bool> sendBulkSMS(List<String> phoneNumbers, String message) async {
    if (phoneNumbers.isEmpty) return false;
    
    // Nettoyage des numéros
    final cleanNumbers = phoneNumbers
        .map((p) => PhoneValidator.formatForWhatsApp(p))
        .where((p) => p.isNotEmpty)
        .toList();

    if (cleanNumbers.isEmpty) return false;

    // Sur Android, on utilise la virgule pour séparer les numéros
    // Sur iOS, on utilise le point-virgule
    final separator = Platform.isAndroid ? ',' : ';';
    final recipients = cleanNumbers.join(separator);
    
    final Uri uri = Uri.parse('sms:$recipients?body=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    } else {
      debugPrint('Could not launch SMS uri: $uri');
      return false;
    }
  }

  static Future<bool> sendBulkEmail(List<String> emails, String subject, String message) async {
    if (emails.isEmpty) return false;
    
    // On utilise BCC (Cci) pour la confidentialité
    final bcc = emails.join(',');
    final Uri uri = Uri(
      scheme: 'mailto',
      query: 'bcc=$bcc&subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    } else {
      debugPrint('Could not launch Email uri: $uri');
      return false;
    }
  }

  static Future<bool> sendWhatsApp(String phoneNumber, String message) async {
    // WhatsApp ne supporte pas nativement l'envoi groupé direct via URL vers plusieurs numéros non enregistrés
    // On ouvre donc la conversation individuelle
    final cleanNumber = PhoneValidator.formatForWhatsApp(phoneNumber);
    if (cleanNumber.isEmpty) return false;

    final Uri uri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanNumber&text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    } else {
      debugPrint('Could not launch WhatsApp uri: $uri');
      return false;
    }
  }
  
  static Future<bool> sendBulkWhatsApp(List<String> phoneNumbers, String message) async {
    if (phoneNumbers.isEmpty) return false;
    
    // Pour WhatsApp Bulk, comme il n'y a pas d'URL officielle multi-destinataire,
    // on propose d'ouvrir WhatsApp avec le texte pré-rempli pour que l'utilisateur choisisse ses contacts/groupes
    // OU on boucle sur les messages individuels (mais attention au spam/blocage UI)
    
    // Option 1: URL de partage universelle (ouvre WhatsApp et laisse choisir)
    final Uri uri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    } else {
      // Fallback vers whatsapp://
      final Uri appUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(appUri)) {
        return await launchUrl(appUri);
      }
      return false;
    }
  }
}
