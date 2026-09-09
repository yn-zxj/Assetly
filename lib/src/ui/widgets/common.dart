import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/assetly_theme.dart';

const pagePadding = EdgeInsets.fromLTRB(16, 8, 16, 24);

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    ),
  );
}

class IconAction extends StatelessWidget {
  const IconAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.badge = false,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final bool badge;
  final String? tooltip;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 21),
        style: IconButton.styleFrom(
          side: BorderSide(color: context.colors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      if (badge)
        Positioned(
          right: 3,
          top: 3,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.card, width: 1.5),
            ),
          ),
        ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing, this.subtitle});
  final String title;
  final Widget? trailing;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class ShadCard extends StatelessWidget {
  const ShadCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {super.key, this.color, this.icon});
  final String label;
  final Color? color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
  });
  final String label, value;
  final String? caption;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => ShadCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: valueColor),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(caption!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}

class Hairline extends StatelessWidget {
  const Hairline({super.key});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.colors.border);
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = LucideIcons.packageOpen,
    this.action,
  });
  final String title, description;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.muted,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 26, color: context.colors.mutedForeground),
        ),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 5),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

Future<T?> showAssetlySheet<T>(
  BuildContext context,
  Widget child, {
  double maxHeight = .9,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => SizedBox(
    width: double.infinity,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeight,
      ),
      child: child,
    ),
  ),
);

class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}

class SelectOption<T> {
  const SelectOption(this.value, this.label, {this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// A compact shadcn-style select. Options use a bottom sheet instead of the
/// platform dropdown, keeping spacing and touch targets consistent on phones.
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder = '请选择',
  });
  final String label;
  final T value;
  final List<SelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final selected = options.where((x) => x.value == value).firstOrNull;
    return InkWell(
      onTap: options.isEmpty ? null : () => _open(context),
      borderRadius: BorderRadius.circular(9),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(LucideIcons.chevronsUpDown, size: 16),
        ),
        child: Row(
          children: [
            if (selected?.icon != null) ...[
              Icon(selected!.icon, size: 17),
              const SizedBox(width: 7),
            ],
            Expanded(
              child: Text(
                selected?.label ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected == null
                      ? context.colors.mutedForeground
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final result = await showAssetlySheet<T>(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: ListView(
          shrinkWrap: true,
          children: [
            SheetHeader(title: '选择$label'),
            ...options.map(
              (option) => ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                tileColor: option.value == value ? context.colors.muted : null,
                leading: option.icon == null
                    ? null
                    : Icon(option.icon, size: 19),
                title: Text(option.label),
                trailing: option.value == value
                    ? Icon(
                        LucideIcons.check,
                        size: 18,
                        color: context.colors.accent,
                      )
                    : null,
                onTap: () => Navigator.pop(context, option.value),
              ),
            ),
          ],
        ),
      ),
      maxHeight: .68,
    );
    if (result != null) onChanged(result);
  }
}

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.controller,
    this.firstDate,
    this.lastDate,
    this.required = false,
  });
  final String label;
  final TextEditingController controller;
  final DateTime? firstDate, lastDate;
  final bool required;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    readOnly: true,
    onTap: () async {
      final now = DateTime.now();
      final parsed = DateTime.tryParse(controller.text);
      final min = firstDate ?? DateTime(1970);
      final max = lastDate ?? DateTime(now.year + 30, 12, 31);
      final initial =
          parsed != null && !parsed.isBefore(min) && !parsed.isAfter(max)
          ? parsed
          : now.isBefore(min)
          ? min
          : now.isAfter(max)
          ? max
          : now;
      final selected = await showDatePicker(
        context: context,
        locale: const Locale('zh', 'CN'),
        initialDate: initial,
        firstDate: min,
        lastDate: max,
        helpText: '选择$label',
      );
      if (selected != null) {
        controller.text = DateFormat('yyyy-MM-dd').format(selected);
      }
    },
    decoration: InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: '选择日期',
      prefixIcon: const Icon(LucideIcons.calendarDays, size: 18),
      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      suffixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 38),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: '清除日期',
              onPressed: controller.clear,
              icon: const Icon(LucideIcons.x, size: 16),
            ),
    ),
  );
}

const assetIconChoices = <String>[
  '📦',
  '💻',
  '📱',
  '⌚',
  '🎧',
  '📷',
  '🎮',
  '📚',
  '🧥',
  '👟',
  '👜',
  '🛋️',
  '🪑',
  '🛏️',
  '💡',
  '☕',
  '🍳',
  '🧹',
  '🧰',
  '🚲',
  '🎸',
  '🏀',
  '🌱',
  '🎁',
];

const spaceIconChoices = <String>[
  '📍',
  '🏠',
  '🏢',
  '🛏️',
  '🛋️',
  '🍳',
  '🚿',
  '🧱',
  '🪜',
  '🌿',
  '🚗',
  '🧳',
  '🗄️',
  '🚪',
  '🗃️',
  '📚',
  '🧰',
  '🧺',
  '📦',
  '🧊',
  '👕',
  '👟',
  '💊',
  '☕',
];

class AssetIconPicker extends StatelessWidget {
  const AssetIconPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.title = '物品图标',
    this.subtitle = '选择便于快速识别的图标',
    this.sheetTitle = '选择物品图标',
    this.sheetSubtitle = '图标只标识物品，不与分类绑定',
    this.choices = assetIconChoices,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final String title, subtitle, sheetTitle, sheetSubtitle;
  final List<String> choices;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _open(context),
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: context.colors.muted,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: context.colors.border),
            ),
            child: Text(value, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 18),
        ],
      ),
    ),
  );

  Future<void> _open(BuildContext context) async {
    final selected = await showAssetlySheet<String>(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: sheetTitle, subtitle: sheetSubtitle),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: choices.length,
              itemBuilder: (context, index) {
                final icon = choices[index];
                return InkWell(
                  onTap: () => Navigator.pop(context, icon),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: icon == value
                          ? context.colors.accent.withValues(alpha: .12)
                          : context.colors.muted,
                      border: Border.all(
                        color: icon == value
                            ? context.colors.accent
                            : context.colors.border,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }
}
