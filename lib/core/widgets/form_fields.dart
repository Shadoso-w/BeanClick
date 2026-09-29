/// 表单通用控件。
///
/// M2 的三个表单（豆子 / 磨豆机 / 冲煮记录）共用这些控件，
/// 保证「标签在左、输入在右、错误提示统一」的观感一致。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 表单分组卡片，带可选标题与说明。
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// 带标签的字段容器。
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
    this.isRequired = false,
    this.labelTrailing,
  });

  final String label;
  final String? helper;
  final bool isRequired;

  /// 标签右侧的附加控件（例如「研磨刻度 ⓘ」里的信息按钮）。
  final Widget? labelTrailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(label, style: theme.textTheme.titleSmall),
              if (isRequired) ...<Widget>[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              ?labelTrailing,
            ],
          ),
          const SizedBox(height: 6),
          child,
          if (helper != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              helper!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 小数输入框。
///
/// 未填写时回调 `null`，便于上层直接写入可空字段。
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    this.hintText,
    this.suffixText,
    this.onChanged,
    this.allowNegative = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.extraFormatters = const <TextInputFormatter>[],
  });

  final TextEditingController controller;
  final String? hintText;
  final String? suffixText;
  final ValueChanged<double?>? onChanged;
  final bool allowNegative;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  /// 追加的输入过滤（如金额的两位小数限制），排在默认过滤之后。
  final List<TextInputFormatter> extraFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: allowNegative,
      ),
      textInputAction: textInputAction,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(
          allowNegative ? RegExp(r'[0-9.\-]') : RegExp(r'[0-9.]'),
        ),
        ...extraFormatters,
      ],
      onChanged: (String value) => onChanged?.call(parseNumber(value)),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        suffixText: suffixText,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// 整数输入框。
class IntField extends StatelessWidget {
  const IntField({
    super.key,
    required this.controller,
    this.hintText,
    this.suffixText,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? suffixText;
  final String? Function(String?)? validator;

  /// 只要文本变了就回调，用来刷新依赖这个值的提示行。
  final ValueChanged<int?>? onChanged;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator,
      onChanged: (String value) => onChanged?.call(int.tryParse(value.trim())),
      decoration: InputDecoration(
        hintText: hintText,
        suffixText: suffixText,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// 普通文本输入框。
class PlainTextField extends StatelessWidget {
  const PlainTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.inputFormatters = const <TextInputFormatter>[],
  });

  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final List<TextInputFormatter> inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// 枚举选择器（横向排列的 ChoiceChip，选项多时会自动换行）。
class EnumSelector<T> extends StatelessWidget {
  const EnumSelector({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.allowDeselect = false,
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final ValueChanged<T?> onSelected;

  /// 是否允许再次点击取消选择（用于可空枚举字段）。
  final bool allowDeselect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final T value in values)
          ChoiceChip(
            label: Text(labelOf(value)),
            selected: value == selected,
            onSelected: (bool isSelected) {
              if (isSelected) {
                onSelected(value);
              } else if (allowDeselect) {
                onSelected(null);
              }
            },
          ),
      ],
    );
  }
}

/// 日期选择行。
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onPick,
    this.hintText = '选择日期',
    this.onClear,
    this.lastDate,
    this.firstDate,
    this.formatter = formatDate,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onClear;
  final String hintText;
  final DateTime? lastDate;
  final DateTime? firstDate;

  /// 显示用的格式化函数，默认 `yyyy-MM-dd`；传 [formatDateChinese] 得中文日期。
  final String Function(DateTime) formatter;

  @override
  Widget build(BuildContext context) {
    final DateTime? current = value;

    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final DateTime now = DateTime.now();
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: current ?? now,
                firstDate: firstDate ?? DateTime(now.year - 5),
                lastDate: lastDate ?? DateTime(now.year + 1),
              );
              if (picked != null) onPick(picked);
            },
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(current == null ? hintText : formatter(current)),
            ),
          ),
        ),
        if (current != null && onClear != null) ...<Widget>[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClear,
            tooltip: '清除日期',
            icon: const Icon(Icons.clear),
          ),
        ],
      ],
    );
  }
}

/// 日期 + 时分选择行（冲煮时间用）。
///
/// 左边点日期、右边点时间，各改各的 —— 不像纯日期字段那样只能改日期，
/// 也不想做成「一个按钮分两步弹」逼着用户每次都走完两步。
///
/// [onDatePicked] 与 [onTimePicked] 分开回调：日期选完要不要顺手弹时间，
/// 由调用方决定（表单里是「新建且从没设过时间」才弹一次）。
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    super.key,
    required this.value,
    required this.onDatePicked,
    required this.onTimePicked,
    this.dateKey,
    this.timeKey,
    this.hintText = '选择时间',
    this.lastDate,
    this.firstDate,
    this.dateFormatter = formatDateChinese,
    this.timeFormatter = formatTime,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onDatePicked;
  final ValueChanged<TimeOfDay> onTimePicked;

  /// 两个按钮各自的 Key（测试用）。
  final Key? dateKey;
  final Key? timeKey;

  final String hintText;
  final DateTime? lastDate;
  final DateTime? firstDate;

  /// 日期的显示格式，默认中文；[timeFormatter] 默认 `HH:mm`。
  final String Function(DateTime) dateFormatter;
  final String Function(TimeOfDay) timeFormatter;

  @override
  Widget build(BuildContext context) {
    final DateTime? current = value;

    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: OutlinedButton.icon(
            key: dateKey,
            onPressed: () async {
              final DateTime now = DateTime.now();
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: current ?? now,
                firstDate: firstDate ?? DateTime(now.year - 5),
                lastDate: lastDate ?? DateTime(now.year + 1),
              );
              if (picked != null) onDatePicked(picked);
            },
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                current == null ? hintText : dateFormatter(current),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            key: timeKey,
            onPressed: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: current == null
                    ? TimeOfDay.now()
                    : TimeOfDay.fromDateTime(current),
              );
              if (picked != null) onTimePicked(picked);
            },
            icon: const Icon(Icons.schedule_outlined, size: 18),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                current == null
                    ? '--:--'
                    : timeFormatter(TimeOfDay.fromDateTime(current)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 1–5 星评分选择器。
class RatingSelector extends StatelessWidget {
  const RatingSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int current = value ?? 0;

    return Row(
      children: <Widget>[
        for (int i = 1; i <= 5; i++)
          IconButton(
            onPressed: () => onChanged(current == i ? null : i),
            tooltip: '$i 分',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              i <= current ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 30,
              color: i <= current ? colors.primary : colors.outlineVariant,
            ),
          ),
        const SizedBox(width: 4),
        Text(
          current == 0 ? '未评分' : '$current 分',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 双语提示条（用于表单内的说明或警告）。
class FormHint extends StatelessWidget {
  const FormHint({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.isWarning = false,
  });

  final String message;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color background = isWarning
        ? colors.errorContainer
        : colors.surfaceContainerHighest;
    final Color foreground = isWarning
        ? colors.onErrorContainer
        : colors.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// 表单底部操作栏：取消 / 保存。
class FormActions extends StatelessWidget {
  const FormActions({
    super.key,
    required this.saving,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = '保存',
  });

  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onCancel,
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(saveLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 把输入框文本解析成小数；空串或非法输入返回 null。
double? parseNumber(String? raw) {
  if (raw == null) return null;
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

/// 只保留小数点后最多一位，整数不显示 `.0`。
String formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

/// 把 double 转成输入框初始文本（去掉多余的 `.0`）。
String numberToText(double? value) {
  if (value == null) return '';
  return formatNumber(value);
}

/// `yyyy-MM-dd`。
String formatDate(DateTime value) {
  final DateTime local = value.toLocal();
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

/// `yyyy年M月d日`，中文日期。
String formatDateChinese(DateTime value) {
  final DateTime local = value.toLocal();
  return '${local.year}年${local.month}月${local.day}日';
}

/// `HH:mm`（24 小时制，补零）。
///
/// 不跟随系统 12/24 小时制：冲煮记录里 `14:30` 比 `2:30 PM` 好认，
/// 也和导出、日志里的格式一致。
String formatTime(TimeOfDay value) {
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// `yyyy年M月d日 HH:mm`，中文日期 + 时分。
String formatDateTimeChinese(DateTime value) {
  return '${formatDateChinese(value)} ${formatTime(TimeOfDay.fromDateTime(value))}';
}

/// 把日期部分换掉、保留原时分。
DateTime withDate(DateTime value, DateTime date) => DateTime(
  date.year,
  date.month,
  date.day,
  value.hour,
  value.minute,
  value.second,
);

/// 把时分换掉、保留原日期。
///
/// **秒会被清零**：时间选择器只有分钟精度，留着原来的秒会存出
/// `14:30:47` 这种值，显示和排序都更容易出意外。
DateTime withTime(DateTime value, TimeOfDay time) =>
    DateTime(value.year, value.month, value.day, time.hour, time.minute);

/// 过滤风味标签输入：只保留中日韩文字、英文字母、数字与分隔符。
///
/// 用于 `TextInputFormatter`，在**输入阶段**就把表情、符号等清掉，
/// 避免它们进入标签后污染导出结果与将来的统计分组。
///
/// 空格保留（`parseTags` 会把它当分隔符切分），但括号、点号、感叹号
/// 这类符号会被删掉。
String filterTagInput(String raw) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in raw.runes) {
    final bool keep =
        (rune >= 0x4E00 && rune <= 0x9FFF) || // 中日韩统一表意文字
        (rune >= 0x3040 && rune <= 0x30FF) || // 日文假名
        (rune >= 0xAC00 && rune <= 0xD7A3) || // 韩文
        (rune >= 0x41 && rune <= 0x5A) || // A-Z
        (rune >= 0x61 && rune <= 0x7A) || // a-z
        (rune >= 0x30 && rune <= 0x39) || // 0-9
        rune == 0x0020 || // 空格
        rune == 0x3001 || // 、
        rune == 0x002C || // ,
        rune == 0xFF0C; // ，
    if (keep) buffer.writeCharCode(rune);
  }
  return buffer.toString();
}

/// 只允许最多两位小数（用于价格这类金额输入）。
class PriceInputFormatter extends TextInputFormatter {
  const PriceInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 只允许数字与至多一个小数点，且小数位不超过两位。
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newValue.text)) return oldValue;
    return newValue;
  }
}

/// 按 [filter] 清洗输入文本，并把光标收回到末尾。
///
/// 必须显式设置 selection：过滤会缩短文本，若沿用旧的 selection，
/// 位置可能超出新文本长度，触发
/// `'range.start >= 0 && range.start <= text.length'` 断言。
/// 粘贴含表情的文本时，这个问题在真机上同样会发生。
class FilteringTagFormatter extends TextInputFormatter {
  const FilteringTagFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String filtered = filterTagInput(newValue.text);
    if (filtered == newValue.text) return newValue;
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

/// 把「、,，空格换行」分隔的输入切成标签列表，去空去重。
List<String> parseTags(String? raw) {
  if (raw == null) return const <String>[];
  final List<String> parts = raw
      .split(RegExp(r'[、,，\s]+'))
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty)
      .toList();
  final List<String> unique = <String>[];
  for (final String part in parts) {
    if (!unique.contains(part)) unique.add(part);
  }
  return unique;
}

/// 秒数 → `m:ss`。
String formatDuration(int totalSeconds) {
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
