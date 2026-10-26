import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/game_notification_service.dart';
import '../shared/widgets/fireman_card.dart';
import '../shared/widgets/game_keyboard.dart';
import 'direct_chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}
class _FriendsScreenState extends State<FriendsScreen> {
  late Future<List<Map<String, dynamic>>> _friends;
  bool _working = false;
  final Set<String> _announcedFriendRequests = {};
  Timer? _requestTimer;
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _friends = context.read<ApiService>().getFriends(); }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _reload(); });
    _requestTimer = Timer.periodic(const Duration(seconds: 15), (_) { if (mounted) _reload(); });
  }
  @override
  void dispose() { _requestTimer?.cancel(); super.dispose(); }

  void _reload() {
    final api = context.read<ApiService>();
    final pending = api.getFriends();
    pending.then((entries) {
      for (final entry in entries) {
        final id = entry['friendshipId']?.toString() ?? '';
        final isIncoming = entry['status']?.toString().split('.').last == 'Pending' && entry['isIncoming'] == true;
        if (id.isNotEmpty && isIncoming && _announcedFriendRequests.add(id)) {
          unawaited(GameNotificationService.instance
              .notifyFriendRequest(entry['friendUsername']?.toString() ?? 'Bir oyuncu')
              .catchError((_) {}));
        }
      }
    }).catchError((_) {});
    unawaited(_checkGameInvitations(api));
    setState(() => _friends = pending);
  }

  Future<void> _checkGameInvitations(ApiService api) async {
    try {
      final notifications = await api.getNotifications();
      for (final notification in notifications) {
        final type = notification['type']?.toString().split('.').last.toLowerCase();
        final id = notification['id']?.toString() ?? '';
        if (id.isEmpty || (type != 'matchinvite' && type != '3') || notification['isRead'] == true) continue;
        final message = notification['message']?.toString() ?? '';
        final details = RegExp(r'^(.+?) seni [“"](.+?)[”"] odasına').firstMatch(message);
        unawaited(GameNotificationService.instance.notifyGameInvite(
          details?.group(2) ?? 'oyun odasına',
          details?.group(1) ?? 'Bir arkadaşın',
        ).catchError((_) {}));
        await api.markNotificationRead(id);
      }
    } catch (_) {
      // Keep social screens usable when notification polling is unavailable.
    }
  }

  Future<void> _addFriend() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (ctx) {
      var active = controller;
      return StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(title: const Text('Arkadaş ekle'),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        GameKeyboardField(controller: controller, label: 'Oyuncu adı', maxLength: 18, onFocus: (c) => setDialogState(() => active = c)),
        const SizedBox(height: 8), GameKeyboard(controller: active),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('İstek gönder'))]));
    });
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => _working = true);
    try { await context.read<ApiService>().addFriendByUsername(name); _reload(); _notice('Arkadaşlık isteği gönderildi.'); }
    catch (_) { _notice('İstek gönderilemedi. Oyuncu adını ve bağlantını kontrol et.'); }
    finally { if (mounted) setState(() => _working = false); }
  }

  void _notice(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }

  Future<void> _showAccountDialog() async {
    final username = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    var register = false;
    var activeController = username;
    final api = context.read<ApiService>();
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: Text(register ? 'Oyuncu hesabı oluştur' : 'Oyuncu hesabına giriş'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        GameKeyboardField(controller: username, label: 'Oyuncu adı', onFocus: (c) => setDialogState(() => activeController = c)),
        if (register) GameKeyboardField(controller: email, label: 'E-posta', onFocus: (c) => setDialogState(() => activeController = c)),
        GameKeyboardField(controller: password, label: 'Şifre', obscureText: true, onFocus: (c) => setDialogState(() => activeController = c)),
        GameKeyboard(controller: activeController),
        TextButton(onPressed: () => setDialogState(() => register = !register), child: Text(register ? 'Zaten hesabım var, giriş yap' : 'Yeni hesap oluştur')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
        FilledButton(onPressed: () async {
          try {
            await api.authenticate(username: username.text.trim(), password: password.text, email: register ? email.text.trim() : null);
            if (ctx.mounted) Navigator.pop(ctx);
            _reload(); _notice('Hesap bağlantısı kuruldu.');
          } catch (_) {
            if (mounted) _notice('Hesap işlemi tamamlanamadı. Bilgilerini ve bağlantını kontrol et.');
          }
        }, child: Text(register ? 'Hesap oluştur' : 'Giriş yap'))],
    )));
    username.dispose(); email.dispose(); password.dispose();
  }

  Future<void> _closeAccount() async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Hesabı kapat'),
      content: const Text('Hesabın devre dışı bırakılacak ve tekrar giriş yapamayacaksın. Devam edilsin mi?'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hesabı kapat'))],
    ));
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ApiService>().closeAccount();
      if (mounted) _notice('Hesap kapatıldı.');
    } catch (_) { _notice('Hesap kapatılamadı. Bağlantını kontrol edip yeniden dene.'); }
  }

  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(14, 4, 8, 4), child: Row(children: [
      const Expanded(child: Text('Arkadaşlar ve mesajlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
      IconButton(onPressed: _addFriend, tooltip: 'Arkadaş ekle', icon: const Icon(Icons.person_add_alt_1)),
      IconButton(onPressed: _reload, tooltip: 'Yenile', icon: const Icon(Icons.refresh)),
      IconButton(onPressed: _closeAccount, tooltip: 'Hesabı kapat', icon: const Icon(Icons.person_off_outlined, color: Colors.redAccent)),
    ])),
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: _friends, builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting || _working) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_person_outlined, size: 42, color: Colors.amberAccent), const SizedBox(height: 10),
      const Text('Arkadaşlar ve odalar için oyuncu hesabıyla giriş yap.', textAlign: TextAlign.center), const SizedBox(height: 12),
      FilledButton.icon(onPressed: _showAccountDialog, icon: const Icon(Icons.login), label: const Text('Giriş yap / Kayıt ol')),
      const SizedBox(height: 6),
    ])));
    final entries = snapshot.data ?? const [];
    if (entries.isEmpty) return const Center(child: Text('Henüz arkadaşın yok. Oyuncu adıyla istek gönder!', textAlign: TextAlign.center));
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: entries.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) {
      final friend = entries[index];
      final status = friend['status']?.toString().split('.').last ?? 'Pending';
      final incoming = status == 'Pending' && friend['isIncoming'] == true;
      final accepted = status == 'Accepted';
      final friendId = friend['friendUserId']?.toString() ?? '';
      final accent = incoming ? const Color(0xFFFFC857) : accepted ? const Color(0xFF67D7A5) : const Color(0xFF71B8FF);
      return FiremanCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), borderRadius: 16, borderColor: accent.withValues(alpha: .25), child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withValues(alpha: .33), accent.withValues(alpha: .08)]), borderRadius: BorderRadius.circular(13), border: Border.all(color: accent.withValues(alpha: .4))), child: Center(child: Text((friend['friendUsername']?.toString().isNotEmpty ?? false) ? friend['friendUsername'].toString()[0].toUpperCase() : '?', style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 17)))),
        const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(friend['friendUsername']?.toString() ?? 'Oyuncu', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(accepted ? 'Arkadaş · çevrimiçi oyun için hazır' : incoming ? 'Seni eklemek istiyor' : 'İstek gönderildi', style: TextStyle(color: accepted ? accent : Colors.white60, fontSize: 10)),
        ])),
        if (incoming) ...[
          IconButton(tooltip: 'Kabul et', onPressed: () async {
            try { await context.read<ApiService>().respondFriendRequest(friend['friendshipId'].toString(), true); _reload(); }
            catch (_) { _notice('İstek yanıtlanamadı. Bağlantını kontrol et.'); }
          }, icon: const Icon(Icons.check_circle, color: Colors.greenAccent)),
          IconButton(tooltip: 'Reddet', onPressed: () async {
            try { await context.read<ApiService>().respondFriendRequest(friend['friendshipId'].toString(), false); _reload(); }
            catch (_) { _notice('İstek yanıtlanamadı. Bağlantını kontrol et.'); }
          }, icon: const Icon(Icons.cancel_outlined)),
        ],
        if (accepted) IconButton(tooltip: 'Mesaj gönder', icon: const Icon(Icons.chat_bubble_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DirectChatScreen(friendId: friendId, friendName: friend['friendUsername']?.toString() ?? 'Oyuncu')))),
      ]));
    });
  })),
  ])));
}
