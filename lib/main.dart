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
  Hive.registerAdapter(ScheduleSlotAdapter()); // Ajouté pour empêcher le plantage

  // Open boxes
  await Hive.openBox<Student>('students');
  await Hive.openBox<Group>('groups');
  await Hive.openBox('settings');


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
    // No online checks in offline mode
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
    final authService = AppAuthService();

    // Premier lancement ou configuration incomplète : 
    // Si le mode n'est pas choisi OU si le mot de passe par défaut n'a pas été changé,
    // on considère que l'onboarding n'est pas terminé.
    if (!centerConfig.isModeConfigured || authService.mustChangePassword) {
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
