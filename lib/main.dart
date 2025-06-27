import 'package:car_accessories/config/supabase_config.dart';
import 'package:car_accessories/router/app_router.dart';
import 'package:car_accessories/services/storage_setup_helprt.dart';
import 'package:car_accessories/services/supabase_auth_brdge.dart';
import 'package:car_accessories/services/supabase_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'services/error_handling_service.dart';
import 'services/backup_service.dart';
import 'services/monitoring_service.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Firebase-Supabase auth bridge
  await SupabaseAuthBridge.initialize();

  // Initialize Supabase storage buckets
  await SupabaseStorageService.initializeBuckets();

  // Run storage diagnostics
  await StorageSetupHelper.runDiagnostics();

  // Initialize services
  await _initializeServices();

  runApp(ProviderScope(child: ErrorBoundary(child: const MyApp())));
}

Future<void> _initializeServices() async {
  try {
    // Initialize error handling service
    final errorHandler = ErrorHandlingService();
    errorHandler.setupGlobalErrorHandler();

    // Initialize monitoring service
    final monitoringService = MonitoringService();
    await monitoringService.initialize();

    // Log app initialization
    await monitoringService.logEvent('app_initialized', {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    });

    // Schedule automatic backup (daily at 2 AM)
    final backupService = BackupService();
    await backupService.scheduleAutomaticBackup(
      backupType: BackupService.fullBackup,
      interval: const Duration(days: 1),
    );
  } catch (e) {
    // Log initialization error
    developer.log('Failed to initialize services: $e', name: 'Main', error: e);
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final MonitoringService _monitoringService = MonitoringService();
  final ErrorHandlingService _errorHandler = ErrorHandlingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Track app lifecycle
    _monitoringService.setAppActive(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _monitoringService.setAppActive(true);
        _monitoringService.logEvent('app_resumed', {
          'timestamp': DateTime.now().toIso8601String(),
        });
        break;
      case AppLifecycleState.paused:
        _monitoringService.setAppActive(false);
        _monitoringService.logEvent('app_paused', {
          'timestamp': DateTime.now().toIso8601String(),
        });
        break;
      case AppLifecycleState.detached:
        _monitoringService.setAppActive(false);
        _monitoringService.logEvent('app_detached', {
          'timestamp': DateTime.now().toIso8601String(),
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Car Accessories',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
