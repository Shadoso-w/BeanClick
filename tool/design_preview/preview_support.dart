/// 设计稿渲染的公共部分（字体 + 主题）。
///
/// `flutter_test` 默认字体把**汉字和图标都渲染成方块**，所以中文字体与
/// Material 图标字体都要显式加载，否则出来的设计稿全是 □。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:beanclick/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;

const String _cjkFontPath = r'C:\Windows\Fonts\Deng.ttf';
const String _iconFontPath =
    r'D:\devtools\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf';

/// 预览用的字族名（主题里会把它套到 textTheme 上）。
const String previewFontFamily = 'PreviewCJK';

Future<void> _loadFontFile(String path, String family) async {
  final File file = File(path);
  if (!file.existsSync()) return;
  final Uint8List bytes = file.readAsBytesSync();
  final FontLoader loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// 在 `setUpAll` 里调用一次。
Future<void> loadPreviewFonts() async {
  await _loadFontFile(_cjkFontPath, previewFontFamily);
  // 图标字体的家族名必须是 'MaterialIcons'，否则 Icon 找不到字形。
  await _loadFontFile(_iconFontPath, 'MaterialIcons');
}

/// 真主题 + 中文字体，设计稿必须用这个渲染才能反映实际观感。
ThemeData previewTheme(Brightness brightness) {
  final ThemeData base = buildAppTheme(brightness);
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: previewFontFamily),
  );
}
