import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/google_play_sign_in_service.dart';
import '../shared/widgets/game_keyboard.dart';
class UsernameEntryScreen extends StatefulWidget {
  const UsernameEntryScreen({super.key});

  @override
  State<UsernameEntryScreen> createState() => _UsernameEntryScreenState();
}

class _UsernameEntryScreenState extends State<UsernameEntryScreen> {
  final _controller = TextEditingController();
  final _googleSignIn = GooglePlaySignInService();
  String? _error;
  bool _isConnectingGoogle = false;
  bool _googleConnected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final username = _controller.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Devam etmek için bir oyuncu adı yaz.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fireman_account_mode', 'guest');
    if (mounted) Navigator.of(context).pop(username);
  }

  Future<void> _connectGoogleAccount() async {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = 'Önce oyuncu adını yaz.');
      return;
    }
    setState(() { _isConnectingGoogle = true; _error = null; });
    try {
      final idToken = await _googleSignIn.authenticate();
      if (idToken == null || idToken.isEmpty) throw StateError('Google kimlik doğrulama belirteci alınamadı.');
      final api = context.read<ApiService>();
      await api.signInWithGoogleIdToken(idToken);
      await api.changeUsername(_controller.text.trim());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fireman_account_mode', 'google_play');
      if (mounted) Navigator.of(context).pop(_controller.text.trim());
    } catch (_) {
      if (mounted) setState(() => _error = 'Google hesabına bağlanılamadı. Bağlantını kontrol edip yeniden dene.');
    } finally {
      if (mounted) setState(() => _isConnectingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    backgroundColor: const Color(0xFF090D14),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Color(0xFFFF7A36), size: 44),
                    const SizedBox(height: 8),
                    const Text('OYUNCU ADINI BELİRLE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    const Text('Bu ad oyun içindeki profilinde görünecek.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    const Text('Google Play ile giriş yapabilir veya misafir olarak oynayabilirsin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 16),
                    GameKeyboardField(
                      controller: _controller,
                      maxLength: 18,
                      label: _error ?? 'Oyuncu adı',
                      onFocus: (_) {},
                    ),
                    const SizedBox(height: 6),
                    GameKeyboard(controller: _controller, onDone: _continue),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _continue, icon: const Icon(Icons.person_outline), label: const Text('MİSAFİR MODUNDA DEVAM ET'))),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isConnectingGoogle ? null : _connectGoogleAccount,
                        icon: _isConnectingGoogle
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(_googleConnected ? Icons.verified : Icons.account_circle_outlined),
                        label: Text(_googleConnected ? 'Google Play hesabı bağlandı' : 'Google Play ile giriş yap'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
