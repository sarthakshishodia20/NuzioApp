import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/language_screen.dart';
import 'features/onboarding/profession_screen.dart';
import 'features/onboarding/niches_screen.dart';
import 'features/onboarding/voice_time_screen.dart';
import 'features/brief/home_screen.dart';
import 'features/settings/plan_billing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const NuzioApp(),
    ),
  );
}

class NuzioApp extends StatelessWidget {
  const NuzioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuzio AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/language': (_) => const LanguageScreen(),
        '/login': (_) => const LoginScreen(),
        '/profession': (_) => const ProfessionScreen(),
        '/niches': (_) => const NichesScreen(),
        '/voice_time': (_) => const VoiceTimeScreen(),
        '/home': (_) => const HomeScreen(),
        '/plan_billing': (_) => const PlanBillingScreen(),
      },
    );
  }
}
