import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app.dart';
import '../../state/app_controller.dart';
import '../../theme/assetly_theme.dart';
import '../widgets/common.dart';

/// Theme settings laid out like FlClash's 主题 page: a live preview card, a
/// mode card whose rows carry little screen thumbnails, and a colour card of
/// swatches that ring the choice and pop a check into it.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SubPage(
      title: '主题与外观',
      children: [
        const _ThemePreview(),
        SettingSection(
          icon: LucideIcons.sunMedium,
          label: '主题模式',
          children: [
            for (final option in const [
              (ThemeMode.system, '跟随系统'),
              (ThemeMode.light, '浅色'),
              (ThemeMode.dark, '深色'),
            ])
              SettingRow(
                leading: _ModeThumb(mode: option.$1),
                title: option.$2,
                onTap: () => state.setTheme(option.$1),
                trailing: _CheckMark(selected: state.themeMode == option.$1),
              ),
          ],
        ),
        SettingSection(
          icon: LucideIcons.palette,
          label: '主题色彩',
          children: [
            _SwatchPad(
              accent: state.accent,
              onPick: (color) => state.setAccentColor(color),
            ),
          ],
        ),
      ],
    );
  }
}

/// A miniature of the app that recolours and re-themes as the choice changes.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    final line = context.colors.mutedForeground.withValues(alpha: .28);
    Widget bar(double width, double height, {Color? color}) => Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(color: color ?? line, shape: AppShape.pill),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: ShapeDecoration(
        color: context.colors.card,
        shape: AppShape.all(
          AppCorner.xxl,
          border: context.isDark ? context.colors.border : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: ShapeDecoration(
                  color: accent.withValues(alpha: .16),
                  shape: AppShape.all(AppCorner.xs),
                ),
                child: Icon(LucideIcons.package, size: 14, color: accent),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(58, 7, color: context.colors.mutedForeground),
                  const SizedBox(height: 5),
                  bar(34, 5),
                ],
              ),
              const Spacer(),
              bar(56, 20, color: context.colors.muted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniCard(context, '总资产', accent, 30)),
              const SizedBox(width: 10),
              Expanded(
                child: _miniCard(
                  context,
                  '日均成本',
                  context.colors.mutedForeground,
                  22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ShapeDecoration(
              color: context.colors.muted,
              shape: AppShape.all(AppCorner.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: ShapeDecoration(
                    color: accent.withValues(alpha: .18),
                    shape: AppShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(72, 6, color: context.colors.mutedForeground),
                    const SizedBox(height: 5),
                    bar(48, 5),
                  ],
                ),
                const Spacer(),
                bar(30, 6),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: ShapeDecoration(
              color: context.colors.muted,
              shape: AppShape.pill,
            ),
            child: Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: i == 0 ? 34 : 12,
                        height: 12,
                        decoration: ShapeDecoration(
                          color: i == 0
                              ? accent.withValues(alpha: .9)
                              : line.withValues(alpha: .7),
                          shape: AppShape.pill,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniCard(
    BuildContext context,
    String label,
    Color valueColor,
    double valueWidth,
  ) => Container(
    padding: const EdgeInsets.all(10),
    decoration: ShapeDecoration(
      color: context.colors.muted,
      shape: AppShape.all(AppCorner.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 5,
          decoration: ShapeDecoration(
            color: context.colors.mutedForeground.withValues(alpha: .35),
            shape: AppShape.pill,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: valueWidth,
          height: 8,
          decoration: ShapeDecoration(color: valueColor, shape: AppShape.pill),
        ),
      ],
    ),
  );
}

class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF0B0B0E) : Colors.white;
    final line = dark ? const Color(0xFF4A4A55) : const Color(0xFFD9D9E0);
    return Container(
      color: background,
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MiniBar(factor: .5, height: 3, color: line),
          const SizedBox(height: 3),
          _MiniBar(factor: .9, height: 6, color: line.withValues(alpha: .55)),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: _MiniBar(
                  factor: 1,
                  height: 4,
                  color: line.withValues(alpha: .35),
                ),
              ),
              const SizedBox(width: 3),
              const _MiniDot(),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.factor,
    required this.height,
    required this.color,
  });

  final double factor;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: factor,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    ),
  );
}

class _MiniDot extends StatelessWidget {
  const _MiniDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    decoration: const BoxDecoration(
      color: Color(0xFF2E7CF6),
      shape: BoxShape.circle,
    ),
  );
}

class _ModeThumb extends StatelessWidget {
  const _ModeThumb({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final light = const _MiniScreen(brightness: Brightness.light);
    final dark = const _MiniScreen(brightness: Brightness.dark);
    return Container(
      width: 48,
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: AppShape.all(AppCorner.xs, border: context.colors.border),
      ),
      child: switch (mode) {
        ThemeMode.light => light,
        ThemeMode.dark => dark,
        ThemeMode.system => Row(
          children: [
            Expanded(child: light),
            Expanded(child: dark),
          ],
        ),
      },
    );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: selected ? 1 : 0,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutBack,
    child: Icon(LucideIcons.check, size: 20, color: context.colors.accent),
  );
}

class _SwatchPad extends StatelessWidget {
  const _SwatchPad({required this.accent, required this.onPick});

  final Color accent;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    final presets = AppController.accentPresets.values.toList();
    final isPreset = presets.any((c) => c.toARGB32() == accent.toARGB32());
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const cell = 44.0;
          const minGap = 6.0;
          final columns = ((constraints.maxWidth + minGap) / (cell + minGap))
              .floor()
              .clamp(1, 8);
          final gap = columns > 1
              ? ((constraints.maxWidth - columns * cell) / (columns - 1))
                    .floorToDouble()
              : 0.0;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final color in presets)
                _Swatch(
                  color: color,
                  selected: accent.toARGB32() == color.toARGB32(),
                  onTap: () => onPick(color),
                ),
              if (!isPreset)
                _Swatch(
                  color: accent,
                  selected: true,
                  onTap: () => _pickCustom(context, accent, onPick),
                ),
              _AddSwatch(onTap: () => _pickCustom(context, accent, onPick)),
            ],
          );
        },
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final check = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Semantics(
      button: true,
      selected: selected,
      label: AppController.accentHex(color),
      child: ElasticPress(
        maxGrowth: 6,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2.5),
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Icon(LucideIcons.check, size: 17, color: check),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddSwatch extends StatelessWidget {
  const _AddSwatch({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '自选主题色',
    child: ElasticPress(
      maxGrowth: 6,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: ShapeDecoration(
                color: context.colors.muted,
                shape: AppShape.circle,
              ),
              child: Icon(
                LucideIcons.plus,
                size: 18,
                color: context.colors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pickCustom(
  BuildContext context,
  Color initial,
  ValueChanged<Color> onPick,
) async {
  var hsv = HSVColor.fromColor(initial);
  final picked = await showAssetlySheet<Color>(
    context,
    StatefulBuilder(
      builder: (sheetContext, setLocal) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(title: '自选主题色', subtitle: '整站强调色与卡片色调会一起变化'),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: hsv.toColor(),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.palette,
                  size: 30,
                  color:
                      ThemeData.estimateBrightnessForColor(hsv.toColor()) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _SliderLabel(label: '色相', value: hsv.hue.round().toString()),
            Slider(
              value: hsv.hue,
              min: 0,
              max: 360,
              activeColor: hsv.toColor(),
              onChanged: (value) {
                setLocal(() => hsv = hsv.withHue(value));
              },
            ),
            _SliderLabel(
              label: '饱和度',
              value: '${(hsv.saturation * 100).round()}%',
            ),
            Slider(
              value: hsv.saturation,
              min: .2,
              max: 1,
              activeColor: hsv.toColor(),
              onChanged: (value) {
                setLocal(() => hsv = hsv.withSaturation(value));
              },
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, hsv.toColor()),
              child: const Text('使用这个颜色'),
            ),
          ],
        ),
      ),
    ),
    maxHeight: .72,
  );
  if (picked != null) onPick(picked);
}

class _SliderLabel extends StatelessWidget {
  const _SliderLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const Spacer(),
      Text(value, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
