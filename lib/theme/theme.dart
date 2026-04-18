import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff745186),
      surfaceTint: Color(0xff745186),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xfff5d9ff),
      onPrimaryContainer: Color(0xff5a396d),
      secondary: Color(0xff68596e),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfff0dcf5),
      onSecondaryContainer: Color(0xff4f4255),
      tertiary: Color(0xff815252),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffdad9),
      onTertiaryContainer: Color(0xff663b3c),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff7fc),
      onSurface: Color(0xff1e1a1f),
      onSurfaceVariant: Color(0xff4b444d),
      outline: Color(0xff7d747e),
      outlineVariant: Color(0xffcec3ce),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff342f35),
      inversePrimary: Color(0xffe1b7f5),
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
      surfaceDim: Color(0xffe0d7df),
      surfaceBright: Color(0xfffff7fc),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffaf1f9),
      surfaceContainer: Color(0xfff5ebf3),
      surfaceContainerHigh: Color(0xffefe5ed),
      surfaceContainerHighest: Color(0xffe9e0e7),
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

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfffceaff),
      surfaceTint: Color(0xffe1b7f5),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffddb4f1),
      onPrimaryContainer: Color(0xff180027),
      secondary: Color(0xfffceaff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffcfbdd4),
      onSecondaryContainer: Color(0xff110717),
      tertiary: Color(0xffffeceb),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xfff0b3b4),
      onTertiaryContainer: Color(0xff1e0305),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff161217),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff8edf7),
      outlineVariant: Color(0xffcabfca),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e0e7),
      inversePrimary: Color(0xff5c3a6e),
      primaryFixed: Color(0xfff5d9ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffe1b7f5),
      onPrimaryFixedVariant: Color(0xff200034),
      secondaryFixed: Color(0xfff0dcf5),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffd3c0d8),
      onSecondaryFixedVariant: Color(0xff180d1d),
      tertiaryFixed: Color(0xffffdad9),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xfff4b7b8),
      onTertiaryFixedVariant: Color(0xff250709),
      surfaceDim: Color(0xff161217),
      surfaceBright: Color(0xff544e54),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff221e24),
      surfaceContainer: Color(0xff342f35),
      surfaceContainerHigh: Color(0xff3f3a40),
      surfaceContainerHighest: Color(0xff4a454b),
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


  List<ExtendedColor> get extendedColors => [
  ];
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
