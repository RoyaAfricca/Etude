import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';

void main() {
  runApp(const AdminActivationApp());
}

class AdminActivationApp extends StatelessWidget {
  const AdminActivationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Étude — Admin',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6c63ff),
        scaffoldBackgroundColor: const Color(0xFF0f1123),
      ),
      home: const AdminPanel(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  static const Color primaryColor = Color(0xFF6c63ff);
  static const Color accentColor = Color(0xFF00d9ff);
  static const Color surfaceColor = Color(0xFF1a1d35);
  static const Color successColor = Color(0xFF4caf50);
  static const Color dangerColor = Color(0xFFf44336);

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  List<ActivationCode> _codes = [];

  String _generateActivationCodeForDevice(String deviceId) {
    var key = utf8.encode('ETUDE_SECRET_KEY_2024');
    var bytes = utf8.encode(deviceId.trim().toUpperCase());
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    return digest.toString().substring(0, 8).toUpperCase();
  }

  String _generateResetCodeForDevice(String deviceId) {
    var key = utf8.encode('ETUDE_SECRET_KEY_2024_RESET');
    var bytes = utf8.encode(deviceId.trim().toUpperCase());
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    return digest.toString().substring(0, 8).toUpperCase();
  }

  void _generateActivationCode() {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showSnackBar('Veuillez entrer l\'ID Machine', Colors.orange);
      return;
    }

    final code = _generateActivationCodeForDevice(userId);
    _addCodeToList(userId, code, 'Activation');
  }

  void _generateResetCode() {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showSnackBar('Veuillez entrer l\'ID Machine', Colors.orange);
      return;
    }

    final code = _generateResetCodeForDevice(userId);
    _addCodeToList(userId, code, 'Reset Mot de Passe');
  }

  void _addCodeToList(String userId, String code, String type) {
    final email = _emailController.text.trim();
    final newCode = ActivationCode(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      email: email.isEmpty ? type : email,
      code: code,
      generatedAt: DateTime.now(),
      isUsed: false,
    );

    setState(() {
      _codes.insert(0, newCode);
    });

    _userIdController.clear();
    _emailController.clear();
    _showSnackBar('Code $type généré avec succès', successColor);
  }

  void _copyToClipboard(String text) {
    // Implementation would copy text to clipboard
    _showSnackBar('Code copié', accentColor);
  }

  void _deleteCode(int index) {
    setState(() {
      _codes.removeAt(index);
    });
    _showSnackBar('Code supprimé', dangerColor);
  }

  void _markAsUsed(int index) {
    setState(() {
      _codes[index].isUsed = true;
    });
    _showSnackBar('Code marqué comme utilisé', successColor);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo and title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 2),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 40,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [primaryColor, accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Étude — Admin',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Générateur de codes d\'activation',
                style: TextStyle(color: Color(0xFF9da3c2), fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Generation Card
              _buildGenerationCard(),
              const SizedBox(height: 24),

              // History Card
              if (_codes.isNotEmpty) _buildHistoryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: const Color(0xFF2a2d4a), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GÉNÉRER UN CODE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9da3c2),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _userIdController,
            label: 'ID Utilisateur',
            hint: 'Ex: USER123',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'user@example.com',
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateActivationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Générer code d\'Activation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _generateResetCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border.all(color: dangerColor, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Générer un Code RESET',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: dangerColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: const Color(0xFF2a2d4a), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HISTORIQUE (${_codes.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9da3c2),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 18),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _codes.length,
            itemBuilder: (context, index) {
              final code = _codes[index];
              return _buildCodeItem(code, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCodeItem(ActivationCode code, int index) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252845),
        border: Border.all(
          color: code.isUsed ? dangerColor : accentColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code: ${code.code}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${code.userId} | Email: ${code.email}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9da3c2),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: code.isUsed ? dangerColor : successColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code.isUsed ? 'UTILISÉ' : 'ACTIF',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Généré: ${formatter.format(code.generatedAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF5d6188),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _copyToClipboard(code.code),
                    child: const Icon(Icons.copy, size: 16, color: accentColor),
                  ),
                  if (!code.isUsed)
                    TextButton(
                      onPressed: () => _markAsUsed(index),
                      child: const Icon(Icons.check,
                          size: 16, color: successColor),
                    ),
                  TextButton(
                    onPressed: () => _deleteCode(index),
                    child:
                        const Icon(Icons.delete, size: 16, color: dangerColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9da3c2),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF5d6188)),
            filled: true,
            fillColor: const Color(0xFF252845),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2a2d4a)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2a2d4a)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

class ActivationCode {
  final String id;
  final String userId;
  final String email;
  final String code;
  final DateTime generatedAt;
  bool isUsed;

  ActivationCode({
    required this.id,
    required this.userId,
    required this.email,
    required this.code,
    required this.generatedAt,
    required this.isUsed,
  });
}
