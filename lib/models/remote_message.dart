import 'package:cloud_firestore/cloud_firestore.dart';

class RemoteMessage {
  final String id;
  final String type; // 'sms' or 'whatsapp'
  final String recipient;
  final String body;
  final DateTime timestamp;

  RemoteMessage({
    required this.id,
    required this.type,
    required this.recipient,
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'recipient': recipient,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RemoteMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RemoteMessage(
      id: doc.id,
      type: data['type'] ?? 'sms',
      recipient: data['recipient'] ?? '',
      body: data['body'] ?? '',
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
