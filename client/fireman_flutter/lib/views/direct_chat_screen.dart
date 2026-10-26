import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../shared/widgets/game_keyboard.dart';

class DirectChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  const DirectChatScreen({super.key, required this.friendId, required this.friendName});
  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _controller = TextEditingController();
  late Future<List<Map<String, dynamic>>> _messages;
  bool _sending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _messages = context.read<ApiService>().getDirectMessages(widget.friendId);
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) { if (mounted) _reload(); });
  }

  void _reload() => setState(() => _messages = context.read<ApiService>().getDirectMessages(widget.friendId));

  @override
  void dispose() { _refreshTimer?.cancel(); _controller.dispose(); super.dispose(); }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<ApiService>().sendDirectMessage(widget.friendId, body);
      _controller.clear();
      _reload();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesaj gönderilemedi. Bağlantını kontrol et.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(12, 4, 8, 4), child: Row(children: [
      Expanded(child: Text(widget.friendName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
      IconButton(tooltip: 'Geri', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
    ])),
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: _messages, builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Mesajlar yüklenemedi.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final messages = snapshot.data!;
      if (messages.isEmpty) return const Center(child: Text('Sohbeti başlatmak için mesaj gönder.'));
      return ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: messages.length, itemBuilder: (context, index) {
        final message = messages[messages.length - index - 1];
        return Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF253247), borderRadius: BorderRadius.circular(12)), child: Text('${message['senderUsername']}: ${message['message']}')));
      });
    })),
    SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 10), child: Row(children: [Expanded(child: GameKeyboardField(controller: _controller, label: 'Mesaj yaz', maxLength: 500, onFocus: (_) => _showChatKeyboard())), IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send))]))),
  ])));

  Future<void> _showChatKeyboard() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: false,
      builder: (_) => Padding(padding: const EdgeInsets.all(10), child: GameKeyboard(controller: _controller, onDone: () => Navigator.pop(context))));
  }
}
