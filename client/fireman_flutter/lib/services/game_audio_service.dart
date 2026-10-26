import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Centralized game music, effects, and tactile feedback.
class GameAudioService {
  GameAudioService._();
  static final instance = GameAudioService._();

  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _effects = AudioPlayer();
  bool _musicEnabled = true;
  bool _effectsEnabled = true;
  bool _vibrationEnabled = true;
  bool _playing = false;
  DateTime _lastExplosionFeedback = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> startGameMusic() async {
    if (!_musicEnabled || _playing) return;
    _playing = true;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(.24);
      await _music.play(AssetSource('audio/menu_theme.wav'));
    } catch (_) { _playing = false; }
  }

  Future<void> stopGameMusic() async {
    _playing = false;
    try { await _music.stop(); } catch (_) {}
  }

  Future<void> playExplosion() async {
    final now = DateTime.now();
    if (now.difference(_lastExplosionFeedback) < const Duration(milliseconds: 180)) return;
    _lastExplosionFeedback = now;
    if (_effectsEnabled) {
      try {
        await _effects.stop();
        await _effects.setVolume(.75);
        await _effects.play(AssetSource('audio/bomb_explosion.wav'));
      } catch (_) {}
    }
    if (!_vibrationEnabled) return;
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 110);
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) { await HapticFeedback.heavyImpact(); }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (enabled) {
      await startGameMusic();
    } else {
      await stopGameMusic();
    }
  }

  void setEffectsEnabled(bool enabled) => _effectsEnabled = enabled;
  void setVibrationEnabled(bool enabled) => _vibrationEnabled = enabled;

  Future<void> dispose() async {
    await _music.dispose();
    await _effects.dispose();
  }
}
