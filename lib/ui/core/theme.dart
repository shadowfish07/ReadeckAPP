// Copyright 2024 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  );

  static ThemeData lightTheme = ThemeData(
    colorScheme: _lightColorScheme,
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: ZoomPageTransitionsBuilder(
          // 修复路由返回时的 ink 动画残留问题
          allowEnterRouteSnapshotting: false,
        ),
      },
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _lightColorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: _lightColorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      insetPadding: const EdgeInsets.all(16.0),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    colorScheme: _darkColorScheme,
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: ZoomPageTransitionsBuilder(
          allowEnterRouteSnapshotting: false,
        ),
      },
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _darkColorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: _darkColorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      insetPadding: const EdgeInsets.all(16.0),
    ),
  );
}
