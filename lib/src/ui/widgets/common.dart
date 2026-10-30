import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/assetly_theme.dart';
import '../screens/icon_picker_screen.dart';
import 'elastic_press.dart';
import 'item_icon.dart';

export 'elastic_press.dart';
export 'item_icon.dart';

const pagePadding = EdgeInsets.fromLTRB(16, 4, 16, 96);
const _topNoticePageOffset = 80.0;

OverlayEntry? _activeTopNotice;
Timer? _activeTopNoticeTimer;

/// Shows transient feedback below the status bar and page header.
/// A new notice replaces the previous one so repeated actions never stack.
void showTopNotice(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  _activeTopNoticeTimer?.cancel();
  _activeTopNotice?.remove();

  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      final scheme = Theme.of(overlayContext).colorScheme;
      // Read from the root overlay. Contexts inside AppShell's SafeArea report
      // zero top padding, which would otherwise place this over the status bar.
      final safeTop = MediaQuery.paddingOf(overlayContext).top;
      return Positioned(
        key: const ValueKey('top-notice'),
        top: safeTop + _topNoticePageOffset,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -12 * (1 - value)),
                  child: Transform.scale(
                    scale: .96 + .04 * value,
                    child: child,
                  ),
                ),
              ),
              child: Semantics(
                liveRegion: true,
                label: message,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Material(
                    color: scheme.onSurface,
                    elevation: 12,
                    shadowColor: Colors.black38,
                    shape: AppShape.all(AppCorner.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 17,
                            color: scheme.surface,
                          ),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              message,
                              style: TextStyle(
                                color: scheme.surface,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  _activeTopNotice = entry;
  overlay.insert(entry);
  _activeTopNoticeTimer = Timer(duration, () {
    if (!identical(_activeTopNotice, entry)) return;
    entry.remove();
    _activeTopNotice = null;
    _activeTopNoticeTimer = null;
  });
}

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
    padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        ...actions,
      ],
    ),
  );
}

/// Fades and lifts its child in once, offset in time by [index], so a page's
/// sections land one after another instead of all at once.
class StaggeredEntry extends StatelessWidget {
  const StaggeredEntry({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 460),
    curve: Interval(
      (index * .07).clamp(0.0, .55),
      1,
      curve: Curves.easeOutCubic,
    ),
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - value)),
        child: child,
      ),
    ),
    child: child,
  );
}

/// A group of settings rows under a label that sits outside the card, as
/// FlClash groups its tools: thin line icon, quiet label, then a white card
/// whose rows are split by hairlines inset to the text.
class SettingSection extends StatelessWidget {
  const SettingSection({
    super.key,
    required this.icon,
    required this.label,
    required this.children,
  });

  final IconData icon;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const _SettingDivider());
      rows.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: context.colors.mutedForeground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .1,
                  color: context.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: context.colors.card,
          shape: AppShape.all(
            AppCorner.xxl,
            border: context.isDark ? context.colors.border : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _SettingDivider extends StatelessWidget {
  const _SettingDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: 50,
    endIndent: 16,
    color: context.colors.border.withValues(alpha: .8),
  );
}

/// One row of a [SettingSection]: line icon, bold label, optional caption and
/// a chevron or caller-supplied control on the right. Pressing it swells with
/// [ElasticPress] instead of throwing a ripple.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.chevron = false,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 15),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 19,
                color: context.isDark
                    ? context.colors.mutedForeground
                    : context.scheme.onSurface.withValues(alpha: .78),
              ),
              const SizedBox(width: 15),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null || chevron) const SizedBox(width: 10),
            ?trailing,
            if (chevron)
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: context.colors.mutedForeground,
              ),
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return ElasticPress(
      maxGrowth: 5,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// The FlClash style app bar used by every pushed detail page: a circular
/// back button whose hit area fills the whole leading slot.
PreferredSizeWidget subPageAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
}) {
  void back() => Navigator.maybePop(context);
  return AppBar(
    leadingWidth: 70,
    titleSpacing: 0,
    title: Text(
      title,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
    ),
    actions: actions,
    leading: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: back,
      child: SizedBox(
        width: 70,
        height: kToolbarHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: ElasticPress(
              maxGrowth: 4,
              child: Material(
                color: context.colors.card,
                shape: AppShape.circle,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: back,
                  customBorder: const CircleBorder(),
                  child: SizedBox.square(
                    dimension: 42,
                    child: Icon(
                      LucideIcons.arrowLeft,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A pushed detail page with the shared app bar and a scrolling body.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.background,
    appBar: subPageAppBar(context, title: title, actions: actions),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 40),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: children,
    ),
  );
}

/// A big page title with a quiet caption, the way FlClash opens a tab.
class BigPageHeader extends StatelessWidget {
  const BigPageHeader({super.key, required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 6, 16, 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 3),
          Text(caption!, style: Theme.of(context).textTheme.bodySmall),
        ],
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
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool badge;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        ElasticPress(
          maxGrowth: 6,
          child: Material(
            color: context.colors.muted,
            shape: AppShape.circle,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  icon,
                  size: 20,
                  color: color ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        if (badge)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.background, width: 2),
              ),
            ),
          ),
      ],
    );
    return tooltip == null
        ? content
        : Tooltip(message: tooltip!, child: content);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing, this.subtitle});

  final String title;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 6, left: 2),
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

/// The app's base surface: continuous corners, hairline border and an optional
/// tonal gradient. Pressing it compresses the card slightly.
class ShadCard extends StatelessWidget {
  const ShadCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    this.gradient,
    this.borderColor,
    this.elevated = false,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;
  final bool elevated;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final shape = AppShape.all(
      AppCorner.lg,
      border: borderColor ?? context.colors.border,
    );
    final content = Padding(padding: padding, child: child);
    final pressable = ElasticPress(
      enabled: onTap != null,
      maxGrowth: 8,
      child: Material(
        color: gradient == null ? (color ?? context.colors.card) : null,
        shape: shape,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: Ink(
          decoration: gradient == null
              ? null
              : ShapeDecoration(gradient: gradient, shape: shape),
          child: onTap == null
              ? content
              : InkWell(
                  onTap: onTap,
                  splashColor: context.colors.accent.withValues(alpha: .06),
                  highlightColor: context.colors.accent.withValues(alpha: .03),
                  child: content,
                ),
        ),
      ),
    );
    if (!elevated) return pressable;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppCorner.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? .35 : .05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: pressable,
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: ShapeDecoration(
        color: c.withValues(alpha: context.isDark ? .16 : .08),
        shape: AppShape.pill,
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
              letterSpacing: -.1,
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
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, thickness: 1, color: context.colors.border),
  );
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
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            shape: AppShape.all(AppCorner.xxl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.accent.withValues(alpha: .16),
                context.colors.muted,
              ],
            ),
          ),
          child: Icon(icon, size: 30, color: context.colors.accent),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (action != null) ...[const SizedBox(height: 18), action!],
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
  backgroundColor: context.colors.card,
  barrierColor: Colors.black.withValues(alpha: .42),
  sheetAnimationStyle: const AnimationStyle(
    duration: Duration(milliseconds: 340),
    reverseDuration: Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  ),
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
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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

class PillFilterOption<T> {
  const PillFilterOption(this.value, this.label);
  final T value;
  final String label;
}

/// Horizontal pill filter with a soft colour transition between options.
class PillFilterBar<T> extends StatelessWidget {
  const PillFilterBar({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 38,
    this.padding = EdgeInsets.zero,
  });

  final List<PillFilterOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: padding,
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final option = options[index];
        final selected = option.value == value;
        return ElasticPress(
          maxGrowth: 4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(option.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: ShapeDecoration(
                color: selected ? context.colors.primary : context.colors.muted,
                shape: AppShape.pill,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? context.colors.onPrimary
                      : context.colors.mutedForeground,
                ),
                child: Text(option.label),
              ),
            ),
          ),
        );
      },
    ),
  );
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
      borderRadius: BorderRadius.circular(AppCorner.md),
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
                  fontSize: 13.5,
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
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  shape: AppShape.all(AppCorner.md),
                  tileColor: option.value == value
                      ? context.colors.primary.withValues(alpha: .08)
                      : null,
                  leading: option.icon == null
                      ? null
                      : Icon(option.icon, size: 19),
                  title: Text(option.label),
                  trailing: option.value == value
                      ? Icon(
                          LucideIcons.check,
                          size: 18,
                          color: context.colors.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, option.value),
                ),
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

/// Opens the full-screen icon library so the picker matches the other
/// FlClash-style detail pages instead of a cramped bottom sheet.
class AssetIconPicker extends StatelessWidget {
  const AssetIconPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.title = '物品图标',
    this.subtitle = '选择便于快速识别的图标',
    this.sheetTitle = '选择物品图标',
  });
  final String value;
  final ValueChanged<String> onChanged;
  final String title, subtitle, sheetTitle;

  @override
  Widget build(BuildContext context) => ElasticPress(
    maxGrowth: 4,
    child: Material(
      color: context.colors.muted,
      shape: AppShape.all(AppCorner.md, border: context.colors.border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: context.colors.card,
                  shape: AppShape.all(
                    AppCorner.sm,
                    border: context.colors.border,
                  ),
                ),
                child: ItemIconArt(value, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: context.colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _open(BuildContext context) async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => IconPickerScreen(title: sheetTitle, selected: value),
      ),
    );
    if (selected != null) onChanged(selected);
  }
}

/// Animates a currency figure whenever [value] changes, so totals settle
/// instead of snapping.
class AnimatedMoney extends StatefulWidget {
  const AnimatedMoney({
    super.key,
    required this.value,
    this.style,
    this.prefix = '¥ ',
    this.duration = const Duration(milliseconds: 720),
  });

  final double value;
  final TextStyle? style;
  final String prefix;
  final Duration duration;

  @override
  State<AnimatedMoney> createState() => _AnimatedMoneyState();
}

class _AnimatedMoneyState extends State<AnimatedMoney>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation = AlwaysStoppedAnimation(widget.value);
  late double _from = widget.value;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(covariant AnimatedMoney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _from = _animation.value;
    _animation = Tween<double>(
      begin: _from,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (context, _) => Text(
      '${widget.prefix}${NumberFormat('#,##0.00').format(_animation.value)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    ),
  );
}

/// Small icon chip used to lead pills and rows with a tonal container.
class TintedIcon extends StatelessWidget {
  const TintedIcon({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
    this.iconSize = 21,
    this.radius = AppCorner.md,
    this.background,
  });

  final IconData icon;
  final Color? color;
  final double size, iconSize, radius;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.accent;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: background ?? tint.withValues(alpha: context.isDark ? .18 : .1),
        shape: AppShape.all(radius),
      ),
      child: Icon(icon, size: iconSize, color: tint),
    );
  }
}
