import 'package:flutter/material.dart';

/// Corner scale shared by every surface, mirroring FlClash's AppCorner tokens.
abstract final class AppCorner {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double full = 999;
}

/// Continuous-corner shapes. [RoundedSuperellipseBorder] keeps curves smooth
/// like iOS squircle corners instead of the sharper arc of a plain radius.
abstract final class AppShape {
  static RoundedSuperellipseBorder all(
    double corner, {
    Color? border,
    double width = 1,
  }) => RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(corner),
    side: border == null
        ? BorderSide.none
        : BorderSide(color: border, width: width),
  );

  static RoundedSuperellipseBorder top(
    double corner, {
    Color? border,
    double width = 1,
  }) => RoundedSuperellipseBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(corner)),
    side: border == null
        ? BorderSide.none
        : BorderSide(color: border, width: width),
  );

  static const pill = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppCorner.full)),
  );

  static const circle = CircleBorder();

  static AppInputBorder input({Color? border, double width = 1}) =>
      AppInputBorder(
        borderSide: border == null
            ? BorderSide.none
            : BorderSide(color: border, width: width),
      );
}

/// Rounded-superellipse input outline so text fields share the app's
/// continuous-corner language.
class AppInputBorder extends InputBorder {
  const AppInputBorder({
    super.borderSide = BorderSide.none,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppCorner.md)),
  });

  final BorderRadius borderRadius;

  RoundedSuperellipseBorder get _shape =>
      RoundedSuperellipseBorder(borderRadius: borderRadius, side: borderSide);

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  AppInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
  }) => AppInputBorder(
    borderSide: borderSide ?? this.borderSide,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  AppInputBorder scale(double t) => AppInputBorder(
    borderSide: borderSide.scale(t),
    borderRadius: borderRadius * t,
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) return;
    _shape.paint(canvas, rect, textDirection: textDirection);
  }

  @override
  bool operator ==(Object other) =>
      other is AppInputBorder &&
      other.borderSide == borderSide &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(borderSide, borderRadius);
}

/// FlClash's page motion: the incoming page slides a quarter of its width
/// while fading in, and the page underneath trails out of the way.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  static const duration = Duration(milliseconds: 300);
  static final _slide = CurveTween(curve: Curves.easeInOutCubicEmphasized);
  static final _in = Tween<double>(begin: 0, end: 1).chain(
    CurveTween(curve: const Interval(.04, .46, curve: Curves.easeOutCubic)),
  );
  static final _out = Tween<double>(
    begin: 1,
    end: 0,
  ).chain(CurveTween(curve: const Interval(0, .22, curve: Curves.easeIn)));

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst) return child;
    final enter = Tween<Offset>(
      begin: const Offset(.18, 0),
      end: Offset.zero,
    ).chain(_slide).animate(animation);
    final leave = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-.08, 0),
    ).chain(_slide).animate(secondaryAnimation);
    return SlideTransition(
      position: leave,
      child: FadeTransition(
        opacity: _out.animate(secondaryAnimation),
        child: SlideTransition(
          position: enter,
          child: FadeTransition(opacity: _in.animate(animation), child: child),
        ),
      ),
    );
  }
}

class AssetlyTheme {
  static const zinc = Color(0xFF18181B);
  static const emerald = Color(0xFF10B981);

  static ThemeData light(Color accent) => _theme(Brightness.light, accent);

  static ThemeData dark(Color accent) => _theme(Brightness.dark, accent);

  static ThemeData _theme(Brightness brightness, Color accent) {
    final isDark = brightness == Brightness.dark;
    Color tint(Color base, double alpha) =>
        Color.alphaBlend(accent.withValues(alpha: alpha), base);

    final background = isDark
        ? tint(const Color(0xFF0A0A0C), .06)
        : tint(const Color(0xFFF4F4F6), .04);
    final card = isDark ? const Color(0xFF151518) : Colors.white;
    final muted = isDark
        ? const Color(0xFF212125)
        : tint(const Color(0xFFF1F1F4), .05);
    final border = isDark ? const Color(0xFF2B2B31) : const Color(0xFFE5E5EA);
    final foreground = isDark
        ? const Color(0xFFFAFAFA)
        : const Color(0xFF0B0B0E);
    final mutedForeground = isDark
        ? const Color(0xFFA0A0A8)
        : const Color(0xFF71717A);

    final seeded = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final scheme = seeded.copyWith(
      surface: background,
      onSurface: foreground,
      surfaceContainerLowest: isDark ? background : card,
      surfaceContainerLow: card,
      surfaceContainer: muted,
      surfaceContainerHigh: isDark
          ? const Color(0xFF242428)
          : tint(const Color(0xFFEFEFF2), .05),
      surfaceContainerHighest: isDark
          ? const Color(0xFF2A2A2F)
          : tint(const Color(0xFFEAEAEE), .05),
      onSurfaceVariant: mutedForeground,
      outline: border,
      outlineVariant: border,
      surfaceTint: Colors.transparent,
      inverseSurface: foreground,
      onInverseSurface: background,
      error: isDark ? const Color(0xFFFF6B6E) : const Color(0xFFDC2F3C),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      // FlClash answers a press with the surface's own swell, never a ripple.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      fontFamilyFallback: const [
        'SF Pro Text',
        'PingFang SC',
        'Noto Sans CJK SC',
      ],
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    final textTheme = base.textTheme.copyWith(
      displaySmall: TextStyle(
        fontSize: 40,
        height: 1.06,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
        color: foreground,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: foreground,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -.7,
        color: foreground,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -.3,
        color: foreground,
      ),
      titleMedium: TextStyle(
        fontSize: 15.5,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -.1,
        color: foreground,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: foreground),
      bodyMedium: TextStyle(fontSize: 13.5, height: 1.45, color: foreground),
      bodySmall: TextStyle(fontSize: 12, height: 1.35, color: mutedForeground),
      labelLarge: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      labelMedium: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: mutedForeground,
      ),
    );

    const pill = WidgetStatePropertyAll<OutlinedBorder>(AppShape.pill);
    const buttonPadding = WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    );
    const buttonText = WidgetStatePropertyAll(
      TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -.1),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: foreground,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: foreground, size: 21),
        toolbarHeight: 56,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: AppShape.all(AppCorner.lg, border: border),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: muted,
        isDense: true,
        hintStyle: TextStyle(color: mutedForeground, fontSize: 13),
        labelStyle: TextStyle(color: mutedForeground, fontSize: 13.5),
        floatingLabelStyle: TextStyle(
          color: scheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        prefixIconColor: mutedForeground,
        suffixIconColor: mutedForeground,
        border: AppShape.input(border: Colors.transparent),
        enabledBorder: AppShape.input(border: Colors.transparent),
        focusedBorder: AppShape.input(border: scheme.primary, width: 1.5),
        errorBorder: AppShape.input(border: scheme.error),
        focusedErrorBorder: AppShape.input(border: scheme.error, width: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: buttonPadding,
          elevation: const WidgetStatePropertyAll(0),
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: buttonPadding,
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(scheme.primary),
          foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: border, width: 1.2)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: pill,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          iconSize: 20,
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: AppShape.all(AppCorner.lg),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: AppShape.pill,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(
          color: scheme.onSecondaryContainer,
          size: 22,
        ),
        unselectedIconTheme: IconThemeData(color: mutedForeground, size: 22),
        selectedLabelTextStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: mutedForeground,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: muted,
        selectedColor: scheme.secondaryContainer,
        disabledColor: muted,
        side: BorderSide.none,
        shape: AppShape.pill,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onSecondaryContainer,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.secondaryContainer
                : muted,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : mutedForeground,
          ),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: pill,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : mutedForeground,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : muted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : border,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        modalBackgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: mutedForeground.withValues(alpha: .45),
        dragHandleSize: const Size(38, 4),
        shape: AppShape.top(AppCorner.xxl),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: AppShape.all(AppCorner.xxl),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: foreground,
        contentTextStyle: TextStyle(color: background, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: AppShape.all(AppCorner.md),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: mutedForeground,
        textColor: foreground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: AppShape.all(AppCorner.md),
        minLeadingWidth: 24,
        titleTextStyle: textTheme.labelLarge,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: AppShape.all(AppCorner.lg),
        textStyle: textTheme.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: foreground,
          borderRadius: BorderRadius.circular(AppCorner.sm),
        ),
        textStyle: TextStyle(color: background, fontSize: 11.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: muted,
        circularTrackColor: muted,
        borderRadius: const BorderRadius.all(Radius.circular(AppCorner.full)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? foreground
                : mutedForeground,
          ),
        ),
      ),
      extensions: [
        AssetlyColors(
          border: border,
          muted: muted,
          mutedForeground: mutedForeground,
          card: card,
          accent: accent,
          background: background,
          primary: scheme.primary,
          onPrimary: scheme.onPrimary,
          container: scheme.secondaryContainer,
          onContainer: scheme.onSecondaryContainer,
          isDark: isDark,
        ),
      ],
    );
  }
}

class AssetlyColors extends ThemeExtension<AssetlyColors> {
  const AssetlyColors({
    required this.border,
    required this.muted,
    required this.mutedForeground,
    required this.card,
    required this.accent,
    required this.background,
    required this.primary,
    required this.onPrimary,
    required this.container,
    required this.onContainer,
    required this.isDark,
  });

  final Color border, muted, mutedForeground, card, accent, background;
  final Color primary, onPrimary, container, onContainer;
  final bool isDark;

  @override
  AssetlyColors copyWith({
    Color? border,
    Color? muted,
    Color? mutedForeground,
    Color? card,
    Color? accent,
    Color? background,
    Color? primary,
    Color? onPrimary,
    Color? container,
    Color? onContainer,
    bool? isDark,
  }) => AssetlyColors(
    border: border ?? this.border,
    muted: muted ?? this.muted,
    mutedForeground: mutedForeground ?? this.mutedForeground,
    card: card ?? this.card,
    accent: accent ?? this.accent,
    background: background ?? this.background,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    container: container ?? this.container,
    onContainer: onContainer ?? this.onContainer,
    isDark: isDark ?? this.isDark,
  );

  @override
  AssetlyColors lerp(covariant AssetlyColors? other, double t) => other == null
      ? this
      : AssetlyColors(
          border: Color.lerp(border, other.border, t)!,
          muted: Color.lerp(muted, other.muted, t)!,
          mutedForeground: Color.lerp(
            mutedForeground,
            other.mutedForeground,
            t,
          )!,
          card: Color.lerp(card, other.card, t)!,
          accent: Color.lerp(accent, other.accent, t)!,
          background: Color.lerp(background, other.background, t)!,
          primary: Color.lerp(primary, other.primary, t)!,
          onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
          container: Color.lerp(container, other.container, t)!,
          onContainer: Color.lerp(onContainer, other.onContainer, t)!,
          isDark: t < .5 ? isDark : other.isDark,
        );
}

extension ThemeX on BuildContext {
  AssetlyColors get colors => Theme.of(this).extension<AssetlyColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
