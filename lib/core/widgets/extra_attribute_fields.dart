/// 扩展属性的通用编辑器。
///
/// 按 `ExtraValueType` 自动选控件，所以**新增一个扩展属性不需要改这个文件**，
/// 也不需要改任何表单页——只要在 `ExtraAttributeRegistry` 里加定义即可。
library;

import 'package:beanclick/core/widgets/form_fields.dart';
import 'package:beanclick/domain/extra_attributes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 一个可折叠的「更多信息」区块，承载某类对象的全部扩展属性。
class ExtraAttributesEditor extends StatelessWidget {
  const ExtraAttributesEditor({
    super.key,
    required this.attributes,
    required this.onChanged,
    this.title = '更多信息',
    this.initiallyExpanded = false,
    this.emptyHint = '这个对象还没有附加信息',
  });

  final List<ExtraAttribute> attributes;

  /// 某项被修改时回调（返回新的整份列表，由外层负责保存）。
  final ValueChanged<List<ExtraAttribute>> onChanged;

  final String title;
  final bool initiallyExpanded;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    if (attributes.isEmpty) {
      return FormSection(
        title: title,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              emptyHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    return FormSection(
      title: title,
      subtitle: '这些是附加信息，不影响核心记录',
      children: <Widget>[
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: initiallyExpanded,
          title: Text('$title（${attributes.length}）'),
          children: <Widget>[
            for (final attribute in attributes)
              ExtraAttributeField(
                attribute: attribute,
                onChanged: (Object? value) => onChanged(<ExtraAttribute>[
                  for (final item in attributes)
                    item.key == attribute.key
                        ? item.copyWith(value: value, clearValue: value == null)
                        : item,
                ]),
              ),
          ],
        ),
      ],
    );
  }
}

/// 单个扩展属性的输入控件。按类型自动切换。
class ExtraAttributeField extends StatefulWidget {
  const ExtraAttributeField({
    super.key,
    required this.attribute,
    required this.onChanged,
  });

  final ExtraAttribute attribute;
  final ValueChanged<Object?> onChanged;

  @override
  State<ExtraAttributeField> createState() => _ExtraAttributeFieldState();
}

class _ExtraAttributeFieldState extends State<ExtraAttributeField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.attribute.displayValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit(String raw) {
    widget.onChanged(widget.attribute.valueType.parse(raw));
  }

  @override
  Widget build(BuildContext context) {
    final ExtraAttribute attribute = widget.attribute;

    return LabeledField(
      label: attribute.displayLabel,
      helper: attribute.isBuiltin ? null : '自定义',
      child: switch (attribute.valueType) {
        ExtraValueType.boolean => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: attribute.value == true,
          onChanged: (bool value) => widget.onChanged(value),
          title: Text(attribute.value == true ? '是' : '否'),
        ),
        ExtraValueType.integer => TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: _emit,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        ExtraValueType.number => TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: _emit,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        ExtraValueType.tags => TextField(
          controller: _controller,
          onChanged: _emit,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: '用「、」或逗号分隔',
          ),
        ),
        ExtraValueType.date => DateField(
          value: DateTime.tryParse(attribute.displayValue),
          formatter: formatDateChinese,
          onPick: (DateTime value) => widget.onChanged(value.toIso8601String()),
          onClear: () => widget.onChanged(null),
        ),
        ExtraValueType.text => TextField(
          controller: _controller,
          onChanged: _emit,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      },
    );
  }
}

/// 只读展示：把有值的扩展属性列成若干行。
///
/// 没值的项不显示，避免详情页堆一堆空字段。
class ExtraAttributesSummary extends StatelessWidget {
  const ExtraAttributesSummary({super.key, required this.attributes});

  final List<ExtraAttribute> attributes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ExtraAttribute> filled = attributes
        .where((a) => a.hasValue)
        .toList(growable: false);
    if (filled.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final attribute in filled)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${attribute.displayLabel}：${attribute.displayValue}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
