import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'main_menu_screen.dart';
import 'onboarding_screen.dart';

/// Resolves the first route after a short branded game launch screen.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_openFirstScreen());
  }

  Future<void> _openFirstScreen() async {
    await context.read<ApiService>().restoreSession();
    final completed = await UserProfile.hasCompletedOnboarding();
    final profile = completed ? await UserProfile.load() : null;
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final destination = completed
        ? MainMenuScreen(profile: profile!)
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .98, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080D15),
        body: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = (constraints.maxHeight * .30)
                  .clamp(68.0, 112.0)
                  .toDouble();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size + 28,
                    height: size + 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6A3D).withValues(alpha: .12),
                      border: Border.all(
                        color: const Color(0xFFFF6A3D).withValues(alpha: .45),
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.local_fire_department_rounded,
                          size: size * .72, color: const Color(0xFFFF764B)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('FIREMAN',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      )),
                  const SizedBox(height: 5),
                  const Text('ARENA BAŞLATILIYOR',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Colors.white54)),
                  const SizedBox(height: 22),
                  const SizedBox(
                    width: 110,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: Color(0xFFFF764B),
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}
