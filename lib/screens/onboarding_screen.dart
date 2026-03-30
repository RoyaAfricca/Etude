import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // 0 = choix langue, 1 = choix mode
  int _step = 0;
  String _selectedLanguage = 'fr';
  final _langService = LanguageService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _goToStepTwo() async {
    await _langService.saveLanguage(_selectedLanguage);
    _animController.reset();
    setState(() => _step = 1);
    _animController.forward();
  }

  Future<void> _selectMode(bool isCenter) async {
    await context.read<AppProvider>().saveAppMode(isCenter);
    if (!mounted) return;
    
    // Si Android, on passe à l'étape de synchro, sinon direct au Login
    if (Platform.isAndroid) {
      _animController.reset();
      setState(() => _step = 2);
      _animController.forward();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(isFirstLaunch: true)),
      );
    }
  }

  Future<void> _selectSync(bool visible) async {
    await context.read<AppProvider>().setSyncVisibility(visible);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen(isFirstLaunch: true)),
    );
  }

  AppLocalizations get _l => AppLocalizations(_selectedLanguage);

  @override
  Widget build(BuildContext context) {
    final isRtl = _selectedLanguage == 'ar';
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _step == 0 
                  ? _buildLanguageStep() 
                  : (_step == 1 ? _buildModeStep() : _buildSyncStep()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Étape 0 : Choix de la langue ──────────────────────────────────────────
  Widget _buildLanguageStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // Logo
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.primaryShadow,
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 28),
          Text(
            'Étude',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Bilingue
          Text(
            'Choisissez la langue  •  اختر اللغة',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Carte Français
          _LanguageCard(
            flag: '🇫🇷',
            label: 'Français',
            sublabel: 'French',
            selected: _selectedLanguage == 'fr',
            onTap: () => setState(() => _selectedLanguage = 'fr'),
          ),
          const SizedBox(height: 16),

          // Carte Arabe
          _LanguageCard(
            flag: '🇹🇳',
            label: 'العربية',
            sublabel: 'Arabe / Arabic',
            selected: _selectedLanguage == 'ar',
            onTap: () => setState(() => _selectedLanguage = 'ar'),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToStepTwo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: const Color(0xFF6C63FF),
              ),
              child: Text(
                _selectedLanguage == 'ar' ? 'متابعة  →' : 'Continuer  →',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Étape 1 : Choix du mode ───────────────────────────────────────────────
  Widget _buildModeStep() {
    final l = _l;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.primaryShadow,
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            l.welcome,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            l.chooseProfile,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Bouton retour langue
          Align(
            alignment: _selectedLanguage == 'ar'
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                _animController.reset();
                setState(() => _step = 0);
                _animController.forward();
              },
              icon: Icon(
                _selectedLanguage == 'ar'
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_rounded,
                size: 14,
                color: AppTheme.textMuted,
              ),
              label: Text(
                _selectedLanguage == 'ar' ? 'تغيير اللغة' : 'Changer la langue',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppTheme.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Mode Enseignant
          _ModeCard(
            icon: Icons.person_rounded,
            title: l.modeTeacher,
            description: l.modeTeacherDesc,
            gradientColors: const [Color(0xFF6C63FF), Color(0xFF8B83FF)],
            onTap: () => _selectMode(false),
          ),
          const SizedBox(height: 20),

          // Mode Centre
          _ModeCard(
            icon: Icons.corporate_fare_rounded,
            title: l.modeCenter,
            description: l.modeCenterDesc,
            gradientColors: const [Color(0xFF00BCD4), Color(0xFF0097A7)],
            onTap: () => _selectMode(true),
          ),
          const Spacer(),
          Text(
            'Étude — ${l.appName}',
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Étape 2 : Choix de Synchro (Android uniquement) ────────────────────────
  Widget _buildSyncStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00BCD4)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.primaryShadow,
            ),
            child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedLanguage == 'ar' ? 'المزامنة مع الحاسوب' : 'Liaison avec le PC',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _selectedLanguage == 'ar' 
              ? 'هل ترغب في ربط هذا التطبيق بنسخة الحاسوب لمزامنة البيانات؟' 
              : 'Souhaitez-vous lier cette application avec la version PC pour synchroniser vos données ?',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Choix OUI
          _ModeCard(
            icon: Icons.check_circle_outline_rounded,
            title: _selectedLanguage == 'ar' ? 'نعم، أرغب في الربط' : 'Oui, lier au PC',
            description: _selectedLanguage == 'ar' ? 'تفعيل خيارات المزامنة وربط الهوية' : 'Activer les options de synchronisation cloud',
            gradientColors: const [Color(0xFF6C63FF), Color(0xFF8B83FF)],
            onTap: () => _selectSync(true),
          ),
          const SizedBox(height: 20),

          // Choix NON
          _ModeCard(
            icon: Icons.cloud_off_rounded,
            title: _selectedLanguage == 'ar' ? 'لا، شكراً' : 'Non, pas maintenant',
            description: _selectedLanguage == 'ar' ? 'استخدام التطبيق بشكل مستقل تماماً' : 'Utiliser l\'application de manière autonome',
            gradientColors: const [Color(0xFF9E9E9E), Color(0xFF757575)],
            onTap: () => _selectSync(false),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
               _animController.reset();
               setState(() => _step = 1);
               _animController.forward();
            },
               child: Text(_selectedLanguage == 'ar' ? 'السابق' : 'Retour', style: TextStyle(color: AppTheme.textMuted)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Carte de langue ───────────────────────────────────────────────────────────
class _LanguageCard extends StatelessWidget {
  final String flag;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withOpacity(0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : AppTheme.cardBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppTheme.primaryShadow : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF6C63FF), size: 28),
          ],
        ),
      ),
    );
  }
}

// ── Carte de mode ─────────────────────────────────────────────────────────────
class _ModeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: _hovered
                    ? widget.gradientColors[0].withOpacity(0.7)
                    : AppTheme.cardBorder,
                width: _hovered ? 2 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.gradientColors[0].withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: widget.gradientColors),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
