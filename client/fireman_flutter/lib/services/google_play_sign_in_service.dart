import 'package:google_sign_in/google_sign_in.dart';

/// Google Play users authenticate with a Google account. The server client ID
/// is an OAuth Web client ID configured per build, never a secret embedded in code.
class GooglePlaySignInService {
  GooglePlaySignInService({String? serverClientId})
      : _serverClientId = serverClientId ??
            const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final String _serverClientId;
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _initialized = false;
  bool get isConfigured => _serverClientId.isNotEmpty;

  Future<String?> authenticate() async {
    if (_serverClientId.isEmpty) {
      throw StateError('GOOGLE_SERVER_CLIENT_ID build setting is required.');
    }
    if (!_initialized) {
      await _google.initialize(serverClientId: _serverClientId);
      _initialized = true;
    }
    final account = await _google.authenticate();
    return account.authentication.idToken;
  }

  Future<void> signOut() => _google.signOut();
}
