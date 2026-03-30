import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'models/student_model.dart';
import 'models/group_model.dart';
import 'models/payment_model.dart';
import 'providers/app_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/activation_screen.dart';
import 'services/activation_service.dart';
import 'services/center_service.dart';
import 'services/update_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

  // Register adapters
  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(GroupAdapter());
  Hive.registerAdapter(PaymentAdapter());

  // Open boxes
  await Hive.openBox<Student>('students');
  await Hive.openBox<Group>('groups');
  await Hive.openBox('settings');

  // 2. Initialize Cloud services (Non-blocking or at least after UI/Data ready)
  try {
    if (!kIsWeb && Platform.isWindows) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCZ22Yu6uEU4y1OpwJX5_Zmqk9gLHSkRY4",
          appId: "1:354064718130:android:033808c809572b2223df2b",
          messagingSenderId: "354064718130",
          projectId: "etudeetude-sync",
          storageBucket: "etudeetude-sync.firebasestorage.app",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e. Cloud sync will be disabled.');
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
  final _activationService = ActivationService();
  bool _isEnforcingActivation = false;

  @override
  void initState() {
    super.initState();
    _startTrialTimer();
    // Lancer la vérification de mise à jour au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdate();
    });
  }

  Future<void> _checkUpdate() async {
    final updateData = await UpdateService.checkUpdate();
    if (updateData != null && mounted) {
      _showUpdateDialog(updateData);
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateData) {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.system_update_rounded, color: AppTheme.accent, size: 48),
        title: Text(
          'Mise à jour disponible',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'La version ${updateData['version']} est maintenant disponible.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Souhaitez-vous la télécharger maintenant ?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Plus tard', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              UpdateService.launchUpdate(updateData['url']);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Mettre à jour'),
          ),
        ],
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

  Widget _getStartScreen() {
    final centerConfig = CenterConfigService();
    // Premier lancement : choisir le mode
    if (!centerConfig.isModeConfigured) {
      return const OnboardingScreen();
    }
    // Windows : login + mot de passe
    if (Platform.isWindows) {
      return const LoginScreen();
    }
    // Android : biométrie / PIN du téléphone
    return const AuthScreen();
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
            home: _getStartScreen(),
          );
        },
      ),
    );
  }
}
