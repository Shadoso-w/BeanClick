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
  const BrewLogFormPage({
    super.key,
    this.existing,
    this.prefill,
    this.initialBrewedAt,
  });

  /// 编辑已有记录。
  final BrewLog? existing;

  /// 新增时的预填数据（通常是「上次」的参数）。
  final BrewLog? prefill;

  /// 新增时的「冲煮时间」初始值（不传就是打开表单的那一刻）。
  ///
  /// 存在的理由只有一个：**让渲染稿/golden 可复现**。
  /// 不注入时新建表单的时间来自 `DateTime.now()`，于是每次渲染出的日期/时间文本
  /// 都不一样 —— 截图比对必然失败（生产代码不受影响，行为与 `DateTime.now()` 完全一致）。
  final DateTime? initialBrewedAt;

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

  /// 相对刻度：`圈 × 每圈 click + click − 零点`（M3-T15 定稿规则）。
  ///
  /// **零点与每圈 click 优先取磨豆机当前的值**；磨豆机被删（[grinder] 为 null）
  /// 或该字段为空时，回落到记录里的快照（[zeroPointSnapshot] /
  /// [clicksPerRevolutionSnapshot]）。两个值各回各的：当前值缺一个，
  /// 不会连带另一个也回落。
  ///
  /// 放在页面上是因为记录卡片（`record_page.dart` 的 `_grindLabel`）与表单提示
  /// （[_BrewLogFormPageState._grindHelper]）共用它 —— 两处必须算同一个数。
  /// 「每圈 click」两处都取不到时返回 null：宁可不显示，也不瞎算。
  static double? relativeClicks({
    required double? turns,
    required int? clicks,
    Grinder? grinder,
    double? zeroPointSnapshot,
    int? clicksPerRevolutionSnapshot,
  }) => Grinder.relativeClicksWith(
    turns: turns,
    clicks: clicks,
    clicksPerRevolution:
        grinder?.clicksPerRevolution ?? clicksPerRevolutionSnapshot,
    zeroPoint: grinder?.zeroPoint ?? zeroPointSnapshot,
  );

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

  /// 总时间的「分」与「秒」两个框（M3-T15）；内部仍只存总秒数。
  late final TextEditingController _totalTimeMin;
  late final TextEditingController _totalTimeSec;
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

  /// 打开时的**原始文本**（M3-T22 / B1）：上下限只对「这次改动过的值」生效。
  ///
  /// 库里可能存着加上下限之前的越界值 —— `doseGrams` / `waterGrams` /
  /// `waterTemp` 在 HEAD 上根本没有 validator，`totalTimeSeconds` 也可能是
  /// 3600 以上（旧上限下 3600 秒连合法写法都没有）。历史记录不该一打开就飘红、
  /// 更不该「没有合法表示」而改不动。校验时先比原值，相等直接放行。
  late final String _originalDoseText;
  late final String _originalWaterText;
  late final String _originalWaterTempText;
  late final int? _originalTotalSeconds;

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

  /// 新建时的「冲煮时间」：优先用注入值（渲染稿要可复现），否则就是打开表单的那一刻。
  ///
  /// 用 `late` 才能读 `widget`；[initState] 里还会按「编辑既有记录」再赋一次。
  late DateTime _brewedAt = widget.initialBrewedAt ?? DateTime.now();
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
    _grindSetting = TextEditingController();
    _grindClicks = TextEditingController();
    _dose = TextEditingController(text: numberToText(source?.doseGrams));
    _water = TextEditingController(text: numberToText(source?.waterGrams));
    _waterTemp = TextEditingController(text: numberToText(source?.waterTemp));
    _totalTimeMin = TextEditingController(
      text: _minutesText(source?.totalTimeSeconds),
    );
    _totalTimeSec = TextEditingController(
      text: _secondsText(source?.totalTimeSeconds),
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

    // 记住打开时的原值（见 [_originalDoseText]）：控制器都建好之后才能取。
    _originalDoseText = _dose.text;
    _originalWaterText = _water.text;
    _originalWaterTempText = _waterTemp.text;
    _originalTotalSeconds = _totalSecondsInput;

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
    // 研磨读数的写法由「小数刻度」改成「整数圈 + click」，旧记录在这里折算
    // （放在快照赋值之后：折算要用当时的每圈 click）。
    _setGrindFromLog(source);
    // 复制上次时不继承评分与备注（见 copyFrom 的说明）。
    _rating = widget.existing?.rating;
    _isBest = widget.existing?.isBest ?? false;
    _isFavorite = widget.existing?.isFavorite ?? false;
    _preheatUpperChamber = source?.preheatUpperChamber;
    _brewedAt =
        widget.existing?.brewedAt ??
        // 渲染稿注入的固定值；不传时就是打开表单的这一刻（行为与改前一致）。
        widget.initialBrewedAt ??
        DateTime.now();
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
      _totalTimeMin,
      _totalTimeSec,
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
    // 兜底：`validate()` 只看得到**还在册**的字段，滚出视口的输入框已经被
    // `ListView` 销毁了（见 [_validateRanges]）。
    if (!_validateRanges()) return;
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
    final int? totalTime = _totalSecondsInput;
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
      grindSetting: _turnsInput?.toDouble(),
      grindClicks: _clicksInput,
      doseGrams: _totalDose,
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
      clearGrindSetting: _turnsInput == null,
      clearGrindClicks: _clicksInput == null,
      clearDoseGrams: _totalDose == null,
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
  /// 一条记录只存总粉量（`brew_logs.doseGrams`）和每支豆子的粉量
  /// （`brew_log_beans.doseGrams`）。拼配时表单里**每支填的就是那个克数**，
  /// 占比是按各支克数算出来的只读展示。
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

    return <_BeanPick>[
      for (final BeanUsage usage in usable)
        _BeanPick(
          beanId: usage.beanId,
          batchId: usage.batchId,
          beanName: usage.beanName,
          grams: usage.doseGrams,
          // 这一支打开时的克数（M3-T25 / F2）：与另外四个字段同一套「原值放行」。
          originalGrams: numberToText(usage.doseGrams),
        ),
    ];
  }

  /// 是否拼配（多于一支豆子）。
  bool get _isBlend => _picks.length > 1;

  /// 拼配时各支克数之和。
  double get _gramsSum => _picks.fold<double>(
    0,
    (double sum, _BeanPick pick) => sum + (parseNumber(pick.grams.text) ?? 0),
  );

  /// 这条记录的粉量。
  ///
  /// 单支时就是「粉量」框里填的值（行为与拼配改造前一致）；
  /// 拼配时恒等于**各支克数之和**，「总粉量」框只读展示它。
  /// 这样「总粉量 = 各支之和」不可能被输入破坏。
  double? get _totalDose =>
      _isBlend ? roundGrams(_gramsSum) : parseNumber(_dose.text);

  /// 这支豆子的占比（只读展示）：它的克数 ÷ 各支克数之和。
  double _sharePercentOf(_BeanPick pick) {
    final double total = _gramsSum;
    if (total <= 0) return 0;
    return (parseNumber(pick.grams.text) ?? 0) / total * 100;
  }

  /// 保存前的豆子校验。返回 false 表示已经提示过用户，不要继续。
  bool _validatePicks() {
    // 豆子必填（第二轮反馈）：豆库里**有**豆子时，一支都没选就拦住 ——
    // 有得选还留空，余量扣减无处可去，记录也统计不进来。
    //
    // 例外（用户裁决）：豆库**一支豆子都没有**时放行，允许以「未指定」
    // 存下这一杯。首杯零阻力（手册 §8「快速记录」），而且这一页本身就有
    // 「+ 新增豆子」入口，想建豆的用户随时可以建。
    //
    // 注意：**加载中不是空库**。第一次发射之前 `.value` 同样是 null，
    // 直接当空库会把「豆子必填」放过去（落一条无豆记录）；还在加载就先请用户
    // 稍等。`hasError` 不拦——数据库报错不该把用户锁死。
    final AsyncValue<List<CoffeeBean>> asyncBeans = ref.read(beanListProvider);
    final List<CoffeeBean> beans = asyncBeans.value ?? const <CoffeeBean>[];
    if (asyncBeans.isLoading && beans.isEmpty) {
      _showMessage('豆子列表还在加载，请稍候再保存');
      return false;
    }
    if (beans.isNotEmpty && _picks.every((p) => p.beanId == null)) {
      _showMessage('请先选一支豆子再保存');
      return false;
    }
    if (!_isBlend) return true;

    if (_picks.any((p) => p.beanId == null)) {
      _showMessage('有一支豆子还没选，请选上或删掉这一行');
      return false;
    }
    // 占比是算出来的，所以这里没有「合计要等于 100%」那条校验；
    // 改成每支都要有克数，否则总粉量（= 各支之和）本身就是空的。
    //
    // 每支克数的范围与行内 validator **同口径**（M3-T25 / F1）：行内那条只在
    // 输入框还在册时才跑得了，而 `ListView` 会把滚出视口的输入框反注册 ——
    // 「填 0.05 g → 滚走 → 点保存」原本能静默落库。这里直接读控制器再查一遍，
    // 文案用行内那一句，同一个错因不出现两种说法。
    //
    // 打开时那一支的克数**没改过就放行**（与单支路径同一套机制，见
    // [_BeanPick.originalGrams]）：库里存着加上下限之前记下的 250 g。
    for (final _BeanPick pick in _picks) {
      // 留空是另一回事（「还没填」而不是「填超了」），沿用原来那句提示：
      // 行内 validator 把留空当合法，只能在这里兜住。
      if (pick.grams.text.trim().isEmpty) {
        _showMessage('每支豆子都要填大于 0 的克数');
        return false;
      }
      final String? gramsError = _gramsRangeError(pick);
      if (gramsError != null) {
        _showMessage(gramsError);
        return false;
      }
    }
    // 总分这一层同样要认「原值放行」（M3-T25 / F2）：拼配记录的总粉量就是
    // `brew_logs.doseGrams`。加限之前记下的 60 + 60 = 120 每支都 ≤ 100，
    // 只卡总分会让这条旧记录**连改个备注都存不回去**。新建记录没有原值，
    // 仍然必须落在 0.1–100 g 之内。
    final double total = _gramsSum;
    final double? originalTotal = widget.existing?.doseGrams;
    final bool totalUnchanged =
        originalTotal != null &&
        _unchangedFromOriginal(
          numberToText(total),
          numberToText(originalTotal),
        );
    if ((total < 0.1 || total > 100) && !totalUnchanged) {
      _showMessage('粉量应在 0.1–100 g 之间');
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

  /// 把「豆子 + 克数」换算成记录关联的用量行。
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

    final double total = _totalDose ?? 0;
    if (picks.length == 1) {
      final _BeanPick only = picks.first;
      return <BeanUsage>[
        BeanUsage(beanId: only.beanId, batchId: only.batchId, doseGrams: total),
      ];
    }

    // 拼配：直接写各支填的克数。**最后一支吃掉四舍五入的零头**，
    // 这样各支粉量之和一定等于总粉量，不会出现「加总比总粉量多 0.1g」。
    final List<BeanUsage> usages = <BeanUsage>[];
    double assigned = 0;
    for (int i = 0; i < picks.length; i++) {
      final _BeanPick pick = picks[i];
      final bool isLast = i == picks.length - 1;
      final double grams = isLast
          ? roundGrams(total - assigned)
          : roundGrams(parseNumber(pick.grams.text) ?? 0);
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
        // 1 → 2：把当前粉量对半分，总粉量保持不变，省得用户先算一遍。
        final double total = parseNumber(_dose.text) ?? 0;
        // 小于 0.2 g 拆半没有合法写法（半支不足 0.1 g），干脆不预填 ——
        // 否则第二支会被写成 `0`，一加就报「每支豆子都要填大于 0 的克数」。
        if (total >= 0.2) {
          final double first = roundGrams(total / 2);
          _picks[0].grams.text = numberToText(first);
          _picks.add(_BeanPick(grams: roundGrams(total - first)));
        } else {
          _picks[0].grams.text = '';
          _picks.add(_BeanPick());
        }
      } else {
        _picks.add(_BeanPick());
      }
    });
  }

  void _removePick(int index) {
    setState(() {
      // 总粉量是各支之和，删掉一支它自动跟着降，剩下几支的克数**保持不变**。
      _picks.removeAt(index).dispose();
      // 只剩一支时它回落到「粉量」框（单支路径行为不变）。
      if (_picks.length == 1) {
        // 克数框为空就留空（M3-T22 / S2）：写出 `'0'` 等于替用户填了一个他
        // 没填过的数，还会立刻触发「每支豆子都要填大于 0 的克数」。
        final double? grams = parseNumber(_picks.first.grams.text);
        _dose.text = grams == null ? '' : numberToText(roundGrams(grams));
      }
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
      _grinderId = copied.grinderId;
      _grinderZeroPoint = copied.grinderZeroPointSnapshot;
      _grinderClicksPerRevolution = copied.grinderClicksPerRevolutionSnapshot;
      _setGrindFromLog(copied);
      _dose.text = numberToText(copied.doseGrams);
      _water.text = numberToText(copied.waterGrams);
      _waterTemp.text = numberToText(copied.waterTemp);
      _totalTimeMin.text = _minutesText(copied.totalTimeSeconds);
      _totalTimeSec.text = _secondsText(copied.totalTimeSeconds);
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
                  helper: _isBlend ? '拼配：每支填克数，占比与总粉量自动算' : null,
                  child: _buildBeanPicker(beans),
                ),
                LabeledField(
                  label: '磨豆机',
                  child: _buildGrinderSelector(grinders),
                ),
                LabeledField(
                  // M2.10：标签统一叫「研磨刻度」，两个框里分别填「圈」与 click，
                  // 单位写在框内（suffixText）。算式收进 ⓘ，提示行只给相对刻度。
                  label: '研磨刻度',
                  labelTrailing: _buildGrindInfoButton(),
                  helper: _grindHelper(selectedGrinder),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: IntField(
                          key: const Key('brew.grindSetting'),
                          controller: _grindSetting,
                          hintText: '留空',
                          suffixText: '圈',
                          onChanged: (_) => setState(() {}),
                          validator: _validateTurns,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: IntField(
                          key: const Key('brew.grindClicks'),
                          controller: _grindClicks,
                          hintText: 'click',
                          suffixText: 'click',
                          onChanged: (_) => setState(() {}),
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
                  helper: _isBlend ? '各支豆子的克数之和，自动算出来' : null,
                  child: _isBlend
                      ? _buildTotalDoseDisplay()
                      : NumberField(
                          key: const Key('brew.dose'),
                          controller: _dose,
                          hintText: '例如：15',
                          suffixText: 'g',
                          validator: (String? value) => _rangeError(
                            value,
                            label: '粉量',
                            range: '0.1–100 g',
                            min: 0.1,
                            max: 100,
                            original: _originalDoseText,
                          ),
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
                    // 只做保守的上下限：水量可以比粉量多，也可以是 0。
                    validator: (String? value) => _rangeError(
                      value,
                      label: '水量',
                      range: '0–2000 g',
                      min: 0,
                      max: 2000,
                      original: _originalWaterText,
                    ),
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
                    validator: (String? value) => _rangeError(
                      value,
                      label: '水温',
                      range: '0–100 ℃',
                      min: 0,
                      max: 100,
                      original: _originalWaterTempText,
                    ),
                  ),
                ),
                LabeledField(
                  label: '总时间',
                  helper: _timeHint(),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: IntField(
                          key: const Key('brew.totalTimeMin'),
                          controller: _totalTimeMin,
                          suffixText: '分',
                          onChanged: (_) => setState(() {}),
                          validator: _validateMinutes,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: IntField(
                          key: const Key('brew.totalTimeSec'),
                          controller: _totalTimeSec,
                          suffixText: '秒',
                          onChanged: (_) => setState(() {}),
                          validator: _validateTotalTimeSeconds,
                        ),
                      ),
                    ],
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
          // 不要 avatar：它和 label 的「＋」会在同一个 chip 上画出两个加号
          // （第二轮反馈：仅保留一个＋号框）。
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

  /// 辅料行里三个框共用的高度。
  ///
  /// 数量框是 [NumberField]（TextFormField），名称与单位是 [InputDecorator]，
  /// 两者即使装饰写得一样，自然高度也差 4dp（实测 48 vs 44），
  /// 所以外层统一套一个固定高度，两个 [InputDecorator] 再用 `expands` 撑满，
  /// 这样三个框的边框上下沿严格对齐（测评反馈：数字框大小和其他框不一样）。
  static const double _addInBoxHeight = 48;

  /// 名称与单位共用的装饰：与 [NumberField] 里那份保持一致（isDense + 外框线）。
  static const InputDecoration _addInBoxDecoration = InputDecoration(
    isDense: true,
    border: OutlineInputBorder(),
  );

  Widget _buildAddInRow(int index) {
    final _AddIn addIn = _addIns[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        // 三个框居中对齐（名字/数量/单位）。
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: InkWell(
              key: Key('brew.addInName.$index'),
              onTap: _saving ? null : () => _renameAddIn(index),
              child: SizedBox(
                height: _addInBoxHeight,
                child: InputDecorator(
                  decoration: _addInBoxDecoration,
                  expands: true,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(addIn.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 数量框给固定宽度：以前只占 6 份里的 2 份，去掉单位与删除按钮后
          // 实测只剩 58dp，`1000` 这种四位数就显示不全（第二轮反馈）。
          SizedBox(
            width: 88,
            height: _addInBoxHeight,
            child: NumberField(
              key: Key('brew.addInAmount.$index'),
              controller: addIn.amount,
              hintText: '数量',
            ),
          ),
          const SizedBox(width: 8),
          // 单位：ml / g / 泵 / 份。
          // 外面套 SizedBox 给个确定宽度：InputDecorator 在无界宽度下会断言失败；
          // 高度与装饰和左边的名称框完全一致，边框才对得齐。
          //
          // 宽度 84 而不是更窄：DropdownButton 还要占掉右侧的箭头（约 24dp），
          // 72dp 时 `ml` 会被截成 `m`（渲染稿抓到的回归），84dp 才放得下单位文字 + 箭头。
          SizedBox(
            width: 84,
            height: _addInBoxHeight,
            child: InputDecorator(
              decoration: _addInBoxDecoration,
              expands: true,
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
            // 紧凑一点，把宽度让给数量框。
            visualDensity: VisualDensity.compact,
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

  /// 「圈」框里的整数圈数：空串 → null（= 0 圈）。
  int? get _turnsInput => int.tryParse(_grindSetting.text.trim());

  /// click 框里的整数 click。
  int? get _clicksInput => int.tryParse(_grindClicks.text.trim());

  /// 表单当前选中的磨豆机（列表还在加载或已被删时为 null）。
  Grinder? _selectedGrinder() {
    if (_grinderId == null) return null;
    final List<Grinder> grinders =
        ref.read(grinderListProvider).value ?? const <Grinder>[];
    return grinders.where((Grinder g) => g.id == _grinderId).firstOrNull;
  }

  /// 把一条记录里的研磨读数填进表单。
  ///
  /// M2.10：旧记录存的是**小数刻度**（0.1.0 允许 1.5 圈），而「圈」现在只收正整数，
  /// 所以这里把它折算成「整数圈 + click」——只改表单里的写法，库里的数据不动。
  /// 折算规则：`1.5 圈 × 每圈 30` → `1 圈 + 15 click`。
  void _setGrindFromLog(BrewLog? log, {int? clicksPerRevolution}) {
    final double? setting = log?.grindSetting;
    if (setting == null) {
      _grindSetting.text = '';
      _grindClicks.text = log?.grindClicks?.toString() ?? '';
      return;
    }

    final int whole = setting.floor();
    final double fraction = setting - whole;
    final int perRevolution =
        clicksPerRevolution ?? _grinderClicksPerRevolution ?? 0;

    // 小数部分先按「每圈几 click」折算成 click；没有这个值就整体进位到圈数。
    int extraClicks = 0;
    int turns = whole;
    if (fraction > 0) {
      if (perRevolution > 0) {
        extraClicks = (fraction * perRevolution).round();
      } else {
        turns = setting.round();
      }
    }

    final int? loggedClicks = log?.grindClicks;
    final int totalClicks = extraClicks + (loggedClicks ?? 0);
    _grindSetting.text = turns == 0 ? '' : turns.toString();
    _grindClicks.text = totalClicks == 0 ? '' : totalClicks.toString();
  }

  /// 「圈」框的校验（M2.10 用户要求）：只收正整数。
  ///
  /// 留空是合法的 —— 表示 0 圈，机器停在第 1 圈以内时就该留空，
  /// 把不足一圈的部分填到右边的 click 框里。
  String? _validateTurns(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final int? turns = int.tryParse(text);
    if (turns == null || turns <= 0) {
      return '圈只能是正整数（1、2、3…）；不到一圈请留空';
    }
    return null;
  }

  /// 换算用的「每圈 click」：优先磨豆机**当前**的值，取不到回落记录里的快照。
  int? _effectiveClicksPerRevolution(Grinder? grinder) =>
      grinder?.clicksPerRevolution ?? _grinderClicksPerRevolution;

  /// 换算用的零点：同上（当前值优先，回落到快照）。
  double? _effectiveZeroPoint(Grinder? grinder) =>
      grinder?.zeroPoint ?? _grinderZeroPoint;

  /// 研磨刻度的提示行：**只给相对刻度**，算式收在 [ _buildGrindInfoButton ] 里。
  ///
  /// 用的是磨豆机**现在**的校准；磨豆机被删或字段为空才回落记录里的快照。
  String _grindHelper(Grinder? grinder) {
    final int? perRevolution = _effectiveClicksPerRevolution(grinder);
    if (perRevolution == null || perRevolution <= 0) {
      return grinder == null
          ? '选择磨豆机后可自动换算相对刻度'
          : '这台磨豆机还没填「每圈几 click」，去磨豆机编辑页补上就能换算';
    }

    final double? relative = BrewLogFormPage.relativeClicks(
      turns: _turnsInput?.toDouble(),
      clicks: _clicksInput,
      grinder: grinder,
      zeroPointSnapshot: _grinderZeroPoint,
      clicksPerRevolutionSnapshot: _grinderClicksPerRevolution,
    );
    if (relative == null) return '填入圈数或 click 后自动算出相对刻度';
    return '相对刻度 ${formatNumber(relative)} click';
  }

  /// 标签旁的 ⓘ：点开看「怎么算的」。
  Widget _buildGrindInfoButton() {
    return IconButton(
      key: const Key('brew.grindInfo'),
      onPressed: _showGrindInfo,
      icon: const Icon(Icons.info_outline, size: 16),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.only(left: 6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: '研磨刻度怎么算',
    );
  }

  Future<void> _showGrindInfo() async {
    final Grinder? grinder = _selectedGrinder();
    final int? perRevolution = _effectiveClicksPerRevolution(grinder);
    final double? zeroPoint = _effectiveZeroPoint(grinder);
    final double? relative = BrewLogFormPage.relativeClicks(
      turns: _turnsInput?.toDouble(),
      clicks: _clicksInput,
      grinder: grinder,
      zeroPointSnapshot: _grinderZeroPoint,
      clicksPerRevolutionSnapshot: _grinderClicksPerRevolution,
    );
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('研磨刻度怎么算'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('相对刻度 = 圈 × 每圈 click + click − 零点'),
            const SizedBox(height: 12),
            Text(_grindSourceText(grinder, perRevolution, zeroPoint)),
            Text(
              '这次填写：${formatNumber((_turnsInput ?? 0).toDouble())} 圈'
              ' + ${_clicksInput ?? 0} click',
            ),
            if (relative != null)
              Text('结果：${formatNumber(relative)} click')
            else if (perRevolution == null || perRevolution <= 0)
              const Text('这台磨豆机还没填「每圈几 click」，补上后才能换算'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// ⓘ 里「这两个数分别从哪来」那一行（M3-T22 / S3）。
  ///
  /// **按值分别判断来源**：[_effectiveClicksPerRevolution] 与
  /// [_effectiveZeroPoint] 是**各自**回落的（磨豆机字段为空就取记录里的快照），
  /// 所以不能只看「磨豆机还在不在」——磨豆机在、但它的「每圈 click」为空时，
  /// 那个数其实来自记录快照。用户正是拿这一行核对「为什么减零点」，
  /// 把它说成「这台磨豆机的值」就是事实性错误。
  String _grindSourceText(
    Grinder? grinder,
    int? perRevolution,
    double? zeroPoint,
  ) {
    if (perRevolution == null && zeroPoint == null) {
      return grinder == null ? '这台记录还没选磨豆机' : '这台磨豆机还没填「每圈几 click」';
    }
    final bool clicksCurrent = grinder?.clicksPerRevolution != null;
    final bool zeroCurrent = grinder?.zeroPoint != null;
    String source(bool current) => current ? '这台磨豆机' : '记录里的快照';

    // 两个数都在、且来源相同时并成一行（最常见的情形）。
    if (perRevolution != null &&
        zeroPoint != null &&
        clicksCurrent == zeroCurrent) {
      return '${source(clicksCurrent)}：每圈 $perRevolution click'
          ' · 零点 ${formatNumber(zeroPoint)}';
    }
    // 只有一个数、或者两个数来源不同：逐个标注。
    final List<String> parts = <String>[
      if (perRevolution != null)
        '每圈 $perRevolution click（${source(clicksCurrent)}）',
      if (zeroPoint != null)
        '零点 ${formatNumber(zeroPoint)}（${source(zeroCurrent)}）',
    ];
    return parts.join(' · ');
  }

  /// 豆子选择（含拼配）。
  ///
  /// 单支时不显示克数与占比——那一支的粉量直接在「核心参数」里填；
  /// 一旦加到两支以上，每行填**这一支的克数**，占比只是按各支克数算出来的
  /// 只读展示，总粉量同样由各支求和得到。这样总粉量始终只有一个真值，
  /// 不会出现「各支加起来和总粉量对不上」。
  Widget _buildBeanPicker(List<CoffeeBean> beans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < _picks.length; i++) _buildBeanRow(beans, i),
        if (_isBlend) _buildBlendSummary(),
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
                  key: Key('brew.beanGrams.$index'),
                  controller: pick.grams,
                  hintText: '克数',
                  suffixText: 'g',
                  onChanged: (_) => setState(() {}),
                  validator: (_) => _gramsRangeError(pick),
                ),
              ),
              IconButton(
                tooltip: '删掉这一支',
                onPressed: _saving ? null : () => _removePick(index),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 2),
            child: Text(
              // 占比只读：由这一支的克数 ÷ 各支之和算出来。
              '占比 ${formatNumber(_sharePercentOf(pick))}%',
              key: Key('brew.share.$index'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// 拼配那一行的合计提示：总粉量 = 各支克数之和。
  Widget _buildBlendSummary() {
    final double total = _gramsSum;

    return FormHint(
      message: total > 0
          ? '各支合计 ${formatNumber(roundGrams(total))} g，总粉量与占比都按它自动算'
          : '填上每支豆子的克数，总粉量与占比会自动算出来',
      isWarning: total <= 0,
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
      // 同 [_addPick]：1 → 2 时把当前粉量对半分，总粉量保持不变；
      // 小于 0.2 g 没有合法写法，不预填（否则第二支会被写成 0）。
      final double total = parseNumber(_dose.text) ?? 0;
      if (total >= 0.2) {
        final double first = roundGrams(total / 2);
        _picks[0].grams.text = numberToText(first);
        _picks.add(_BeanPick(beanId: beanId, grams: roundGrams(total - first)));
      } else {
        _picks[0].grams.text = '';
        _picks.add(_BeanPick(beanId: beanId));
      }
    } else {
      _picks.add(_BeanPick(beanId: beanId));
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

  /// 拼配时的「总粉量」：只读展示各支克数之和（M3-T15）。
  ///
  /// 不再可编辑 —— 它是算出来的，写死在界面上就不会出现「各支加起来
  /// 和总粉量对不上」。单支时仍然是 [NumberField] 直接填。
  Widget _buildTotalDoseDisplay() {
    return InputDecorator(
      key: const Key('brew.dose'),
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
      ),
      child: Text('${numberToText(_totalDose)} g'),
    );
  }

  String? _ratioHint() {
    final double? dose = _totalDose;
    final double? water = parseNumber(_water.text);
    if (dose == null || water == null || dose <= 0) {
      return '填写粉量与水量后可自动算出粉水比';
    }
    return '粉水比 1 : ${formatNumber(water / dose)}';
  }

  /// 「分」框的初始文本：0 分不写出来（留空 = 0）。
  static String _minutesText(int? totalSeconds) {
    if (totalSeconds == null) return '';
    final int minutes = totalSeconds ~/ 60;
    return minutes == 0 ? '' : minutes.toString();
  }

  /// 「秒」框的初始文本：**整体 0 秒写 `0`**（要能原样往返）；
  /// 被 60 整除的**余数**才留空（留空 = 0）。
  static String _secondsText(int? totalSeconds) {
    if (totalSeconds == null) return '';
    if (totalSeconds == 0) return '0';
    final int seconds = totalSeconds % 60;
    return seconds == 0 ? '' : seconds.toString();
  }

  /// 「分 + 秒」两框合计出来的总秒数。
  ///
  /// **两个都留空 = 未记录**（null）；只填一个也合法，另一个按 0 算 ——
  /// 所以这里不能把「都留空」当成 0 秒（那是「记了 0 秒」）。
  int? get _totalSecondsInput {
    final String minutes = _totalTimeMin.text.trim();
    final String seconds = _totalTimeSec.text.trim();
    if (minutes.isEmpty && seconds.isEmpty) return null;
    return (int.tryParse(minutes) ?? 0) * 60 + (int.tryParse(seconds) ?? 0);
  }

  /// 「分」框：0–60（留空合法）。
  ///
  /// 上限是 **60** 而不是 59（M3-T22 / B1）：分与秒各 ≤ 59 时总分最大 3599，
  /// `60:00 = 3600` 秒这个上限内的合法值**永远填不出来**，`total > 3600` 那条
  /// 校验就成了死代码。60 分 + 非 0 秒会由「总分」那条拦住。
  String? _validateMinutes(String? value) {
    // 历史记录里的越界总时间（如 7200 秒 → 分框 120）原样不动就放行。
    if (_totalSecondsInput == _originalTotalSeconds) return null;
    return _rangeError(value, label: '分', range: '0–60', min: 0, max: 60);
  }

  /// 「秒」框：本框 0–59，另外把 M3-T12 的 0–3600 上限落到**总分**上。
  ///
  /// 文案是写死的：`_rangeError` 的 `$range 之间` 会在「秒」后面留一个
  /// 多余的空格（第二轮反馈）。
  String? _validateTotalTimeSeconds(String? value) {
    final String? fieldError = _rangeError(
      value,
      label: '秒',
      range: '0–59',
      min: 0,
      max: 59,
    );
    if (fieldError != null) return fieldError;

    // 总分与打开时的原值相同就放行（历史记录里有 > 3600 的旧值，见 B1）。
    if (_totalSecondsInput == _originalTotalSeconds) return null;
    return _totalTimeError();
  }

  /// 总分超过 3600 秒的报错（分/秒两处与保存兜底共用）。
  String? _totalTimeError() {
    final int? total = _totalSecondsInput;
    if (total == null) return null;
    // 没改动过的历史值放行（B1）。
    if (total == _originalTotalSeconds) return null;
    if (total > 3600) return '总时间应在 0–3600 秒之间';
    return null;
  }

  /// 「分 + 秒」整段的复查：两个框各自的上下限 + 总分的 0–3600。
  ///
  /// 规则与 [_validateMinutes] / [_validateTotalTimeSeconds] 一致，只是这里
  /// 是**直接读控制器**（给 [_validateRanges] 的兜底用）。
  String? _timeRangeError() {
    // 历史记录里的越界总时间原样不动就放行（B1）。
    if (_totalSecondsInput == _originalTotalSeconds) return null;
    final String? minutesError = _rangeError(
      _totalTimeMin.text,
      label: '分',
      range: '0–60',
      min: 0,
      max: 60,
    );
    if (minutesError != null) return minutesError;
    final String? secondsError = _rangeError(
      _totalTimeSec.text,
      label: '秒',
      range: '0–59',
      min: 0,
      max: 59,
    );
    if (secondsError != null) return secondsError;
    return _totalTimeError();
  }

  /// `_save()` 的兜底范围复查（M3-T22 / S1）：**不依赖控件还在不在册**。
  ///
  /// `FormState.validate()` 只校验注册着的 `FormField`，而 `ListView` 会把
  /// 滚出视口的输入框反注册（`EditableText.wantKeepAlive => hasFocus`），
  /// 保存按钮却在**常驻的 bottomNavigationBar** 上 —— 「填越界值 → 滚上去看
  /// 豆子 → 点保存」原本能静默把越界数据存进库（拼配克数有 [_validatePicks]
  /// 兜底，单支的粉量/水量/水温/总时间没有）。这里照 [_validatePicks] 的写法
  /// 直接读控制器文本再查一遍，规则与行内 validator 完全一致
  /// （等于打开时的原值就放行，见 [_originalDoseText]）。
  bool _validateRanges() {
    final List<String?> errors = <String?>[
      // 拼配时「粉量」是各支克数之和（只读展示），由 [_validatePicks] 查。
      if (!_isBlend)
        _rangeError(
          _dose.text,
          label: '粉量',
          range: '0.1–100 g',
          min: 0.1,
          max: 100,
          original: _originalDoseText,
        ),
      _rangeError(
        _water.text,
        label: '水量',
        range: '0–2000 g',
        min: 0,
        max: 2000,
        original: _originalWaterText,
      ),
      _rangeError(
        _waterTemp.text,
        label: '水温',
        range: '0–100 ℃',
        min: 0,
        max: 100,
        original: _originalWaterTempText,
      ),
      _timeRangeError(),
    ];
    for (final String? error in errors) {
      if (error != null) {
        _showMessage(error);
        return false;
      }
    }
    return true;
  }

  String? _timeHint() {
    final int? seconds = _totalSecondsInput;
    if (seconds == null) return null;
    return '即 ${formatDuration(seconds)}';
  }

  /// 拼配里**某一支克数**的范围校验（M3-T25）。
  ///
  /// 行内 validator 与 [_validatePicks] 的保存兜底**共用这一个入口**：
  /// 「0.1–100 g」这条范围与它的文案「克数应在 0.1–100 g 之间」就不会在两侧
  /// 各写一遍、各走各的样。打开时那一支的克数没改过照样放行，见
  /// [_BeanPick.originalGrams]。
  String? _gramsRangeError(_BeanPick pick) => _rangeError(
    pick.grams.text,
    label: '克数',
    range: '0.1–100 g',
    min: 0.1,
    max: 100,
    original: pick.originalGrams,
  );

  /// 核心参数的保守上下限校验（第二轮反馈）。
  ///
  /// **留空仍然合法**：这些都是可空字段，只有「填了但超范围」才报错，
  /// 免得把「还没量」当成「填了 0」。
  ///
  /// [original] 是打开这条记录时该字段的原文（M3-T22 / B1）：值没被改动过就
  /// 直接放行 —— 库里可能存着加上下限之前的越界值，历史记录不该一打开就飘红。
  String? _rangeError(
    String? raw, {
    required String label,
    required String range,
    required double min,
    required double max,
    String? original,
  }) {
    final String text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    if (_unchangedFromOriginal(text, original)) return null;
    final double? value = parseNumber(text);
    if (value == null) return '$label请填数字';
    if (value < min || value > max) return '$label应在 $range 之间';
    return null;
  }

  /// [text] 是否还是**打开时那个值** [original]（M3-T22 / B1 的「原值放行」）。
  ///
  /// 文本一致，或者只是写法不同（`15` 与 `15.0`）都算没改过。[original] 为
  /// null 时一律不放行 —— 那是没记过这个字段的旧记录 / 新建记录。
  bool _unchangedFromOriginal(String text, String? original) {
    if (original == null) return false;
    final String before = original.trim();
    if (text == before) return true;
    final double? now = parseNumber(text);
    final double? was = parseNumber(before);
    return now != null && was != null && now == was;
  }
}

/// 表单里的一支豆子。
///
/// [grams] 是拼配时**这一支的克数**输入框（单支时不显示，粉量在「核心参数」
/// 里直接填）。占比不再有输入框，只按各支克数算出来展示。
/// [batchId] 只在编辑已有记录时带出来——新建时留空，让仓储按烘焙日期
/// 自己挑一袋（见 `BeanRepository.adjustStock`）。
class _BeanPick {
  _BeanPick({
    this.beanId,
    this.batchId,
    this.beanName,
    double? grams,
    this.originalGrams,
  }) : grams = TextEditingController(text: numberToText(grams));

  int? beanId;
  int? batchId;

  /// 豆子名快照（来自用量行）。豆子列表还没加载出来时用它显示，
  /// 免得下拉框既没有候选也说不清选的是谁。
  String? beanName;

  final TextEditingController grams;

  /// 打开这条记录时这一支的克数**原文**（M3-T25 / F2）。
  ///
  /// 与单支路径的 `_originalDoseText` 等是同一套机制：`brew_log_beans.doseGrams`
  /// 里可能存着加上下限之前记下的 250 g，值没被改动过就放行，改过才按新范围拦。
  /// 新建记录（含「复制上次」的预填）为 null —— 没有任何原值可放行。
  final String? originalGrams;

  void dispose() => grams.dispose();
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
