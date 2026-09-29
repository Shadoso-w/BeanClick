/// M2.10 研磨刻度栏改稿的**渲染稿**（mock，不是产品代码）。
///
/// 跑法（故意放 `tool/` 而不是 `test/`，免得被 CI 当 golden 比对）：
///
/// ```powershell
/// flutter test tool/design_preview/grind_scale_previews_test.dart --update-goldens
/// ```
///
/// 产物：`tool/design_preview/goldens/grind_scale_previews.png`
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'preview_support.dart';

void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('M2.10 研磨刻度改稿', (WidgetTester tester) async {
    // 画布高度必须够大：SingleChildScrollView 只截到视口，小了就只剩上半张。
    tester.view.physicalSize = const Size(780, 5400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: previewTheme(Brightness.light),
        home: const _GrindSheet(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(_GrindSheet),
      matchesGoldenFile('goldens/grind_scale_previews.png'),
    );
  });
}

class _GrindSheet extends StatelessWidget {
  const _GrindSheet();

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
            const _Title('M2.10 研磨刻度栏：圈 / click 输入 + 相对刻度'),
            const _Label(
              '公式：相对刻度 = 圈 × 每圈 click + click - 零点（减零点）'
              ' · 单位一律 click · 算式收进 (i)',
            ),

            const SizedBox(height: 18),
            const _Title('① 表单（正常态）'),
            const _Label('改前：标签是「圈」，单位只在 hint 里，提示行给绝对刻度'),
            const _MockSection(
              child: _Field(
                label: '研磨刻度',
                helper: '绝对刻度 60（零点 0 + 1.5 圈 × 30 + 15 click）',
                left: _Box(text: '1.5', hint: '例如：1.5'),
                right: _Box(text: '15', hint: 'click'),
              ),
            ),
            const _Label('改后：单位写进框里，提示行只留相对刻度，算式进 (i)'),
            const _MockSection(
              child: _Field(
                label: '研磨刻度',
                info: true,
                helper: '相对刻度 40 click',
                left: _Box(text: '1', suffix: '圈'),
                right: _Box(text: '15', suffix: 'click'),
              ),
            ),

            const SizedBox(height: 18),
            const _Title('② 点 (i) 弹「怎么算的」'),
            const _MockDialog(),

            const SizedBox(height: 18),
            const _Title('③ 表单（零点不为 0）'),
            const _Label('零点 5、每圈 30：1 圈 + 5 click → 1 × 30 + 5 - 5 = 30'),
            const _MockSection(
              child: _Field(
                label: '研磨刻度',
                info: true,
                helper: '相对刻度 30 click',
                left: _Box(text: '1', suffix: '圈'),
                right: _Box(text: '5', suffix: 'click'),
              ),
            ),
            const _Label('对照：0.1.0 的「加零点」会得出 40（错的符号）'),
            const _MockSection(
              child: _Field(
                label: '研磨刻度',
                info: true,
                muted: true,
                helper: '绝对刻度 40',
                left: _Box(text: '1', suffix: '圈'),
                right: _Box(text: '5', suffix: 'click'),
              ),
            ),

            const SizedBox(height: 18),
            const _Title('④ 只填了其中一个框'),
            const _Label('只填圈：click 按 0 算；只填 click：圈按 0 算'),
            const _MockSection(
              child: Column(
                children: <Widget>[
                  _Field(
                    label: '研磨刻度',
                    info: true,
                    helper: '相对刻度 15 click',
                    left: _Box(text: '', suffix: '圈'),
                    right: _Box(text: '', hint: 'click'),
                  ),
                  SizedBox(height: 16),
                  _Field(
                    label: '研磨刻度',
                    info: true,
                    helper: '相对刻度 15 click',
                    left: _Box(text: '', hint: '圈'),
                    right: _Box(text: '15', suffix: 'click'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            const _Title('⑤ 存量旧磨豆机缺「每圈几 click」'),
            const _Label('不瞎算，给一句话让人去补填'),
            const _MockSection(
              child: _Field(
                label: '研磨刻度',
                info: true,
                warn: true,
                helper: '这台磨豆机还没填「每圈几 click」，去磨豆机编辑页补上就能换算',
                left: _Box(text: '2', suffix: '圈'),
                right: _Box(text: '2', suffix: 'click'),
              ),
            ),

            const SizedBox(height: 18),
            const _Title('⑥ 「圈」只收正整数（第 5 条要求）'),
            const _Label('合法：留空 = 0 圈（机器停在第 1 圈以内时就这样填）'),
            const _MockSection(
              child: Column(
                children: <Widget>[
                  _Field(
                    label: '研磨刻度',
                    info: true,
                    helper: '相对刻度 45 click',
                    left: _Box(text: '1', suffix: '圈'),
                    right: _Box(text: '15', suffix: 'click'),
                  ),
                  SizedBox(height: 16),
                  _Field(
                    label: '研磨刻度',
                    info: true,
                    helper: '相对刻度 15 click',
                    left: _Box(text: '', hint: '留空'),
                    right: _Box(text: '15', suffix: 'click'),
                  ),
                ],
              ),
            ),
            const _Label('非法：0 / 小数 / 负数 → 红字提醒 + 保存被拦下'),
            const _MockSection(
              child: Column(
                children: <Widget>[
                  _Field(
                    label: '研磨刻度',
                    info: true,
                    invalid: true,
                    helper: '圈只能是正整数（1、2、3…）；不到一圈请留空，把 click 填在右边',
                    left: _Box(text: '0', suffix: '圈', invalid: true),
                    right: _Box(text: '15', suffix: 'click'),
                  ),
                  SizedBox(height: 16),
                  _Field(
                    label: '研磨刻度',
                    info: true,
                    invalid: true,
                    helper: '圈只能是正整数（1、2、3…）；不到一圈请留空，把 click 填在右边',
                    left: _Box(text: '1.5', suffix: '圈', invalid: true),
                    right: _Box(text: '15', suffix: 'click'),
                  ),
                ],
              ),
            ),
            const _Label('输入阶段就挡住：整数键盘 + digitsOnly，打不出小数点与负号'),
            const _Label('旧记录的小数圈数自动折算：1.5 圈（每圈 30）→ 1 圈 + 15 click'),
            const _MockSection(
              child: _Field(
                label: '研磨刻度',
                info: true,
                helper: '相对刻度 45 click（旧读数 1.5 圈已折算）',
                left: _Box(text: '1', suffix: '圈'),
                right: _Box(text: '15', suffix: 'click'),
              ),
            ),

            const SizedBox(height: 18),
            const _Title('⑦ 磨豆机表单：每圈 click 改必填'),
            _MockSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '每圈 click *',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  _Box(text: '30', suffix: 'click', hint: '例如：30（C40 是 30）'),
                  const SizedBox(height: 4),
                  const _Error('请填写每圈 click —— 记录里要用它把圈数换算成 click'),
                ],
              ),
            ),

            const SizedBox(height: 22),
            const _Title('⑧ 记录卡片（「这一杯」展示栏）'),
            const _Label('改前：第一行 = 豆名 + 方法 + 星，第二行两段 click'),
            const _MockSection(
              child: Column(
                children: <Widget>[
                  _CardRow(
                    first: '耶菲雪加  [拿铁]            ☆☆☆☆',
                    second: 'mavo 巫师2 / 22 click + 15 click',
                  ),
                  SizedBox(height: 12),
                  _CardRow(
                    first: '黑猫拼配 + 花魁  [意式浓缩]   ☆☆☆',
                    second: 'C40 / 6.5 刻度 + 2 click / 零点 0',
                  ),
                ],
              ),
            ),
            const _Label('改后：第二行只留「磨豆机 · 相对刻度」，第一行不动（方法 chip 留在第一行）'),
            const _MockSection(
              child: Column(
                children: <Widget>[
                  _CardRow(
                    first: '耶菲雪加  [拿铁]          ☆☆☆☆',
                    second: 'mavo 巫师2 · 相对刻度 75 click',
                  ),
                  SizedBox(height: 12),
                  _CardRow(
                    first: '黑猫拼配 + 花魁  [意式浓缩]  ☆☆☆',
                    second: 'C40 · 相对刻度 32 click',
                  ),
                ],
              ),
            ),
            const _Label('没有磨豆机的记录：第二行是「未记录研磨刻度」，第一行照旧'),
            const _MockSection(
              child: _CardRow(
                first: '耶菲雪加  [拿铁]          ☆☆☆☆',
                second: '未记录研磨刻度',
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                '定稿：减零点 · 每圈 click 必填 · 单位一律 click · 算式进 ⓘ · '
                '缺值给提示 · 方法 chip 留第一行',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _MockSection extends StatelessWidget {
  const _MockSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

/// 复刻 `LabeledField`：标签（可带 ⓘ）在左上、控件、提示文字。
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.helper,
    required this.left,
    required this.right,
    this.info = false,
    this.warn = false,
    this.invalid = false,
    this.muted = false,
  });

  final String label;
  final String helper;
  final Widget left;
  final Widget right;
  final bool info;

  /// 警示语气（缺每圈 click）。
  final bool warn;

  /// 校验失败（圈不是正整数）：提示用 error 色。
  final bool invalid;

  /// 灰掉 + 删除线：用来标「旧的错误做法」。
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(label, style: theme.textTheme.titleSmall),
              if (info) ...<Widget>[
                const SizedBox(width: 6),
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(flex: 3, child: left),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: right),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (warn || invalid) ...<Widget>[
                Icon(Icons.error_outline, size: 14, color: colors.error),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  helper,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted
                        ? colors.outline
                        : ((warn || invalid)
                              ? colors.error
                              : colors.onSurfaceVariant),
                    decoration: muted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 点 ⓘ 后的对话框。
class _MockDialog extends StatelessWidget {
  const _MockDialog();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    Widget row(String left, String right) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(left, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(right, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('研磨刻度怎么算', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              '相对刻度 = 圈 × 每圈 click + click - 零点',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            row('这台磨豆机', '每圈 30 click · 零点 0'),
            row('这次填写', '1 圈 + 10 click'),
            row('结果', '1 × 30 + 10 - 0 = 40 click'),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '知道了',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

/// 一个输入框：右边可以带单位后缀。
class _Box extends StatelessWidget {
  const _Box({this.text, this.suffix, this.hint, this.invalid = false});

  final String? text;
  final String? suffix;
  final String? hint;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool filled = text != null && text!.isNotEmpty;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: invalid ? theme.colorScheme.error : theme.colorScheme.outline,
          width: invalid ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              filled ? text! : (hint ?? ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: filled
                  ? theme.textTheme.bodyLarge
                  : theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
            ),
          ),
          if (suffix != null)
            Text(
              suffix!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// 记录卡片的两行示意（第一行 = 豆名 + 星，第二行 = 磨豆机 + 刻度 + 方法）。
class _CardRow extends StatelessWidget {
  const _CardRow({required this.first, required this.second});

  final String first;
  final String second;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            first,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            second,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
