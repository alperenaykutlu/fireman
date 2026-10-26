import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/api_service.dart';
import 'viewmodels/character_viewmodel.dart';
import 'viewmodels/missions_viewmodel.dart';
import 'viewmodels/match_viewmodel.dart';
import 'viewmodels/gameplay_viewmodel.dart';
import 'services/game_notification_service.dart';
import 'views/startup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
  unawaited(GameNotificationService.instance.initialize().catchError((_) {}));
}

class FiremanApp extends StatelessWidget {
  const FiremanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fireman Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const StartupScreen(),
    );
  }
}
