/// 第一批 UI 改动的**设计稿渲染**（mock，不是产品代码）。
///
/// 为什么是 mock：按 `docs/DEVELOPMENT.md` §13.1 的约定，UI 改动要先出稿定稿
/// 再写产品代码。这里用**真主题**（`buildAppTheme`）+ **真中文字体**把提案画出来，
/// 观感与实际界面一致；等你看过 PNG 点头，再改 `lib/features/...`。
///
/// 跑法（故意放在 `tool/` 而不是 `test/`，免得被 CI 当 golden 比对，
/// 跨平台字体差异会假红）：
///
/// ```powershell
/// flutter test tool/design_preview/batch1_previews_test.dart --update-goldens
/// ```
///
/// 产物：`tool/design_preview/goldens/batch1_previews.png`
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:beanclick/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

/// 预览用的字体。`flutter_test` 默认字体把**汉字和图标都渲染成方块**，
/// 所以中文字体和 Material 图标字体都要显式加载。
const String _cjkFontPath = r'C:\Windows\Fonts\Deng.ttf';
const String _iconFontPath =
    r'D:\devtools\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf';
const String _fontFamily = 'PreviewCJK';

Future<void> _loadFontFile(String path, String family) async {
  final File file = File(path);
  if (!file.existsSync()) return;
  final Uint8List bytes = file.readAsBytesSync();
  final FontLoader loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

Future<void> _loadFonts() async {
  await _loadFontFile(_cjkFontPath, _fontFamily);
  // 图标字体家族名必须是 'MaterialIcons'，否则 Icon 找不到字形。
  await _loadFontFile(_iconFontPath, 'MaterialIcons');
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('第一批 UI 改稿', (WidgetTester tester) async {
    // 画布要足够高，否则下半部分会被裁掉（golden 只截视口）。
    tester.view.physicalSize = const Size(760, 3760);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final ThemeData theme = buildAppTheme(Brightness.light).copyWith(
      textTheme: buildAppTheme(Brightness.light).textTheme
          .apply(fontFamily: _fontFamily),
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const _MockSheet(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(_MockSheet),
      matchesGoldenFile('goldens/batch1_previews.png'),
    );
  });
}

/// 一页纸：把改前 / 改后并排放，方便对比。
class _MockSheet extends StatelessWidget {
  const _MockSheet();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _SectionTitle('① 记录卡片标题：[B2] 豆子（方法）'),
            const _RowLabel('改前'),
            _MockLogCard(
              title: '黑猫拼配',
              showMethodChip: true,
              method: '手冲',
              grind: 'C40 / 22 click',
            ),
            const SizedBox(height: 12),
            const _RowLabel('改后（方法进标题，第二行去掉方法 chip）'),
            _MockLogCard(
              title: '黑猫拼配（拿铁）',
              showMethodChip: false,
              grind: 'C40 / 22 click',
            ),
            const SizedBox(height: 12),
            const _RowLabel('改后 · 拼配（主豆 + 其余，方法在最后）'),
            _MockLogCard(
              title: '黑猫拼配 + 花魁（拿铁）',
              showMethodChip: false,
              grind: 'C40 / 22 click',
              blend: '拼配 14 g + 6 g',
            ),

            const SizedBox(height: 28),
            const _SectionTitle('② [C1] 左滑露出「收藏 / 删除」'),
            const _RowLabel('左滑前'),
            _MockLogCard(
              title: '黑猫拼配（拿铁）',
              showMethodChip: false,
              grind: 'C40 / 22 click',
            ),
            const SizedBox(height: 12),
            const _RowLabel('左滑后（按钮在右侧，删除在最外侧）'),
            _MockSwipeOpen(
              title: '黑猫拼配（拿铁）',
              grind: 'C40 / 22 click',
              favorited: false,
            ),
            const SizedBox(height: 12),
            const _RowLabel('已收藏的那条（文案变「取消收藏」）'),
            _MockSwipeOpen(
              title: '花魁（手冲）',
              grind: 'C40 / 22 click',
              favorited: true,
            ),

            const SizedBox(height: 28),
            const _SectionTitle('③ [A3] 冲煮时间可选到时分'),
            const _RowLabel('改前（只有日期）'),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('2026年9月27日'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _RowLabel('改后（日期 + 时分两个按钮，点哪个改哪个）'),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('2026年9月27日'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: const Text('14:30'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const _SectionTitle('④ [A2] 日期弹窗中文化（示意）'),
            const _RowLabel(
              '文案由 Material 组件给出：月标题「2026年9月」、星期「日一二三四五六」、按钮「取消 / 确定」',
            ),
            const _MockDatePicker(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// 记录卡片的 mock：结构与 `record_page.dart` 的 `_BrewLogCard` 对齐。
class _MockLogCard extends StatelessWidget {
  const _MockLogCard({
    required this.title,
    required this.showMethodChip,
    this.method,
    this.grind,
    this.blend,
    this.favorited = false,
  });

  final String title;
  final bool showMethodChip;
  final String? method;
  final String? grind;
  final String? blend;
  final bool favorited;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (favorited) ...<Widget>[
                  Icon(Icons.bookmark_rounded, size: 18, color: colors.primary),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const _MockStars(4),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (showMethodChip) _MockChip(label: method ?? '手冲'),
                if (grind != null) Text(grind!, style: muted),
              ],
            ),
            if (blend != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(blend!, style: muted),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: <Widget>[
                _MockMetric(icon: Icons.scale_outlined, text: '15g / 240g'),
                _MockMetric(icon: Icons.thermostat_outlined, text: '92 ℃'),
                _MockMetric(icon: Icons.timer_outlined, text: '2:35'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.schedule, size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('3 天前 14:30', style: muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 左滑打开后的样子：卡片**整体左移 156**，右侧露出两个按钮。
///
/// 注意卡片宽度不变（真实实现是位移，不是被挤窄），
/// 否则标题会被截断，看起来比实际难看。
class _MockSwipeOpen extends StatelessWidget {
  const _MockSwipeOpen({
    required this.title,
    required this.grind,
    required this.favorited,
  });

  final String title;
  final String grind;
  final bool favorited;

  static const double _actionWidth = 78;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double shift = _actionWidth * 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: shift,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _MockAction(
                        icon: favorited
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        label: favorited ? '取消收藏' : '收藏',
                        color: colors.primary,
                      ),
                    ),
                    Expanded(
                      child: _MockAction(
                        icon: Icons.delete_outline,
                        label: '删除',
                        color: colors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-shift, 0),
            child: _MockLogCard(
              title: title,
              showMethodChip: false,
              grind: grind,
              favorited: favorited,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockAction extends StatelessWidget {
  const _MockAction({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 148,
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MockChip extends StatelessWidget {
  const _MockChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: colors.onSecondaryContainer),
      ),
    );
  }
}

class _MockMetric extends StatelessWidget {
  const _MockMetric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MockStars extends StatelessWidget {
  const _MockStars(this.rating);

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }
}

/// 中文日期弹窗的示意（真弹窗由 Material 组件渲染，这里只画结构）。
class _MockDatePicker extends StatelessWidget {
  const _MockDatePicker();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<String> weekdays = <String>['日', '一', '二', '三', '四', '五', '六'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('2026年9月', style: theme.textTheme.titleMedium),
                ),
                const Text('‹   ›'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                for (final String day in weekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (int week = 0; week < 2; week++)
              Row(
                children: <Widget>[
                  for (int day = 0; day < 7; day++)
                    Expanded(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.all(6),
                          decoration: week == 1 && day == 3
                              ? BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            '${week * 7 + day + 1}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: week == 1 && day == 3
                                  ? colors.onPrimary
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(onPressed: () {}, child: const Text('取消')),
                FilledButton(onPressed: () {}, child: const Text('确定')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
