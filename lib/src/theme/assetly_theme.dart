import 'package:flutter/material.dart';

class AssetlyTheme {
  static const zinc = Color(0xFF18181B);
  static const emerald = Color(0xFF10B981);

  static ThemeData light(Color accent) => _theme(
    Brightness.light,
    const Color(0xFFFFFFFF),
    const Color(0xFF09090B),
    const Color(0xFFFFFFFF),
    const Color(0xFFE4E4E7),
    const Color(0xFFF4F4F5),
    const Color(0xFF71717A),
    accent,
  );
  static ThemeData dark(Color accent) => _theme(
    Brightness.dark,
    const Color(0xFF09090B),
    const Color(0xFFFAFAFA),
    const Color(0xFF18181B),
    const Color(0xFF27272A),
    const Color(0xFF27272A),
    const Color(0xFFA1A1AA),
    accent,
  );

  static ThemeData _theme(
    Brightness brightness,
    Color background,
    Color foreground,
    Color card,
    Color border,
    Color muted,
    Color mutedForeground,
    Color accent,
  ) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: foreground,
      onPrimary: background,
      secondary: muted,
      onSecondary: foreground,
      error: const Color(0xFFE11D48),
      onError: Colors.white,
      surface: background,
      onSurface: foreground,
      outline: border,
      tertiary: accent,
      onTertiary: Colors.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamilyFallback: const [
        'SF Pro Text',
        'PingFang SC',
        'Noto Sans CJK SC',
      ],
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: 30,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
          color: foreground,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
          color: foreground,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -.25,
          color: foreground,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
        bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: foreground),
        bodyMedium: TextStyle(fontSize: 13, height: 1.4, color: foreground),
        bodySmall: TextStyle(
          fontSize: 11.5,
          height: 1.35,
          color: mutedForeground,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      dividerColor: border,
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: muted,
        isDense: true,
        hintStyle: TextStyle(color: mutedForeground, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: foreground, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: card,
        elevation: 0,
        indicatorColor: muted,
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        modalBackgroundColor: card,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: foreground,
        contentTextStyle: TextStyle(color: background),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: [
        AssetlyColors(
          border: border,
          muted: muted,
          mutedForeground: mutedForeground,
          card: card,
          accent: accent,
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
  });
  final Color border, muted, mutedForeground, card, accent;
  @override
  AssetlyColors copyWith({
    Color? border,
    Color? muted,
    Color? mutedForeground,
    Color? card,
    Color? accent,
  }) => AssetlyColors(
    border: border ?? this.border,
    muted: muted ?? this.muted,
    mutedForeground: mutedForeground ?? this.mutedForeground,
    card: card ?? this.card,
    accent: accent ?? this.accent,
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
        );
}

extension ThemeX on BuildContext {
  AssetlyColors get colors => Theme.of(this).extension<AssetlyColors>()!;
}
