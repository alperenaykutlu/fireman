import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/character/animated_character_painter.dart';
import '../viewmodels/character_viewmodel.dart';
import '../widgets/fireman_card.dart';
import '../widgets/fireman_choice_chip.dart';
import '../widgets/fireman_section_title.dart';
import '../widgets/color_palette_picker.dart';
import '../widgets/shop_asset_card.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key, this.username, this.embedded = false});
  final String? username;
  final bool embedded;

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  static const skinColors = [Color(0xFFFFD1A4), Color(0xFFE8B087), Color(0xFFC6865B), Color(0xFF8D5524), Color(0xFF623A25)];
  static const suitColors = [Color(0xFFDC2626), Color(0xFF1D4ED8), Color(0xFFF97316), Color(0xFF15803D), Color(0xFF7E22CE), Color(0xFF111827), Color(0xFFEAB308)];
  static const hats = ['Standart kask', 'Alev kaskı', 'Kurtarma şapkası'];
  static const suits = ['Klasik itfaiye ceketi', 'Gece kurtarma üniforması', 'Teknik kurtarma kıyafeti'];
  static const accessories = ['Hortum seti', 'Omuz telsizi', 'Hava tüpü'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CharacterViewModel>().loadCharacter());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CharacterViewModel>();
    final char = vm.character;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(
                title: Text('${widget.username ?? char?.name ?? 'Karakter'} • Karakter'),
                actions: [Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Center(child: Text('🪙 ${vm.coins}')))],
              ),
        body: vm.isLoading || char == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(builder: (context, box) {
                final compact = box.maxHeight < 390;
                return Padding(
                  padding: EdgeInsets.all(compact ? 8 : 14),
                  child: Row(children: [
                    Expanded(
                      flex: 4,
                      child: FiremanCard(
                        padding: const EdgeInsets.all(10),
                        borderRadius: 18,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Expanded(child: Center(child: AnimatedFirefighterWidget(
                            size: (box.maxHeight * .68).clamp(100.0, 250.0),
                            isFemale: char.gender == 'female',
                            hatStyle: char.hatStyle,
                            accessoryStyle: char.equippedAccessory.contains('telsizi') ? 1 : char.equippedAccessory.contains('tüp') ? 2 : 0,
                            suitColor: Color(char.suitColorValue), skinColor: Color(char.skinColorValue),
                            showShadow: true,
                          ))),
                          Text(widget.username ?? char.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Seviye ${char.level} • ${char.experience} XP', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          SizedBox(height: compact ? 4 : 10),
                        ]),
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 14),
                    Expanded(flex: 6, child: Column(children: [
                      const TabBar(isScrollable: true, tabs: [Tab(text: 'Görünüş'), Tab(text: 'Kıyafet'), Tab(text: 'Başlık'), Tab(text: 'Aksesuar')]),
                      Expanded(child: TabBarView(children: [
                        _scroll(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const FiremanSectionTitle('Karakter'),
                          Wrap(spacing: 8, children: [FiremanChoiceChip(label: 'Erkek', selected: char.gender == 'male', onTap: () => vm.customize(gender: 'male')), FiremanChoiceChip(label: 'Kadın', selected: char.gender == 'female', onTap: () => vm.customize(gender: 'female'))]),
                          const FiremanSectionTitle('Ten rengi'), ColorPalettePicker(colors: skinColors, selectedValue: char.skinColorValue, onSelected: (c) => vm.customize(skinColorValue: c.value)),
                        ])),
                        _shopTab(vm: vm, current: char.suitStyle, unlocked: vm.suitUnlocked, category: 'suit', items: suits, onEquip: (i) => vm.customize(suitStyle: i, suit: suits[i]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const FiremanSectionTitle('Kıyafet rengi'), ColorPalettePicker(colors: suitColors, selectedValue: char.suitColorValue, onSelected: (c) => vm.customize(suitColorValue: c.value))])),
                        _shopTab(vm: vm, current: char.hatStyle, unlocked: vm.hatUnlocked, category: 'hat', items: hats, onEquip: (i) => vm.customize(hatStyle: i, hat: hats[i])),
                        _shopTab(vm: vm, current: char.equippedAccessory.contains('telsizi') ? 1 : char.equippedAccessory.contains('tüp') ? 2 : 0, unlocked: vm.accessoryUnlocked, category: 'accessory', items: accessories, onEquip: (i) => vm.customize(accessory: accessories[i])),
                      ])),
                    ])),
                  ]),
                );
              }),
      ),
    );
  }

  Widget _scroll(Widget child) => SingleChildScrollView(padding: const EdgeInsets.all(12), child: child);
  Widget _shopTab({required CharacterViewModel vm, required int current, required int unlocked, required String category, required List<String> items, required ValueChanged<int> onEquip, Widget? child}) => _scroll(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const FiremanSectionTitle('Varlıklar • sırayla açılır'),
    ...List.generate(items.length, (i) {
      final available = i <= unlocked;
      final selected = i == current;
      return ShopAssetCard(
        title: items[i],
        subtitle: i == 0 ? 'Ücretsiz' : available ? 'Açıldı' : '100 🪙',
        selected: selected,
        unlocked: available,
        onTap: () => onEquip(i),
      );
    }),
    if (unlocked < items.length - 1) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: vm.coins >= 100 ? () {
      if (!vm.purchaseNext(category)) return;
      final next = unlocked + 1;
      onEquip(next);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${items[next]} açıldı')));
    } : null, icon: const Icon(Icons.lock_open), label: Text('Sıradaki öğeyi aç • 100 🪙'))),),
    if (child != null) child,
  ]));
}
