import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/form_fields.dart';
import '../../data/providers.dart';
import '../../domain/entities.dart';
import '../../domain/enums.dart';

/// 磨豆机新增 / 编辑表单（手册 §7「手磨 / 磨豆机」）。
///
/// 通过 [GrinderFormPage.show] 打开，返回 `true` 表示已保存或删除。
class GrinderFormPage extends ConsumerStatefulWidget {
  const GrinderFormPage({super.key, this.grinder});

  /// 为 null 时是新增，否则是编辑。
  final Grinder? grinder;

  /// 打开表单。返回 `true` 表示数据有变化（已保存或已删除）。
  static Future<bool> show(BuildContext context, {Grinder? grinder}) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext context) => GrinderFormPage(grinder: grinder),
      ),
    );
    return changed ?? false;
  }

  @override
  ConsumerState<GrinderFormPage> createState() => _GrinderFormPageState();
}

class _GrinderFormPageState extends ConsumerState<GrinderFormPage> {
  /// 常见刀盘类型，作为快捷选项；也可以自己填。
  static const List<String> _commonBurrs = <String>['锥刀', '平刀', '鬼齿'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _burrType;
  late final TextEditingController _zeroPoint;
  late final TextEditingController _clicksPerRevolution;
  late final TextEditingController _micronsPerClick;
  late final TextEditingController _calibrationNote;
  late final TextEditingController _notes;

  GrindScaleUnit _scaleUnit = GrindScaleUnit.click;
  bool _saving = false;

  bool get _isEditing => widget.grinder != null;

  @override
  void initState() {
    super.initState();
    final Grinder? grinder = widget.grinder;
    _brand = TextEditingController(text: grinder?.brand ?? '');
    _model = TextEditingController(text: grinder?.model ?? '');
    _burrType = TextEditingController(text: grinder?.burrType ?? '');
    _zeroPoint = TextEditingController(text: numberToText(grinder?.zeroPoint));
    _clicksPerRevolution = TextEditingController(
      text: grinder?.clicksPerRevolution?.toString() ?? '',
    );
    _micronsPerClick = TextEditingController(
      text: numberToText(grinder?.micronsPerClick),
    );
    _calibrationNote = TextEditingController(
      text: grinder?.calibrationNote ?? '',
    );
    _notes = TextEditingController(text: grinder?.notes ?? '');
    _scaleUnit = grinder?.scaleUnit ?? GrindScaleUnit.click;
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _burrType.dispose();
    _zeroPoint.dispose();
    _clicksPerRevolution.dispose();
    _micronsPerClick.dispose();
    _calibrationNote.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final DateTime now = DateTime.now();
    final Grinder base =
        widget.grinder ??
        Grinder(brand: '', model: '', createdAt: now, updatedAt: now);
    final Grinder grinder = base.copyWith(
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      burrType: _burrType.text.trim().isEmpty ? null : _burrType.text.trim(),
      scaleUnit: _scaleUnit,
      zeroPoint: parseNumber(_zeroPoint.text),
      clicksPerRevolution: int.tryParse(_clicksPerRevolution.text.trim()),
      micronsPerClick: parseNumber(_micronsPerClick.text),
      calibrationNote: _calibrationNote.text.trim().isEmpty
          ? null
          : _calibrationNote.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      updatedAt: now,
      clearBurrType: _burrType.text.trim().isEmpty,
      clearZeroPoint: parseNumber(_zeroPoint.text) == null,
      clearClicksPerRevolution:
          int.tryParse(_clicksPerRevolution.text.trim()) == null,
      clearCalibrationNote: _calibrationNote.text.trim().isEmpty,
      clearNotes: _notes.text.trim().isEmpty,
    );

    try {
      await ref.read(grinderRepositoryProvider).save(grinder);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('保存失败：$error');
    }
  }

  Future<void> _delete() async {
    final Grinder? grinder = widget.grinder;
    if (grinder?.id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除这台磨豆机？'),
        content: const Text('删除后无法恢复。已有的冲煮记录会保留，但不再关联这台磨豆机。'),
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
      await ref.read(grinderRepositoryProvider).delete(grinder!.id!);
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
    final double? zeroPoint = parseNumber(_zeroPoint.text);
    final String preview = _buildPreview(zeroPoint);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑磨豆机' : '新增磨豆机'),
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
              title: '机型',
              children: <Widget>[
                LabeledField(
                  label: '品牌',
                  isRequired: true,
                  child: PlainTextField(
                    key: const Key('grinder.brand'),
                    controller: _brand,
                    hintText: '例如：Comandante',
                    validator: (String? value) =>
                        (value == null || value.trim().isEmpty)
                        ? '请填写品牌'
                        : null,
                  ),
                ),
                LabeledField(
                  label: '型号',
                  isRequired: true,
                  child: PlainTextField(
                    key: const Key('grinder.model'),
                    controller: _model,
                    hintText: '例如：C40 MK4',
                    validator: (String? value) =>
                        (value == null || value.trim().isEmpty)
                        ? '请填写型号'
                        : null,
                  ),
                ),
                LabeledField(
                  label: '刀盘类型',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      PlainTextField(
                        controller: _burrType,
                        hintText: '选填，例如：锥刀',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: <Widget>[
                          for (final String burr in _commonBurrs)
                            ActionChip(
                              label: Text(burr),
                              onPressed: () =>
                                  setState(() => _burrType.text = burr),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            FormSection(
              title: '刻度体系',
              children: <Widget>[
                LabeledField(
                  label: '刻度单位',
                  isRequired: true,
                  child: EnumSelector<GrindScaleUnit>(
                    values: GrindScaleUnit.values,
                    selected: _scaleUnit,
                    labelOf: (GrindScaleUnit value) => value.label,
                    onSelected: (GrindScaleUnit? value) {
                      if (value != null) setState(() => _scaleUnit = value);
                    },
                  ),
                ),
                LabeledField(
                  label: '零点',
                  helper: '多数手磨零点为 0；有偏移时填写校准值',
                  child: NumberField(
                    key: const Key('grinder.zeroPoint'),
                    controller: _zeroPoint,
                    hintText: '0',
                    allowNegative: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                LabeledField(
                  label: '每圈 click 数',
                  helper: '用于把「圈数」换算成刻度，例如 C40 为 30',
                  child: IntField(
                    key: const Key('grinder.clicksPerRevolution'),
                    controller: _clicksPerRevolution,
                    hintText: '选填，例如：30',
                    suffixText: 'click',
                  ),
                ),
                LabeledField(
                  label: '每 click 位移',
                  helper: '一格刻度大约改变多少刀盘间隙，用来对比不同磨豆机的粗细变化',
                  child: NumberField(
                    key: const Key('grinder.micronsPerClick'),
                    controller: _micronsPerClick,
                    hintText: '选填，例如：30',
                    suffixText: 'µm',
                  ),
                ),
              ],
            ),
            FormSection(
              title: '展示预览',
              subtitle: '手册 §7 的展示格式',
              children: <Widget>[
                FormHint(icon: Icons.visibility_outlined, message: preview),
              ],
            ),
            FormSection(
              title: '其他',
              children: <Widget>[
                LabeledField(
                  label: '校准说明',
                  child: PlainTextField(
                    controller: _calibrationNote,
                    hintText: '选填，例如：拆洗后零点归零',
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

  /// 用当前输入拼一条「品牌 型号 / 刻度 / 零点」的预览。
  String _buildPreview(double? zeroPoint) {
    final String brand = _brand.text.trim();
    final String model = _model.text.trim();
    final String name = <String>[
      if (brand.isNotEmpty) brand,
      if (model.isNotEmpty) model,
    ].join(' ');
    if (name.isEmpty) return '填写品牌与型号后这里会显示展示格式';

    final List<String> parts = <String>[name, '22 ${_scaleUnit.label}'];
    if (zeroPoint != null) parts.add('零点 ${formatNumber(zeroPoint)}');
    return parts.join(' / ');
  }
}
