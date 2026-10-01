import 'dart:io';

import 'package:beanclick/core/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// 版本号的**单一来源**守护。
///
/// 背景：0.2.0 的包在「关于豆刻」里、以及导出的 JSON 备份里都还自称 `0.1.0`
/// —— 三处各写了一份版本号，发版时全忘了改。现在只留 [kAppVersion] 一处，
/// 这个测试负责把它和 `pubspec.yaml` 钉死：
///
/// **只改 pubspec 而忘了改 [kAppVersion]，这里会直接红。**
void main() {
  group('应用信息', () {
    /// 从当前目录逐级向上找 `pubspec.yaml`（IDE 里从别处跑测试也能找到）。
    File? findPubspec() {
      Directory dir = Directory.current;
      for (int i = 0; i < 6; i++) {
        final File candidate = File(
          '${dir.path}${Platform.pathSeparator}pubspec.yaml',
        );
        if (candidate.existsSync()) return candidate;
        final Directory parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
      return null;
    }

    test('kAppVersion 与 pubspec.yaml 的 version 一致', () {
      final File? pubspec = findPubspec();
      expect(pubspec, isNotNull, reason: '应该在仓库里（能找到 pubspec.yaml）');

      final String? line = pubspec!
          .readAsLinesSync()
          .map((String l) => l.trim())
          .where((String l) => l.startsWith('version:'))
          .firstOrNull;
      expect(line, isNotNull, reason: 'pubspec.yaml 里必须有 version:');

      // `version: 0.2.0+2` → 展示版本 `0.2.0`（`+` 后面是构建号，不给用户看）。
      // 两边各留一个可选引号：pubspec 写成 `"0.2.0+2"` 时也能解析，
      // 否则会以"格式不对"的名义报错，把真正的原因（带了引号）盖掉。
      final RegExpMatch? match = RegExp(r'''^version:\s*"?([0-9][^"\s+]*)"?''')
          .firstMatch(line!);
      expect(match, isNotNull, reason: 'version 行的格式应当是 x.y.z[+构建号]');
      final String displayVersion = match!.group(1)!;

      expect(
        kAppVersion,
        displayVersion,
        reason:
            'pubspec.yaml 是 ${line.trim()}，而 kAppVersion 是 $kAppVersion。'
            '发版时两个都要改（lib/core/app_info.dart）。',
      );
    });

    test('版本号是 x.y.z 形式，且不带构建号', () {
      expect(kAppVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
      expect(kAppVersion, isNot(contains('+')));
    });
  });
}
