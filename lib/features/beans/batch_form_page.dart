import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/extra_attribute_fields.dart';
import '../../core/widgets/form_fields.dart';
import '../../data/providers.dart';
import '../../domain/entities.dart';
import '../../domain/enums.dart';
import '../../domain/extra_attributes.dart';

/// 批次新增 / 编辑表单。
///
/// 批次承载「这一次购买」的信息：烘焙日期、烘焙度、余量、购入总重、价格。
/// 复购同一款豆子就是再建一个批次，而不是新建一支重复的豆子。
///
/// 通过 [BatchFormPage.show] 打开，返回 `true` 表示已保存或删除。
class BatchFormPage extends ConsumerStatefulWidget {
  const BatchFormPage({super.key, required this.beanId, this.batch});

  /// 所属豆子。
  final int beanId;

  /// 为 null 时是新增（复购），否则是编辑。
  final BeanBatch? batch;

  static Future<bool> show(
    BuildContext context, {
    required int beanId,
    BeanBatch? batch,
  }) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext context) =>
            BatchFormPage(beanId: beanId, batch: batch),
      ),
    );
    return changed ?? false;
  }

  @override
  ConsumerState<BatchFormPage> createState() => _BatchFormPageState();
}

class _BatchFormPageState extends ConsumerState<BatchFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _remaining;
  late final TextEditingController _initial;
  late final TextEditingController _price;
  late final TextEditingController _notes;

  DateTime? _roastDate;
  RoastLevel? _roastLevel;
  List<ExtraAttribute> _extra = const <ExtraAttribute>[];
  bool _saving = false;
  bool _extraLoaded = false;

  bool get _isEditing => widget.batch != null;

  @override
  void initState() {
    super.initState();
    final BeanBatch? batch = widget.batch;
    _remaining = TextEditingController(
      text: numberToText(batch?.remainingGrams),
    );
    _initial = TextEditingController(text: numberToText(batch?.initialGrams));
    _price = TextEditingController(text: numberToText(batch?.price));
    _notes = TextEditingController(text: batch?.notes ?? '');
    _roastDate = batch?.roastDate;
    _roastLevel = batch?.roastLevel;
    _loadExtra();
  }

  /// 载入批次的扩展属性（编辑时才有）。
  Future<void> _loadExtra() async {
    final int? id = widget.batch?.id;
    if (id == null) {
      // 新增：只要内置定义的骨架，便于直接填。
      final List<ExtraAttribute> skeleton = ExtraAttributeRegistry.of(
        ExtraOwnerType.batch,
      ).map((d) => d.toAttribute()).toList(growable: false);
      if (mounted) setState(() => _extra = skeleton);
      return;
    }
    final List<ExtraAttribute> loaded = await ref
        .read(extraAttributeRepositoryProvider)
        .getForBatch(id);
    if (!mounted) return;
    setState(() {
      _extra = loaded;
      _extraLoaded = true;
    });
  }

  @override
  void dispose() {
    _remaining.dispose();
    _initial.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final DateTime now = DateTime.now();
    final BeanBatch base =
        widget.batch ??
        BeanBatch(beanId: widget.beanId, createdAt: now, updatedAt: now);

    final double? initial = parseNumber(_initial.text);
    final BeanBatch batch = base.copyWith(
      beanId: widget.beanId,
      roastDate: _roastDate,
      roastLevel: _roastLevel,
      remainingGrams: parseNumber(_remaining.text) ?? 0,
      initialGrams: initial,
      price: parseNumber(_price.text),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      updatedAt: now,
      clearRoastDate: _roastDate == null,
      clearRoastLevel: _roastLevel == null,
      clearInitialGrams: initial == null,
      clearPrice: parseNumber(_price.text) == null,
      clearNotes: _notes.text.trim().isEmpty,
    );

    try {
      final int batchId = await ref
          .read(beanRepositoryProvider)
          .saveBatch(batch);
      // 扩展属性跟着批次走。
      await ref
          .read(extraAttributeRepositoryProvider)
          .saveForBatch(batchId, _extra);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  Future<void> _delete() async {
    final int? id = widget.batch?.id;
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除这个批次？'),
        content: const Text('删除后无法恢复。已经用它记录过的冲煮不受影响。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(beanRepositoryProvider).deleteBatch(id);
      await ref
          .read(extraAttributeRepositoryProvider)
          .deleteAllFor(ExtraOwnerType.batch, id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('删除失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑批次' : '再来一袋'),
        actions: <Widget>[
          if (_isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            FormSection(
              title: '这一次买的',
              children: <Widget>[
                LabeledField(
                  label: '烘焙日期',
                  child: DateField(
                    value: _roastDate,
                    formatter: formatDateChinese,
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    onPick: (DateTime value) =>
                        setState(() => _roastDate = value),
                    onClear: () => setState(() => _roastDate = null),
                  ),
                ),
                LabeledField(
                  label: '烘焙度',
                  helper: '同款豆子不同批次可能不同',
                  child: EnumSelector<RoastLevel>(
                    values: RoastLevel.selectable,
                    selected: _roastLevel,
                    allowDeselect: true,
                    labelOf: (RoastLevel value) => value.label,
                    onSelected: (RoastLevel? value) =>
                        setState(() => _roastLevel = value),
                  ),
                ),
                LabeledField(
                  label: '剩余克数',
                  helper: _ratioHint(),
                  child: NumberField(
                    key: const Key('batch.remaining'),
                    controller: _remaining,
                    hintText: '0',
                    suffixText: 'g',
                    onChanged: (_) => setState(() {}),
                    validator: (String? value) {
                      final double? remaining = parseNumber(value);
                      final double? initial = parseNumber(_initial.text);
                      if (remaining != null &&
                          initial != null &&
                          remaining > initial) {
                        return '剩余克数不能大于购入总重（${formatNumber(initial)} g）';
                      }
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: '购入总重',
                  child: NumberField(
                    key: const Key('batch.initial'),
                    controller: _initial,
                    hintText: '例如：200',
                    suffixText: 'g',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                LabeledField(
                  label: '价格',
                  child: NumberField(
                    key: const Key('batch.price'),
                    controller: _price,
                    hintText: '选填',
                    suffixText: '元',
                    textInputAction: TextInputAction.next,
                    extraFormatters: const <TextInputFormatter>[
                      PriceInputFormatter(),
                    ],
                  ),
                ),
                LabeledField(
                  label: '备注',
                  child: PlainTextField(
                    controller: _notes,
                    hintText: '选填',
                    maxLines: 2,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ],
            ),
            ExtraAttributesEditor(
              attributes: _extra,
              initiallyExpanded: _extraLoaded,
              onChanged: (List<ExtraAttribute> next) =>
                  setState(() => _extra = next),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FormActions(
        saving: _saving,
        onCancel: () => Navigator.of(context).pop(false),
        onSave: _save,
        saveLabel: _isEditing ? '保存' : '添加批次',
      ),
    );
  }

  String? _ratioHint() {
    final double? initial = parseNumber(_initial.text);
    final double? remaining = parseNumber(_remaining.text);
    if (initial == null || initial <= 0 || remaining == null) {
      return '填写购入总重后可算消耗比例';
    }
    final double consumed = (initial - remaining).clamp(0, initial);
    final int percent = ((1 - remaining / initial) * 100).clamp(0, 100).round();
    return '已消耗 ${formatNumber(consumed)} g（$percent%）';
  }
}
