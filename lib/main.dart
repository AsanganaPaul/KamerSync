import 'package:flutter/foundation.dart'; // Added for kReleaseMode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_preview/device_preview.dart'; // Added DevicePreview import

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization skipped (no config): $e');
  }

  runApp(
    // 1. Wrap the entire application inside DevicePreview
    DevicePreview(
      enabled: !kReleaseMode, // Disables preview completely in production releases
      builder: (context) => const ProviderScope(
        child: KamerSyncApp(),
      ),
    ),
  );
}

class KamerSyncApp extends ConsumerWidget {
  const KamerSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'KamerSync – Land Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      
      // 2. Add these properties to delegate locale and text direction tracking to DevicePreview
      locale: DevicePreview.locale(context),
      
      // 3. Chain DevicePreview's builder together with your existing MediaQuery configuration
      builder: (context, child) {
        // First, pass the widget through DevicePreview's custom app builder
        final previewChild = DevicePreview.appBuilder(context, child);
        
        // Then, apply your custom text scaling logic on top of it
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: previewChild,
        );
      },
    );
  }
}