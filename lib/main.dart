import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upgrader/upgrader.dart';
import 'package:wouritv/config/api_response_box.dart';
import 'package:wouritv/config/app_theme.dart';
import 'package:wouritv/config/global_translation.dart';
import 'package:wouritv/config/navigation_service.dart';
import 'package:wouritv/config/setting.dart';
import 'package:wouritv/config/sizeconfig.dart';
import 'package:wouritv/firebase_options.dart';
import 'package:wouritv/l10n/app_localizations.dart';
import 'package:wouritv/presentation/screen/auth/auth_gate.dart';
import 'package:wouritv/presentation/screen/home/dashboard_screen.dart';
import 'dart:developer' as developer;
import 'dart:async';

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // initialize GetIt (service locator)
    setupLocator();

    // initialize firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Activer la collecte automatique des crashs
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    
    // Capturer les erreurs Flutter fatales
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      developer.log(
        'Flutter Error: ${errorDetails.exception}',
        name: 'Crashlytics',
        error: errorDetails.exception,
        stackTrace: errorDetails.stack,
      );
    };
    
    // Capturer les erreurs asynchrones non gérées
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      developer.log(
        'Async Error: $error',
        name: 'Crashlytics',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    // initialize upgrader
    await Upgrader.clearSavedSettings();

    // initialize hive
    final appDocumentDirectory = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDirectory.path);
    Hive.registerAdapter(ApiResponseBoxAdapter());

    // lock orientation for small devices
    final firstView = WidgetsBinding.instance.platformDispatcher.views.first;
    final logicalShortestSide = firstView.physicalSize.shortestSide / firstView.devicePixelRatio;
    if(logicalShortestSide <= 550) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]); 
    }

    // initialize supabase;
    final supabaseUrl = const String.fromEnvironment("SUPABASE_URL");
    final supabaseKey = const String.fromEnvironment("SUPABASE_KEY");
    
    developer.log('Supabase URL: ${supabaseUrl.isEmpty ? "VIDE" : supabaseUrl}', name: 'Main');
    developer.log('Supabase Key: ${supabaseKey.isEmpty ? "VIDE" : "Définie"}', name: 'Main');
    
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      developer.log('ERREUR: Les variables d\'environnement Supabase ne sont pas définies!', name: 'Main');
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 10,
      ),
    );

    runApp(ProviderScope(child: MyApp()));
  }, (error, stack) {
    // Capturer les erreurs dans la zone racine
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    developer.log(
      'Zone Error: $error',
      name: 'Crashlytics',
      error: error,
      stackTrace: stack,
    );
  });
}

class MyApp extends StatefulHookConsumerWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends ConsumerState<MyApp> {

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState()  {
    super.initState();
  }    

  @override
  Widget build(BuildContext context) {

    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            SizeConfig().init(constraints, orientation);
            return OverlaySupport(
              child: MaterialApp(
                title: Setting.appName,
                debugShowCheckedModeBanner: false,
                // Configuration du thème
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.system, // Suit automatiquement les paramètres du système
                navigatorKey: locator<NavigationService>().navigatorKey,
                navigatorObservers: <NavigatorObserver>[observer],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: allTranslations.supportedLocales(),
                home: AuthGate(),
                routes: {
                  '/home': (context) => const DashboardScreen(),
                },
              ),
            );
          },
        );
      },
    );
  }
}
