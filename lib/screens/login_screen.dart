import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/center_service.dart';
import '../services/activation_service.dart';
import '../theme/app_theme.dart';
import 'activation_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isFirstLaunch;
  const LoginScreen({super.key, this.isFirstLaunch = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AppAuthService();
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _newLoginCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _changeFormKey = GlobalKey<FormState>();

  bool _obscure = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;
  bool _showChangePassword = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // Si premier lancement OU mot de passe non encore changé → forcer changement
    if (widget.isFirstLaunch || _authService.mustChangePassword) {
      _showChangePassword = true;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _loginCtrl.dispose();
    _passCtrl.dispose();
    _newLoginCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final ok = _authService.verifyCredentials(_loginCtrl.text, _passCtrl.text);
    if (!mounted) return;

    if (ok) {
      // Vérification activation
      final activationService = ActivationService();
      if (!activationService.isActive()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ActivationScreen()),
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Login ou mot de passe incorrect.';
      });
    }
  }

  Future<void> _saveNewCredentials() async {
    if (!_changeFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await _authService.changeCredentials(
        _newLoginCtrl.text, _newPassCtrl.text);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _showChangePassword = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Identifiants mis à jour ! Connectez-vous.'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppTheme.primaryShadow,
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Étude',
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _showChangePassword
                          ? 'Définissez vos identifiants de connexion'
                          : 'Connectez-vous pour continuer',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    if (_showChangePassword)
                      _buildChangePasswordForm()
                    else
                      _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Login'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loginCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Votre login',
                prefixIcon:
                    Icon(Icons.person_outline, color: AppTheme.textMuted),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Login requis' : null,
            ),
            const SizedBox(height: 20),
            _label('Mot de passe'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon:
                    const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Mot de passe requis' : null,
              onFieldSubmitted: (_) => _login(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.danger, size: 18),
                    const SizedBox(width: 8),
                    Text(_error!,
                        style: const TextStyle(
                            color: AppTheme.danger, fontSize: 13)),
                  ],
                ),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showResetPasswordDialog,
                child: const Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text('Se connecter',
                        style:
                            GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
        boxShadow: AppTheme.primaryShadow,
      ),
      child: Form(
        key: _changeFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_reset, color: AppTheme.warning, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Définissez vos identifiants',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pour votre sécurité, changez le login et mot de passe par défaut (Admin / admin).',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 22),
            _label('Nouveau Login'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newLoginCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Votre nouveau login',
                prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Login requis' : null,
            ),
            const SizedBox(height: 16),
            _label('Nouveau Mot de passe'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newPassCtrl,
              obscureText: _obscureNew,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Min. 6 caractères',
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textMuted),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Mot de passe requis';
                if (v.length < 6) return 'Minimum 6 caractères';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _label('Confirmer le mot de passe'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Répétez le mot de passe',
                prefixIcon: const Icon(Icons.check_circle_outline, color: AppTheme.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textMuted),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v != _newPassCtrl.text) return 'Les mots de passe ne correspondent pas';
                return null;
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveNewCredentials,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text('Enregistrer et continuer',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      );

  Future<void> _showResetPasswordDialog() async {
    final activationService = ActivationService();
    final deviceId = await activationService.getDeviceId();
    final ctrl = TextEditingController();
    bool isResetting = false;
    String? resetError;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Réinitialiser le mot de passe', style: TextStyle(color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Veuillez communiquer cet ID au développeur pour obtenir un code de réinitialisation :',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: SelectableText(
                      deviceId, 
                      style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: ctrl,
                    style: const TextStyle(color: AppTheme.textPrimary, letterSpacing: 2, fontWeight: FontWeight.bold),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'CODE DE RÉINITIALISATION',
                      hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5), letterSpacing: 0, fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      errorText: resetError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isResetting ? null : () async {
                    if (ctrl.text.isEmpty) return;
                    setDialogState(() {
                      isResetting = true;
                      resetError = null;
                    });
                    
                    final ok = await _authService.resetCredentials(ctrl.text);
                    if (!mounted) return;
                    
                    if (ok) {
                      Navigator.pop(context); // fermer dialog
                      setState(() {
                         _showChangePassword = true;
                         _loginCtrl.clear();
                         _passCtrl.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Réinitialisation réussie. Veuillez définir un nouveau mot de passe.'), 
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    } else {
                      setDialogState(() {
                        isResetting = false;
                        resetError = 'Code de réinitialisation incorrect';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isResetting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Réinitialiser'),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
