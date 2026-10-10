import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/user_profile.dart';
import 'main_menu_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final List<String> _storyLines = [
    "Alevler şehri sardı...\nLabirentin derinliklerinde yangın büyüyor.",
    "Her itfaiyeci başta yalnızca tek bir bomba taşıyabilir.",
    "Kırmızı varilleri patlatarak gizlenmiş güçleri ortaya çıkar!",
    "⚡ Şimşek şiddeti artırır, 👟 Ayakkabı hız kazandırır,\n💣 Bomba kapasiteni genişletir, 🔧 Tamir canını yeniler.",
    "Arenanın kontrolünü ele geçir!\nAteşle oynamaya hazır mısın?"
  ];

  int _currentLineIndex = 0;
  bool _showUsernameInput = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _usernameController = TextEditingController();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _startSequence();
  }

  Future<void> _loadProfile() async {
    _userProfile = await UserProfile.load();
    if (_userProfile!.username.isNotEmpty) {
      _usernameController.text = _userProfile!.username;
    }

    final hasCompleted = await UserProfile.hasCompletedOnboarding();
    if (hasCompleted && mounted && _userProfile!.username.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainMenuScreen(profile: _userProfile!),
        ),
      );
    }
  }

  Future<void> _startSequence() async {
    // İlk metni karartmadan aç
    await _animController.forward();
    await Future.delayed(const Duration(milliseconds: 1800));

    // Sırayla metinleri karartarak değiştir
    while (mounted && _currentLineIndex < _storyLines.length - 1) {
      // 1. Karararak git (Fade Out)
      await _animController.reverse();
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      setState(() {
        _currentLineIndex++;
      });

      // 2. Yeni metin belirsin (Fade In)
      await _animController.forward();
      await Future.delayed(const Duration(milliseconds: 1800));
    }

    // Metinler bitti, kullanıcı adı belirleme alanını aç
    if (mounted) {
      await _animController.reverse();
      setState(() {
        _showUsernameInput = true;
      });
      await _animController.forward();
    }
  }

  void _proceedToMainMenu() async {
    final name = _usernameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir itfaiyeci adı belirleyin!')),
      );
      return;
    }

    if (_userProfile != null) {
      _userProfile!.username = name;
      await _userProfile!.save();
      await UserProfile.setOnboardingCompleted();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => MainMenuScreen(profile: _userProfile!),
        transitionsBuilder: (context, animation, secAnim, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka plan atmosfer ışığı
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppConstants.fireRed.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // İçerik
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: !_showUsernameInput
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 24),
                          Text(
                            _storyLines[_currentLineIndex],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.6,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Geç Butonu
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showUsernameInput = true;
                              });
                              _animController.forward(from: 0.0);
                            },
                            child: const Text('Geç >>', style: TextStyle(color: Colors.white38)),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🧑‍🚒', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 16),
                          const Text(
                            'OYUNCU ADINI BELİRLE',
                            style: TextStyle(
                              color: AppConstants.fireOrange,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Arenada seni bu isimle tanıyacaklar.',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: AppConstants.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConstants.borderCard),
                            ),
                            child: TextField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: 'Örn: Kaptan_Alev',
                                hintStyle: TextStyle(color: Colors.white30),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.fireOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _proceedToMainMenu,
                            child: const Text('ARENAYA GİRİŞ YAP', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
