import 'package:flutter/material.dart';

/// Returns true when the player chooses to continue in offline mode.
Future<bool> confirmOfflinePlay(BuildContext context, Future<bool> Function() check) async {
  while (!await check()) {
    if (!context.mounted) return false;
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF172033), Color(0xFF090D14)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF8A3D), width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x663F1D0B), blurRadius: 28, spreadRadius: 2)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64, height: 64, decoration: const BoxDecoration(color: Color(0x33F97316), shape: BoxShape.circle), child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFFFA45B), size: 34)),
            const SizedBox(height: 14),
            const Text('İNTERNET BAĞLANTISI YOK', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: .7)),
            const SizedBox(height: 8),
            const Text('Bağlantı kurulamadı. Çevrimdışı arenada oynayabilir veya tekrar deneyebilirsin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.4)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('TEKRAR DENE'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ÇEVRİMDIŞI OYNA'))),
            ]),
          ]),
        ),
      ),
    );
    if (retry != true) return true;
  }
  return true;
}

class ConnectionAlert extends StatelessWidget {
  const ConnectionAlert({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(10, 4, 10, 5),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFF511B1B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFF6B4A))),
    child: Row(children: [const Icon(Icons.portable_wifi_off, color: Color(0xFFFFA45B), size: 19), const SizedBox(width: 8), Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))) ]),
  );
}
