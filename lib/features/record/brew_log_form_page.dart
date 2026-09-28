import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons.dart';
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
  ///
  /// 豆子（含拼配配方）会一起复制，但**批次清空**：那一袋很可能已经用完了，
  /// 留着它会让扣减落到空袋上。批次交给仓储按烘焙日期重新挑最新的一袋。
  static BrewLog copyFrom(BrewLog source, {DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    return BrewLog(
      beanId: source.beanId,
      beanUsages: <BeanUsage>[
        for (final BeanUsage usage in source.beanUsages)
          usage.copyWith(clearBatchId: true),
      ],
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

  /// 自定义方法的原文；为空表示用内置的 [_method]。
  String? _methodLabel;

  /// 这一杯用到的豆子（拼配时多于一支）。顺序就是 [BeanUsage.position]。
  late final List<_BeanPick> _picks;

  /// 打开时发现有几支豆子已被删除（用量行的 `beanId` 为空）。
  /// 这些行没法重新选中，保存后不再保留，所以要如实告诉用户。
  int _orphanUsageCount = 0;

  int? _grinderId;

  /// 写入时的磨豆机零点 / 每圈 click 快照。
  ///
  /// 「老研磨度关联老记录，新研磨度关联新记录」：编辑旧记录时沿用**当时**的
  /// 零点（不是磨豆机现在的），新建时取当前磨豆机的值。
  double? _grinderZeroPoint;
  int? _grinderClicksPerRevolution;
  int? _rating;
  bool _isBest = false;
  bool _isFavorite = false;

  /// 这条记录加的辅料（牛奶、糖浆…）。
  late final List<_AddIn> _addIns;

  /// 弹一次「选择辅料」面板用的历史项（最近用过）。
  List<String> _recentAddInNames = const <String>[];

  /// 时分是否已被确认过（编辑旧记录算已确认）。
  ///
  /// 只影响「选完日期要不要顺手弹时间」这一个行为，见 [_onBrewedDatePicked]。
  bool _timeConfirmed = false;
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
    _methodLabel = source?.methodLabel;
    _addIns = <_AddIn>[
      for (final BrewLogAddIn addIn in source?.addIns ?? const <BrewLogAddIn>[])
        _AddIn(name: addIn.name, amount: addIn.amount, unit: addIn.unit),
    ];
    _picks = _initialPicks(source);
    _grinderId = source?.grinderId;
    // 编辑旧记录：沿用当时的零点快照（= 老研磨度关联老记录）。
    _grinderZeroPoint = source?.grinderZeroPointSnapshot;
    _grinderClicksPerRevolution = source?.grinderClicksPerRevolutionSnapshot;
    // 复制上次时不继承评分与备注（见 copyFrom 的说明）。
    _rating = widget.existing?.rating;
    _isBest = widget.existing?.isBest ?? false;
    _isFavorite = widget.existing?.isFavorite ?? false;
    _preheatUpperChamber = source?.preheatUpperChamber;
    _brewedAt = widget.existing?.brewedAt ?? DateTime.now();
    // 编辑旧记录时，时分就是它当时真实的时间，不需要再确认一次。
    _timeConfirmed = widget.existing != null;

    if (_method != BrewMethod.pourOver && _method != BrewMethod.mokaPot) {
      _showAllMethods = true;
    }
  }

  @override
  void dispose() {
    for (final _AddIn addIn in _addIns) {
      addIn.dispose();
    }
    for (final _BeanPick pick in _picks) {
      pick.dispose();
    }
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
    if (!_validatePicks()) return;
    setState(() => _saving = true);

    final DateTime now = DateTime.now();
    final BrewLog base =
        widget.existing ??
        BrewLog(brewedAt: _brewedAt, createdAt: now, updatedAt: now);

    final int? primaryBeanId = _picks
        .where((p) => p.beanId != null)
        .firstOrNull
        ?.beanId;
    final int? totalTime = int.tryParse(_totalTime.text.trim());
    final BrewLog log = base.copyWith(
      beanId: primaryBeanId,
      grinderId: _grinderId,
      // 自定义方法归到「其他」那一档：库里的原文放 methodLabel，
      // 这样按 method 统计/筛选时自定义项不会混进「手冲」。
      method: _methodLabel == null ? _method : BrewMethod.other,
      methodLabel: _methodLabel,
      // 换刻度/重新校准前的老记录保留当时的零点与每圈 click（见 schema v7）。
      grinderZeroPointSnapshot: _grinderZeroPoint,
      grinderClicksPerRevolutionSnapshot: _grinderClicksPerRevolution,
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
      isFavorite: _isFavorite,
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
      clearBeanId: primaryBeanId == null,
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
      beanUsages: _usagesFromPicks(),
      addIns: <BrewLogAddIn>[
        for (int i = 0; i < _addIns.length; i++) _addIns[i].toEntity(i),
      ],
      clearMethodLabel: _methodLabel == null,
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
        _showMessage(
          result.stockAdjustments.length > 1
              ? '已保存，但有豆子余量不足，已扣至 0'
              : '已保存，但这支豆子余量不足，已扣至 0',
        );
      } else if (result.hasBatchFallback) {
        _showMessage('已保存。原来那一袋批次已不在，余量扣到了别的批次上');
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('保存失败：$error');
    }
  }

  // ---------------------------------------------------------------------------
  // 豆子与拼配
  // ---------------------------------------------------------------------------

  /// 从数据来源（编辑原记录 / 复制上次的预填）还原豆子列表。
  ///
  /// 拼配的占比是从**各支豆子的粉量**倒推的：一条记录只存总粉量
  /// （`brew_logs.doseGrams`）和每支豆子的粉量（`brew_log_beans.doseGrams`），
  /// 界面上的「占比」是这两者的比值。
  List<_BeanPick> _initialPicks(BrewLog? source) {
    final List<BeanUsage> usages = source?.beanUsages ?? const <BeanUsage>[];
    _orphanUsageCount = usages.where((u) => u.beanId == null).length;
    final List<BeanUsage> usable = usages
        .where((u) => u.beanId != null)
        .toList(growable: false);

    if (usable.isEmpty) {
      // 新记录（或旧记录没关联任何豆子）：留一个空行给用户选。
      return <_BeanPick>[_BeanPick(beanId: source?.beanId)];
    }
    if (usable.length == 1) {
      return <_BeanPick>[
        _BeanPick(
          beanId: usable.first.beanId,
          batchId: usable.first.batchId,
          beanName: usable.first.beanName,
        ),
      ];
    }

    final double total =
        source?.doseGrams ?? usable.fold<double>(0, (s, u) => s + u.doseGrams);
    return <_BeanPick>[
      for (final BeanUsage usage in usable)
        _BeanPick(
          beanId: usage.beanId,
          batchId: usage.batchId,
          beanName: usage.beanName,
          share: total > 0
              ? usage.doseGrams / total * 100
              : 100 / usable.length,
        ),
    ];
  }

  /// 是否拼配（多于一支豆子）。
  bool get _isBlend => _picks.length > 1;

  /// 占比合计。单支时恒为 100（那一支就是全部）。
  double get _shareSum => _picks.length < 2
      ? 100
      : _picks.fold<double>(0, (s, p) => s + (parseNumber(p.share.text) ?? 0));

  /// 归一化后的占比（合计正好 100）。
  ///
  /// 不直接用输入值，是为了容忍 33.3 + 33.3 + 33.4 这种输入；
  /// 合计偏离 100 太多的情况在 [_validatePicks] 里已经被拦下。
  double _shareOf(_BeanPick pick) {
    if (!_isBlend) return 100;
    final double sum = _shareSum;
    if (sum <= 0) return 0;
    return (parseNumber(pick.share.text) ?? 0) / sum * 100;
  }

  /// 这支豆子分到的粉量（按当前总粉量与占比实时算出来，给界面显示）。
  double _gramsOf(_BeanPick pick) {
    final double total = parseNumber(_dose.text) ?? 0;
    return roundGrams(total * _shareOf(pick) / 100);
  }

  /// 保存前的拼配校验。返回 false 表示已经提示过用户，不要继续。
  bool _validatePicks() {
    if (!_isBlend) return true;

    final double sum = _shareSum;
    if ((sum - 100).abs() > 0.5) {
      _showMessage('各支豆子的占比合计要等于 100%（现在是 ${formatNumber(sum)}%）');
      return false;
    }
    if (_picks.any((p) => p.beanId == null)) {
      _showMessage('有一支豆子还没选，请选上或删掉这一行');
      return false;
    }
    final List<int> ids = _picks
        .map((p) => p.beanId)
        .whereType<int>()
        .toList(growable: false);
    if (ids.length != ids.toSet().length) {
      _showMessage('同一支豆子不能在一条记录里选两次');
      return false;
    }
    return true;
  }

  /// 把「豆子 + 占比 + 总粉量」换算成记录关联的用量行。
  ///
  /// 余量自动扣减（手册 §6.2）就是按这些用量行的 `doseGrams` 走的：
  /// 新建时各支按各自粉量扣，编辑时按各支的差值补扣，换豆则旧豆回补。
  ///
  /// 未选豆子时返回空列表——既解除了关联，也让仓储把原来扣的余量回补。
  List<BeanUsage> _usagesFromPicks() {
    final List<_BeanPick> picks = _picks
        .where((p) => p.beanId != null)
        .toList(growable: false);
    if (picks.isEmpty) return const <BeanUsage>[];

    final double total = parseNumber(_dose.text) ?? 0;
    if (picks.length == 1) {
      final _BeanPick only = picks.first;
      return <BeanUsage>[
        BeanUsage(beanId: only.beanId, batchId: only.batchId, doseGrams: total),
      ];
    }

    // 拼配：按归一化占比分摊总粉量。**最后一支吃掉四舍五入的零头**，
    // 这样各支粉量之和一定等于总粉量，不会出现「加总比总粉量多 0.1g」。
    final List<BeanUsage> usages = <BeanUsage>[];
    double assigned = 0;
    for (int i = 0; i < picks.length; i++) {
      final _BeanPick pick = picks[i];
      final bool isLast = i == picks.length - 1;
      final double grams = isLast
          ? roundGrams(total - assigned)
          : roundGrams(total * _shareOf(pick) / 100);
      assigned = roundGrams(assigned + grams);
      usages.add(
        BeanUsage(
          beanId: pick.beanId,
          batchId: pick.batchId,
          doseGrams: grams < 0 ? 0 : grams,
          position: i,
        ),
      );
    }
    return usages;
  }

  void _addPick() {
    setState(() {
      if (_picks.length == 1) {
        // 1 → 2：默认对半分，省得用户先算一遍
        _picks[0].share.text = '50';
        _picks.add(_BeanPick(share: 50));
      } else {
        _picks.add(_BeanPick(share: 0));
      }
    });
  }

  void _removePick(int index) {
    setState(() {
      // 拿掉一支就把它的粉量从总粉量里减掉，剩下几支实际克数**保持不变**。
      // 否则「删掉 30% 那支」会把这 30% 悄悄转给剩下的豆子，余量跟着多扣。
      final double removed = _gramsOf(_picks[index]);
      final double? total = parseNumber(_dose.text);
      if (_isBlend && total != null) {
        _dose.text = numberToText(roundGrams(total - removed));
      }
      _picks.removeAt(index).dispose();
      if (_picks.length == 1) _picks.first.share.text = '100';
    });
  }

  Future<void> _delete() async {
    final int? id = widget.existing?.id;
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: const Text('删除后无法恢复。已扣减的豆子余量会自动回补。'),
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

  /// 选完日期后：新建的记录如果**从没设过时分**，顺手把时间选择器弹一次。
  ///
  /// 为什么只在「首次」弹：编辑旧记录时它的时分是当时真实的时间，
  /// 每改一次日期都弹一次是打扰；新建的第一次则确实该确认是几点。
  Future<void> _onBrewedDatePicked(DateTime date) async {
    setState(() => _brewedAt = withDate(_brewedAt, date));
    if (_timeConfirmed) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_brewedAt),
    );
    if (picked == null) return;
    setState(() {
      _brewedAt = withTime(_brewedAt, picked);
      _timeConfirmed = true;
    });
  }

  /// 单击复制按钮：直接复制**上次**那杯的参数。
  Future<void> _applyCopyFromLast() async {
    final BrewLog? latest = await ref
        .read(brewLogRepositoryProvider)
        .getLatest();
    if (!mounted) return;
    if (latest == null) {
      _showMessage('还没有可复制的记录');
      return;
    }
    _applyCopyFrom(latest, message: '已复制上次参数');
  }

  /// 长按复制按钮：从**收藏过的参数**里挑一条复制。
  ///
  /// 收藏是「这套参数我要留着再用」，所以这里的列表按冲煮时间倒序，
  /// 每条显示豆子 / 方法 / 刻度 / 粉水 / 评分，够判断选哪条。
  Future<void> _pickFavoriteToCopy() async {
    final List<BrewLog> favorites = await ref
        .read(brewLogRepositoryProvider)
        .getFavorites();
    if (!mounted) return;

    if (favorites.isEmpty) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) => const _NoFavoriteSheet(),
      );
      return;
    }

    final BrewLog? chosen = await showModalBottomSheet<BrewLog>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) =>
          _FavoritePickerSheet(favorites: favorites),
    );
    if (chosen == null || !mounted) return;
    _applyCopyFrom(chosen, message: '已复制收藏的参数');
  }

  /// 把一条记录的参数填进表单（复制上次 / 复制收藏共用）。
  ///
  /// 刻意不继承：评分、备注、最佳标记、收藏标记 —— 这是一杯新的咖啡，
  /// 要重新评价（见 [BrewLogFormPage.copyFrom] 的说明）。
  void _applyCopyFrom(BrewLog source, {required String message}) {
    final BrewLog copied = BrewLogFormPage.copyFrom(source);
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
      _methodLabel = copied.methodLabel;
      _resetPicks(copied);
      _grinderId = copied.grinderId;
      _grinderZeroPoint = copied.grinderZeroPointSnapshot;
      _grinderClicksPerRevolution = copied.grinderClicksPerRevolutionSnapshot;
      _preheatUpperChamber = copied.preheatUpperChamber;
      _rating = null;
      _isBest = false;
      _isFavorite = false;
    });
    _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 用「复制上次」的数据整体替换豆子列表（拼配也一起复制）。
  void _resetPicks(BrewLog copied) {
    for (final _BeanPick pick in _picks) {
      pick.dispose();
    }
    _picks
      ..clear()
      ..addAll(_initialPicks(copied));
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
            // 单击 = 复制上次；长按 = 从收藏过的参数里挑一条复制。
            // `IconButton` 没有 onLongPress，所以用 Tooltip + InkWell 自己拼。
            Tooltip(
              message: '单击复制上次参数\n长按选择收藏过的参数',
              child: InkWell(
                key: const Key('brew.copyLast'),
                customBorder: const CircleBorder(),
                onTap: _saving ? null : _applyCopyFromLast,
                onLongPress: _saving ? null : _pickFavoriteToCopy,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.content_copy_outlined),
                ),
              ),
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
                LabeledField(
                  label: '辅料',
                  helper: _addIns.isEmpty ? '牛奶、糖浆这类额外加的，可以只记名字不记量' : null,
                  child: _buildAddIns(),
                ),
                LabeledField(
                  label: '豆子',
                  helper: _isBlend ? '拼配：按占比分摊下面的总粉量' : null,
                  child: _buildBeanPicker(beans),
                ),
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
                  helper: '日期与时分各改各的',
                  child: DateTimeField(
                    value: _brewedAt,
                    dateKey: const Key('brew.brewedDate'),
                    timeKey: const Key('brew.brewedTime'),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    onDatePicked: _onBrewedDatePicked,
                    onTimePicked: (TimeOfDay time) =>
                        setState(() => _brewedAt = withTime(_brewedAt, time)),
                  ),
                ),
              ],
            ),
            FormSection(
              title: '核心参数',
              children: <Widget>[
                LabeledField(
                  label: _isBlend ? '总粉量' : '粉量',
                  helper: _isBlend ? '下面几支豆子的粉量加起来就是它' : null,
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
                SwitchListTile(
                  key: const Key('brew.isFavorite'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('收藏这套参数'),
                  subtitle: const Text('记录页右滑也能收藏；复制按钮长按可从收藏里挑'),
                  value: _isFavorite,
                  onChanged: (bool value) =>
                      setState(() => _isFavorite = value),
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

    // 自定义方法库（全局，见 SettingsKeys.customBrewMethods）。
    final List<String> customs =
        ref.watch(customBrewMethodsProvider).value ?? const <String>[];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final BrewMethod method in visible)
          ChoiceChip(
            label: Text(method.label),
            selected: _methodLabel == null && method == _method,
            onSelected: (bool selected) {
              if (selected) {
                setState(() {
                  _method = method;
                  _methodLabel = null;
                });
              }
            },
          ),
        // 自定义方法：与内置**同一款式**（测评反馈：新增项颜色要和默认项一致）。
        // 记录时归到「其他」那一档，见 [_save] 里的 method 取值。
        for (final String custom in customs)
          ChoiceChip(
            label: Text(custom),
            selected: _methodLabel == custom,
            onSelected: (bool selected) {
              if (selected) setState(() => _methodLabel = custom);
            },
            // ChoiceChip 没有 onLongPress，用 GestureDetector 包一层。
            // 用 InkWell 之外的包装不影响短按：短按由 chip 自己处理。
          ).withLongPress(() => _manageCustomMethod(custom)),
        ActionChip(
          key: const Key('brew.addMethod'),
          avatar: const Icon(Icons.add, size: 16),
          label: const Text('＋'),
          tooltip: '新建冲煮方法',
          onPressed: _saving ? null : _createCustomMethod,
        ),
        if (!showAll && visible.length < BrewMethod.values.length)
          ActionChip(
            label: const Text('更多方法'),
            onPressed: () => setState(() => _showAllMethods = true),
          ),
      ],
    );
  }

  /// 新建自定义方法：弹输入框 → 存进全局库 → 直接选中。
  Future<void> _createCustomMethod() async {
    final String? name = await _promptMethodName(title: '新的冲煮方法');
    if (name == null || !mounted) return;

    final List<String> current =
        ref.read(customBrewMethodsProvider).value ?? const <String>[];
    if (!current.contains(name)) {
      await ref.read(settingsRepositoryProvider).setCustomBrewMethods(<String>[
        ...current,
        name,
      ]);
    }
    if (!mounted) return;
    setState(() => _methodLabel = name);
  }

  /// 长按自定义方法：重命名 / 删除。
  ///
  /// 两者都只动**方法库**，历史记录里存的原文不变 —— 和豆名快照一个语义：
  /// 记录要能反映「当时是怎么冲的」。
  Future<void> _manageCustomMethod(String name) async {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('重命名「$name」'),
              subtitle: const Text('只改列表里的名字，历史记录保留原来的写法'),
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.error),
              title: Text(
                '从列表删除「$name」',
                style: TextStyle(color: colors.error),
              ),
              subtitle: const Text('已有的记录仍显示这个名字'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    final List<String> current = List<String>.of(
      ref.read(customBrewMethodsProvider).value ?? const <String>[],
    );

    if (action == 'delete') {
      current.remove(name);
      await ref.read(settingsRepositoryProvider).setCustomBrewMethods(current);
      if (!mounted) return;
      setState(() {
        // 正在用被删掉的方法：退回内置的手冲。
        if (_methodLabel == name) _methodLabel = null;
      });
      _showMessage('已从列表删除「$name」');
      return;
    }

    final String? renamed = await _promptMethodName(
      title: '重命名「$name」',
      initial: name,
    );
    if (renamed == null || !mounted || renamed == name) return;
    final int index = current.indexOf(name);
    if (index >= 0) current[index] = renamed;
    await ref.read(settingsRepositoryProvider).setCustomBrewMethods(current);
    if (!mounted) return;
    setState(() {
      if (_methodLabel == name) _methodLabel = renamed;
    });
  }

  /// 方法名的输入对话框（新建与重命名共用）。取消返回 null。
  ///
  /// 输入框由 [_MethodNameDialog] 自己持有并释放：在这里 `await showDialog`
  /// 之后立刻 dispose 会踩到「退场动画期间还在用同一个 controller」的断言
  /// （A TextEditingController was used after being disposed）。
  Future<String?> _promptMethodName({
    required String title,
    String initial = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          _MethodNameDialog(title: title, initial: initial),
    );
  }

  /// 辅料：一行一个（名字 + 数量 + 单位 + 删除），名字从「常用 / 最近用过 / 新建」里选。
  Widget _buildAddIns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < _addIns.length; i++) _buildAddInRow(i),
        if (_addIns.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '还没有加辅料',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('brew.addAddIn'),
            onPressed: _saving ? null : _pickAddIn,
            icon: const Icon(addCircleIcon, size: 18),
            label: const Text('添加辅料'),
          ),
        ),
      ],
    );
  }

  Widget _buildAddInRow(int index) {
    final _AddIn addIn = _addIns[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        // 三个框居中对齐（名字/数量/单位）。
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: InkWell(
              key: Key('brew.addInName.$index'),
              onTap: _saving ? null : () => _renameAddIn(index),
              child: InputDecorator(
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                child: Text(addIn.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: NumberField(
              key: Key('brew.addInAmount.$index'),
              controller: addIn.amount,
              hintText: '数量',
            ),
          ),
          const SizedBox(width: 4),
          // 单位：ml / g / 泵 / 份。
          // 外面套 SizedBox 给个确定宽度：InputDecorator 在无界宽度下会断言失败；
          // 顺带让它的边框与高度跟左边的名字/数量框对齐
          // （测评反馈：两个框大小不一致，要对齐）。
          SizedBox(
            width: 84,
            child: InputDecorator(
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AddInUnit>(
                  key: Key('brew.addInUnit.$index'),
                  value: addIn.unit,
                  isDense: true,
                  isExpanded: true,
                  items: <DropdownMenuItem<AddInUnit>>[
                    for (final AddInUnit unit in AddInUnit.selectable)
                      DropdownMenuItem<AddInUnit>(
                        value: unit,
                        child: Text(unit.label),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (AddInUnit? value) {
                          if (value == null) return;
                          setState(() => addIn.unit = value);
                        },
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '删掉这一项',
            onPressed: _saving
                ? null
                : () => setState(() => _addIns.removeAt(index).dispose()),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  /// 打开「选择辅料」面板：常用 / 最近用过 / 新建。
  Future<void> _pickAddIn() async {
    const List<String> common = <String>[
      '牛奶',
      '燕麦奶',
      '豆奶',
      '水',
      '冰块',
      '榛果糖浆',
      '焦糖酱',
      '糖',
    ];
    final List<String> recent = await ref
        .read(brewLogRepositoryProvider)
        .getRecentAddInNames();
    if (!mounted) return;
    _recentAddInNames = recent
        .where((String name) => !common.contains(name))
        .toList(growable: false);

    final String? name = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          _AddInPickerSheet(common: common, recent: _recentAddInNames),
    );
    if (name == null || !mounted) return;
    setState(() => _addIns.add(_AddIn(name: name)));
  }

  /// 改这一行的名字（复用选择面板）。
  Future<void> _renameAddIn(int index) async {
    final String? name = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => _AddInPickerSheet(
        common: const <String>[
          '牛奶',
          '燕麦奶',
          '豆奶',
          '水',
          '冰块',
          '榛果糖浆',
          '焦糖酱',
          '糖',
        ],
        recent: _recentAddInNames,
        title: '换一种辅料',
      ),
    );
    if (name == null || !mounted) return;
    setState(() => _addIns[index].name = name);
  }

  /// 豆子选择（含拼配）。
  ///
  /// 单支时不显示占比——那一支就是全部；一旦加到两支以上，每行多出「占比」，
  /// 各支按归一化占比分摊「核心参数」里的总粉量。这样总粉量始终只有一个
  /// 真值，不会出现「各支加起来和总粉量对不上」。
  Widget _buildBeanPicker(List<CoffeeBean> beans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < _picks.length; i++) _buildBeanRow(beans, i),
        if (_isBlend) _buildShareSummary(),
        if (_orphanUsageCount > 0)
          FormHint(
            message: _orphanUsageCount == 1
                ? '这条记录里有一支豆子已被删除；保存后它的用量行不再保留。'
                : '这条记录里有 $_orphanUsageCount 支豆子已被删除；保存后它们的用量行不再保留。',
            isWarning: true,
          ),
        if (beans.isEmpty)
          FormHint(
            message: '还没有咖啡豆。建议先添加一支，记录才能关联到豆子并自动扣减余量。',
            isWarning: true,
          ),
        Wrap(
          spacing: 4,
          children: <Widget>[
            TextButton.icon(
              key: const Key('brew.addBean'),
              onPressed: _saving ? null : _addBean,
              icon: const Icon(addCircleIcon, size: 18),
              label: const Text('新增豆子'),
            ),
            if (beans.isNotEmpty)
              TextButton.icon(
                key: const Key('brew.addPick'),
                onPressed: _saving ? null : _addPick,
                icon: const Icon(Icons.blender_outlined, size: 18),
                label: Text(_isBlend ? '再加一支' : '加一支（拼配）'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBeanRow(List<CoffeeBean> beans, int index) {
    final _BeanPick pick = _picks[index];
    // 同一支豆子不能在一条记录里选两次（仓储按 beanId 汇总差值，重复会算错），
    // 所以别的行已经选过的豆子不在这一行的候选里。
    final Set<int> takenElsewhere = <int>{
      for (int i = 0; i < _picks.length; i++)
        if (i != index && _picks[i].beanId != null) _picks[i].beanId!,
    };
    // 按 id 去重：豆子列表理论上不会重复，但一旦重复，
    // DropdownButton 会因为「同一 value 有多个 item」直接抛断言。
    final Map<int, CoffeeBean> byId = <int, CoffeeBean>{
      for (final CoffeeBean bean in beans)
        if (bean.id != null) bean.id!: bean,
    };

    final List<DropdownMenuItem<int?>> items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(child: Text('未指定')),
      for (final CoffeeBean bean in byId.values)
        if (bean.id == pick.beanId || !takenElsewhere.contains(bean.id))
          DropdownMenuItem<int?>(
            value: bean.id,
            child: Text(
              // 余量在批次上，这里只显示豆子名。
              bean.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
    ];
    // 选中的豆子还不在候选里（豆子列表尚在加载，或这支豆子刚被删掉）：
    // 补一个占位项，否则 DropdownButton 会因为「没有对应 value 的 item」抛断言。
    // 列表加载完/换成真名后，占位项自然消失。
    if (pick.beanId != null &&
        !items.any(
          (DropdownMenuItem<int?> item) => item.value == pick.beanId,
        )) {
      items.add(
        DropdownMenuItem<int?>(
          value: pick.beanId,
          child: Text(
            pick.beanName ?? '豆子#${pick.beanId}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    final Widget dropdown = DropdownButtonFormField<int?>(
      key: Key('brew.bean.$index'),
      initialValue: pick.beanId,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        hintText: '选择豆子',
      ),
      items: items,
      onChanged: (int? value) => setState(() {
        pick.beanId = value;
        pick.beanName = null;
        // 换了豆子，原来那一袋不能再沿用，交回给仓储按烘焙日期重挑。
        if (pick.batchId != null) pick.batchId = null;
      }),
    );

    if (!_isBlend) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: dropdown,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: dropdown),
              const SizedBox(width: 8),
              SizedBox(
                width: 104,
                child: NumberField(
                  key: Key('brew.share.$index'),
                  controller: pick.share,
                  hintText: '占比',
                  suffixText: '%',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                tooltip: '删掉这一支',
                onPressed: _saving ? null : () => _removePick(index),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          if (pick.beanId != null)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text(
                '这一支约 ${formatNumber(_gramsOf(pick))} g',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShareSummary() {
    final double sum = _shareSum;
    final bool ok = (sum - 100).abs() <= 0.5;
    final double total = parseNumber(_dose.text) ?? 0;

    return FormHint(
      message: ok
          ? '占比合计 100%，共 ${formatNumber(total)} g 由 ${_picks.length} 支豆子分摊'
          : '占比合计 ${formatNumber(sum)}%，要凑成 100% 才能保存',
      isWarning: !ok,
    );
  }

  Widget _buildGrinderSelector(List<Grinder> grinders) {
    final Map<int, Grinder> byId = <int, Grinder>{
      for (final Grinder grinder in grinders)
        if (grinder.id != null) grinder.id!: grinder,
    };
    final List<DropdownMenuItem<int?>> items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(child: Text('未指定')),
      for (final Grinder grinder in byId.values)
        DropdownMenuItem<int?>(
          value: grinder.id,
          child: Text(grinder.displayName(), overflow: TextOverflow.ellipsis),
        ),
    ];
    // 同豆子下拉：列表还在加载（或这台磨豆机刚被删）时补一个占位项，
    // 否则 initialValue 找不到对应的 item，DropdownButton 会直接抛断言。
    if (_grinderId != null &&
        !items.any((DropdownMenuItem<int?> item) => item.value == _grinderId)) {
      items.add(
        DropdownMenuItem<int?>(
          value: _grinderId,
          child: const Text('原磨豆机', overflow: TextOverflow.ellipsis),
        ),
      );
    }

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
          items: items,
          onChanged: (int? value) => setState(() {
            _grinderId = value;
            // 换了磨豆机就换成新机器的零点（还没选机器时清空）。
            final Grinder? picked = value == null
                ? null
                : grinders.where((Grinder g) => g.id == value).firstOrNull;
            _grinderZeroPoint = picked?.zeroPoint;
            _grinderClicksPerRevolution = picked?.clicksPerRevolution;
          }),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _saving ? null : _addGrinder,
            icon: const Icon(addCircleIcon, size: 18),
            label: const Text('新增磨豆机'),
          ),
        ),
      ],
    );
  }

  /// 内联新增豆子：保存后自动选中新豆。
  ///
  /// 挂在第一个还空着的行上；都选满了就新开一行（拼配时这是常见动作）。
  Future<void> _addBean() async {
    final bool changed = await BeanFormPage.show(context);
    if (!mounted || !changed) return;
    final List<CoffeeBean> beans = await ref
        .read(beanRepositoryProvider)
        .getAll();
    if (!mounted || beans.isEmpty) return;
    // 自增 id 最大的就是刚建的那支。列表按 createdAt 倒序，但 Drift 的
    // dateTime 只到秒，同一秒建的两支会并列，所以这里不看排序看 id。
    final int newId = _newestId(beans.map((CoffeeBean b) => b.id));

    setState(() {
      final _BeanPick? empty = _picks
          .where((p) => p.beanId == null)
          .firstOrNull;
      if (empty != null) {
        empty.beanId = newId;
        empty.batchId = null;
      } else {
        _addPickSilently(newId);
      }
    });
  }

  static int _newestId(Iterable<int?> ids) =>
      ids.whereType<int>().reduce((int a, int b) => a > b ? a : b);

  /// 加一行并选好豆子。调用方负责已经处在 `setState` 里或自行刷新。
  void _addPickSilently(int beanId) {
    if (_picks.length == 1) {
      _picks[0].share.text = '50';
      _picks.add(_BeanPick(beanId: beanId, share: 50));
    } else {
      _picks.add(_BeanPick(beanId: beanId, share: 0));
    }
  }

  /// 内联新增磨豆机：保存后自动选中新磨豆机。
  Future<void> _addGrinder() async {
    final bool changed = await GrinderFormPage.show(context);
    if (!mounted || !changed) return;
    final List<Grinder> grinders = await ref
        .read(grinderRepositoryProvider)
        .getAll();
    if (!mounted || grinders.isEmpty) return;
    final int newId = _newestId(grinders.map((Grinder g) => g.id));
    setState(() {
      _grinderId = newId;
      final Grinder picked = grinders.firstWhere((Grinder g) => g.id == newId);
      _grinderZeroPoint = picked.zeroPoint;
      _grinderClicksPerRevolution = picked.clicksPerRevolution;
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

/// 表单里的一支豆子。
///
/// [share] 是拼配占比的输入框（单支时不显示，恒等于 100%）。
/// [batchId] 只在编辑已有记录时带出来——新建时留空，让仓储按烘焙日期
/// 自己挑一袋（见 `BeanRepository.adjustStock`）。
class _BeanPick {
  _BeanPick({this.beanId, this.batchId, this.beanName, double share = 100})
    : share = TextEditingController(text: numberToText(share));

  int? beanId;
  int? batchId;

  /// 豆子名快照（来自用量行）。豆子列表还没加载出来时用它显示，
  /// 免得下拉框既没有候选也说不清选的是谁。
  String? beanName;

  final TextEditingController share;

  void dispose() => share.dispose();
}

/// 「复制收藏的参数」选择面板：列出收藏过的记录，点一条就复制。
class _FavoritePickerSheet extends StatelessWidget {
  const _FavoritePickerSheet({required this.favorites});

  final List<BrewLog> favorites;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              '复制收藏的参数',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: favorites.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final BrewLog log = favorites[index];
                return ListTile(
                  key: Key('brew.favorite.${log.id}'),
                  leading: Icon(
                    favoriteFilledIcon,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(log.beanLabel ?? '未指定豆子'),
                  subtitle: Text(_favoriteSubtitle(log)),
                  trailing: const Icon(Icons.content_copy_outlined, size: 20),
                  onTap: () => Navigator.of(context).pop(log),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// `手冲 · C40 22 · 15g / 240g · ★4 · 1月3日`。
  static String _favoriteSubtitle(BrewLog log) {
    final List<String> parts = <String>[
      log.method.label,
      if (log.grindSetting != null) '刻度 ${numberToText(log.grindSetting)}',
      if (log.doseGrams != null || log.waterGrams != null)
        '${numberToText(log.doseGrams)}g / ${numberToText(log.waterGrams)}g',
      if (log.rating != null) '★${log.rating}',
      formatDate(log.brewedAt.toLocal()),
    ];
    return parts.join(' · ');
  }
}

/// 一条收藏都没有时的提示。
class _NoFavoriteSheet extends StatelessWidget {
  const _NoFavoriteSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  favoriteIcon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '还没有收藏的参数',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('在「记录」里向左滑动一条记录，点「收藏」就能存下这套参数；以后长按这里就能挑出来复制。'),
          ],
        ),
      ),
    );
  }
}

/// 表单里的一条辅料。
///
/// 名字在写入记录时成为**文本快照**（见 `BrewLogAddIn`），
/// 所以这里不需要引用任何「辅料表」——辅料库是从历史记录聚合出来的。
class _AddIn {
  _AddIn({required this.name, double? amount, this.unit = AddInUnit.ml})
    : amount = TextEditingController(text: numberToText(amount));

  String name;
  final TextEditingController amount;
  AddInUnit unit;

  BrewLogAddIn toEntity(int position) => BrewLogAddIn(
    name: name,
    amount: parseNumber(amount.text),
    unit: unit,
    position: position,
  );

  void dispose() => amount.dispose();
}

/// 给任意 widget 套一个长按（`ChoiceChip` 自己没有 `onLongPress`）。
extension _LongPressable on Widget {
  Widget withLongPress(VoidCallback onLongPress) =>
      GestureDetector(onLongPress: onLongPress, child: this);
}

/// 输入冲煮方法名的对话框。
///
/// 自己持有 [TextEditingController] 并在 `dispose` 里释放 ——
/// 由调用方 `await showDialog` 之后释放会踩到「退场动画还在用 controller」的断言。
class _MethodNameDialog extends StatefulWidget {
  const _MethodNameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_MethodNameDialog> createState() => _MethodNameDialogState();
}

class _MethodNameDialogState extends State<_MethodNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('brew.methodName'),
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(hintText: '例如：拿铁、摩卡、燕麦拿铁'),
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

/// 「选择辅料」面板：常用 / 最近用过 / 新建。
class _AddInPickerSheet extends StatefulWidget {
  const _AddInPickerSheet({
    required this.common,
    required this.recent,
    this.title = '选择辅料',
  });

  final List<String> common;
  final List<String> recent;
  final String title;

  @override
  State<_AddInPickerSheet> createState() => _AddInPickerSheetState();
}

class _AddInPickerSheetState extends State<_AddInPickerSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget group(String title, List<String> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String item in items)
                ActionChip(
                  key: Key('brew.addInOption.$item'),
                  label: Text(item),
                  onPressed: () => Navigator.of(context).pop(item),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        // 键盘弹起时把面板顶上去。
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            group('常用', widget.common),
            group('最近用过', widget.recent),
            Text('新建', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('brew.addInName'),
                    controller: _controller,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      hintText: '输入辅料名…',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _submit, child: const Text('添加')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
