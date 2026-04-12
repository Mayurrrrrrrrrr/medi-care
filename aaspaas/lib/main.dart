import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/patient_provider.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';

import 'shared/providers/family_provider.dart';

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
      ],
      child: const AaspaasApp(),
    ),
  );
}

class AaspaasApp extends StatelessWidget {
  const AaspaasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aaspaas',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Bootloader(),
    );
  }
}

// Simple Bootloader to decide where to route user based on auth state
class Bootloader extends StatelessWidget {
  const Bootloader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!auth.isAuthenticated) return const LoginScreen();
        return const HomeScreen();
      },
    );
  }
}
