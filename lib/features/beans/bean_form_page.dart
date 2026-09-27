import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/form_fields.dart';
import '../../data/providers.dart';
import '../../domain/entities.dart';
import '../../domain/enums.dart';

/// 咖啡豆新增 / 编辑表单（手册 §7「咖啡豆」标准字段）。
///
/// 通过 [BeanFormPage.show] 打开，返回 `true` 表示已保存或删除。
class BeanFormPage extends ConsumerStatefulWidget {
  const BeanFormPage({super.key, this.bean});

  /// 为 null 时是新增，否则是编辑。
  final CoffeeBean? bean;

  /// 打开表单。返回 `true` 表示数据有变化（已保存或已删除）。
  static Future<bool> show(BuildContext context, {CoffeeBean? bean}) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext context) => BeanFormPage(bean: bean),
      ),
    );
    return changed ?? false;
  }

  @override
  ConsumerState<BeanFormPage> createState() => _BeanFormPageState();
}

class _BeanFormPageState extends ConsumerState<BeanFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _origin;
  late final TextEditingController _farm;
  late final TextEditingController _remaining;
  late final TextEditingController _initial;
  late final TextEditingController _price;
  late final TextEditingController _flavors;
  late final TextEditingController _notes;

  ProcessMethod? _process;
  RoastLevel? _roastLevel;
  DateTime? _roastDate;
  bool _saving = false;

  bool get _isEditing => widget.bean != null;

  @override
  void initState() {
    super.initState();
    final CoffeeBean? bean = widget.bean;
    _name = TextEditingController(text: bean?.name ?? '');
    _origin = TextEditingController(text: bean?.origin ?? '');
    _farm = TextEditingController(text: bean?.farm ?? '');
    _remaining = TextEditingController(
      text: bean == null ? '' : numberToText(bean.remainingGrams),
    );
    _initial = TextEditingController(text: numberToText(bean?.initialGrams));
    _price = TextEditingController(text: numberToText(bean?.price));
    _flavors = TextEditingController(text: bean?.flavorTags.join('、') ?? '');
    _notes = TextEditingController(text: bean?.notes ?? '');
    _process = bean?.process;
    _roastLevel = bean?.roastLevel;
    _roastDate = bean?.roastDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _origin.dispose();
    _farm.dispose();
    _remaining.dispose();
    _initial.dispose();
    _price.dispose();
    _flavors.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final DateTime now = DateTime.now();
    final CoffeeBean base =
        widget.bean ?? CoffeeBean(name: '', createdAt: now, updatedAt: now);
    final CoffeeBean bean = base.copyWith(
      name: _name.text.trim(),
      origin: _origin.text.trim().isEmpty ? null : _origin.text.trim(),
      farm: _farm.text.trim().isEmpty ? null : _farm.text.trim(),
      process: _process,
      roastLevel: _roastLevel,
      roastDate: _roastDate,
      flavorTags: parseTags(_flavors.text),
      remainingGrams: parseNumber(_remaining.text) ?? 0,
      initialGrams: parseNumber(_initial.text),
      price: parseNumber(_price.text),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      updatedAt: now,
      clearProcess: _process == null,
      clearRoastLevel: _roastLevel == null,
      clearRoastDate: _roastDate == null,
      clearInitialGrams: parseNumber(_initial.text) == null,
      clearPrice: parseNumber(_price.text) == null,
      clearNotes: _notes.text.trim().isEmpty,
    );

    try {
      await ref.read(beanRepositoryProvider).save(bean);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('保存失败：$error');
    }
  }

  Future<void> _delete() async {
    final CoffeeBean? bean = widget.bean;
    if (bean?.id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除这支豆子？'),
        content: const Text('删除后无法恢复。已有的冲煮记录会保留，但不再关联这支豆子。'),
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
      await ref.read(beanRepositoryProvider).delete(bean!.id!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage('删除失败：$error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final double? remaining = parseNumber(_remaining.text);
    final double? initial = parseNumber(_initial.text);
    final String? ratioHint =
        (initial != null && initial > 0 && remaining != null)
        ? '已消耗 ${formatNumber((initial - remaining).clamp(0, initial))} g'
              '（${((1 - remaining / initial) * 100).clamp(0, 100).toStringAsFixed(0)}%）'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑咖啡豆' : '新增咖啡豆'),
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
              title: '基本信息',
              children: <Widget>[
                LabeledField(
                  label: '名称',
                  isRequired: true,
                  child: PlainTextField(
                    key: const Key('bean.name'),
                    controller: _name,
                    hintText: '例如：耶加雪菲 科契尔',
                    validator: (String? value) =>
                        (value == null || value.trim().isEmpty)
                        ? '请填写豆子名称'
                        : null,
                  ),
                ),
                LabeledField(
                  label: '产地',
                  child: PlainTextField(
                    key: const Key('bean.origin'),
                    controller: _origin,
                    hintText: '例如：埃塞俄比亚',
                  ),
                ),
                LabeledField(
                  label: '庄园 / 处理厂',
                  child: PlainTextField(
                    key: const Key('bean.farm'),
                    controller: _farm,
                    hintText: '例如：科契尔',
                  ),
                ),
              ],
            ),
            FormSection(
              title: '烘焙与处理',
              children: <Widget>[
                LabeledField(
                  label: '处理法',
                  helper: '再次点击已选中的项可取消',
                  child: EnumSelector<ProcessMethod>(
                    values: ProcessMethod.values,
                    selected: _process,
                    allowDeselect: true,
                    labelOf: (ProcessMethod value) => value.label,
                    onSelected: (ProcessMethod? value) =>
                        setState(() => _process = value),
                  ),
                ),
                LabeledField(
                  label: '烘焙度',
                  child: EnumSelector<RoastLevel>(
                    values: RoastLevel.values,
                    selected: _roastLevel,
                    allowDeselect: true,
                    labelOf: (RoastLevel value) => value.label,
                    onSelected: (RoastLevel? value) =>
                        setState(() => _roastLevel = value),
                  ),
                ),
                LabeledField(
                  label: '烘焙日期',
                  child: DateField(
                    value: _roastDate,
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    onPick: (DateTime value) =>
                        setState(() => _roastDate = value),
                    onClear: () => setState(() => _roastDate = null),
                  ),
                ),
              ],
            ),
            FormSection(
              title: '库存与价格',
              children: <Widget>[
                LabeledField(
                  label: '剩余克数',
                  helper: ratioHint ?? '冲煮保存时会按粉量自动扣减',
                  child: NumberField(
                    key: const Key('bean.remaining'),
                    controller: _remaining,
                    hintText: '0',
                    suffixText: 'g',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                LabeledField(
                  label: '购入总重',
                  helper: '填写后可计算消耗比例',
                  child: NumberField(
                    key: const Key('bean.initial'),
                    controller: _initial,
                    hintText: '例如：200',
                    suffixText: 'g',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                LabeledField(
                  label: '价格',
                  child: NumberField(
                    key: const Key('bean.price'),
                    controller: _price,
                    hintText: '选填',
                    suffixText: '元',
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            FormSection(
              title: '风味与备注',
              children: <Widget>[
                LabeledField(
                  label: '风味标签',
                  helper: '用「、」或逗号分隔，例如：柑橘、花香、蜂蜜',
                  child: PlainTextField(
                    controller: _flavors,
                    hintText: '柑橘、花香',
                  ),
                ),
                LabeledField(
                  label: '备注',
                  child: PlainTextField(
                    controller: _notes,
                    hintText: '选填',
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: FormActions(
        saving: _saving,
        onCancel: () => Navigator.of(context).pop(false),
        onSave: _save,
      ),
    );
  }
}
