import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/match.dart';
import '../models/user_profile.dart';
import '../viewmodels/match_viewmodel.dart';
import '../shared/widgets/game_keyboard.dart';
import 'gameplay_screen.dart';
import 'friends_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<MatchViewModel>().refreshRooms()); }

  Future<void> _createRoom() async {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final form = GlobalKey<FormState>();
    TextEditingController? activeController = nameCtrl;
    final values = await showDialog<(String, String?)>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Oda oluştur'),
        content: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
          GameKeyboardField(controller: nameCtrl, maxLength: 40, label: 'Oda adı', onFocus: (c) => setDialogState(() => activeController = c)),
          GameKeyboardField(controller: passCtrl, obscureText: true, label: 'Şifre (isteğe bağlı)', onFocus: (c) => setDialogState(() => activeController = c)),
          if (activeController != null) Padding(padding: const EdgeInsets.only(top: 8), child: GameKeyboard(controller: activeController!, onDone: () => setDialogState(() => activeController = null))),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
          FilledButton(onPressed: () { if (form.currentState!.validate() && nameCtrl.text.trim().isNotEmpty) Navigator.pop(dialogContext, (nameCtrl.text.trim(), passCtrl.text.isEmpty ? null : passCtrl.text)); }, child: const Text('Oluştur'))],
      ),
    ));
    nameCtrl.dispose(); passCtrl.dispose();
    if (values == null || !mounted) return;
    await context.read<MatchViewModel>().createMatch(roomName: values.$1, password: values.$2);
  }

  Future<void> _join(MatchModel room) async {
    String? password;
    if (room.hasPassword) {
      final ctrl = TextEditingController();
      password = await showDialog<String>(context: context, builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('${room.roomName} şifreli oda'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            GameKeyboardField(controller: ctrl, obscureText: true, label: 'Oda şifresi', onFocus: (_) => setDialogState(() {})),
            Padding(padding: const EdgeInsets.only(top: 8), child: GameKeyboard(controller: ctrl, onDone: () => Navigator.pop(dialogContext, ctrl.text))),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, ctrl.text), child: const Text('Katıl'))],
        ),
      ));
      ctrl.dispose();
      if (password == null) return;
    }
    await context.read<MatchViewModel>().joinRoom(room.id, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MatchViewModel>();
    return Scaffold(
      body: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFF52C7F2).withValues(alpha: .15), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.public_rounded, color: Color(0xFF52C7F2), size: 19)),
          const SizedBox(width: 9),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Oyun odaları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text('Arkadaş ekibini kur ve arenaya gir', style: TextStyle(fontSize: 10, color: Colors.white54))])),
          IconButton(tooltip: 'Arkadaşlar ve mesajlar', onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
            if (mounted) vm.refreshRooms();
          }, icon: const Icon(Icons.people_alt_outlined)),
          IconButton(tooltip: 'Odaları yenile', onPressed: vm.refreshRooms, icon: const Icon(Icons.refresh)),
        ]),
        Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF18334A), Color(0xFF172238), Color(0xFF21243A)]), borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFF52C7F2).withValues(alpha: .3))), child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF52C7F2).withValues(alpha: .13), shape: BoxShape.circle), child: const Icon(Icons.groups_rounded, color: Color(0xFF52C7F2), size: 22)),
          const SizedBox(width: 11),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Birlikte mücadele et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('Oda kur, listeden katıl veya eşleş.', style: TextStyle(color: Colors.white70, fontSize: 11))])),
          const SizedBox(width: 10),
          FilledButton.icon(onPressed: vm.isSearching ? null : _createRoom, icon: const Icon(Icons.add), label: const Text('Oda kur')),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(onPressed: vm.isSearching ? null : vm.quickMatch, icon: const Icon(Icons.shuffle), label: const Text('Rastgele')),
        ])),
        if (vm.statusMessage != 'Lobiye bağlanmaya hazır.') Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(vm.statusMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppConstants.waterBlue))),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.fromLTRB(2, 7, 2, 7), child: Row(children: [const Expanded(child: Text('Açık oyun odaları', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF52C7F2).withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Text('${vm.openRooms.length} ODA', style: const TextStyle(color: Color(0xFF52C7F2), fontSize: 9, fontWeight: FontWeight.w900)))])),
        const SizedBox(height: 8),
        Expanded(child: vm.isSearching ? const Center(child: CircularProgressIndicator()) : vm.openRooms.isEmpty
          ? Center(child: Text(vm.statusMessage.contains('401') || vm.statusMessage.toLowerCase().contains('unauthorized') ? 'Oda listesi için oyuncu hesabıyla giriş yapmalısın.' : 'Şu an açık oda yok. İlk odayı sen kur!', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)))
          : ListView.separated(itemCount: vm.openRooms.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) {
              final room = vm.openRooms[index];
              final full = room.currentPlayers >= room.maxPlayers;
              final accent = room.hasPassword ? const Color(0xFFFFC857) : const Color(0xFF52C7F2);
              return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: const Color(0xFF172231), borderRadius: BorderRadius.circular(15), border: Border.all(color: accent.withValues(alpha: .24))), child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: accent.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)), child: Icon(room.hasPassword ? Icons.lock_outline : Icons.sports_esports_rounded, color: accent, size: 19)), const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(room.roomName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)), Text(room.hasPassword ? 'Şifreli oda' : 'Herkese açık', style: const TextStyle(color: Colors.white54, fontSize: 10))])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(9)), child: Text('${room.currentPlayers}/${room.maxPlayers}', style: TextStyle(color: full ? Colors.white38 : accent, fontWeight: FontWeight.w900, fontSize: 10))),
                const SizedBox(width: 8),
                FilledButton.tonal(onPressed: full ? null : () => _join(room), child: Text(full ? 'DOLU' : 'KATIL', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
              ]));
            })),
        if (vm.currentMatch != null) Padding(padding: const EdgeInsets.only(top: 10), child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppConstants.fireRed),
          onPressed: () async {
            final profile = await UserProfile.load();
            if (!context.mounted) return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => GameplayScreen(isOnline: true, playerName: profile.username, profile: profile)));
          },
          icon: const Icon(Icons.play_arrow), label: Text('${vm.currentMatch!.roomName} · Oyuna gir'),
        )),
      ]))),
    );
  }
}
