import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/form_fields.dart';
import '../../data/providers.dart';
import '../../data/repositories/brew_log_repository.dart';
import '../../domain/entities.dart';
import '../../domain/enums.dart';
import '../beans/bean_form_page.dart';
import '../beans/grinder_form_page.dart';

/// 冲煮记录表单（手册 §7「冲煮记录」）。
///
/// 三种入口：
/// - [BrewLogFormPage.show] 新增（可选预填数据）
/// - [BrewLogFormPage.show] 传入 `existing` 编辑
/// - 记录页 FAB 走「复制上次」：把最近一条的参数预填，但**不带评分与备注**，
///   因为这是一杯新的咖啡，需要重新评价。
class BrewLogFormPage extends ConsumerStatefulWidget {
  const BrewLogFormPage({super.key, this.existing, this.prefill});

  /// 编辑已有记录。
  final BrewLog? existing;

  /// 新增时的预填数据（通常是「上次」的参数）。
  final BrewLog? prefill;

  /// 打开表单。返回 `true` 表示已保存或删除。
  static Future<bool> show(
    BuildContext context, {
    BrewLog? existing,
    BrewLog? prefill,
  }) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext context) =>
            BrewLogFormPage(existing: existing, prefill: prefill),
      ),
    );
    return changed ?? false;
  }

  /// 从一条旧记录生成「复制上次」的预填数据。
  ///
  /// 刻意清空：`id`（保持 null，否则会被当成编辑那条旧记录）、`rating`、
  /// `notes`、`photoPath`、`isBest`，并把冲煮时间设为当前时间。
  static BrewLog copyFrom(BrewLog source, {DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    return BrewLog(
      beanId: source.beanId,
      grinderId: source.grinderId,
      recipeId: source.recipeId,
      method: source.method,
      grindSetting: source.grindSetting,
      grindClicks: source.grindClicks,
      doseGrams: source.doseGrams,
      waterGrams: source.waterGrams,
      ratio: source.ratio,
      waterTemp: source.waterTemp,
      totalTimeSeconds: source.totalTimeSeconds,
      dripper: source.dripper,
      flavorTags: source.flavorTags,
      brewedAt: timestamp,
      tds: source.tds,
      extractionYield: source.extractionYield,
      waterPpm: source.waterPpm,
      ambientTemp: source.ambientTemp,
      ambientHumidity: source.ambientHumidity,
      beanTemp: source.beanTemp,
      pressure: source.pressure,
      pourStages: source.pourStages,
      heatLevel: source.heatLevel,
      yieldGrams: source.yieldGrams,
      preheatUpperChamber: source.preheatUpperChamber,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  @override
  ConsumerState<BrewLogFormPage> createState() => _BrewLogFormPageState();
}

class _BrewLogFormPageState extends ConsumerState<BrewLogFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _grindSetting;
  late final TextEditingController _grindClicks;
  late final TextEditingController _dose;
  late final TextEditingController _water;
  late final TextEditingController _waterTemp;
  late final TextEditingController _totalTime;
  late final TextEditingController _dripper;
  late final TextEditingController _flavors;
  late final TextEditingController _notes;
  late final TextEditingController _tds;
  late final TextEditingController _extractionYield;
  late final TextEditingController _waterPpm;
  late final TextEditingController _ambientTemp;
  late final TextEditingController _ambientHumidity;
  late final TextEditingController _beanTemp;
  late final TextEditingController _pressure;
  late final TextEditingController _heatLevel;
  late final TextEditingController _yieldGrams;

  BrewMethod _method = BrewMethod.pourOver;
  int? _beanId;
  int? _grinderId;
  int? _rating;
  bool _isBest = false;
  bool? _preheatUpperChamber;
  DateTime _brewedAt = DateTime.now();
  bool _advancedExpanded = false;
  bool _showAllMethods = false;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  /// 表单的数据来源：编辑取原记录，新增取预填。
  BrewLog? get _source => widget.existing ?? widget.prefill;

  @override
  void initState() {
    super.initState();
    final BrewLog? source = _source;
    _grindSetting = TextEditingController(
      text: numberToText(source?.grindSetting),
    );
    _grindClicks = TextEditingController(
      text: source?.grindClicks?.toString() ?? '',
    );
    _dose = TextEditingController(text: numberToText(source?.doseGrams));
    _water = TextEditingController(text: numberToText(source?.waterGrams));
    _waterTemp = TextEditingController(text: numberToText(source?.waterTemp));
    _totalTime = TextEditingController(
      text: source?.totalTimeSeconds?.toString() ?? '',
    );
    _dripper = TextEditingController(text: source?.dripper ?? '');
    _flavors = TextEditingController(text: source?.flavorTags.join('、') ?? '');
    _notes = TextEditingController(text: source?.notes ?? '');
    _tds = TextEditingController(text: numberToText(source?.tds));
    _extractionYield = TextEditingController(
      text: numberToText(source?.extractionYield),
    );
    _waterPpm = TextEditingController(text: source?.waterPpm?.toString() ?? '');
    _ambientTemp = TextEditingController(
      text: numberToText(source?.ambientTemp),
    );
    _ambientHumidity = TextEditingController(
      text: numberToText(source?.ambientHumidity),
    );
    _beanTemp = TextEditingController(text: numberToText(source?.beanTemp));
    _pressure = TextEditingController(text: numberToText(source?.pressure));
    _heatLevel = TextEditingController(text: source?.heatLevel ?? '');
    _yieldGrams = TextEditingController(text: numberToText(source?.yieldGrams));

    _method = source?.method ?? BrewMethod.pourOver;
    _beanId = source?.beanId;
    _grinderId = source?.grinderId;
    // 复制上次时不继承评分与备注（见 copyFrom 的说明）。
    _rating = widget.existing?.rating;
    _isBest = widget.existing?.isBest ?? false;
    _preheatUpperChamber = source?.preheatUpperChamber;
    _brewedAt = widget.existing?.brewedAt ?? DateTime.now();

    if (_method != BrewMethod.pourOver && _method != BrewMethod.mokaPot) {
      _showAllMethods = true;
    }
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _grindSetting,
      _grindClicks,
      _dose,
      _water,
      _waterTemp,
      _totalTime,
      _dripper,
      _flavors,
      _notes,
      _tds,
      _extractionYield,
      _waterPpm,
      _ambientTemp,
      _ambientHumidity,
      _beanTemp,
      _pressure,
      _heatLevel,
      _yieldGrams,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final DateTime now = DateTime.now();
    final BrewLog base =
        widget.existing ??
        BrewLog(brewedAt: _brewedAt, createdAt: now, updatedAt: now);

    final int? totalTime = int.tryParse(_totalTime.text.trim());
    final BrewLog log = base.copyWith(
      beanId: _beanId,
      grinderId: _grinderId,
      method: _method,
      grindSetting: parseNumber(_grindSetting.text),
      grindClicks: int.tryParse(_grindClicks.text.trim()),
      doseGrams: parseNumber(_dose.text),
      waterGrams: parseNumber(_water.text),
      waterTemp: parseNumber(_waterTemp.text),
      totalTimeSeconds: totalTime,
      dripper: _dripper.text.trim().isEmpty ? null : _dripper.text.trim(),
      rating: _rating,
      flavorTags: parseTags(_flavors.text),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      brewedAt: _brewedAt,
      isBest: _isBest,
      tds: parseNumber(_tds.text),
      extractionYield: parseNumber(_extractionYield.text),
      waterPpm: int.tryParse(_waterPpm.text.trim()),
      ambientTemp: parseNumber(_ambientTemp.text),
      ambientHumidity: parseNumber(_ambientHumidity.text),
      beanTemp: parseNumber(_beanTemp.text),
      pressure: parseNumber(_pressure.text),
      heatLevel: _heatLevel.text.trim().isEmpty ? null : _heatLevel.text.trim(),
      yieldGrams: parseNumber(_yieldGrams.text),
      preheatUpperChamber: _method == BrewMethod.mokaPot
          ? _preheatUpperChamber
          : null,
      updatedAt: now,
      clearBeanId: _beanId == null,
      clearGrinderId: _grinderId == null,
      clearGrindSetting: parseNumber(_grindSetting.text) == null,
      clearGrindClicks: int.tryParse(_grindClicks.text.trim()) == null,
      clearDoseGrams: parseNumber(_dose.text) == null,
      clearWaterGrams: parseNumber(_water.text) == null,
      clearWaterTemp: parseNumber(_waterTemp.text) == null,
      clearTotalTimeSeconds: totalTime == null,
      clearDripper: _dripper.text.trim().isEmpty,
      clearRating: _rating == null,
      clearNotes: _notes.text.trim().isEmpty,
      clearTds: parseNumber(_tds.text) == null,
      clearExtractionYield: parseNumber(_extractionYield.text) == null,
      clearWaterPpm: int.tryParse(_waterPpm.text.trim()) == null,
      clearAmbientTemp: parseNumber(_ambientTemp.text) == null,
      clearAmbientHumidity: parseNumber(_ambientHumidity.text) == null,
      clearBeanTemp: parseNumber(_beanTemp.text) == null,
      clearPressure: parseNumber(_pressure.text) == null,
      clearHeatLevel: _heatLevel.text.trim().isEmpty,
      clearYieldGrams: parseNumber(_yieldGrams.text) == null,
      clearPreheatUpperChamber: _preheatUpperChamber == null,
    );

    try {
      final bool autoDeduct = await ref
          .read(settingsRepositoryProvider)
          .getAutoDeductStock();
      final SaveBrewLogResult result = await ref
          .read(brewLogRepositoryProvider)
          .save(log, autoDeductStock: autoDeduct);

      if (!mounted) return;
      if (result.hasStockShortage) {
        _showMessage('已保存，但这支豆子余量不足，已扣至 0');
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('保存失败：$error');
    }
  }

  Future<void> _delete() async {
    final int? id = widget.existing?.id;
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: const Text('删除后无法恢复。已扣减的豆子余量不会自动回补。'),
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
      await ref.read(brewLogRepositoryProvider).delete(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage('删除失败：$error');
    }
  }

  /// 手动再复制一次「上次」。仅新增时有意义。
  Future<void> _applyCopyFromLast() async {
    final BrewLog? latest = await ref
        .read(brewLogRepositoryProvider)
        .getLatest();
    if (!mounted) return;
    if (latest == null) {
      _showMessage('还没有可复制的记录');
      return;
    }
    final BrewLog copied = BrewLogFormPage.copyFrom(latest);
    setState(() {
      _grindSetting.text = numberToText(copied.grindSetting);
      _grindClicks.text = copied.grindClicks?.toString() ?? '';
      _dose.text = numberToText(copied.doseGrams);
      _water.text = numberToText(copied.waterGrams);
      _waterTemp.text = numberToText(copied.waterTemp);
      _totalTime.text = copied.totalTimeSeconds?.toString() ?? '';
      _dripper.text = copied.dripper ?? '';
      _flavors.text = copied.flavorTags.join('、');
      _tds.text = numberToText(copied.tds);
      _extractionYield.text = numberToText(copied.extractionYield);
      _waterPpm.text = copied.waterPpm?.toString() ?? '';
      _ambientTemp.text = numberToText(copied.ambientTemp);
      _ambientHumidity.text = numberToText(copied.ambientHumidity);
      _beanTemp.text = numberToText(copied.beanTemp);
      _pressure.text = numberToText(copied.pressure);
      _heatLevel.text = copied.heatLevel ?? '';
      _yieldGrams.text = numberToText(copied.yieldGrams);
      _method = copied.method;
      _beanId = copied.beanId;
      _grinderId = copied.grinderId;
      _preheatUpperChamber = copied.preheatUpperChamber;
      _rating = null;
      _isBest = false;
    });
    _showMessage('已复制上次参数');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final List<CoffeeBean> beans =
        ref.watch(beanListProvider).value ?? const <CoffeeBean>[];
    final List<Grinder> grinders =
        ref.watch(grinderListProvider).value ?? const <Grinder>[];

    final Grinder? selectedGrinder = _grinderId == null
        ? null
        : grinders.where((Grinder g) => g.id == _grinderId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑记录' : '记录一杯'),
        actions: <Widget>[
          if (!_isEditing)
            IconButton(
              onPressed: _saving ? null : _applyCopyFromLast,
              tooltip: '复制上次',
              icon: const Icon(Icons.content_copy_outlined),
            ),
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
              title: '这一杯',
              children: <Widget>[
                LabeledField(
                  label: '冲煮方法',
                  isRequired: true,
                  child: _buildMethodSelector(),
                ),
                LabeledField(label: '豆子', child: _buildBeanSelector(beans)),
                LabeledField(
                  label: '磨豆机',
                  child: _buildGrinderSelector(grinders),
                ),
                LabeledField(
                  label: '研磨刻度',
                  helper: selectedGrinder == null
                      ? '选择磨豆机后会显示手册 §7 的展示格式'
                      : selectedGrinder.displayName(
                          grindSetting: parseNumber(_grindSetting.text),
                          clicks: int.tryParse(_grindClicks.text.trim()),
                        ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: NumberField(
                          key: const Key('brew.grindSetting'),
                          controller: _grindSetting,
                          hintText: selectedGrinder?.scaleUnit.label ?? '刻度',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: IntField(
                          key: const Key('brew.grindClicks'),
                          controller: _grindClicks,
                          hintText: 'click',
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                ),
                LabeledField(
                  label: '冲煮时间',
                  child: DateField(
                    value: _brewedAt,
                    hintText: '选择冲煮时间',
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    onPick: (DateTime value) =>
                        setState(() => _brewedAt = value),
                  ),
                ),
              ],
            ),
            FormSection(
              title: '核心参数',
              children: <Widget>[
                LabeledField(
                  label: '粉量',
                  child: NumberField(
                    key: const Key('brew.dose'),
                    controller: _dose,
                    hintText: '例如：15',
                    suffixText: 'g',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                LabeledField(
                  label: '水量',
                  helper: _ratioHint(),
                  child: NumberField(
                    key: const Key('brew.water'),
                    controller: _water,
                    hintText: '例如：240',
                    suffixText: 'g',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                LabeledField(
                  label: '水温',
                  child: NumberField(
                    key: const Key('brew.waterTemp'),
                    controller: _waterTemp,
                    hintText: '例如：92',
                    suffixText: '℃',
                  ),
                ),
                LabeledField(
                  label: '总时间',
                  helper: _timeHint(),
                  child: IntField(
                    key: const Key('brew.totalTime'),
                    controller: _totalTime,
                    hintText: '例如：155',
                    suffixText: '秒',
                  ),
                ),
                LabeledField(
                  label: '滤杯',
                  child: PlainTextField(
                    key: const Key('brew.dripper'),
                    controller: _dripper,
                    hintText: '例如：V60 02',
                  ),
                ),
              ],
            ),
            if (_method == BrewMethod.mokaPot)
              FormSection(
                title: '摩卡壶',
                subtitle: '手册 §7 的摩卡壶专属字段',
                children: <Widget>[
                  LabeledField(
                    label: '火力',
                    child: EnumSelector<String>(
                      values: const <String>['小火', '中火', '大火'],
                      selected: _heatLevel.text.isEmpty
                          ? null
                          : _heatLevel.text,
                      allowDeselect: true,
                      labelOf: (String value) => value,
                      onSelected: (String? value) =>
                          setState(() => _heatLevel.text = value ?? ''),
                    ),
                  ),
                  LabeledField(
                    label: '出液量',
                    child: NumberField(
                      controller: _yieldGrams,
                      hintText: '例如：60',
                      suffixText: 'g',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('上壶预热'),
                    value: _preheatUpperChamber ?? false,
                    onChanged: (bool value) =>
                        setState(() => _preheatUpperChamber = value),
                  ),
                ],
              ),
            FormSection(
              title: '评价',
              children: <Widget>[
                LabeledField(
                  label: '评分',
                  child: RatingSelector(
                    value: _rating,
                    onChanged: (int? value) => setState(() => _rating = value),
                  ),
                ),
                LabeledField(
                  label: '风味标签',
                  helper: '用「、」或逗号分隔',
                  child: PlainTextField(
                    controller: _flavors,
                    hintText: '柑橘、花香',
                  ),
                ),
                LabeledField(
                  label: '备注',
                  child: PlainTextField(
                    controller: _notes,
                    hintText: '这一杯喝起来怎么样？下次怎么调整？',
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('标记为最佳参数'),
                  subtitle: const Text('调磨对比时一眼看出哪一杯最好'),
                  value: _isBest,
                  onChanged: (bool value) => setState(() => _isBest = value),
                ),
              ],
            ),
            FormSection(
              title: '专业字段',
              subtitle: '新手可以忽略，展开后填写',
              children: <Widget>[
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  initiallyExpanded: _advancedExpanded,
                  onExpansionChanged: (bool value) =>
                      setState(() => _advancedExpanded = value),
                  title: const Text('TDS、水质、环境与压力'),
                  children: <Widget>[
                    LabeledField(
                      label: 'TDS',
                      child: NumberField(
                        controller: _tds,
                        hintText: '例如：1.35',
                        suffixText: '%',
                      ),
                    ),
                    LabeledField(
                      label: '萃取率',
                      child: NumberField(
                        controller: _extractionYield,
                        hintText: '例如：20.1',
                        suffixText: '%',
                      ),
                    ),
                    LabeledField(
                      label: '水质 ppm',
                      child: IntField(
                        controller: _waterPpm,
                        hintText: '例如：80',
                        suffixText: 'ppm',
                      ),
                    ),
                    LabeledField(
                      label: '环境温度',
                      child: NumberField(
                        controller: _ambientTemp,
                        hintText: '例如：24',
                        suffixText: '℃',
                      ),
                    ),
                    LabeledField(
                      label: '环境湿度',
                      child: NumberField(
                        controller: _ambientHumidity,
                        hintText: '例如：55',
                        suffixText: '%',
                      ),
                    ),
                    LabeledField(
                      label: '豆温',
                      child: NumberField(
                        controller: _beanTemp,
                        hintText: '例如：22',
                        suffixText: '℃',
                      ),
                    ),
                    LabeledField(
                      label: '压力',
                      child: NumberField(
                        controller: _pressure,
                        hintText: '例如：1.2',
                        suffixText: 'bar',
                      ),
                    ),
                  ],
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

  Widget _buildMethodSelector() {
    final bool showAll = _showAllMethods;
    final List<BrewMethod> visible = showAll
        ? BrewMethod.values
        : BrewMethod.values
              .where(
                (BrewMethod m) =>
                    BrewMethod.primary.contains(m) || m == _method,
              )
              .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final BrewMethod method in visible)
          ChoiceChip(
            label: Text(method.label),
            selected: method == _method,
            onSelected: (bool selected) {
              if (selected) setState(() => _method = method);
            },
          ),
        if (!showAll && visible.length < BrewMethod.values.length)
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('更多方法'),
            onPressed: () => setState(() => _showAllMethods = true),
          ),
      ],
    );
  }

  Widget _buildBeanSelector(List<CoffeeBean> beans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<int?>(
          initialValue: _beanId,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: '选择豆子',
          ),
          items: <DropdownMenuItem<int?>>[
            const DropdownMenuItem<int?>(child: Text('未指定')),
            for (final CoffeeBean bean in beans)
              DropdownMenuItem<int?>(
                value: bean.id,
                child: Text(
                  // 余量在批次上，这里只显示豆子名；余量提示见下方。
                  bean.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (int? value) => setState(() => _beanId = value),
        ),
        if (beans.isEmpty)
          FormHint(
            message: '还没有咖啡豆。建议先添加一支，记录才能关联到豆子并自动扣减余量。',
            isWarning: true,
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _saving ? null : _addBean,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新增豆子'),
          ),
        ),
      ],
    );
  }

  Widget _buildGrinderSelector(List<Grinder> grinders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<int?>(
          initialValue: _grinderId,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: '选择磨豆机',
          ),
          items: <DropdownMenuItem<int?>>[
            const DropdownMenuItem<int?>(child: Text('未指定')),
            for (final Grinder grinder in grinders)
              DropdownMenuItem<int?>(
                value: grinder.id,
                child: Text(
                  grinder.displayName(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (int? value) => setState(() => _grinderId = value),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _saving ? null : _addGrinder,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新增磨豆机'),
          ),
        ),
      ],
    );
  }

  /// 内联新增豆子：保存后自动选中新豆。
  Future<void> _addBean() async {
    final bool changed = await BeanFormPage.show(context);
    if (!mounted || !changed) return;
    final List<CoffeeBean> beans = await ref
        .read(beanRepositoryProvider)
        .getAll();
    if (!mounted) return;
    setState(() {
      _beanId = beans.isEmpty ? _beanId : beans.first.id;
    });
  }

  /// 内联新增磨豆机：保存后自动选中新磨豆机。
  Future<void> _addGrinder() async {
    final bool changed = await GrinderFormPage.show(context);
    if (!mounted || !changed) return;
    final List<Grinder> grinders = await ref
        .read(grinderRepositoryProvider)
        .getAll();
    if (!mounted) return;
    setState(() {
      _grinderId = grinders.isEmpty ? _grinderId : grinders.last.id;
    });
  }

  String? _ratioHint() {
    final double? dose = parseNumber(_dose.text);
    final double? water = parseNumber(_water.text);
    if (dose == null || water == null || dose <= 0) {
      return '填写粉量与水量后可自动算出粉水比';
    }
    return '粉水比 1 : ${formatNumber(water / dose)}';
  }

  String? _timeHint() {
    final int? seconds = int.tryParse(_totalTime.text.trim());
    if (seconds == null) return null;
    return '即 ${formatDuration(seconds)}';
  }
}
