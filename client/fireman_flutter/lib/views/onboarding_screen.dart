import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/character/animated_firefighter_widget.dart';
import '../core/character/character_state.dart';
import '../core/particles/ambient_ember_overlay.dart';
import '../core/responsive/responsive_layout.dart';
import '../models/user_profile.dart';
import 'main_menu_screen.dart';
import '../shared/widgets/power_up_card.dart';
import 'city_skyline_painter.dart';
import 'username_entry_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedHeroName = "Kaptan Ateş";
  CharacterAnimState _heroAnimState = CharacterAnimState.idle;
  final TextEditingController _customNameCtrl = TextEditingController();
  bool _isCustomNameMode = false;

  final List<String> _presetNames = [
    "Kaptan Ateş",
    "Alev Avcısı",
    "Kurtarma 1",
    "Demir Kask",
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _customNameCtrl.dispose();
    super.dispose();
  }

  void _onHeroTapped() {
    HapticFeedback.lightImpact();
    setState(() {
      _heroAnimState = _heroAnimState == CharacterAnimState.action
          ? CharacterAnimState.celebrate
          : CharacterAnimState.action;
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _heroAnimState = CharacterAnimState.idle);
      }
    });
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.heavyImpact();
    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const UsernameEntryScreen(),
      ),
    );
    if (username == null || username.trim().isEmpty) return;

    final profile = await UserProfile.load();
    profile.username = username;
    await profile.save();
    await UserProfile.setOnboardingCompleted();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainMenuScreen(profile: profile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final compactLandscape = screenSize.height < 520 || screenSize.width < 640;
    return Scaffold(
      // The separate username route owns the keyboard resize; keep this route
      // laid out at full height underneath it to avoid a 50px Flex constraint.
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF090D14),
      body: Stack(
        children: [
          // 1. KATMAN: Parallax Gece Gökyüzü ve Şehir Silueti
          Positioned.fill(
            child: CustomPaint(
              painter: CinematicCitySkylinePainter(
                pageOffset: _currentPage.toDouble(),
              ),
            ),
          ),

          // 2. KATMAN: Yükselen Gerçek Zamanlı Kıvılcım Parçacıkları
          const Positioned.fill(child: AmbientEmberOverlay(maxParticles: 35)),

          // 3. KATMAN: Responsive İçerik ve PageView
          ResponsiveLayout(
            customPadding: EdgeInsets.symmetric(
              horizontal: screenSize.width < 720 ? 8 : 20,
              vertical: compactLandscape ? 4 : 12,
            ),
            child: Column(
              children: [
                // Üst Bar: Başlık & Hızlı Atla Butonu
                Padding(
                  padding: EdgeInsets.only(top: compactLandscape ? 2 : 12, bottom: compactLandscape ? 0 : 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withAlpha(40),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                            child: const Text(
                              '🚒',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'FIREMAN HERO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      if (_currentPage < 2)
                        TextButton(
                          onPressed: () {
                            _pageController.animateToPage(
                              2,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text(
                            'ATLA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Ortadaki Dinamik Etkileşimli Kahraman (Karakter)
                if (!compactLandscape) Expanded(
                  flex: 5,
                  child: Center(
                    child: GestureDetector(
                      onTap: _onHeroTapped,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedFirefighterWidget(
                            size: 150,
                            state: _heroAnimState,
                            showHose: true,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(140),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amberAccent.withAlpha(80),
                              ),
                            ),
                            child: const Text(
                              '👆 Dokun ve Gücü Gör!',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Alt Panel: Açıklayıcı Sayfalar (PageView)
                Expanded(
                  flex: 5,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      _buildCinematicIntroPage(),
                      _buildMechanicsPage(),
                      _buildQuickHeroSelectPage(),
                    ],
                  ),
                ),

                // Sayfa Göstergeleri ve İleri / Başla Butonu
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. SİNEMATİK GİRİŞ SAYFASI
  Widget _buildCinematicIntroPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'ALEVLER ŞEHRİ SARDI!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFF5722),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Labirent sokaklarda yangın büyüyor. Şehrin kaderi cesur bir itfaiyecinin ellerinde!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
      ],
    );
  }

  /// 2. MEKANİKLER VE STRATEJİ SAYFASI
  Widget _buildMechanicsPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'ARENA GÜÇLERİNİ TOPLA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFC107),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PowerUpCard(icon: '⚡', title: 'Şimşek', description: 'Alev menzilini genişlet', color: Colors.amber),
            const SizedBox(width: 8),
            const PowerUpCard(icon: '🛼', title: 'Paten', description: 'Hız kazan, kaç', color: Colors.cyan),
            const SizedBox(width: 8),
            const PowerUpCard(icon: '💣', title: 'Dinamit', description: 'Kapasiteyi katla', color: Colors.redAccent),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  /// 3. KLAVYESİZ HIZLI KAHRAMAN PROFİLİ SEÇİM SAYFASI
  Widget _buildQuickHeroSelectPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'OYUNCU ADINI BELİRLE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Onboarding tamamlanınca kullanacağın adı gireceksin.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),

        // Hızlı İsim Hapları (Pills)
        if (MediaQuery.sizeOf(context).height >= 430) Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _presetNames.map((name) {
            final isSelected = !_isCustomNameMode && _selectedHeroName == name;
            return ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isCustomNameMode = false;
                    _selectedHeroName = name;
                  });
                }
              },
              selectedColor: const Color(0xFFEF4444),
              backgroundColor: const Color(0xFF1A2232),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected
                    ? Colors.amberAccent
                    : const Color(0xFF2E3A4E),
              ),
            );
          }).toList(),
        ),

        if (MediaQuery.sizeOf(context).height >= 430) const SizedBox(height: 8),

        // İsteğe Bağlı Kendi İsmini Gir Butonu
        if (MediaQuery.sizeOf(context).height >= 430) TextButton.icon(
          onPressed: () {
            setState(() => _isCustomNameMode = !_isCustomNameMode);
          },
          icon: Icon(
            _isCustomNameMode ? Icons.check : Icons.edit,
            size: 14,
            color: Colors.amberAccent,
          ),
          label: Text(
            _isCustomNameMode
                ? 'Hazır İsimlere Dön'
                : 'Özel İsim Yaz (İsteğe Bağlı)',
            style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
          ),
        ),

        if (_isCustomNameMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _customNameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Kahraman Adı',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.amberAccent),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// ALT KONTROL PANELİ
  Widget _buildBottomControls() {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).height < 430 ? 4 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sayfa Göstergeleri (Dots)
          Row(
            children: List.generate(3, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFF5722) : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Aksiyon Butonu (İLERİ veya OYUNA BAŞLA)
          GestureDetector(
            onTap: () {
              if (_currentPage < 2) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              } else {
                _completeOnboarding();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: MediaQuery.sizeOf(context).height < 430 ? 8 : 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amberAccent, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withAlpha(120),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    _currentPage == 2 ? 'OYUNA BAŞLA' : 'İLERİ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _currentPage == 2
                        ? Icons.play_arrow
                        : Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
