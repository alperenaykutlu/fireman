import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/character/animated_firefighter_widget.dart';
import '../viewmodels/character_viewmodel.dart';
import '../shared/widgets/color_palette_picker.dart';
import 'widgets/asset_tile.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key, this.username, this.embedded = false});
  final String? username;
  final bool embedded;

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  int? _previewSuitStyle;
  static const skinColors = [Color(0xFFFFD1A4), Color(0xFFE8B087), Color(0xFFC6865B), Color(0xFF8D5524), Color(0xFF623A25)];
  static const suitColors = [Color(0xFFDC2626), Color(0xFF1D4ED8), Color(0xFFF97316), Color(0xFF15803D), Color(0xFF7E22CE), Color(0xFF111827), Color(0xFFEAB308)];
  static List<String> _fifty(String category, List<String> styles) => List.generate(50, (i) => '${styles[i % styles.length]} $category • ${i + 1}');
  static final hats = _fifty('kaskı', ['Klasik', 'Alev', 'Kurtarma', 'Komutan', 'Gece', 'Dağ', 'Endüstri', 'Teknik', 'Taktik', 'Pro']);
  static final suits = _fifty('kıyafeti', ['Klasik', 'Kentsel', 'Gece', 'Dağ', 'Endüstriyel', 'Alev', 'Teknik', 'Kurtarma', 'Taktik', 'Pro']);
  static final accessories = _fifty('aksesuarı', ['Hortum', 'Telsiz', 'Hava tüpü', 'Fener', 'Balta', 'Kanca', 'Pusula', 'Kemer', 'Rozet', 'Kurtarma']);
  static final masks = _fifty('maskesi', ['Filtreli', 'Oksijen', 'Duman', 'Termal', 'Kompakt', 'Tam yüz', 'Acil durum', 'Basınçlı', 'Seramik', 'Pro']);
  static final gloves = _fifty('eldiveni', ['Isı kalkanı', 'Kesilmez', 'Kurtarma', 'Termal', 'Su geçirmez', 'Takviyeli', 'Esnek', 'Karbon', 'Aramid', 'Pro']);
  static final shoes = _fifty('ayakkabısı', ['Çelik burun', 'Isı kalkanı', 'Dağ', 'Kentsel', 'Kaymaz', 'Kurtarma', 'Hafif', 'Takviyeli', 'Karbon', 'Pro']);
  static final bombs = _fifty('dinamiti', ['Klasik', 'Alev', 'Duman', 'Buz', 'Şok', 'Zincir', 'Hızlı', 'Güçlü', 'Taktik', 'Pro']);
  static const categories = [
    (label: 'Görünüş', icon: Icons.face_retouching_natural, color: Color(0xFF58D6C0)),
    (label: 'Kıyafet', icon: Icons.checkroom, color: Color(0xFFFF714B)),
    (label: 'Kask', icon: Icons.sports_motorsports, color: Color(0xFFFFC857)),
    (label: 'Aksesuar', icon: Icons.backpack_outlined, color: Color(0xFF69A9FF)),
    (label: 'Maske', icon: Icons.masks, color: Color(0xFFB698FF)),
    (label: 'Eldiven', icon: Icons.back_hand_outlined, color: Color(0xFFFF8CA1)),
    (label: 'Ayakkabı', icon: Icons.hiking, color: Color(0xFF8FD176)),
    (label: 'Dinamit', icon: Icons.whatshot, color: Color(0xFFFF5E57)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CharacterViewModel>().loadCharacter());
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: categories.length,
    child: Scaffold(body: Consumer<CharacterViewModel>(builder: (context, vm, _) {
      final char = vm.character;
      if (vm.isLoading || char == null) return const Center(child: CircularProgressIndicator());
      return LayoutBuilder(builder: (context, box) {
        final compact = box.maxHeight < 420;
        final narrow = box.maxWidth < 680;
        return Padding(
          padding: EdgeInsets.all(compact ? 8 : 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: (box.maxWidth * (narrow ? .31 : .27)).clamp(190.0, 310.0).toDouble(), child: _preview(context, vm, char, compact)),
            SizedBox(width: compact ? 9 : 14),
            Expanded(child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(child: _inventoryHeading(vm, compact)),
                SliverToBoxAdapter(child: SizedBox(height: compact ? 5 : 9)),
                SliverToBoxAdapter(child: TabBar(
                  isScrollable: true, tabAlignment: TabAlignment.start,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [for (final category in categories) Tab(icon: Icon(category.icon, size: 16), text: category.label)],
                )),
              ],
              body: TabBarView(children: [
                _appearance(vm, char, compact),
                _assetTab(vm, current: char.suitStyle, category: 'suit', items: suits, unlocked: vm.suitUnlocked, accent: categories[1].color,
                  onEquip: (i) { setState(() => _previewSuitStyle = null); vm.customize(suitStyle: i, suit: suits[i]); },
                  onPreview: (i) => setState(() => _previewSuitStyle = i),
                  extra: _colorEditor('Kıyafet rengini seç', suitColors, char.suitColorValue, (c) => vm.customize(suitColorValue: c.toARGB32()))),
                _assetTab(vm, current: char.hatStyle, category: 'hat', items: hats, unlocked: vm.hatUnlocked, accent: categories[2].color, onEquip: (i) => vm.customize(hatStyle: i, hat: hats[i])),
                _assetTab(vm, current: _index(accessories, char.equippedAccessory), category: 'accessory', items: accessories, unlocked: vm.accessoryUnlocked, accent: categories[3].color, onEquip: (i) => vm.customize(accessory: accessories[i])),
                _assetTab(vm, current: _index(masks, char.equippedMask), category: 'mask', items: masks, unlocked: vm.unlockedFor('mask'), accent: categories[4].color, onEquip: (i) => vm.customize(mask: masks[i])),
                _assetTab(vm, current: _index(gloves, char.equippedGloves), category: 'gloves', items: gloves, unlocked: vm.unlockedFor('gloves'), accent: categories[5].color, onEquip: (i) => vm.customize(gloves: gloves[i])),
                _assetTab(vm, current: _index(shoes, char.equippedShoes), category: 'shoes', items: shoes, unlocked: vm.unlockedFor('shoes'), accent: categories[6].color, onEquip: (i) => vm.customize(shoes: shoes[i])),
                _assetTab(vm, current: _index(bombs, char.equippedBomb), category: 'bomb', items: bombs, unlocked: vm.unlockedFor('bomb'), accent: categories[7].color, onEquip: (i) => vm.customize(bomb: bombs[i])),
              ]),
            )),
          ]),
        );
      });
    })),
  );

  static int _index(List<String> list, String value) => list.indexOf(value).clamp(0, list.length - 1).toInt();

  Widget _preview(BuildContext context, CharacterViewModel vm, dynamic char, bool compact) {
    return AnimatedBuilder(animation: DefaultTabController.of(context), builder: (context, _) {
      final active = categories[DefaultTabController.of(context).index];
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF202D3F), const Color(0xFF111A28), active.color.withValues(alpha: .18)]),
          border: Border.all(color: active.color.withValues(alpha: .5)),
        ),
        child: Stack(children: [
          Positioned(right: -30, top: -30, child: Icon(active.icon, size: compact ? 90 : 130, color: active.color.withValues(alpha: .08))),
          Padding(padding: EdgeInsets.all(compact ? 10 : 16), child: Column(children: [
            Row(children: [Icon(Icons.view_in_ar_rounded, color: active.color, size: 17), const SizedBox(width: 6), const Expanded(child: Text('MODEL ÖNİZLEME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white70))), Icon(Icons.circle, size: 8, color: active.color)]),
            Expanded(child: Center(child: RepaintBoundary(child: AnimatedFirefighterWidget(
              size: (MediaQuery.sizeOf(context).height * .42).clamp(90.0, 210.0).toDouble(),
              isFemale: char.gender == 'female', hatStyle: char.hatStyle,
              suitStyle: _previewSuitStyle ?? char.suitStyle,
              maskStyle: masks.indexOf(char.equippedMask),
              accessoryStyle: char.equippedAccessory.contains('telsizi') ? 1 : char.equippedAccessory.contains('tüp') ? 2 : 0,
              suitColor: Color(char.suitColorValue), skinColor: Color(char.skinColorValue), showShadow: true,
            )))),
            Text(widget.username ?? char.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Text('SEVİYE ${char.level}  ·  ${char.experience} XP', style: const TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: .5)),
            SizedBox(height: compact ? 8 : 14),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.monetization_on, color: Color(0xFFFFC857), size: 17), const SizedBox(width: 7), const Expanded(child: Text('BAKİYE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))), Text('${vm.coins}', style: const TextStyle(color: Color(0xFFFFC857), fontWeight: FontWeight.w900))])),
          ])),
        ]),
      );
    });
  }

  Widget _inventoryHeading(CharacterViewModel vm, bool compact) => Row(children: [
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Atölye', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)), Text('Karakterini parça parça tasarla', style: TextStyle(fontSize: 11, color: Colors.white60))])),
    if (compact) const SizedBox.shrink() else const Icon(Icons.auto_awesome, color: Color(0xFFFFC857), size: 17),
    if (!compact) const SizedBox(width: 6),
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFFFC857).withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Text('🪙 ${vm.coins}', style: const TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.w900, fontSize: 12))),
  ]);

  Widget _appearance(CharacterViewModel vm, dynamic char, bool compact) => _scroll([
    _section('Kimlik', 'Kadın ve erkek karakter gövdeleri', Icons.person_outline, categories[0].color),
    Wrap(spacing: 8, children: [for (final entry in [('Erkek', 'male', Icons.male), ('Kadın', 'female', Icons.female)]) ChoiceChip(label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(entry.$3, size: 16), const SizedBox(width: 5), Text(entry.$1)]), selected: char.gender == entry.$2, onSelected: (_) => vm.customize(gender: entry.$2))]),
    _section('Ten rengi', 'Önizleme anında güncellenir', Icons.palette_outlined, const Color(0xFF58D6C0)),
    ColorPalettePicker(colors: skinColors, selectedValue: char.skinColorValue, onSelected: (c) => vm.customize(skinColorValue: c.toARGB32())),
    const SizedBox(height: 10),
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF58D6C0).withValues(alpha: .08), borderRadius: BorderRadius.circular(14)), child: const Row(children: [Icon(Icons.touch_app, color: Color(0xFF58D6C0)), SizedBox(width: 10), Expanded(child: Text('Kategorileri seçerek kask, kıyafet ve ekipmanları ayrı ayrı düzenle.', style: TextStyle(color: Colors.white70, fontSize: 12)))])),
  ], compact);

  Widget _colorEditor(String title, List<Color> colors, int selected, ValueChanged<Color> onSelected) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _section(title, 'Hazır palet veya özel RGB', Icons.color_lens_outlined, const Color(0xFFFF714B)),
    ColorPalettePicker(colors: colors, selectedValue: selected, onSelected: onSelected),
  ]);

  Widget _assetTab(CharacterViewModel vm, {required int current, required String category, required List<String> items, required int unlocked, required Color accent, required ValueChanged<int> onEquip, ValueChanged<int>? onPreview, Widget? extra}) {
    final next = unlocked + 1;
    return Column(children: [
      if (extra != null) Padding(padding: const EdgeInsets.fromLTRB(4, 2, 4, 2), child: extra),
      Expanded(child: LayoutBuilder(builder: (context, box) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: box.maxWidth < 540 ? 2 : 3, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: 1.7),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final available = i <= unlocked;
          final selected = current == i;
          return AssetTile(title: items[i], index: i, accent: accent, selected: selected, unlocked: available, price: i == 0 ? 'ÜCRETSİZ' : available ? 'AÇILDI' : '100 🪙', onTap: available ? (selected ? null : () => onEquip(i)) : () => onPreview?.call(i));
        },
      ))),
      if (next < items.length) Padding(padding: const EdgeInsets.only(top: 5), child: SizedBox(width: double.infinity, height: 42, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black87),
        onPressed: vm.coins >= 100 ? () { if (vm.purchaseNext(category)) { onEquip(next); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${items[next]} açıldı'))); } } : null,
        icon: const Icon(Icons.lock_open, size: 18), label: Text('Sıradaki öğeyi aç · 100 🪙', style: const TextStyle(fontWeight: FontWeight.w800)),
      ))),
    ]);
  }

  Widget _section(String title, String subtitle, IconData icon, Color color) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 18)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white54))]))]));
  Widget _scroll(List<Widget> children, bool compact) => ListView(padding: EdgeInsets.fromLTRB(8, compact ? 0 : 8, 8, 12), children: children);
}
