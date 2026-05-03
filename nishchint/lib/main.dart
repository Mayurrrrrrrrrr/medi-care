import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/splash_screen.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/patient_provider.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';

import 'shared/providers/family_provider.dart';
import 'shared/providers/settings_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await AlarmService.initialize();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("Service init error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkExistingAuth()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const NishchintApp(),
    ),
  );
}

class NishchintApp extends StatelessWidget {
  const NishchintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Nishchint',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: settings.largeTextMode ? AppTheme.largeTextTheme : AppTheme.lightTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}

// Simple Bootloader to decide where to route user based on auth state
class Bootloader extends StatefulWidget {
  const Bootloader({super.key});

  @override
  State<Bootloader> createState() => _BootloaderState();
}

class _BootloaderState extends State<Bootloader> {
  bool _alarmsInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!auth.isAuthenticated) return const LoginScreen();

        if (!_alarmsInitialized) {
          _alarmsInitialized = true;
          AlarmService.rescheduleOnAppOpen();
          AndroidAlarmManager.periodic(
            const Duration(hours: 12),
            999999,
            AlarmService.rescheduleOnAppOpen,
            wakeup: true,
            exact: true,
            rescheduleOnReboot: true,
          );
        }

        return const HomeScreen();
      },
    );
  }
}
