import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons.dart';
import '../../core/widgets/extra_attribute_fields.dart';
import '../../core/widgets/form_fields.dart';
import '../../data/providers.dart';
import '../../data/repositories/extra_attribute_repository.dart';
import '../../domain/entities.dart';
import '../../domain/enums.dart';
import '../../domain/extra_attributes.dart';
import 'batch_form_page.dart';

/// 咖啡豆新增 / 编辑表单。
///
/// 表单分三块：
///
/// 1. **豆子的身份**（名称、产地、庄园、处理法、风味、收藏）——不随购买变化
/// 2. **批次**（烘焙日期、烘焙度、余量、价格）——每次购买都会不同
///    - 新增豆子时强制填第一个批次
///    - 编辑时展示已有批次列表，可增删改（复购就是再加一袋）
/// 3. **更多信息**（扩展属性）——加属性只需改注册表，不用改这个文件
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

  // --- 身份 ---
  late final TextEditingController _name;
  late final TextEditingController _origin;
  late final TextEditingController _farm;
  late final TextEditingController _flavors;

  ProcessMethod? _process;
  bool _isFavorite = false;

  // --- 新增时的首个批次 ---
  late final TextEditingController _remaining;
  late final TextEditingController _initial;
  late final TextEditingController _price;
  DateTime? _roastDate;
  RoastLevel? _roastLevel;

  // --- 扩展属性 ---
  List<ExtraAttribute> _extra = const <ExtraAttribute>[];

  // --- 编辑时的批次列表 ---
  List<BeanBatch> _batches = const <BeanBatch>[];

  bool _saving = false;

  bool get _isEditing => widget.bean != null;

  @override
  void initState() {
    super.initState();
    final CoffeeBean? bean = widget.bean;
    _name = TextEditingController(text: bean?.name ?? '');
    _origin = TextEditingController(text: bean?.origin ?? '');
    _farm = TextEditingController(text: bean?.farm ?? '');
    _flavors = TextEditingController(text: bean?.flavorTags.join('、') ?? '');
    _process = bean?.process;
    _isFavorite = bean?.isFavorite ?? false;

    // 首个批次默认值：刚买回来通常是满袋。
    _remaining = TextEditingController(text: '200');
    _initial = TextEditingController(text: '200');
    _price = TextEditingController();
    _roastDate = DateTime.now();
    _roastLevel = RoastLevel.medium;

    _loadExtras();
    final int? id = bean?.id;
    if (id != null) _loadBatches(id);
  }

  Future<void> _loadExtras() async {
    final ExtraAttributeRepository repo = ref.read(
      extraAttributeRepositoryProvider,
    );
    final int? id = widget.bean?.id;
    final List<ExtraAttribute> loaded = id == null
        ? repo.skeletonFor(ExtraOwnerType.bean)
        : await repo.getForBean(id);
    if (!mounted) return;
    setState(() => _extra = loaded);
  }

  Future<void> _loadBatches(int beanId) async {
    final List<BeanBatch> batches = await ref
        .read(beanRepositoryProvider)
        .batchesOf(beanId);
    if (!mounted) return;
    setState(() => _batches = batches);
  }

  @override
  void dispose() {
    _name.dispose();
    _origin.dispose();
    _farm.dispose();
    _flavors.dispose();
    _remaining.dispose();
    _initial.dispose();
    _price.dispose();
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
      flavorTags: parseTags(_flavors.text),
      isFavorite: _isFavorite,
      updatedAt: now,
      clearOrigin: _origin.text.trim().isEmpty,
      clearFarm: _farm.text.trim().isEmpty,
      clearProcess: _process == null,
    );

    try {
      final int beanId = await ref.read(beanRepositoryProvider).save(bean);

      // 新增豆子时强制写入第一个批次（决策 5）。
      if (!_isEditing) {
        await ref
            .read(beanRepositoryProvider)
            .saveBatch(
              BeanBatch(
                beanId: beanId,
                roastDate: _roastDate,
                roastLevel: _roastLevel,
                remainingGrams: parseNumber(_remaining.text) ?? 0,
                initialGrams: parseNumber(_initial.text),
                price: parseNumber(_price.text),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      await ref
          .read(extraAttributeRepositoryProvider)
          .saveForBean(beanId, _extra);

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
        content: const Text('它的全部批次会一并删除。已有的冲煮记录会保留，但不再关联这支豆子。'),
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
      final int id = bean!.id!;
      await ref.read(beanRepositoryProvider).delete(id);
      await ref
          .read(extraAttributeRepositoryProvider)
          .deleteAllFor(ExtraOwnerType.bean, id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage('删除失败：$error');
    }
  }

  /// 复购：加一袋。
  Future<void> _addBatch() async {
    final int? beanId = widget.bean?.id;
    if (beanId == null) return;

    final bool changed = await BatchFormPage.show(context, beanId: beanId);
    if (!mounted || !changed) return;
    await _loadBatches(beanId);
    if (mounted) _showMessage('已添加批次');
  }

  Future<void> _editBatch(BeanBatch batch) async {
    final int? beanId = widget.bean?.id;
    if (beanId == null) return;

    final bool changed = await BatchFormPage.show(
      context,
      beanId: beanId,
      batch: batch,
    );
    if (!mounted || !changed) return;
    await _loadBatches(beanId);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                  helper: '选填',
                  child: PlainTextField(
                    key: const Key('bean.farm'),
                    controller: _farm,
                    hintText: '例如：科契尔',
                  ),
                ),
                LabeledField(
                  label: '处理法',
                  helper: '再次点击已选中的项可取消',
                  child: EnumSelector<ProcessMethod>(
                    values: ProcessMethod.selectable,
                    selected: _process,
                    allowDeselect: true,
                    labelOf: (ProcessMethod value) => value.label,
                    onSelected: (ProcessMethod? value) =>
                        setState(() => _process = value),
                  ),
                ),
                LabeledField(
                  label: '风味标签',
                  helper: '用「、」或逗号分隔，例如：柑橘、花香、蜂蜜',
                  child: PlainTextField(
                    key: const Key('bean.flavors'),
                    controller: _flavors,
                    hintText: '柑橘、花香',
                    inputFormatters: const <TextInputFormatter>[
                      FilteringTagFormatter(),
                    ],
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('收藏'),
                  subtitle: const Text('复购时可以先从收藏里挑'),
                  value: _isFavorite,
                  onChanged: (bool value) =>
                      setState(() => _isFavorite = value),
                ),
              ],
            ),

            if (_isEditing)
              _BatchSection(
                batches: _batches,
                onAdd: _addBatch,
                onEdit: _editBatch,
              )
            else
              _FirstBatchSection(
                roastDate: _roastDate,
                roastLevel: _roastLevel,
                remaining: _remaining,
                initial: _initial,
                price: _price,
                onRoastDateChanged: (DateTime? value) =>
                    setState(() => _roastDate = value),
                onRoastLevelChanged: (RoastLevel? value) =>
                    setState(() => _roastLevel = value),
                onNumberChanged: () => setState(() {}),
              ),

            ExtraAttributesEditor(
              attributes: _extra,
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
      ),
    );
  }
}

/// 新增豆子时的第一个批次（强制填写）。
class _FirstBatchSection extends StatelessWidget {
  const _FirstBatchSection({
    required this.roastDate,
    required this.roastLevel,
    required this.remaining,
    required this.initial,
    required this.price,
    required this.onRoastDateChanged,
    required this.onRoastLevelChanged,
    required this.onNumberChanged,
  });

  final DateTime? roastDate;
  final RoastLevel? roastLevel;
  final TextEditingController remaining;
  final TextEditingController initial;
  final TextEditingController price;
  final ValueChanged<DateTime?> onRoastDateChanged;
  final ValueChanged<RoastLevel?> onRoastLevelChanged;
  final VoidCallback onNumberChanged;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: '第一袋',
      subtitle: '烘焙日期与余量记在批次上；以后复购再加一袋即可',
      children: <Widget>[
        LabeledField(
          label: '烘焙日期',
          child: DateField(
            value: roastDate,
            formatter: formatDateChinese,
            lastDate: DateTime.now().add(const Duration(days: 1)),
            onPick: (DateTime value) => onRoastDateChanged(value),
            onClear: () => onRoastDateChanged(null),
          ),
        ),
        LabeledField(
          label: '烘焙度',
          child: EnumSelector<RoastLevel>(
            values: RoastLevel.selectable,
            selected: roastLevel,
            allowDeselect: true,
            labelOf: (RoastLevel value) => value.label,
            onSelected: onRoastLevelChanged,
          ),
        ),
        LabeledField(
          label: '剩余克数',
          child: NumberField(
            key: const Key('bean.remaining'),
            controller: remaining,
            hintText: '0',
            suffixText: 'g',
            onChanged: (_) => onNumberChanged(),
            validator: (String? value) {
              final double? r = parseNumber(value);
              final double? i = parseNumber(initial.text);
              if (r != null && i != null && r > i) {
                return '剩余克数不能大于购入总重（${formatNumber(i)} g）';
              }
              return null;
            },
          ),
        ),
        LabeledField(
          label: '购入总重',
          child: NumberField(
            key: const Key('bean.initial'),
            controller: initial,
            hintText: '例如：200',
            suffixText: 'g',
            onChanged: (_) => onNumberChanged(),
          ),
        ),
        LabeledField(
          label: '价格',
          child: NumberField(
            key: const Key('bean.price'),
            controller: price,
            hintText: '选填',
            suffixText: '元',
            textInputAction: TextInputAction.next,
            extraFormatters: const <TextInputFormatter>[PriceInputFormatter()],
          ),
        ),
      ],
    );
  }
}

/// 编辑豆子时的批次列表。
class _BatchSection extends StatelessWidget {
  const _BatchSection({
    required this.batches,
    required this.onAdd,
    required this.onEdit,
  });

  final List<BeanBatch> batches;
  final VoidCallback onAdd;
  final ValueChanged<BeanBatch> onEdit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double total = batches.fold<double>(
      0,
      (sum, b) => sum + b.remainingGrams,
    );

    return FormSection(
      title: '批次（${batches.length}）',
      subtitle: total > 0 ? '当前总余量 ${formatNumber(total)} g' : '所有批次都已用完',
      children: <Widget>[
        if (batches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '这支豆子还没有批次，余量无处记录',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          )
        else
          for (final BeanBatch batch in batches)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                batch.isEmpty
                    ? Icons.remove_circle_outline
                    : Icons.inventory_2_outlined,
                color: batch.isEmpty
                    ? theme.colorScheme.outline
                    : theme.colorScheme.primary,
              ),
              title: Text(_batchTitle(batch)),
              subtitle: Text(_batchSubtitle(batch)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onEdit(batch),
            ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(addCircleIcon, size: 18),
            label: const Text('再来一袋'),
          ),
        ),
      ],
    );
  }

  static String _batchTitle(BeanBatch batch) {
    final DateTime? date = batch.roastDate;
    final String dateText = date == null ? '未记烘焙日期' : formatDateChinese(date);
    return '$dateText · 余 ${formatNumber(batch.remainingGrams)} g';
  }

  static String _batchSubtitle(BeanBatch batch) {
    final List<String> parts = <String>[];
    if (batch.roastLevel != null) parts.add(batch.roastLevel!.label);
    final int? age = batch.ageInDays();
    if (age != null && age >= 0) parts.add('烘焙 $age 天');
    final double? ratio = batch.consumedRatio();
    if (ratio != null) parts.add('已用 ${(ratio * 100).round()}%');
    final double? price = batch.price;
    if (price != null) parts.add('${formatNumber(price)} 元');
    return parts.isEmpty ? '点开可编辑' : parts.join(' · ');
  }
}
