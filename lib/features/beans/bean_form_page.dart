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

/// 「第一袋」两个必填项的**行内**错误文案。
///
/// 与 `_save()` 里那条可见提示（`_firstBatchHint`）用词不同：同一个字段在
/// 同一屏上不会出现两个文案相同的 `Text`（M3-T31）。
const String _roastDateRequiredMessage = '请填写烘焙日期';
const String _remainingRequiredMessage = '请填写剩余克数';

/// 名称为空时，**保存路径**给的那条可见提示（M3-T35）。
///
/// 与名称框的行内文案（`请填写豆子名称`）故意不同：名称框在 `ListView` 里
/// 可能根本没被构建、或者被滚出 cacheExtent 后连同它的 `FormField` 一起销毁
/// —— 那时行内错误既不会渲染、也不会参与 `validate()`。文案不同还保证了
/// 两者万一同屏（例如名称框可见但用户没填）时不会出现两个相同的 `Text`。
const String _nameRequiredHint = '请先填写豆子名称';

/// 「其它行内校验失败」的通用提示（M3-T33）。
///
/// `validate()` 只返回一个 bool，行内错误又可能落在视口之外；保存路径不能
/// 无声 `return`，否则用户只会觉得「点了没反应」。
const String _formInvalidHint = '表单还有未通过的校验，请检查标红提示';

/// 新增豆子时「剩余克数 > 购入总重」的**保存路径**提示（G5-S1）。
///
/// 与行内那条（`剩余克数不能大于购入总重（X g）`）用词不同，理由同上面几条：
/// 同屏时不会出现两个文案相同的 `Text`。
const String _gramsOverInitialHint = '剩余克数不能大于购入总重，请核对第一袋的两个数字';

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

  final Set<ProcessMethod> _processes = <ProcessMethod>{};
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
    _processes.addAll(bean?.processes ?? const <ProcessMethod>[]);
    _isFavorite = bean?.isFavorite ?? false;

    // 首个批次：**三项都不预填**（M3-T31）。
    // 「必填」= 必须主动确认：一打开就带着「今天 / 200 g」，用户什么都不选
    // 也能存下一袋没确认过的库存，等于必填形同虚设。
    _remaining = TextEditingController();
    // 购入总重是**选填**，但同样不预填：那个没人填过的 200 会反过来把
    // 「剩余克数不能大于购入总重」这条校验套在真实袋重上（250 g 的袋子
    // 会被一个用户从没输入过的数字拦住）。留空即不参与该校验。
    _initial = TextEditingController();
    _price = TextEditingController();
    _roastDate = null;
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

  /// 新增豆子时，「第一袋」缺项的**可见提示**（保存路径用）。
  ///
  /// 两个各自独立成立的坑：
  /// - 表单是 `ListView`，**视口外的控件根本不会被构建** → 那一段的 `FormField`
  ///   可能压根没注册进 `Form`，`validate()` 会直接放行（同一事实见
  ///   `test/helpers/widget_harness.dart` 的文件头与「为什么不能只用
  ///   `scrollUntilVisible`」一节）；
  /// - 即便那一段落在 `cacheExtent` 内被构建过、`validate()` 也确实返回 false，
  ///   行内错误也渲染在视口外 —— 用户点「保存」之后**屏幕上什么都不动**。
  ///
  /// 所以这条兜底**不看 `validate()` 的结果**，直接读 `_roastDate` 与
  /// `_remaining` 控制器。文案与行内（[_roastDateRequiredMessage] /
  /// [_remainingRequiredMessage]）故意不同：同屏时不会有两处渲染同一个 `Text`。
  String? _firstBatchHint() {
    if (_isEditing) return null;
    final bool noDate = _roastDate == null;
    final bool noGrams = parseNumber(_remaining.text) == null;
    if (noDate && noGrams) return '请先填写第一袋的烘焙日期与剩余克数';
    if (noDate) return '请先填写第一袋的烘焙日期';
    if (noGrams) return '请先填写第一袋的剩余克数';
    return null;
  }

  /// 「剩余克数 ≤ 购入总重」的**保存路径**兜底（G5-S1）。
  ///
  /// 这条规则只挂在「第一袋」余量框的行内 validator 上。`ListView` 的构建窗口
  /// （内容坐标）= `[offset - cacheExtent, offset + 视口高 + cacheExtent]`
  /// （`SliverList` 的终点再叠加 `scrollOffset + cacheOrigin`，两者抵消后就是
  /// 这个右端点）：列表停在顶部时窗口最小 —— 实测 320×568 下右端点只有 694，
  /// 而「第一袋」段顶在 786 → 那一段整段不在窗口内、`FormField` 随之注销，
  /// `validate()` 便会放行，于是「购入总重 200 / 剩余 250」会一路走到落库。
  /// 所以这里直读两个控制器。
  ///
  /// 编辑路径没有「第一袋」，天然返回 null；两边都留空则交给前面几级。
  String? _crossFieldGramsHint() {
    if (_isEditing) return null;
    final double? remaining = parseNumber(_remaining.text);
    final double? initial = parseNumber(_initial.text);
    if (remaining == null || initial == null) return null;
    if (remaining > initial) return _gramsOverInitialHint;
    return null;
  }

  /// 保存前的四条兜底，按优先级返回**唯一**一条给用户看的提示。
  ///
  /// 返回 null 表示「没有兜底要说的」——**不代表表单一定合法**，`formValid`
  /// 由调用方在 `validate()` 之后传进来。四条的顺序就是优先级：
  ///
  /// 1. 「第一袋」缺项（`_firstBatchHint()`）——**不看 `validate()` 结果**：
  ///    视口外那段的 `FormField` 可能压根没注册进 `Form`，`validate()` 会放行。
  /// 2. 名称为空——同样不依赖 `Form` 的注册表，直接读控制器（M3-T35）：
  ///    小屏上滚到「第一袋」时整段「基本信息」会被 `ListView` 销毁，名称框的
  ///    `FormField` 随之注销，空名称会一路走到数据库的 `name` 约束上，用户看到
  ///    的是 `保存失败：InvalidDataException…`。
  /// 3. 其它行内错误（最典型：余量 > 购入总重）——`validate()` 只返回一个
  ///    bool，行内错误又可能落在视口之外，无声 `return` 会被当成「点了没反应」
  ///    （M3-T33）。
  /// 4. 「剩余克数 > 购入总重」的 cross-field 兜底（`_crossFieldGramsHint()`，
  ///    G5-S1）——同样直读控制器：这条行内 validator 就挂在「第一袋」里，那一段
  ///    整段注销后 `validate()` 会返回 true，第 3 级因此也不会兜住它。
  ///
  /// 只返回一条，保存路径因此**只弹一条提示**；每条文案都与同字段的行内文案不同。
  String? _blockingHint({required bool formValid}) {
    final String? firstBatchHint = _firstBatchHint();
    if (firstBatchHint != null) return firstBatchHint;
    if (_name.text.trim().isEmpty) return _nameRequiredHint;
    if (!formValid) return _formInvalidHint;
    final String? crossFieldHint = _crossFieldGramsHint();
    if (crossFieldHint != null) return crossFieldHint;
    return null;
  }

  Future<void> _save() async {
    // `validate()` 必须最先跑：它负责在该段可见时把行内错误照常渲染出来，
    // 抢在它前面 `return` 会让行内错误永不出现（M3-T31 的教训）。
    final bool formValid = _formKey.currentState?.validate() ?? false;

    final String? blockingHint = _blockingHint(formValid: formValid);
    if (blockingHint != null) {
      _showMessage(blockingHint);
      return;
    }

    setState(() => _saving = true);

    final DateTime now = DateTime.now();
    final CoffeeBean base =
        widget.bean ?? CoffeeBean(name: '', createdAt: now, updatedAt: now);

    final CoffeeBean bean = base.copyWith(
      name: _name.text.trim(),
      origin: _origin.text.trim().isEmpty ? null : _origin.text.trim(),
      farm: _farm.text.trim().isEmpty ? null : _farm.text.trim(),
      processes: _processes.toList(growable: false),
      flavorTags: parseTags(_flavors.text),
      isFavorite: _isFavorite,
      updatedAt: now,
      clearOrigin: _origin.text.trim().isEmpty,
      clearFarm: _farm.text.trim().isEmpty,
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
                  helper: '可以多选（例如「水洗 + 厌氧」）；再点一次取消',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final ProcessMethod method
                          in ProcessMethod.selectable)
                        FilterChip(
                          key: Key('bean.process.${method.name}'),
                          label: Text(method.label),
                          selected: _processes.contains(method),
                          onSelected: (bool selected) => setState(() {
                            if (selected) {
                              _processes.add(method);
                            } else {
                              _processes.remove(method);
                            }
                          }),
                        ),
                    ],
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
    final ThemeData theme = Theme.of(context);

    return FormSection(
      title: '第一袋',
      subtitle: '烘焙日期与余量记在批次上；以后复购再加一袋即可',
      children: <Widget>[
        LabeledField(
          label: '烘焙日期',
          isRequired: true,
          // `DateField` 本身不是 `FormField`，包一层才能让「必填」和名称、
          // 剩余克数那样由 `_formKey.currentState.validate()` 一起触发。
          // 值仍以父级的 `roastDate` 为准：`builder` 里读 `field.value`，
          // 避免 FormField 只在 initState 认一次 `initialValue` 导致读旧值。
          child: FormField<DateTime?>(
            initialValue: roastDate,
            validator: (DateTime? value) =>
                value == null ? _roastDateRequiredMessage : null,
            builder: (FormFieldState<DateTime?> field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DateField(
                    value: field.value,
                    formatter: formatDateChinese,
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    onPick: (DateTime value) {
                      field.didChange(value);
                      onRoastDateChanged(value);
                    },
                    onClear: () {
                      field.didChange(null);
                      onRoastDateChanged(null);
                    },
                  ),
                  // 报错前这一列只有 DateField，与改动前的布局逐像素一致。
                  if (field.hasError) ...<Widget>[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        field.errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
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
          isRequired: true,
          child: NumberField(
            key: const Key('bean.remaining'),
            controller: remaining,
            hintText: '0',
            suffixText: 'g',
            onChanged: (_) => onNumberChanged(),
            validator: (String? value) {
              final double? r = parseNumber(value);
              if (r == null) return _remainingRequiredMessage;
              final double? i = parseNumber(initial.text);
              if (i != null && r > i) {
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
