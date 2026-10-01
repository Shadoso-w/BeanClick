/// 设计稿渲染的公共部分（字体查找 + 主题）。
///
/// `flutter_test` 默认字体把**汉字和图标都渲染成方块**，所以中文字体与
/// Material 图标字体都要显式加载，否则出来的设计稿全是 □。
///
/// ## 字体路径为什么是「查找」而不是写死
///
/// 原来这里写死过本机路径（`<盘符>:\Windows\Fonts\...` 与 Flutter 安装目录下的
/// 图标字体）。那属于「把本机环境写进公开仓库」：换台机器照抄就加载不到，
/// 而字体位置本来就因系统 / 安装方式而异。
///
/// 现在按候选列表**逐个探测**，并允许用环境变量覆盖：
/// - 中文字体：`BEANCLICK_PREVIEW_CJK_FONT` → 常见系统字体候选
/// - 图标字体：`BEANCLICK_PREVIEW_ICON_FONT` → 从 `FLUTTER_ROOT` / PATH 里的
///   `flutter` 可执行文件推导
///
/// 探测不到时**不抛异常**，但会在 stderr 说明缺的是哪一个（见 [loadPreviewFonts]）；
/// 设计稿会因此渲染成方块，于是 golden 比对不匹配 —— 这就是"这台机器缺字体"的信号。
///
/// 字体属于「因机器而异」的东西，所以只探测、不写死路径。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:beanclick/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;

/// 预览用的字族名（主题里会把它套到 textTheme 上）。
const String previewFontFamily = 'PreviewCJK';

/// 渲染稿内容 Column 的 key。
///
/// golden 必须截**它**，而不是整个 `Scaffold`：`SingleChildScrollView` 会把超出
/// 视口的内容裁掉，而**被裁掉的内容 golden 永远比不出来** —— 加了新段落却忘记
/// 抬高画布时，图上会少一段而测试依然全绿（本项目真踩过：M2.10 渲染稿的
/// 「⑧ 记录卡片」整段消失且无人发现）。截内容本身时，它的高度 = 实际内容高度，
/// 画布给多大都不会漏，也不会在图里留下空白带。
const Key previewSheetKey = Key('preview.sheetContent');

/// Windows 系统字体文件名候选（按优先级，相对于 Windows 的 Fonts 目录）。
const List<String> _windowsFontFiles = <String>[
  'Deng.ttf',
  'msyh.ttc',
  'simhei.ttf',
  'simsun.ttc',
];

/// 非 Windows 的常见中文字体候选。
const List<String> _unixFonts = <String>[
  '/System/Library/Fonts/PingFang.ttc',
  '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
];

/// 图标字体相对 Flutter 根目录的路径。
///
/// 用**正斜杠**：`File` 在 Windows 上也接受它，而反斜杠在类 Unix 上是合法
/// 文件名字符 —— 拼出来会是一个永远不存在的路径，导致非 Windows 上必然探测失败。
const String _iconFontRelative =
    'bin/cache/artifacts/material_fonts/materialicons-regular.otf';

File? _firstExisting(Iterable<String> paths) {
  for (final String path in paths) {
    final File file = File(path);
    if (file.existsSync()) return file;
  }
  return null;
}

File? _existingFile(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final File file = File(path.trim());
  return file.existsSync() ? file : null;
}

/// 中文字体：环境变量优先，其次系统字体候选。
File? findPreviewCjkFont() {
  final File? override = _existingFile(
    Platform.environment['BEANCLICK_PREVIEW_CJK_FONT'],
  );
  if (override != null) return override;

  if (Platform.isWindows) {
    // 先看系统装在哪（`SystemRoot` 一般是 `<盘符>:\Windows`），再回落常见盘符 ——
    // 免得系统不在 C 盘时错选到 C 盘的同名文件。
    final List<String> windowsDirs = <String>[];
    final String? systemRoot = Platform.environment['SystemRoot'];
    if (systemRoot != null && systemRoot.trim().isNotEmpty) {
      windowsDirs.add(systemRoot.trim());
    }
    for (final String drive in <String>['C:', 'D:']) {
      windowsDirs.add('$drive\\Windows');
    }

    final List<String> candidates = <String>[];
    for (final String dir in windowsDirs) {
      for (final String file in _windowsFontFiles) {
        candidates.add('$dir\\Fonts\\$file');
      }
    }
    return _firstExisting(candidates);
  }
  return _firstExisting(_unixFonts);
}

/// 图标字体：环境变量 → `FLUTTER_ROOT` → PATH 里的 `flutter` 反推根目录。
File? findPreviewIconFont() {
  final File? override = _existingFile(
    Platform.environment['BEANCLICK_PREVIEW_ICON_FONT'],
  );
  if (override != null) return override;

  final List<String> roots = <String>[];
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.trim().isNotEmpty) {
    roots.add(flutterRoot.trim());
  }
  final String? flutterExe = _flutterExecutable();
  if (flutterExe != null) {
    // `<flutter>/bin/flutter` → `<flutter>`
    roots.add(Directory(flutterExe).parent.parent.path);
  }

  return _firstExisting(
    roots.map(
      (String root) => '$root${Platform.pathSeparator}$_iconFontRelative',
    ),
  );
}

/// 从 PATH 里找 `flutter` 可执行文件（找不到返回 null）。
String? _flutterExecutable() {
  final String? path = Platform.environment['PATH'];
  if (path == null) return null;
  final List<String> extensions = Platform.isWindows
      ? <String>['.bat', '.exe', '']
      : <String>[''];
  for (final String dir in path.split(Platform.isWindows ? ';' : ':')) {
    if (dir.trim().isEmpty) continue;
    for (final String ext in extensions) {
      final String candidate =
          '${dir.trim()}${Platform.pathSeparator}flutter$ext';
      if (File(candidate).existsSync()) return candidate;
    }
  }
  return null;
}

Future<void> _loadFontFile(File? file, String family) async {
  if (file == null) return;
  final Uint8List bytes = file.readAsBytesSync();
  final FontLoader loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// 在 `setUpAll` 里调用一次。
///
/// 缺字体时**不抛异常**，但会在 stderr 上说明缺的是哪一个 —— 失败模式是
/// "golden 不匹配"，光看差异图分不清是"缺字体"还是"UI 真改了"，
/// 一行诊断能把这两者区分开（stderr 不参与渲染，不会进 golden）。
Future<void> loadPreviewFonts() async {
  final File? cjk = findPreviewCjkFont();
  final File? icon = findPreviewIconFont();
  if (cjk == null) {
    stderr.writeln('[preview] 没找到中文字体，可用 BEANCLICK_PREVIEW_CJK_FONT 指定绝对路径');
  }
  if (icon == null) {
    stderr.writeln(
      '[preview] 没找到 Material 图标字体，可用 BEANCLICK_PREVIEW_ICON_FONT 指定绝对路径',
    );
  }
  await _loadFontFile(cjk, previewFontFamily);
  // 图标字体的家族名必须是 'MaterialIcons'，否则 Icon 找不到字形。
  await _loadFontFile(icon, 'MaterialIcons');
}

/// 真主题 + 中文字体，设计稿必须用这个渲染才能反映实际观感。
ThemeData previewTheme(Brightness brightness) {
  final ThemeData base = buildAppTheme(brightness);
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: previewFontFamily),
  );
}
