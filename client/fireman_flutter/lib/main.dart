import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/api_service.dart';
import 'viewmodels/character_viewmodel.dart';
import 'viewmodels/missions_viewmodel.dart';
import 'viewmodels/match_viewmodel.dart';
import 'viewmodels/gameplay_viewmodel.dart';
import 'views/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => CharacterViewModel(apiService)),
        ChangeNotifierProvider(create: (_) => MissionsViewModel(apiService)),
        ChangeNotifierProvider(create: (_) => MatchViewModel(apiService)),
        ChangeNotifierProvider(create: (_) => GameplayViewModel()),
      ],
      child: const FiremanApp(),
    ),
  );
}

class FiremanApp extends StatelessWidget {
  const FiremanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fireman Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OnboardingScreen(),
    );
  }
}
