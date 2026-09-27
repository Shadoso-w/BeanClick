import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'features/shell/home_shell.dart';

/// 主色：咖啡棕。
const Color _seedColor = Color(0xFF6F4E37);

/// 浅色模式背景：米白。
const Color _lightSurface = Color(0xFFFAF6F0);

/// 深色模式背景：深棕黑。
const Color _darkSurface = Color(0xFF1C1613);

/// 豆刻根组件：负责主题与首页外壳。
///
/// 主题模式来自 `themeModeProvider`（数据层监听 Settings 表），
/// 设置页写入后 MaterialApp 会自动重建；读不到时回落到 [ThemeMode.system]
/// （手册 §6.3 默认值）。
class BeanClickApp extends ConsumerWidget {
  const BeanClickApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode =
        ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return MaterialApp(
      title: '豆刻 BeanClick',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}

/// 棕黑为主、灰度较低的简约主题（手册 §9）。
///
/// 浅色用米白背景、深色用深棕黑背景，并显式给出一组暖调 surface 层级；
/// `fidelity` 变体保留种子色的暖调，避免默认变体把咖啡棕冲淡成灰调。
/// 字体一律使用系统默认，不额外指定 fontFamily。
///
/// 公开出来是给 `tool/design_preview/` 的设计稿渲染用：设计稿必须用**真主题**
/// 渲染，否则配色和间距会和实际界面不一致。
ThemeData buildAppTheme(Brightness brightness) {
  final bool isLight = brightness == Brightness.light;
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    surface: isLight ? _lightSurface : _darkSurface,
    surfaceContainerLowest: isLight
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF14100D),
    surfaceContainerLow: isLight
        ? const Color(0xFFF5EFE6)
        : const Color(0xFF241D19),
    surfaceContainer: isLight
        ? const Color(0xFFEFE8DE)
        : const Color(0xFF2A231E),
    surfaceContainerHigh: isLight
        ? const Color(0xFFE9E1D6)
        : const Color(0xFF352C25),
    surfaceContainerHighest: isLight
        ? const Color(0xFFE2D9CD)
        : const Color(0xFF41352D),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isLight
          ? const Color(0xFFF3EBE1)
          : const Color(0xFF221B17),
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: isLight ? const Color(0xFFF5EFE6) : const Color(0xFF2A231E),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
