import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_keyboard.dart';

class ColorPalettePicker extends StatelessWidget {
  const ColorPalettePicker({
    super.key,
    required this.colors,
    required this.selectedValue,
    required this.onSelected,
    this.spacing = 10,
  });

  final List<Color> colors;
  final int selectedValue;
  final ValueChanged<Color> onSelected;
  final double spacing;

  Future<void> _chooseRgb(BuildContext context) async {
    final initial = Color(selectedValue);
    final red = TextEditingController(text: (initial.r * 255).round().toString());
    final green = TextEditingController(text: (initial.g * 255).round().toString());
    final blue = TextEditingController(text: (initial.b * 255).round().toString());
    var active = red;
    var selected = initial;
    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void update(Color color) {
            setDialogState(() {
              selected = color;
              red.text = (color.r * 255).round().toString();
              green.text = (color.g * 255).round().toString();
              blue.text = (color.b * 255).round().toString();
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF172231),
            title: const Text('Özel kıyafet rengi'),
            content: SizedBox(
              width: 370,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: GestureDetector(
                      onPanDown: (event) => update(_wheelColor(event.localPosition, const Size(220, 220))),
                      onPanUpdate: (event) => update(_wheelColor(event.localPosition, const Size(220, 220))),
                      child: CustomPaint(
                        painter: _ColorWheelPainter(selected),
                        child: Center(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    for (final entry in [('R', red), ('G', green), ('B', blue)])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setDialogState(() => active = entry.$2),
                            child: IgnorePointer(
                              child: TextField(
                                controller: entry.$2,
                                readOnly: true,
                                maxLength: 3,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: entry.$1,
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: .06),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  GameKeyboard(
                    controller: active,
                    numericOnly: true,
                    onDone: () {
                      final channels = [red, green, blue].map((c) => int.tryParse(c.text)).toList();
                      if (channels.every((v) => v != null && v >= 0 && v <= 255)) {
                        update(Color.fromARGB(255, channels[0]!, channels[1]!, channels[2]!));
                      }
                    },
                  ),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, selected),
                icon: const Icon(Icons.check),
                label: const Text('Rengi uygula'),
              ),
            ],
          );
        },
      ),
    );
    red.dispose();
    green.dispose();
    blue.dispose();
    if (result != null) onSelected(result);
  }

  Color _wheelColor(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = position - center;
    final radius = math.min(size.width, size.height) / 2;
    final saturation = (delta.distance / radius).clamp(0.0, 1.0);
    final hue = (math.atan2(delta.dy, delta.dx) * 180 / math.pi + 360) % 360;
    return HSVColor.fromAHSV(1, hue, saturation, 1).toColor();
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: spacing,
    runSpacing: 8,
    children: [
      ...colors.map((color) {
        final selected = color.toARGB32() == selectedValue;
        return InkWell(
          onTap: () => onSelected(color),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? Colors.white : Colors.white24, width: selected ? 3 : 1),
            ),
          ),
        );
      }),
      ActionChip(label: const Text('ÖZEL RGB'), avatar: const Icon(Icons.colorize, size: 16), onPressed: () => _chooseRgb(context)),
    ],
  );
}

class _ColorWheelPainter extends CustomPainter {
  const _ColorWheelPainter(this.selected);
  final Color selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;
    final paint = Paint()..shader = const SweepGradient(colors: [
      Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
      Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000),
    ]).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * .62, Paint()..shader = RadialGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: radius * .62)));

    final hsv = HSVColor.fromColor(selected);
    final angle = hsv.hue * math.pi / 180;
    final marker = center + Offset(math.cos(angle), math.sin(angle)) * radius * hsv.saturation;
    canvas.drawCircle(marker, 8, Paint()..color = Colors.black.withValues(alpha: .75));
    canvas.drawCircle(marker, 5, Paint()..color = selected..style = PaintingStyle.fill);
    canvas.drawCircle(marker, 5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) => oldDelegate.selected != selected;
}
