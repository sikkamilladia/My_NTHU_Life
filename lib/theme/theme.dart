import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  // static ColorScheme lightScheme() {
  //   return const ColorScheme(
  //     brightness: Brightness.light,
  //     primary: Color(0xff745186),
  //     surfaceTint: Color(0xff745186),
  //     onPrimary: Color(0xffffffff),
  //     primaryContainer: Color(0xfff5d9ff),
  //     onPrimaryContainer: Color(0xff5a396d),
  //     secondary: Color(0xff68596e),
  //     onSecondary: Color(0xffffffff),
  //     secondaryContainer: Color(0xfff0dcf5),
  //     onSecondaryContainer: Color(0xff4f4255),
  //     tertiary: Color(0xff815252),
  //     onTertiary: Color(0xffffffff),
  //     tertiaryContainer: Color(0xffffdad9),
  //     onTertiaryContainer: Color(0xff663b3c),
  //     error: Color(0xffba1a1a),
  //     onError: Color(0xffffffff),
  //     errorContainer: Color(0xffffdad6),
  //     onErrorContainer: Color(0xff93000a),
  //     surface: Color(0xfffff7fc),
  //     onSurface: Color(0xff1e1a1f),
  //     onSurfaceVariant: Color(0xff4b444d),
  //     outline: Color(0xff7d747e),
  //     outlineVariant: Color(0xffcec3ce),
  //     shadow: Color(0xff000000),
  //     scrim: Color(0xff000000),
  //     inverseSurface: Color(0xff342f35),
  //     inversePrimary: Color(0xffe1b7f5),
  //     primaryFixed: Color(0xfff5d9ff),
  //     onPrimaryFixed: Color(0xff2c0b3e),
  //     primaryFixedDim: Color(0xffe1b7f5),
  //     onPrimaryFixedVariant: Color(0xff5a396d),
  //     secondaryFixed: Color(0xfff0dcf5),
  //     onSecondaryFixed: Color(0xff221728),
  //     secondaryFixedDim: Color(0xffd3c0d8),
  //     onSecondaryFixedVariant: Color(0xff4f4255),
  //     tertiaryFixed: Color(0xffffdad9),
  //     onTertiaryFixed: Color(0xff331113),
  //     tertiaryFixedDim: Color(0xfff4b7b8),
  //     onTertiaryFixedVariant: Color(0xff663b3c),
  //     surfaceDim: Color(0xffe0d7df),
  //     surfaceBright: Color(0xfffff7fc),
  //     surfaceContainerLowest: Color(0xffffffff),
  //     surfaceContainerLow: Color(0xfffaf1f9),
  //     surfaceContainer: Color(0xfff5ebf3),
  //     surfaceContainerHigh: Color(0xffefe5ed),
  //     surfaceContainerHighest: Color(0xffe9e0e7),
  //   );
  // }

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,

      // ── Primary (Purple Accent) ──
      primary: Color(0xff5A189A),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color.fromARGB(
        255,
        58,
        19,
        92,
      ), // same role: chip, badge, icon color
      onPrimaryContainer: Color(0xffffffff),
      primaryFixed: Color(0xffF0D9FF),
      onPrimaryFixed: Color(0xff1a0030),
      primaryFixedDim: Color(0xffC77DFF),
      onPrimaryFixedVariant: Color(0xff3b0077),
      surfaceTint: Color(0xff7B2CBF),

      // ── Secondary ──
      secondary: Color(0xff6B4F80),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffEEDCFF),
      onSecondaryContainer: Color(0xff2a1040),
      secondaryFixed: Color(0xffE8D5F5),
      onSecondaryFixed: Color(0xff1f0a30),
      secondaryFixedDim: Color(0xffC9ADDE),
      onSecondaryFixedVariant: Color(0xff3d1f55),

      // ── Tertiary ──
      tertiary: Color(0xff1A6B6E),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffD0F0F2),
      onTertiaryContainer: Color(0xff002B2D),
      tertiaryFixed: Color(0xffD0F0F2),
      onTertiaryFixed: Color(0xff002B2D),
      tertiaryFixedDim: Color(0xff8ED4D7),
      onTertiaryFixedVariant: Color(0xff004F52),

      // ── Error ──
      errorContainer: Color(0xffFFE5E5),
      onErrorContainer: Color(0xff410002),
      error: Color(0xffBA1A1A),
      onError: Color(0xffffffff),

      // ── Surface Stack ──
      surface: Color(0xffFBF7FF), // scaffold background (warm white)
      onSurface: Color(0xff1C1A22), // body text — near black
      onSurfaceVariant: Color(0xff4A4550), // subtitle / muted text
      surfaceDim: Color(0xffE8E0F0),
      surfaceBright: Color(0xffE8DFFF), // pure purple tint, no pink
      surfaceContainerLow: Color(0xffF2ECFF), // cooler purple, no pink
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainer: Color(0xffECE2F8), // mid container
      surfaceContainerHigh: Color(0xffE4D8F5), // input fill
      surfaceContainerHighest: Color(0xffDDD0EE),

      // ── Borders & Outlines ──
      outline: Color(0xff7B2CBF), // FAB, active border (same as dark)
      outlineVariant: Color(0xffCEB8E8), // subtle card border
      // ── Misc ──
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff1C1A22),
      inversePrimary: Color.fromARGB(
        255,
        100,
        45,
        145,
      ), // section label purple (same as dark)
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff49285b),
      surfaceTint: Color(0xff745186),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff835f96),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff3e3244),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff77687d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff532a2c),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff926061),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff7fc),
      onSurface: Color(0xff141015),
      onSurfaceVariant: Color(0xff3a343c),
      outline: Color(0xff575059),
      outlineVariant: Color(0xff726a74),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff342f35),
      inversePrimary: Color(0xffe1b7f5),
      primaryFixed: Color(0xff835f96),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff69477c),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff77687d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff5e5064),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff926061),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff764849),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffccc4cb),
      surfaceBright: Color(0xfffff7fc),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffaf1f9),
      surfaceContainer: Color(0xffefe5ed),
      surfaceContainerHigh: Color(0xffe3dae2),
      surfaceContainerHighest: Color(0xffd8cfd6),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff3e1e50),
      surfaceTint: Color(0xff745186),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff5d3b70),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff34283a),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff524458),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff472122),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff693d3e),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff7fc),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff302a32),
      outlineVariant: Color(0xff4e474f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff342f35),
      inversePrimary: Color(0xffe1b7f5),
      primaryFixed: Color(0xff5d3b70),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff452557),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff524458),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff3b2e40),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff693d3e),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff4f2728),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbeb6be),
      surfaceBright: Color(0xfffff7fc),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7eef6),
      surfaceContainer: Color(0xffe9e0e7),
      surfaceContainerHigh: Color(0xffdbd2d9),
      surfaceContainerHighest: Color(0xffccc4cb),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffe1b7f5),
      surfaceTint: Color(0xffe1b7f5),
      onPrimary: Color(0xff422255),
      primaryContainer: Color(0xff5a396d),
      onPrimaryContainer: Color(0xfff5d9ff),
      secondary: Color(0xffd3c0d8),
      onSecondary: Color(0xff382c3e),
      secondaryContainer: Color(0xff4f4255),
      onSecondaryContainer: Color(0xfff0dcf5),
      tertiary: Color(0xfff4b7b8),
      onTertiary: Color(0xff4c2526),
      tertiaryContainer: Color(0xff663b3c),
      onTertiaryContainer: Color(0xffffdad9),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff161217),
      onSurface: Color(0xffe9e0e7),
      onSurfaceVariant: Color(0xffcec3ce),
      outline: Color(0xff978e98),
      outlineVariant: Color(0xff4b444d),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e0e7),
      inversePrimary: Color(0xff745186),
      primaryFixed: Color(0xfff5d9ff),
      onPrimaryFixed: Color(0xff2c0b3e),
      primaryFixedDim: Color(0xffe1b7f5),
      onPrimaryFixedVariant: Color(0xff5a396d),
      secondaryFixed: Color(0xfff0dcf5),
      onSecondaryFixed: Color(0xff221728),
      secondaryFixedDim: Color(0xffd3c0d8),
      onSecondaryFixedVariant: Color(0xff4f4255),
      tertiaryFixed: Color(0xffffdad9),
      onTertiaryFixed: Color(0xff331113),
      tertiaryFixedDim: Color(0xfff4b7b8),
      onTertiaryFixedVariant: Color(0xff663b3c),
      surfaceDim: Color(0xff161217),
      surfaceBright: Color(0xff3c383d),
      surfaceContainerLowest: Color(0xff110d12),
      surfaceContainerLow: Color(0xff1e1a1f),
      surfaceContainer: Color(0xff221e24),
      surfaceContainerHigh: Color(0xff2d282e),
      surfaceContainerHighest: Color(0xff383339),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff2d1ff),
      surfaceTint: Color(0xffe1b7f5),
      onPrimary: Color(0xff371749),
      primaryContainer: Color(0xffa982bc),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffe9d6ee),
      onSecondary: Color(0xff2d2133),
      secondaryContainer: Color(0xff9c8ba1),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffffd1d1),
      onTertiary: Color(0xff3f1a1c),
      tertiaryContainer: Color(0xffb98383),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff161217),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffe4d9e4),
      outline: Color(0xffb9afb9),
      outlineVariant: Color(0xff968d97),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e0e7),
      inversePrimary: Color(0xff5c3a6e),
      primaryFixed: Color(0xfff5d9ff),
      onPrimaryFixed: Color(0xff200034),
      primaryFixedDim: Color(0xffe1b7f5),
      onPrimaryFixedVariant: Color(0xff49285b),
      secondaryFixed: Color(0xfff0dcf5),
      onSecondaryFixed: Color(0xff180d1d),
      secondaryFixedDim: Color(0xffd3c0d8),
      onSecondaryFixedVariant: Color(0xff3e3244),
      tertiaryFixed: Color(0xffffdad9),
      onTertiaryFixed: Color(0xff250709),
      tertiaryFixedDim: Color(0xfff4b7b8),
      onTertiaryFixedVariant: Color(0xff532a2c),
      surfaceDim: Color(0xff161217),
      surfaceBright: Color(0xff484349),
      surfaceContainerLowest: Color(0xff09060b),
      surfaceContainerLow: Color(0xff201c22),
      surfaceContainer: Color(0xff2b262c),
      surfaceContainerHigh: Color(0xff363137),
      surfaceContainerHighest: Color(0xff413c42),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  // static ColorScheme darkHighContrastScheme() {
  //   return const ColorScheme(
  //     brightness: Brightness.dark,
  //     primary: Color(0xfffceaff),
  //     surfaceTint: Color(0xffe1b7f5),
  //     onPrimary: Color(0xff000000),
  //     primaryContainer: Color(0xffddb4f1),
  //     onPrimaryContainer: Color(0xff180027),
  //     secondary: Color(0xfffceaff),
  //     onSecondary: Color(0xff000000),
  //     secondaryContainer: Color(0xffcfbdd4),
  //     onSecondaryContainer: Color(0xff110717),
  //     tertiary: Color(0xffffeceb),
  //     onTertiary: Color(0xff000000),
  //     tertiaryContainer: Color(0xfff0b3b4),
  //     onTertiaryContainer: Color(0xff1e0305),
  //     error: Color(0xffffece9),
  //     onError: Color(0xff000000),
  //     errorContainer: Color(0xffffaea4),
  //     onErrorContainer: Color(0xff220001),
  //     surface: Color(0xff0B090A),
  //     onSurface: Color(0xffE9E0E7),
  //     onSurfaceVariant: Color(0xff9E9299),
  //     outline: Color(0xff7B2CBF),
  //     outlineVariant: Color(0xff240046),
  //     shadow: Color(0xff000000),
  //     scrim: Color(0xff000000),
  //     inverseSurface: Color(0xffe9e0e7),
  //     inversePrimary: Color(0xff5c3a6e),
  //     primaryFixed: Color(0xfff5d9ff),
  //     onPrimaryFixed: Color(0xff000000),
  //     primaryFixedDim: Color(0xffe1b7f5),
  //     onPrimaryFixedVariant: Color(0xff200034),
  //     secondaryFixed: Color(0xfff0dcf5),
  //     onSecondaryFixed: Color(0xff000000),
  //     secondaryFixedDim: Color(0xffd3c0d8),
  //     onSecondaryFixedVariant: Color(0xff180d1d),
  //     tertiaryFixed: Color(0xffffdad9),
  //     onTertiaryFixed: Color(0xff000000),
  //     tertiaryFixedDim: Color(0xfff4b7b8),
  //     onTertiaryFixedVariant: Color(0xff250709),
  //     surfaceDim: Color(0xff0B090A),
  //     surfaceBright: Color(0xff3C096C),
  //     surfaceContainerLowest: Color(0xff110d12),
  //     surfaceContainerLow: Color(0xff16121E),
  //     surfaceContainer: Color(0xff1E1A24),
  //     surfaceContainerHigh: Color(0xff241E2E),
  //     surfaceContainerHighest: Color(0xff2D2838),
  //   );
  // }
  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,

      // ── Primary (Purple Accent) ──
      primary: Color(0xfffceaff), // High-contrast primary text/icon
      onPrimary: Color(0xff000000), // Text on primary
      primaryContainer: Color(0xffC77DFF), // Neon light purple (chip, badge bg)
      onPrimaryContainer: Color(0xff180027), // Text on primaryContainer
      primaryFixed: Color(0xfff5d9ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffe1b7f5),
      onPrimaryFixedVariant: Color(0xff200034),
      surfaceTint: Color(0xffe1b7f5),

      // ── Secondary ──
      secondary: Color(0xfffceaff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffcfbdd4),
      onSecondaryContainer: Color(0xff110717),
      secondaryFixed: Color(0xfff0dcf5),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffd3c0d8),
      onSecondaryFixedVariant: Color(0xff180d1d),

      // ── Tertiary ──
      tertiary: Color(0xffffeceb),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xfff0b3b4),
      onTertiaryContainer: Color(0xff1e0305),
      tertiaryFixed: Color(0xffffdad9),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xfff4b7b8),
      onTertiaryFixedVariant: Color(0xff250709),

      // ── Error ──
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),

      // ── Surface Stack (matches task_list_page aesthetic) ──
      surface: Color(0xff0B090A), // bgBlack — scaffold background
      onSurface: Color(0xffE9E0E7), // Body text (cards, titles)
      onSurfaceVariant: Color(0xff9E9299), // Subtitle / icon (grey.shade500)
      surfaceDim: Color(0xff0B090A), // Same as surface (true abyss)
      surfaceBright: Color(0xff3C096C), // Selected-day highlight purple
      surfaceContainerLowest: Color(0xff110d12), // Deepest layer
      surfaceContainerLow: Color(
        0xff16121E,
      ), // cardDarkPurple — card & dialog bg
      surfaceContainer: Color(0xff1E1A24), // Mid-level container
      surfaceContainerHigh: Color(0xff241E2E), // Input fill / dropdown bg
      surfaceContainerHighest: Color(0xff2D2838), // Cancel button / top layer
      // ── Borders & Outlines ──
      outline: Color.fromARGB(
        255,
        152,
        55,
        236,
      ), // Active/focus border, FAB color
      outlineVariant: Color(0xff240046), // Subtle card border
      // ── Misc ──
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e0e7),
      inversePrimary: Color(0xff9D4EDD), // Section label purple
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.background,
    canvasColor: colorScheme.surface,
  );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
