import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'models/student_model.dart';
import 'models/group_model.dart';
import 'models/payment_model.dart';
import 'models/schedule_slot.dart'; // Ajouté pour ScheduleSlotAdapter
import 'providers/app_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/activation_screen.dart';
import 'services/activation_service.dart';
import 'services/center_service.dart';
import 'services/sync_service.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remplace l'écran gris par un écran d'information avec bouton de secours
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0F1123),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Étude — Chargement',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      details.exceptionAsString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.home_rounded, color: Colors.white),
                    label: const Text('Aller au tableau de bord', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      navigatorKey.currentState?.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };
  
  // 1. Initialize local services (Critical for UI and Data)
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('ar_SA', null);

  Directory dataDir;
  if (!kIsWeb && Platform.isWindows) {
    final supportDir = await getApplicationSupportDirectory();
    dataDir = Directory(p.join(supportDir.path, 'etude_data'));
    
    // Migration logic from legacy folder
    final oldDir = Directory(p.join(p.dirname(Platform.resolvedExecutable), 'etude_data'));
    if (oldDir.existsSync() && !dataDir.existsSync()) {
      try {
        debugPrint('Migrating data from ${oldDir.path} to ${dataDir.path}');
        dataDir.createSync(recursive: true);
        for (var file in oldDir.listSync()) {
          if (file is File) {
            file.copySync(p.join(dataDir.path, p.basename(file.path)));
          }
        }
      } catch (e) {
        debugPrint('Migration error: $e');
      }
    }
    
    if (!dataDir.existsSync()) {
      dataDir.createSync(recursive: true);
    }
    Hive.init(dataDir.path);
  } else {
    await Hive.initFlutter();
  }

  // Register adapters safely
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(StudentAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(GroupAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PaymentAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ScheduleSlotAdapter());

  // Open boxes safely — vérifie d'abord si déjà ouvertes (hot restart)
  if (!Hive.isBoxOpen('students')) {
    try {
      await Hive.openBox<Student>('students');
    } catch (e) {
      debugPrint('Error opening students box: $e');
      // Tenter de supprimer et recréer la box corrompue
      try {
        await Hive.deleteBoxFromDisk('students');
        await Hive.openBox<Student>('students');
        debugPrint('Students box recreated after corruption');
      } catch (e2) {
        debugPrint('Failed to recreate students box: $e2');
      }
    }
  }
  if (!Hive.isBoxOpen('groups')) {
    try {
      await Hive.openBox<Group>('groups');
    } catch (e) {
      debugPrint('Error opening groups box: $e');
      try {
        await Hive.deleteBoxFromDisk('groups');
        await Hive.openBox<Group>('groups');
        debugPrint('Groups box recreated after corruption');
      } catch (e2) {
        debugPrint('Failed to recreate groups box: $e2');
      }
    }
  }
  if (!Hive.isBoxOpen('settings')) {
    try {
      await Hive.openBox('settings');
    } catch (e) {
      debugPrint('Error opening settings box: $e');
      try {
        await Hive.deleteBoxFromDisk('settings');
        await Hive.openBox('settings');
        debugPrint('Settings box recreated after corruption');
      } catch (e2) {
        debugPrint('Failed to recreate settings box: $e2');
      }
    }
  }

  // Initialize Sync Service (Offline-First) — ne bloque pas le démarrage
  try {
    SyncService().init();
  } catch (e) {
    debugPrint('Error initializing SyncService: $e');
  }


  // Set status bar style (mobile only)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  runApp(const EtudeApp());
}

class EtudeApp extends StatefulWidget {
  const EtudeApp({super.key});

  @override
  State<EtudeApp> createState() => _EtudeAppState();
}

class _EtudeAppState extends State<EtudeApp> {
  Timer? _timer;
  late final ActivationService _activationService;
  bool _isEnforcingActivation = false;
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    // Calculé une seule fois au démarrage
    _startScreen = _safeGetStartScreen();
    _activationService = ActivationService();
    _startTrialTimer();
  }

  Widget _safeGetStartScreen() {
    try {
      // Vérifier que la box settings est bien ouverte
      if (!Hive.isBoxOpen('settings')) {
        return _buildErrorScreen('Base de données non disponible');
      }
      final centerConfig = CenterConfigService();
      final authService = AppAuthService();

      if (!centerConfig.isModeConfigured || authService.mustChangePassword) {
        return const OnboardingScreen();
      }
      if (Platform.isWindows) {
        return const LoginScreen();
      }
      return const AuthScreen();
    } catch (e) {
      debugPrint('Error determining start screen: $e');
      return const OnboardingScreen();
    }
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 64),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() {
                  _startScreen = _safeGetStartScreen();
                }),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTrialTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_activationService.isActive() && !_isEnforcingActivation) {
        _isEnforcingActivation = true;
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ActivationScreen()),
          (route) => false,
        );
      } else if (_activationService.isActive() && _isEnforcingActivation) {
        _isEnforcingActivation = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..loadData(),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Étude - Gestion des Séances',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: Locale(provider.language),
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('ar', 'SA'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _startScreen ?? const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
