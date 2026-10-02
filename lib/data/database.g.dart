// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CoffeeBeansTable extends CoffeeBeans
    with TableInfo<$CoffeeBeansTable, CoffeeBeanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoffeeBeansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _farmMeta = const VerificationMeta('farm');
  @override
  late final GeneratedColumn<String> farm = GeneratedColumn<String>(
    'farm',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<ProcessMethod>, String>
  process = GeneratedColumn<String>(
    'process',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<ProcessMethod>>($CoffeeBeansTable.$converterprocess);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> flavorTags =
      GeneratedColumn<String>(
        'flavor_tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($CoffeeBeansTable.$converterflavorTags);
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    origin,
    farm,
    process,
    flavorTags,
    isFavorite,
    photoPath,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coffee_beans';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoffeeBeanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('farm')) {
      context.handle(
        _farmMeta,
        farm.isAcceptableOrUnknown(data['farm']!, _farmMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoffeeBeanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoffeeBeanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      ),
      farm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}farm'],
      ),
      process: $CoffeeBeansTable.$converterprocess.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}process'],
        ),
      ),
      flavorTags: $CoffeeBeansTable.$converterflavorTags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}flavor_tags'],
        )!,
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CoffeeBeansTable createAlias(String alias) {
    return $CoffeeBeansTable(attachedDatabase, alias);
  }

  static TypeConverter<List<ProcessMethod>, String?> $converterprocess =
      const ProcessListConverter();
  static TypeConverter<List<String>, String> $converterflavorTags =
      const StringListConverter();
}

class CoffeeBeanRow extends DataClass implements Insertable<CoffeeBeanRow> {
  final int id;
  final String name;
  final String? origin;
  final String? farm;

  /// 处理法，JSON 数组（**可多选**，如「水洗 + 厌氧」）；NULL / `[]` = 没填。
  ///
  /// 保持可空、不加 SQL 默认值：v6 → v7 只要把老值改写成数组，**不用重建表** ——
  /// 重建会 DROP `coffee_beans`，而它被批次/用量用外键引用着，会触发级联删除
  /// （v1 → v4 那段注释里记过这个坑）。
  final List<ProcessMethod> process;

  /// 风味标签，JSON 数组。属于「这款豆子」而不是某个批次。
  final List<String> flavorTags;

  /// 收藏标记：豆库可只看收藏，复购时也先从这里挑。
  final bool isFavorite;
  final String? photoPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CoffeeBeanRow({
    required this.id,
    required this.name,
    this.origin,
    this.farm,
    required this.process,
    required this.flavorTags,
    required this.isFavorite,
    this.photoPath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || origin != null) {
      map['origin'] = Variable<String>(origin);
    }
    if (!nullToAbsent || farm != null) {
      map['farm'] = Variable<String>(farm);
    }
    {
      map['process'] = Variable<String>(
        $CoffeeBeansTable.$converterprocess.toSql(process),
      );
    }
    {
      map['flavor_tags'] = Variable<String>(
        $CoffeeBeansTable.$converterflavorTags.toSql(flavorTags),
      );
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CoffeeBeansCompanion toCompanion(bool nullToAbsent) {
    return CoffeeBeansCompanion(
      id: Value(id),
      name: Value(name),
      origin: origin == null && nullToAbsent
          ? const Value.absent()
          : Value(origin),
      farm: farm == null && nullToAbsent ? const Value.absent() : Value(farm),
      process: Value(process),
      flavorTags: Value(flavorTags),
      isFavorite: Value(isFavorite),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CoffeeBeanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoffeeBeanRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      origin: serializer.fromJson<String?>(json['origin']),
      farm: serializer.fromJson<String?>(json['farm']),
      process: serializer.fromJson<List<ProcessMethod>>(json['process']),
      flavorTags: serializer.fromJson<List<String>>(json['flavorTags']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'origin': serializer.toJson<String?>(origin),
      'farm': serializer.toJson<String?>(farm),
      'process': serializer.toJson<List<ProcessMethod>>(process),
      'flavorTags': serializer.toJson<List<String>>(flavorTags),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'photoPath': serializer.toJson<String?>(photoPath),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CoffeeBeanRow copyWith({
    int? id,
    String? name,
    Value<String?> origin = const Value.absent(),
    Value<String?> farm = const Value.absent(),
    List<ProcessMethod>? process,
    List<String>? flavorTags,
    bool? isFavorite,
    Value<String?> photoPath = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CoffeeBeanRow(
    id: id ?? this.id,
    name: name ?? this.name,
    origin: origin.present ? origin.value : this.origin,
    farm: farm.present ? farm.value : this.farm,
    process: process ?? this.process,
    flavorTags: flavorTags ?? this.flavorTags,
    isFavorite: isFavorite ?? this.isFavorite,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CoffeeBeanRow copyWithCompanion(CoffeeBeansCompanion data) {
    return CoffeeBeanRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      origin: data.origin.present ? data.origin.value : this.origin,
      farm: data.farm.present ? data.farm.value : this.farm,
      process: data.process.present ? data.process.value : this.process,
      flavorTags: data.flavorTags.present
          ? data.flavorTags.value
          : this.flavorTags,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoffeeBeanRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('origin: $origin, ')
          ..write('farm: $farm, ')
          ..write('process: $process, ')
          ..write('flavorTags: $flavorTags, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('photoPath: $photoPath, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    origin,
    farm,
    process,
    flavorTags,
    isFavorite,
    photoPath,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoffeeBeanRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.origin == this.origin &&
          other.farm == this.farm &&
          other.process == this.process &&
          other.flavorTags == this.flavorTags &&
          other.isFavorite == this.isFavorite &&
          other.photoPath == this.photoPath &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CoffeeBeansCompanion extends UpdateCompanion<CoffeeBeanRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> origin;
  final Value<String?> farm;
  final Value<List<ProcessMethod>> process;
  final Value<List<String>> flavorTags;
  final Value<bool> isFavorite;
  final Value<String?> photoPath;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CoffeeBeansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.origin = const Value.absent(),
    this.farm = const Value.absent(),
    this.process = const Value.absent(),
    this.flavorTags = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CoffeeBeansCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.origin = const Value.absent(),
    this.farm = const Value.absent(),
    this.process = const Value.absent(),
    this.flavorTags = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CoffeeBeanRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? origin,
    Expression<String>? farm,
    Expression<String>? process,
    Expression<String>? flavorTags,
    Expression<bool>? isFavorite,
    Expression<String>? photoPath,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (origin != null) 'origin': origin,
      if (farm != null) 'farm': farm,
      if (process != null) 'process': process,
      if (flavorTags != null) 'flavor_tags': flavorTags,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (photoPath != null) 'photo_path': photoPath,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CoffeeBeansCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? origin,
    Value<String?>? farm,
    Value<List<ProcessMethod>>? process,
    Value<List<String>>? flavorTags,
    Value<bool>? isFavorite,
    Value<String?>? photoPath,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CoffeeBeansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      farm: farm ?? this.farm,
      process: process ?? this.process,
      flavorTags: flavorTags ?? this.flavorTags,
      isFavorite: isFavorite ?? this.isFavorite,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (farm.present) {
      map['farm'] = Variable<String>(farm.value);
    }
    if (process.present) {
      map['process'] = Variable<String>(
        $CoffeeBeansTable.$converterprocess.toSql(process.value),
      );
    }
    if (flavorTags.present) {
      map['flavor_tags'] = Variable<String>(
        $CoffeeBeansTable.$converterflavorTags.toSql(flavorTags.value),
      );
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoffeeBeansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('origin: $origin, ')
          ..write('farm: $farm, ')
          ..write('process: $process, ')
          ..write('flavorTags: $flavorTags, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('photoPath: $photoPath, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BeanBatchesTable extends BeanBatches
    with TableInfo<$BeanBatchesTable, BeanBatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeanBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _beanIdMeta = const VerificationMeta('beanId');
  @override
  late final GeneratedColumn<int> beanId = GeneratedColumn<int>(
    'bean_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES coffee_beans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roastDateMeta = const VerificationMeta(
    'roastDate',
  );
  @override
  late final GeneratedColumn<DateTime> roastDate = GeneratedColumn<DateTime>(
    'roast_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RoastLevel?, String> roastLevel =
      GeneratedColumn<String>(
        'roast_level',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<RoastLevel?>($BeanBatchesTable.$converterroastLevel);
  static const VerificationMeta _remainingGramsMeta = const VerificationMeta(
    'remainingGrams',
  );
  @override
  late final GeneratedColumn<double> remainingGrams = GeneratedColumn<double>(
    'remaining_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _initialGramsMeta = const VerificationMeta(
    'initialGrams',
  );
  @override
  late final GeneratedColumn<double> initialGrams = GeneratedColumn<double>(
    'initial_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    beanId,
    roastDate,
    roastLevel,
    remainingGrams,
    initialGrams,
    price,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bean_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<BeanBatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bean_id')) {
      context.handle(
        _beanIdMeta,
        beanId.isAcceptableOrUnknown(data['bean_id']!, _beanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_beanIdMeta);
    }
    if (data.containsKey('roast_date')) {
      context.handle(
        _roastDateMeta,
        roastDate.isAcceptableOrUnknown(data['roast_date']!, _roastDateMeta),
      );
    }
    if (data.containsKey('remaining_grams')) {
      context.handle(
        _remainingGramsMeta,
        remainingGrams.isAcceptableOrUnknown(
          data['remaining_grams']!,
          _remainingGramsMeta,
        ),
      );
    }
    if (data.containsKey('initial_grams')) {
      context.handle(
        _initialGramsMeta,
        initialGrams.isAcceptableOrUnknown(
          data['initial_grams']!,
          _initialGramsMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BeanBatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BeanBatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      beanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bean_id'],
      )!,
      roastDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}roast_date'],
      ),
      roastLevel: $BeanBatchesTable.$converterroastLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}roast_level'],
        ),
      ),
      remainingGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_grams'],
      )!,
      initialGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_grams'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BeanBatchesTable createAlias(String alias) {
    return $BeanBatchesTable(attachedDatabase, alias);
  }

  static TypeConverter<RoastLevel?, String?> $converterroastLevel =
      const TolerantEnumConverter<RoastLevel>(RoastLevel.values);
}

class BeanBatchRow extends DataClass implements Insertable<BeanBatchRow> {
  final int id;
  final int beanId;

  /// 烘焙日期。
  final DateTime? roastDate;

  /// 这一袋的烘焙度（同款豆子不同批次可能不同）。
  final RoastLevel? roastLevel;

  /// 剩余克数（g），下限 0，由 Repository 保证。
  final double remainingGrams;

  /// 购入总重（g），用于算消耗比例。
  final double? initialGrams;
  final double? price;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BeanBatchRow({
    required this.id,
    required this.beanId,
    this.roastDate,
    this.roastLevel,
    required this.remainingGrams,
    this.initialGrams,
    this.price,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bean_id'] = Variable<int>(beanId);
    if (!nullToAbsent || roastDate != null) {
      map['roast_date'] = Variable<DateTime>(roastDate);
    }
    if (!nullToAbsent || roastLevel != null) {
      map['roast_level'] = Variable<String>(
        $BeanBatchesTable.$converterroastLevel.toSql(roastLevel),
      );
    }
    map['remaining_grams'] = Variable<double>(remainingGrams);
    if (!nullToAbsent || initialGrams != null) {
      map['initial_grams'] = Variable<double>(initialGrams);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BeanBatchesCompanion toCompanion(bool nullToAbsent) {
    return BeanBatchesCompanion(
      id: Value(id),
      beanId: Value(beanId),
      roastDate: roastDate == null && nullToAbsent
          ? const Value.absent()
          : Value(roastDate),
      roastLevel: roastLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(roastLevel),
      remainingGrams: Value(remainingGrams),
      initialGrams: initialGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(initialGrams),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BeanBatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BeanBatchRow(
      id: serializer.fromJson<int>(json['id']),
      beanId: serializer.fromJson<int>(json['beanId']),
      roastDate: serializer.fromJson<DateTime?>(json['roastDate']),
      roastLevel: serializer.fromJson<RoastLevel?>(json['roastLevel']),
      remainingGrams: serializer.fromJson<double>(json['remainingGrams']),
      initialGrams: serializer.fromJson<double?>(json['initialGrams']),
      price: serializer.fromJson<double?>(json['price']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'beanId': serializer.toJson<int>(beanId),
      'roastDate': serializer.toJson<DateTime?>(roastDate),
      'roastLevel': serializer.toJson<RoastLevel?>(roastLevel),
      'remainingGrams': serializer.toJson<double>(remainingGrams),
      'initialGrams': serializer.toJson<double?>(initialGrams),
      'price': serializer.toJson<double?>(price),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BeanBatchRow copyWith({
    int? id,
    int? beanId,
    Value<DateTime?> roastDate = const Value.absent(),
    Value<RoastLevel?> roastLevel = const Value.absent(),
    double? remainingGrams,
    Value<double?> initialGrams = const Value.absent(),
    Value<double?> price = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BeanBatchRow(
    id: id ?? this.id,
    beanId: beanId ?? this.beanId,
    roastDate: roastDate.present ? roastDate.value : this.roastDate,
    roastLevel: roastLevel.present ? roastLevel.value : this.roastLevel,
    remainingGrams: remainingGrams ?? this.remainingGrams,
    initialGrams: initialGrams.present ? initialGrams.value : this.initialGrams,
    price: price.present ? price.value : this.price,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BeanBatchRow copyWithCompanion(BeanBatchesCompanion data) {
    return BeanBatchRow(
      id: data.id.present ? data.id.value : this.id,
      beanId: data.beanId.present ? data.beanId.value : this.beanId,
      roastDate: data.roastDate.present ? data.roastDate.value : this.roastDate,
      roastLevel: data.roastLevel.present
          ? data.roastLevel.value
          : this.roastLevel,
      remainingGrams: data.remainingGrams.present
          ? data.remainingGrams.value
          : this.remainingGrams,
      initialGrams: data.initialGrams.present
          ? data.initialGrams.value
          : this.initialGrams,
      price: data.price.present ? data.price.value : this.price,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BeanBatchRow(')
          ..write('id: $id, ')
          ..write('beanId: $beanId, ')
          ..write('roastDate: $roastDate, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('remainingGrams: $remainingGrams, ')
          ..write('initialGrams: $initialGrams, ')
          ..write('price: $price, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    beanId,
    roastDate,
    roastLevel,
    remainingGrams,
    initialGrams,
    price,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BeanBatchRow &&
          other.id == this.id &&
          other.beanId == this.beanId &&
          other.roastDate == this.roastDate &&
          other.roastLevel == this.roastLevel &&
          other.remainingGrams == this.remainingGrams &&
          other.initialGrams == this.initialGrams &&
          other.price == this.price &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BeanBatchesCompanion extends UpdateCompanion<BeanBatchRow> {
  final Value<int> id;
  final Value<int> beanId;
  final Value<DateTime?> roastDate;
  final Value<RoastLevel?> roastLevel;
  final Value<double> remainingGrams;
  final Value<double?> initialGrams;
  final Value<double?> price;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BeanBatchesCompanion({
    this.id = const Value.absent(),
    this.beanId = const Value.absent(),
    this.roastDate = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.remainingGrams = const Value.absent(),
    this.initialGrams = const Value.absent(),
    this.price = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BeanBatchesCompanion.insert({
    this.id = const Value.absent(),
    required int beanId,
    this.roastDate = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.remainingGrams = const Value.absent(),
    this.initialGrams = const Value.absent(),
    this.price = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : beanId = Value(beanId);
  static Insertable<BeanBatchRow> custom({
    Expression<int>? id,
    Expression<int>? beanId,
    Expression<DateTime>? roastDate,
    Expression<String>? roastLevel,
    Expression<double>? remainingGrams,
    Expression<double>? initialGrams,
    Expression<double>? price,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (beanId != null) 'bean_id': beanId,
      if (roastDate != null) 'roast_date': roastDate,
      if (roastLevel != null) 'roast_level': roastLevel,
      if (remainingGrams != null) 'remaining_grams': remainingGrams,
      if (initialGrams != null) 'initial_grams': initialGrams,
      if (price != null) 'price': price,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BeanBatchesCompanion copyWith({
    Value<int>? id,
    Value<int>? beanId,
    Value<DateTime?>? roastDate,
    Value<RoastLevel?>? roastLevel,
    Value<double>? remainingGrams,
    Value<double?>? initialGrams,
    Value<double?>? price,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BeanBatchesCompanion(
      id: id ?? this.id,
      beanId: beanId ?? this.beanId,
      roastDate: roastDate ?? this.roastDate,
      roastLevel: roastLevel ?? this.roastLevel,
      remainingGrams: remainingGrams ?? this.remainingGrams,
      initialGrams: initialGrams ?? this.initialGrams,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (beanId.present) {
      map['bean_id'] = Variable<int>(beanId.value);
    }
    if (roastDate.present) {
      map['roast_date'] = Variable<DateTime>(roastDate.value);
    }
    if (roastLevel.present) {
      map['roast_level'] = Variable<String>(
        $BeanBatchesTable.$converterroastLevel.toSql(roastLevel.value),
      );
    }
    if (remainingGrams.present) {
      map['remaining_grams'] = Variable<double>(remainingGrams.value);
    }
    if (initialGrams.present) {
      map['initial_grams'] = Variable<double>(initialGrams.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeanBatchesCompanion(')
          ..write('id: $id, ')
          ..write('beanId: $beanId, ')
          ..write('roastDate: $roastDate, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('remainingGrams: $remainingGrams, ')
          ..write('initialGrams: $initialGrams, ')
          ..write('price: $price, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GrindersTable extends Grinders
    with TableInfo<$GrindersTable, GrinderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _burrTypeMeta = const VerificationMeta(
    'burrType',
  );
  @override
  late final GeneratedColumn<String> burrType = GeneratedColumn<String>(
    'burr_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GrindScaleUnit?, String>
  scaleUnit = GeneratedColumn<String>(
    'scale_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('click'),
  ).withConverter<GrindScaleUnit?>($GrindersTable.$converterscaleUnit);
  static const VerificationMeta _zeroPointMeta = const VerificationMeta(
    'zeroPoint',
  );
  @override
  late final GeneratedColumn<double> zeroPoint = GeneratedColumn<double>(
    'zero_point',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _clicksPerRevolutionMeta =
      const VerificationMeta('clicksPerRevolution');
  @override
  late final GeneratedColumn<int> clicksPerRevolution = GeneratedColumn<int>(
    'clicks_per_revolution',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _micronsPerClickMeta = const VerificationMeta(
    'micronsPerClick',
  );
  @override
  late final GeneratedColumn<double> micronsPerClick = GeneratedColumn<double>(
    'microns_per_click',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calibrationNoteMeta = const VerificationMeta(
    'calibrationNote',
  );
  @override
  late final GeneratedColumn<String> calibrationNote = GeneratedColumn<String>(
    'calibration_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brand,
    model,
    burrType,
    scaleUnit,
    zeroPoint,
    clicksPerRevolution,
    micronsPerClick,
    calibrationNote,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grinders';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrinderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('burr_type')) {
      context.handle(
        _burrTypeMeta,
        burrType.isAcceptableOrUnknown(data['burr_type']!, _burrTypeMeta),
      );
    }
    if (data.containsKey('zero_point')) {
      context.handle(
        _zeroPointMeta,
        zeroPoint.isAcceptableOrUnknown(data['zero_point']!, _zeroPointMeta),
      );
    }
    if (data.containsKey('clicks_per_revolution')) {
      context.handle(
        _clicksPerRevolutionMeta,
        clicksPerRevolution.isAcceptableOrUnknown(
          data['clicks_per_revolution']!,
          _clicksPerRevolutionMeta,
        ),
      );
    }
    if (data.containsKey('microns_per_click')) {
      context.handle(
        _micronsPerClickMeta,
        micronsPerClick.isAcceptableOrUnknown(
          data['microns_per_click']!,
          _micronsPerClickMeta,
        ),
      );
    }
    if (data.containsKey('calibration_note')) {
      context.handle(
        _calibrationNoteMeta,
        calibrationNote.isAcceptableOrUnknown(
          data['calibration_note']!,
          _calibrationNoteMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrinderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrinderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      burrType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}burr_type'],
      ),
      scaleUnit: $GrindersTable.$converterscaleUnit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}scale_unit'],
        )!,
      ),
      zeroPoint: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zero_point'],
      ),
      clicksPerRevolution: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clicks_per_revolution'],
      ),
      micronsPerClick: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}microns_per_click'],
      ),
      calibrationNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calibration_note'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GrindersTable createAlias(String alias) {
    return $GrindersTable(attachedDatabase, alias);
  }

  static TypeConverter<GrindScaleUnit?, String?> $converterscaleUnit =
      const TolerantEnumConverter<GrindScaleUnit>(GrindScaleUnit.values);
}

class GrinderRow extends DataClass implements Insertable<GrinderRow> {
  final int id;
  final String brand;
  final String model;

  /// 刀盘类型：锥刀 / 平刀 / 鬼齿。
  final String? burrType;
  final GrindScaleUnit? scaleUnit;
  final double? zeroPoint;
  final int? clicksPerRevolution;

  /// 每 click 约等于多少微米（刀盘每格的位移量）。
  ///
  /// 用来把「调粗/调细了几格」换算成实际间隙变化，方便跨磨豆机对比。
  final double? micronsPerClick;
  final String? calibrationNote;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const GrinderRow({
    required this.id,
    required this.brand,
    required this.model,
    this.burrType,
    this.scaleUnit,
    this.zeroPoint,
    this.clicksPerRevolution,
    this.micronsPerClick,
    this.calibrationNote,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['brand'] = Variable<String>(brand);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || burrType != null) {
      map['burr_type'] = Variable<String>(burrType);
    }
    if (!nullToAbsent || scaleUnit != null) {
      map['scale_unit'] = Variable<String>(
        $GrindersTable.$converterscaleUnit.toSql(scaleUnit),
      );
    }
    if (!nullToAbsent || zeroPoint != null) {
      map['zero_point'] = Variable<double>(zeroPoint);
    }
    if (!nullToAbsent || clicksPerRevolution != null) {
      map['clicks_per_revolution'] = Variable<int>(clicksPerRevolution);
    }
    if (!nullToAbsent || micronsPerClick != null) {
      map['microns_per_click'] = Variable<double>(micronsPerClick);
    }
    if (!nullToAbsent || calibrationNote != null) {
      map['calibration_note'] = Variable<String>(calibrationNote);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GrindersCompanion toCompanion(bool nullToAbsent) {
    return GrindersCompanion(
      id: Value(id),
      brand: Value(brand),
      model: Value(model),
      burrType: burrType == null && nullToAbsent
          ? const Value.absent()
          : Value(burrType),
      scaleUnit: scaleUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(scaleUnit),
      zeroPoint: zeroPoint == null && nullToAbsent
          ? const Value.absent()
          : Value(zeroPoint),
      clicksPerRevolution: clicksPerRevolution == null && nullToAbsent
          ? const Value.absent()
          : Value(clicksPerRevolution),
      micronsPerClick: micronsPerClick == null && nullToAbsent
          ? const Value.absent()
          : Value(micronsPerClick),
      calibrationNote: calibrationNote == null && nullToAbsent
          ? const Value.absent()
          : Value(calibrationNote),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GrinderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrinderRow(
      id: serializer.fromJson<int>(json['id']),
      brand: serializer.fromJson<String>(json['brand']),
      model: serializer.fromJson<String>(json['model']),
      burrType: serializer.fromJson<String?>(json['burrType']),
      scaleUnit: serializer.fromJson<GrindScaleUnit?>(json['scaleUnit']),
      zeroPoint: serializer.fromJson<double?>(json['zeroPoint']),
      clicksPerRevolution: serializer.fromJson<int?>(
        json['clicksPerRevolution'],
      ),
      micronsPerClick: serializer.fromJson<double?>(json['micronsPerClick']),
      calibrationNote: serializer.fromJson<String?>(json['calibrationNote']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'brand': serializer.toJson<String>(brand),
      'model': serializer.toJson<String>(model),
      'burrType': serializer.toJson<String?>(burrType),
      'scaleUnit': serializer.toJson<GrindScaleUnit?>(scaleUnit),
      'zeroPoint': serializer.toJson<double?>(zeroPoint),
      'clicksPerRevolution': serializer.toJson<int?>(clicksPerRevolution),
      'micronsPerClick': serializer.toJson<double?>(micronsPerClick),
      'calibrationNote': serializer.toJson<String?>(calibrationNote),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GrinderRow copyWith({
    int? id,
    String? brand,
    String? model,
    Value<String?> burrType = const Value.absent(),
    Value<GrindScaleUnit?> scaleUnit = const Value.absent(),
    Value<double?> zeroPoint = const Value.absent(),
    Value<int?> clicksPerRevolution = const Value.absent(),
    Value<double?> micronsPerClick = const Value.absent(),
    Value<String?> calibrationNote = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GrinderRow(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    burrType: burrType.present ? burrType.value : this.burrType,
    scaleUnit: scaleUnit.present ? scaleUnit.value : this.scaleUnit,
    zeroPoint: zeroPoint.present ? zeroPoint.value : this.zeroPoint,
    clicksPerRevolution: clicksPerRevolution.present
        ? clicksPerRevolution.value
        : this.clicksPerRevolution,
    micronsPerClick: micronsPerClick.present
        ? micronsPerClick.value
        : this.micronsPerClick,
    calibrationNote: calibrationNote.present
        ? calibrationNote.value
        : this.calibrationNote,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GrinderRow copyWithCompanion(GrindersCompanion data) {
    return GrinderRow(
      id: data.id.present ? data.id.value : this.id,
      brand: data.brand.present ? data.brand.value : this.brand,
      model: data.model.present ? data.model.value : this.model,
      burrType: data.burrType.present ? data.burrType.value : this.burrType,
      scaleUnit: data.scaleUnit.present ? data.scaleUnit.value : this.scaleUnit,
      zeroPoint: data.zeroPoint.present ? data.zeroPoint.value : this.zeroPoint,
      clicksPerRevolution: data.clicksPerRevolution.present
          ? data.clicksPerRevolution.value
          : this.clicksPerRevolution,
      micronsPerClick: data.micronsPerClick.present
          ? data.micronsPerClick.value
          : this.micronsPerClick,
      calibrationNote: data.calibrationNote.present
          ? data.calibrationNote.value
          : this.calibrationNote,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrinderRow(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('burrType: $burrType, ')
          ..write('scaleUnit: $scaleUnit, ')
          ..write('zeroPoint: $zeroPoint, ')
          ..write('clicksPerRevolution: $clicksPerRevolution, ')
          ..write('micronsPerClick: $micronsPerClick, ')
          ..write('calibrationNote: $calibrationNote, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    brand,
    model,
    burrType,
    scaleUnit,
    zeroPoint,
    clicksPerRevolution,
    micronsPerClick,
    calibrationNote,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrinderRow &&
          other.id == this.id &&
          other.brand == this.brand &&
          other.model == this.model &&
          other.burrType == this.burrType &&
          other.scaleUnit == this.scaleUnit &&
          other.zeroPoint == this.zeroPoint &&
          other.clicksPerRevolution == this.clicksPerRevolution &&
          other.micronsPerClick == this.micronsPerClick &&
          other.calibrationNote == this.calibrationNote &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GrindersCompanion extends UpdateCompanion<GrinderRow> {
  final Value<int> id;
  final Value<String> brand;
  final Value<String> model;
  final Value<String?> burrType;
  final Value<GrindScaleUnit?> scaleUnit;
  final Value<double?> zeroPoint;
  final Value<int?> clicksPerRevolution;
  final Value<double?> micronsPerClick;
  final Value<String?> calibrationNote;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GrindersCompanion({
    this.id = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.burrType = const Value.absent(),
    this.scaleUnit = const Value.absent(),
    this.zeroPoint = const Value.absent(),
    this.clicksPerRevolution = const Value.absent(),
    this.micronsPerClick = const Value.absent(),
    this.calibrationNote = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GrindersCompanion.insert({
    this.id = const Value.absent(),
    required String brand,
    required String model,
    this.burrType = const Value.absent(),
    this.scaleUnit = const Value.absent(),
    this.zeroPoint = const Value.absent(),
    this.clicksPerRevolution = const Value.absent(),
    this.micronsPerClick = const Value.absent(),
    this.calibrationNote = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : brand = Value(brand),
       model = Value(model);
  static Insertable<GrinderRow> custom({
    Expression<int>? id,
    Expression<String>? brand,
    Expression<String>? model,
    Expression<String>? burrType,
    Expression<String>? scaleUnit,
    Expression<double>? zeroPoint,
    Expression<int>? clicksPerRevolution,
    Expression<double>? micronsPerClick,
    Expression<String>? calibrationNote,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (burrType != null) 'burr_type': burrType,
      if (scaleUnit != null) 'scale_unit': scaleUnit,
      if (zeroPoint != null) 'zero_point': zeroPoint,
      if (clicksPerRevolution != null)
        'clicks_per_revolution': clicksPerRevolution,
      if (micronsPerClick != null) 'microns_per_click': micronsPerClick,
      if (calibrationNote != null) 'calibration_note': calibrationNote,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GrindersCompanion copyWith({
    Value<int>? id,
    Value<String>? brand,
    Value<String>? model,
    Value<String?>? burrType,
    Value<GrindScaleUnit?>? scaleUnit,
    Value<double?>? zeroPoint,
    Value<int?>? clicksPerRevolution,
    Value<double?>? micronsPerClick,
    Value<String?>? calibrationNote,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return GrindersCompanion(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      burrType: burrType ?? this.burrType,
      scaleUnit: scaleUnit ?? this.scaleUnit,
      zeroPoint: zeroPoint ?? this.zeroPoint,
      clicksPerRevolution: clicksPerRevolution ?? this.clicksPerRevolution,
      micronsPerClick: micronsPerClick ?? this.micronsPerClick,
      calibrationNote: calibrationNote ?? this.calibrationNote,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (burrType.present) {
      map['burr_type'] = Variable<String>(burrType.value);
    }
    if (scaleUnit.present) {
      map['scale_unit'] = Variable<String>(
        $GrindersTable.$converterscaleUnit.toSql(scaleUnit.value),
      );
    }
    if (zeroPoint.present) {
      map['zero_point'] = Variable<double>(zeroPoint.value);
    }
    if (clicksPerRevolution.present) {
      map['clicks_per_revolution'] = Variable<int>(clicksPerRevolution.value);
    }
    if (micronsPerClick.present) {
      map['microns_per_click'] = Variable<double>(micronsPerClick.value);
    }
    if (calibrationNote.present) {
      map['calibration_note'] = Variable<String>(calibrationNote.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrindersCompanion(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('burrType: $burrType, ')
          ..write('scaleUnit: $scaleUnit, ')
          ..write('zeroPoint: $zeroPoint, ')
          ..write('clicksPerRevolution: $clicksPerRevolution, ')
          ..write('micronsPerClick: $micronsPerClick, ')
          ..write('calibrationNote: $calibrationNote, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, RecipeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BrewMethod?, String> method =
      GeneratedColumn<String>(
        'method',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pourOver'),
      ).withConverter<BrewMethod?>($RecipesTable.$convertermethod);
  static const VerificationMeta _doseGramsMeta = const VerificationMeta(
    'doseGrams',
  );
  @override
  late final GeneratedColumn<double> doseGrams = GeneratedColumn<double>(
    'dose_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterGramsMeta = const VerificationMeta(
    'waterGrams',
  );
  @override
  late final GeneratedColumn<double> waterGrams = GeneratedColumn<double>(
    'water_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratioMeta = const VerificationMeta('ratio');
  @override
  late final GeneratedColumn<double> ratio = GeneratedColumn<double>(
    'ratio',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterTempMeta = const VerificationMeta(
    'waterTemp',
  );
  @override
  late final GeneratedColumn<double> waterTemp = GeneratedColumn<double>(
    'water_temp',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalTimeSecondsMeta = const VerificationMeta(
    'totalTimeSeconds',
  );
  @override
  late final GeneratedColumn<int> totalTimeSeconds = GeneratedColumn<int>(
    'total_time_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<PourStage>?, String>
  pourStages = GeneratedColumn<String>(
    'pour_stages',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<PourStage>?>($RecipesTable.$converterpourStages);
  static const VerificationMeta _grindSuggestionMeta = const VerificationMeta(
    'grindSuggestion',
  );
  @override
  late final GeneratedColumn<String> grindSuggestion = GeneratedColumn<String>(
    'grind_suggestion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    method,
    doseGrams,
    waterGrams,
    ratio,
    waterTemp,
    totalTimeSeconds,
    pourStages,
    grindSuggestion,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dose_grams')) {
      context.handle(
        _doseGramsMeta,
        doseGrams.isAcceptableOrUnknown(data['dose_grams']!, _doseGramsMeta),
      );
    }
    if (data.containsKey('water_grams')) {
      context.handle(
        _waterGramsMeta,
        waterGrams.isAcceptableOrUnknown(data['water_grams']!, _waterGramsMeta),
      );
    }
    if (data.containsKey('ratio')) {
      context.handle(
        _ratioMeta,
        ratio.isAcceptableOrUnknown(data['ratio']!, _ratioMeta),
      );
    }
    if (data.containsKey('water_temp')) {
      context.handle(
        _waterTempMeta,
        waterTemp.isAcceptableOrUnknown(data['water_temp']!, _waterTempMeta),
      );
    }
    if (data.containsKey('total_time_seconds')) {
      context.handle(
        _totalTimeSecondsMeta,
        totalTimeSeconds.isAcceptableOrUnknown(
          data['total_time_seconds']!,
          _totalTimeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('grind_suggestion')) {
      context.handle(
        _grindSuggestionMeta,
        grindSuggestion.isAcceptableOrUnknown(
          data['grind_suggestion']!,
          _grindSuggestionMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      method: $RecipesTable.$convertermethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}method'],
        )!,
      ),
      doseGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dose_grams'],
      ),
      waterGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_grams'],
      ),
      ratio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ratio'],
      ),
      waterTemp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_temp'],
      ),
      totalTimeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_time_seconds'],
      ),
      pourStages: $RecipesTable.$converterpourStages.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pour_stages'],
        ),
      ),
      grindSuggestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grind_suggestion'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }

  static TypeConverter<BrewMethod?, String?> $convertermethod =
      const TolerantEnumConverter<BrewMethod>(BrewMethod.values);
  static TypeConverter<List<PourStage>?, String?> $converterpourStages =
      const PourStageListConverter();
}

class RecipeRow extends DataClass implements Insertable<RecipeRow> {
  final int id;
  final String name;
  final BrewMethod? method;
  final double? doseGrams;
  final double? waterGrams;
  final double? ratio;
  final double? waterTemp;
  final int? totalTimeSeconds;
  final List<PourStage>? pourStages;

  /// 研磨建议（文字描述，不绑定具体磨豆机）。
  final String? grindSuggestion;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RecipeRow({
    required this.id,
    required this.name,
    this.method,
    this.doseGrams,
    this.waterGrams,
    this.ratio,
    this.waterTemp,
    this.totalTimeSeconds,
    this.pourStages,
    this.grindSuggestion,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>(
        $RecipesTable.$convertermethod.toSql(method),
      );
    }
    if (!nullToAbsent || doseGrams != null) {
      map['dose_grams'] = Variable<double>(doseGrams);
    }
    if (!nullToAbsent || waterGrams != null) {
      map['water_grams'] = Variable<double>(waterGrams);
    }
    if (!nullToAbsent || ratio != null) {
      map['ratio'] = Variable<double>(ratio);
    }
    if (!nullToAbsent || waterTemp != null) {
      map['water_temp'] = Variable<double>(waterTemp);
    }
    if (!nullToAbsent || totalTimeSeconds != null) {
      map['total_time_seconds'] = Variable<int>(totalTimeSeconds);
    }
    if (!nullToAbsent || pourStages != null) {
      map['pour_stages'] = Variable<String>(
        $RecipesTable.$converterpourStages.toSql(pourStages),
      );
    }
    if (!nullToAbsent || grindSuggestion != null) {
      map['grind_suggestion'] = Variable<String>(grindSuggestion);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      name: Value(name),
      method: method == null && nullToAbsent
          ? const Value.absent()
          : Value(method),
      doseGrams: doseGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(doseGrams),
      waterGrams: waterGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(waterGrams),
      ratio: ratio == null && nullToAbsent
          ? const Value.absent()
          : Value(ratio),
      waterTemp: waterTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(waterTemp),
      totalTimeSeconds: totalTimeSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(totalTimeSeconds),
      pourStages: pourStages == null && nullToAbsent
          ? const Value.absent()
          : Value(pourStages),
      grindSuggestion: grindSuggestion == null && nullToAbsent
          ? const Value.absent()
          : Value(grindSuggestion),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecipeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      method: serializer.fromJson<BrewMethod?>(json['method']),
      doseGrams: serializer.fromJson<double?>(json['doseGrams']),
      waterGrams: serializer.fromJson<double?>(json['waterGrams']),
      ratio: serializer.fromJson<double?>(json['ratio']),
      waterTemp: serializer.fromJson<double?>(json['waterTemp']),
      totalTimeSeconds: serializer.fromJson<int?>(json['totalTimeSeconds']),
      pourStages: serializer.fromJson<List<PourStage>?>(json['pourStages']),
      grindSuggestion: serializer.fromJson<String?>(json['grindSuggestion']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'method': serializer.toJson<BrewMethod?>(method),
      'doseGrams': serializer.toJson<double?>(doseGrams),
      'waterGrams': serializer.toJson<double?>(waterGrams),
      'ratio': serializer.toJson<double?>(ratio),
      'waterTemp': serializer.toJson<double?>(waterTemp),
      'totalTimeSeconds': serializer.toJson<int?>(totalTimeSeconds),
      'pourStages': serializer.toJson<List<PourStage>?>(pourStages),
      'grindSuggestion': serializer.toJson<String?>(grindSuggestion),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RecipeRow copyWith({
    int? id,
    String? name,
    Value<BrewMethod?> method = const Value.absent(),
    Value<double?> doseGrams = const Value.absent(),
    Value<double?> waterGrams = const Value.absent(),
    Value<double?> ratio = const Value.absent(),
    Value<double?> waterTemp = const Value.absent(),
    Value<int?> totalTimeSeconds = const Value.absent(),
    Value<List<PourStage>?> pourStages = const Value.absent(),
    Value<String?> grindSuggestion = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RecipeRow(
    id: id ?? this.id,
    name: name ?? this.name,
    method: method.present ? method.value : this.method,
    doseGrams: doseGrams.present ? doseGrams.value : this.doseGrams,
    waterGrams: waterGrams.present ? waterGrams.value : this.waterGrams,
    ratio: ratio.present ? ratio.value : this.ratio,
    waterTemp: waterTemp.present ? waterTemp.value : this.waterTemp,
    totalTimeSeconds: totalTimeSeconds.present
        ? totalTimeSeconds.value
        : this.totalTimeSeconds,
    pourStages: pourStages.present ? pourStages.value : this.pourStages,
    grindSuggestion: grindSuggestion.present
        ? grindSuggestion.value
        : this.grindSuggestion,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecipeRow copyWithCompanion(RecipesCompanion data) {
    return RecipeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      method: data.method.present ? data.method.value : this.method,
      doseGrams: data.doseGrams.present ? data.doseGrams.value : this.doseGrams,
      waterGrams: data.waterGrams.present
          ? data.waterGrams.value
          : this.waterGrams,
      ratio: data.ratio.present ? data.ratio.value : this.ratio,
      waterTemp: data.waterTemp.present ? data.waterTemp.value : this.waterTemp,
      totalTimeSeconds: data.totalTimeSeconds.present
          ? data.totalTimeSeconds.value
          : this.totalTimeSeconds,
      pourStages: data.pourStages.present
          ? data.pourStages.value
          : this.pourStages,
      grindSuggestion: data.grindSuggestion.present
          ? data.grindSuggestion.value
          : this.grindSuggestion,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('method: $method, ')
          ..write('doseGrams: $doseGrams, ')
          ..write('waterGrams: $waterGrams, ')
          ..write('ratio: $ratio, ')
          ..write('waterTemp: $waterTemp, ')
          ..write('totalTimeSeconds: $totalTimeSeconds, ')
          ..write('pourStages: $pourStages, ')
          ..write('grindSuggestion: $grindSuggestion, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    method,
    doseGrams,
    waterGrams,
    ratio,
    waterTemp,
    totalTimeSeconds,
    pourStages,
    grindSuggestion,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.method == this.method &&
          other.doseGrams == this.doseGrams &&
          other.waterGrams == this.waterGrams &&
          other.ratio == this.ratio &&
          other.waterTemp == this.waterTemp &&
          other.totalTimeSeconds == this.totalTimeSeconds &&
          other.pourStages == this.pourStages &&
          other.grindSuggestion == this.grindSuggestion &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecipesCompanion extends UpdateCompanion<RecipeRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<BrewMethod?> method;
  final Value<double?> doseGrams;
  final Value<double?> waterGrams;
  final Value<double?> ratio;
  final Value<double?> waterTemp;
  final Value<int?> totalTimeSeconds;
  final Value<List<PourStage>?> pourStages;
  final Value<String?> grindSuggestion;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.method = const Value.absent(),
    this.doseGrams = const Value.absent(),
    this.waterGrams = const Value.absent(),
    this.ratio = const Value.absent(),
    this.waterTemp = const Value.absent(),
    this.totalTimeSeconds = const Value.absent(),
    this.pourStages = const Value.absent(),
    this.grindSuggestion = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RecipesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.method = const Value.absent(),
    this.doseGrams = const Value.absent(),
    this.waterGrams = const Value.absent(),
    this.ratio = const Value.absent(),
    this.waterTemp = const Value.absent(),
    this.totalTimeSeconds = const Value.absent(),
    this.pourStages = const Value.absent(),
    this.grindSuggestion = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<RecipeRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? method,
    Expression<double>? doseGrams,
    Expression<double>? waterGrams,
    Expression<double>? ratio,
    Expression<double>? waterTemp,
    Expression<int>? totalTimeSeconds,
    Expression<String>? pourStages,
    Expression<String>? grindSuggestion,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (method != null) 'method': method,
      if (doseGrams != null) 'dose_grams': doseGrams,
      if (waterGrams != null) 'water_grams': waterGrams,
      if (ratio != null) 'ratio': ratio,
      if (waterTemp != null) 'water_temp': waterTemp,
      if (totalTimeSeconds != null) 'total_time_seconds': totalTimeSeconds,
      if (pourStages != null) 'pour_stages': pourStages,
      if (grindSuggestion != null) 'grind_suggestion': grindSuggestion,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RecipesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<BrewMethod?>? method,
    Value<double?>? doseGrams,
    Value<double?>? waterGrams,
    Value<double?>? ratio,
    Value<double?>? waterTemp,
    Value<int?>? totalTimeSeconds,
    Value<List<PourStage>?>? pourStages,
    Value<String?>? grindSuggestion,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      doseGrams: doseGrams ?? this.doseGrams,
      waterGrams: waterGrams ?? this.waterGrams,
      ratio: ratio ?? this.ratio,
      waterTemp: waterTemp ?? this.waterTemp,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      pourStages: pourStages ?? this.pourStages,
      grindSuggestion: grindSuggestion ?? this.grindSuggestion,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(
        $RecipesTable.$convertermethod.toSql(method.value),
      );
    }
    if (doseGrams.present) {
      map['dose_grams'] = Variable<double>(doseGrams.value);
    }
    if (waterGrams.present) {
      map['water_grams'] = Variable<double>(waterGrams.value);
    }
    if (ratio.present) {
      map['ratio'] = Variable<double>(ratio.value);
    }
    if (waterTemp.present) {
      map['water_temp'] = Variable<double>(waterTemp.value);
    }
    if (totalTimeSeconds.present) {
      map['total_time_seconds'] = Variable<int>(totalTimeSeconds.value);
    }
    if (pourStages.present) {
      map['pour_stages'] = Variable<String>(
        $RecipesTable.$converterpourStages.toSql(pourStages.value),
      );
    }
    if (grindSuggestion.present) {
      map['grind_suggestion'] = Variable<String>(grindSuggestion.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('method: $method, ')
          ..write('doseGrams: $doseGrams, ')
          ..write('waterGrams: $waterGrams, ')
          ..write('ratio: $ratio, ')
          ..write('waterTemp: $waterTemp, ')
          ..write('totalTimeSeconds: $totalTimeSeconds, ')
          ..write('pourStages: $pourStages, ')
          ..write('grindSuggestion: $grindSuggestion, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BrewLogsTable extends BrewLogs
    with TableInfo<$BrewLogsTable, BrewLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _beanIdMeta = const VerificationMeta('beanId');
  @override
  late final GeneratedColumn<int> beanId = GeneratedColumn<int>(
    'bean_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES coffee_beans (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _grinderIdMeta = const VerificationMeta(
    'grinderId',
  );
  @override
  late final GeneratedColumn<int> grinderId = GeneratedColumn<int>(
    'grinder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES grinders (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<int> recipeId = GeneratedColumn<int>(
    'recipe_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<BrewMethod?, String> method =
      GeneratedColumn<String>(
        'method',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pourOver'),
      ).withConverter<BrewMethod?>($BrewLogsTable.$convertermethod);
  static const VerificationMeta _methodLabelMeta = const VerificationMeta(
    'methodLabel',
  );
  @override
  late final GeneratedColumn<String> methodLabel = GeneratedColumn<String>(
    'method_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grindSettingMeta = const VerificationMeta(
    'grindSetting',
  );
  @override
  late final GeneratedColumn<double> grindSetting = GeneratedColumn<double>(
    'grind_setting',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grindClicksMeta = const VerificationMeta(
    'grindClicks',
  );
  @override
  late final GeneratedColumn<int> grindClicks = GeneratedColumn<int>(
    'grind_clicks',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grinderZeroPointSnapshotMeta =
      const VerificationMeta('grinderZeroPointSnapshot');
  @override
  late final GeneratedColumn<double> grinderZeroPointSnapshot =
      GeneratedColumn<double>(
        'grinder_zero_point_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _grinderClicksPerRevolutionSnapshotMeta =
      const VerificationMeta('grinderClicksPerRevolutionSnapshot');
  @override
  late final GeneratedColumn<int> grinderClicksPerRevolutionSnapshot =
      GeneratedColumn<int>(
        'grinder_clicks_per_revolution_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _doseGramsMeta = const VerificationMeta(
    'doseGrams',
  );
  @override
  late final GeneratedColumn<double> doseGrams = GeneratedColumn<double>(
    'dose_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterGramsMeta = const VerificationMeta(
    'waterGrams',
  );
  @override
  late final GeneratedColumn<double> waterGrams = GeneratedColumn<double>(
    'water_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratioMeta = const VerificationMeta('ratio');
  @override
  late final GeneratedColumn<double> ratio = GeneratedColumn<double>(
    'ratio',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterTempMeta = const VerificationMeta(
    'waterTemp',
  );
  @override
  late final GeneratedColumn<double> waterTemp = GeneratedColumn<double>(
    'water_temp',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalTimeSecondsMeta = const VerificationMeta(
    'totalTimeSeconds',
  );
  @override
  late final GeneratedColumn<int> totalTimeSeconds = GeneratedColumn<int>(
    'total_time_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dripperMeta = const VerificationMeta(
    'dripper',
  );
  @override
  late final GeneratedColumn<String> dripper = GeneratedColumn<String>(
    'dripper',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> flavorTags =
      GeneratedColumn<String>(
        'flavor_tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($BrewLogsTable.$converterflavorTags);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brewedAtMeta = const VerificationMeta(
    'brewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> brewedAt = GeneratedColumn<DateTime>(
    'brewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isBestMeta = const VerificationMeta('isBest');
  @override
  late final GeneratedColumn<bool> isBest = GeneratedColumn<bool>(
    'is_best',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_best" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tdsMeta = const VerificationMeta('tds');
  @override
  late final GeneratedColumn<double> tds = GeneratedColumn<double>(
    'tds',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractionYieldMeta = const VerificationMeta(
    'extractionYield',
  );
  @override
  late final GeneratedColumn<double> extractionYield = GeneratedColumn<double>(
    'extraction_yield',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterPpmMeta = const VerificationMeta(
    'waterPpm',
  );
  @override
  late final GeneratedColumn<int> waterPpm = GeneratedColumn<int>(
    'water_ppm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ambientTempMeta = const VerificationMeta(
    'ambientTemp',
  );
  @override
  late final GeneratedColumn<double> ambientTemp = GeneratedColumn<double>(
    'ambient_temp',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ambientHumidityMeta = const VerificationMeta(
    'ambientHumidity',
  );
  @override
  late final GeneratedColumn<double> ambientHumidity = GeneratedColumn<double>(
    'ambient_humidity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beanTempMeta = const VerificationMeta(
    'beanTemp',
  );
  @override
  late final GeneratedColumn<double> beanTemp = GeneratedColumn<double>(
    'bean_temp',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pressureMeta = const VerificationMeta(
    'pressure',
  );
  @override
  late final GeneratedColumn<double> pressure = GeneratedColumn<double>(
    'pressure',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<PourStage>?, String>
  pourStages = GeneratedColumn<String>(
    'pour_stages',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<PourStage>?>($BrewLogsTable.$converterpourStages);
  static const VerificationMeta _beanRoastDateMeta = const VerificationMeta(
    'beanRoastDate',
  );
  @override
  late final GeneratedColumn<DateTime> beanRoastDate =
      GeneratedColumn<DateTime>(
        'bean_roast_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<RoastLevel?, String>
  beanRoastLevel = GeneratedColumn<String>(
    'bean_roast_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<RoastLevel?>($BrewLogsTable.$converterbeanRoastLevel);
  static const VerificationMeta _heatLevelMeta = const VerificationMeta(
    'heatLevel',
  );
  @override
  late final GeneratedColumn<String> heatLevel = GeneratedColumn<String>(
    'heat_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yieldGramsMeta = const VerificationMeta(
    'yieldGrams',
  );
  @override
  late final GeneratedColumn<double> yieldGrams = GeneratedColumn<double>(
    'yield_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preheatUpperChamberMeta =
      const VerificationMeta('preheatUpperChamber');
  @override
  late final GeneratedColumn<bool> preheatUpperChamber = GeneratedColumn<bool>(
    'preheat_upper_chamber',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("preheat_upper_chamber" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    beanId,
    grinderId,
    recipeId,
    method,
    methodLabel,
    grindSetting,
    grindClicks,
    grinderZeroPointSnapshot,
    grinderClicksPerRevolutionSnapshot,
    doseGrams,
    waterGrams,
    ratio,
    waterTemp,
    totalTimeSeconds,
    dripper,
    rating,
    flavorTags,
    notes,
    photoPath,
    brewedAt,
    isBest,
    isFavorite,
    tds,
    extractionYield,
    waterPpm,
    ambientTemp,
    ambientHumidity,
    beanTemp,
    pressure,
    pourStages,
    beanRoastDate,
    beanRoastLevel,
    heatLevel,
    yieldGrams,
    preheatUpperChamber,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brew_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BrewLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bean_id')) {
      context.handle(
        _beanIdMeta,
        beanId.isAcceptableOrUnknown(data['bean_id']!, _beanIdMeta),
      );
    }
    if (data.containsKey('grinder_id')) {
      context.handle(
        _grinderIdMeta,
        grinderId.isAcceptableOrUnknown(data['grinder_id']!, _grinderIdMeta),
      );
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    }
    if (data.containsKey('method_label')) {
      context.handle(
        _methodLabelMeta,
        methodLabel.isAcceptableOrUnknown(
          data['method_label']!,
          _methodLabelMeta,
        ),
      );
    }
    if (data.containsKey('grind_setting')) {
      context.handle(
        _grindSettingMeta,
        grindSetting.isAcceptableOrUnknown(
          data['grind_setting']!,
          _grindSettingMeta,
        ),
      );
    }
    if (data.containsKey('grind_clicks')) {
      context.handle(
        _grindClicksMeta,
        grindClicks.isAcceptableOrUnknown(
          data['grind_clicks']!,
          _grindClicksMeta,
        ),
      );
    }
    if (data.containsKey('grinder_zero_point_snapshot')) {
      context.handle(
        _grinderZeroPointSnapshotMeta,
        grinderZeroPointSnapshot.isAcceptableOrUnknown(
          data['grinder_zero_point_snapshot']!,
          _grinderZeroPointSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('grinder_clicks_per_revolution_snapshot')) {
      context.handle(
        _grinderClicksPerRevolutionSnapshotMeta,
        grinderClicksPerRevolutionSnapshot.isAcceptableOrUnknown(
          data['grinder_clicks_per_revolution_snapshot']!,
          _grinderClicksPerRevolutionSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('dose_grams')) {
      context.handle(
        _doseGramsMeta,
        doseGrams.isAcceptableOrUnknown(data['dose_grams']!, _doseGramsMeta),
      );
    }
    if (data.containsKey('water_grams')) {
      context.handle(
        _waterGramsMeta,
        waterGrams.isAcceptableOrUnknown(data['water_grams']!, _waterGramsMeta),
      );
    }
    if (data.containsKey('ratio')) {
      context.handle(
        _ratioMeta,
        ratio.isAcceptableOrUnknown(data['ratio']!, _ratioMeta),
      );
    }
    if (data.containsKey('water_temp')) {
      context.handle(
        _waterTempMeta,
        waterTemp.isAcceptableOrUnknown(data['water_temp']!, _waterTempMeta),
      );
    }
    if (data.containsKey('total_time_seconds')) {
      context.handle(
        _totalTimeSecondsMeta,
        totalTimeSeconds.isAcceptableOrUnknown(
          data['total_time_seconds']!,
          _totalTimeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('dripper')) {
      context.handle(
        _dripperMeta,
        dripper.isAcceptableOrUnknown(data['dripper']!, _dripperMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('brewed_at')) {
      context.handle(
        _brewedAtMeta,
        brewedAt.isAcceptableOrUnknown(data['brewed_at']!, _brewedAtMeta),
      );
    }
    if (data.containsKey('is_best')) {
      context.handle(
        _isBestMeta,
        isBest.isAcceptableOrUnknown(data['is_best']!, _isBestMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('tds')) {
      context.handle(
        _tdsMeta,
        tds.isAcceptableOrUnknown(data['tds']!, _tdsMeta),
      );
    }
    if (data.containsKey('extraction_yield')) {
      context.handle(
        _extractionYieldMeta,
        extractionYield.isAcceptableOrUnknown(
          data['extraction_yield']!,
          _extractionYieldMeta,
        ),
      );
    }
    if (data.containsKey('water_ppm')) {
      context.handle(
        _waterPpmMeta,
        waterPpm.isAcceptableOrUnknown(data['water_ppm']!, _waterPpmMeta),
      );
    }
    if (data.containsKey('ambient_temp')) {
      context.handle(
        _ambientTempMeta,
        ambientTemp.isAcceptableOrUnknown(
          data['ambient_temp']!,
          _ambientTempMeta,
        ),
      );
    }
    if (data.containsKey('ambient_humidity')) {
      context.handle(
        _ambientHumidityMeta,
        ambientHumidity.isAcceptableOrUnknown(
          data['ambient_humidity']!,
          _ambientHumidityMeta,
        ),
      );
    }
    if (data.containsKey('bean_temp')) {
      context.handle(
        _beanTempMeta,
        beanTemp.isAcceptableOrUnknown(data['bean_temp']!, _beanTempMeta),
      );
    }
    if (data.containsKey('pressure')) {
      context.handle(
        _pressureMeta,
        pressure.isAcceptableOrUnknown(data['pressure']!, _pressureMeta),
      );
    }
    if (data.containsKey('bean_roast_date')) {
      context.handle(
        _beanRoastDateMeta,
        beanRoastDate.isAcceptableOrUnknown(
          data['bean_roast_date']!,
          _beanRoastDateMeta,
        ),
      );
    }
    if (data.containsKey('heat_level')) {
      context.handle(
        _heatLevelMeta,
        heatLevel.isAcceptableOrUnknown(data['heat_level']!, _heatLevelMeta),
      );
    }
    if (data.containsKey('yield_grams')) {
      context.handle(
        _yieldGramsMeta,
        yieldGrams.isAcceptableOrUnknown(data['yield_grams']!, _yieldGramsMeta),
      );
    }
    if (data.containsKey('preheat_upper_chamber')) {
      context.handle(
        _preheatUpperChamberMeta,
        preheatUpperChamber.isAcceptableOrUnknown(
          data['preheat_upper_chamber']!,
          _preheatUpperChamberMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BrewLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrewLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      beanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bean_id'],
      ),
      grinderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grinder_id'],
      ),
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recipe_id'],
      ),
      method: $BrewLogsTable.$convertermethod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}method'],
        )!,
      ),
      methodLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_label'],
      ),
      grindSetting: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grind_setting'],
      ),
      grindClicks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grind_clicks'],
      ),
      grinderZeroPointSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grinder_zero_point_snapshot'],
      ),
      grinderClicksPerRevolutionSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grinder_clicks_per_revolution_snapshot'],
      ),
      doseGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dose_grams'],
      ),
      waterGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_grams'],
      ),
      ratio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ratio'],
      ),
      waterTemp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_temp'],
      ),
      totalTimeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_time_seconds'],
      ),
      dripper: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dripper'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      flavorTags: $BrewLogsTable.$converterflavorTags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}flavor_tags'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      brewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}brewed_at'],
      )!,
      isBest: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_best'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      tds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tds'],
      ),
      extractionYield: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}extraction_yield'],
      ),
      waterPpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}water_ppm'],
      ),
      ambientTemp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ambient_temp'],
      ),
      ambientHumidity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ambient_humidity'],
      ),
      beanTemp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bean_temp'],
      ),
      pressure: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pressure'],
      ),
      pourStages: $BrewLogsTable.$converterpourStages.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pour_stages'],
        ),
      ),
      beanRoastDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}bean_roast_date'],
      ),
      beanRoastLevel: $BrewLogsTable.$converterbeanRoastLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}bean_roast_level'],
        ),
      ),
      heatLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heat_level'],
      ),
      yieldGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}yield_grams'],
      ),
      preheatUpperChamber: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}preheat_upper_chamber'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BrewLogsTable createAlias(String alias) {
    return $BrewLogsTable(attachedDatabase, alias);
  }

  static TypeConverter<BrewMethod?, String?> $convertermethod =
      const TolerantEnumConverter<BrewMethod>(BrewMethod.values);
  static TypeConverter<List<String>, String> $converterflavorTags =
      const StringListConverter();
  static TypeConverter<List<PourStage>?, String?> $converterpourStages =
      const PourStageListConverter();
  static TypeConverter<RoastLevel?, String?> $converterbeanRoastLevel =
      const TolerantEnumConverter<RoastLevel>(RoastLevel.values);
}

class BrewLogRow extends DataClass implements Insertable<BrewLogRow> {
  final int id;

  /// 主豆（冗余，便于快速查询）。
  final int? beanId;
  final int? grinderId;
  final int? recipeId;
  final BrewMethod? method;

  /// 自定义冲煮方法的原文（如「拿铁」）；为空表示用内置的 [method]。
  ///
  /// 单独一列而不是把自定义名字塞进 [method]：[method] 挂着容忍枚举转换器，
  /// 认不出的字符串会被回退掉，等于**丢掉方法**。
  final String? methodLabel;
  final double? grindSetting;
  final int? grindClicks;

  /// 当时的磨豆机零点（快照）。
  ///
  /// 「老研磨度关联老记录」：换了刻度或重新校准零点之后，
  /// 老记录仍然按**当时**的零点解释，不会被新零点重新换算。
  final double? grinderZeroPointSnapshot;

  /// 当时的「每圈 click」（快照），同上。
  final int? grinderClicksPerRevolutionSnapshot;

  /// 总粉量（拼配时是各支豆子之和）。
  final double? doseGrams;
  final double? waterGrams;

  /// 粉水比中「1 : N」的 N。
  final double? ratio;
  final double? waterTemp;
  final int? totalTimeSeconds;
  final String? dripper;

  /// 评分 1–5。
  final int? rating;
  final List<String> flavorTags;
  final String? notes;
  final String? photoPath;
  final DateTime brewedAt;

  /// 「标记最佳参数」。
  final bool isBest;

  /// 收藏这条参数（方便以后一键复制出来）。
  ///
  /// 与 [isBest] 的区别：`isBest` 是「这一杯是这套参数的最好结果」，
  /// 收藏是「把这套参数存起来，以后还要照着冲」——
  /// 「新增一杯」右上角复制按钮长按后列出的就是收藏过的这些。
  final bool isFavorite;
  final double? tds;
  final double? extractionYield;
  final int? waterPpm;
  final double? ambientTemp;
  final double? ambientHumidity;
  final double? beanTemp;
  final double? pressure;

  /// 分段注水，JSON 数组，可为空。
  final List<PourStage>? pourStages;

  /// 烘焙日期。
  final DateTime? beanRoastDate;

  /// 烘焙度。
  final RoastLevel? beanRoastLevel;
  final String? heatLevel;
  final double? yieldGrams;
  final bool? preheatUpperChamber;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BrewLogRow({
    required this.id,
    this.beanId,
    this.grinderId,
    this.recipeId,
    this.method,
    this.methodLabel,
    this.grindSetting,
    this.grindClicks,
    this.grinderZeroPointSnapshot,
    this.grinderClicksPerRevolutionSnapshot,
    this.doseGrams,
    this.waterGrams,
    this.ratio,
    this.waterTemp,
    this.totalTimeSeconds,
    this.dripper,
    this.rating,
    required this.flavorTags,
    this.notes,
    this.photoPath,
    required this.brewedAt,
    required this.isBest,
    required this.isFavorite,
    this.tds,
    this.extractionYield,
    this.waterPpm,
    this.ambientTemp,
    this.ambientHumidity,
    this.beanTemp,
    this.pressure,
    this.pourStages,
    this.beanRoastDate,
    this.beanRoastLevel,
    this.heatLevel,
    this.yieldGrams,
    this.preheatUpperChamber,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || beanId != null) {
      map['bean_id'] = Variable<int>(beanId);
    }
    if (!nullToAbsent || grinderId != null) {
      map['grinder_id'] = Variable<int>(grinderId);
    }
    if (!nullToAbsent || recipeId != null) {
      map['recipe_id'] = Variable<int>(recipeId);
    }
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>(
        $BrewLogsTable.$convertermethod.toSql(method),
      );
    }
    if (!nullToAbsent || methodLabel != null) {
      map['method_label'] = Variable<String>(methodLabel);
    }
    if (!nullToAbsent || grindSetting != null) {
      map['grind_setting'] = Variable<double>(grindSetting);
    }
    if (!nullToAbsent || grindClicks != null) {
      map['grind_clicks'] = Variable<int>(grindClicks);
    }
    if (!nullToAbsent || grinderZeroPointSnapshot != null) {
      map['grinder_zero_point_snapshot'] = Variable<double>(
        grinderZeroPointSnapshot,
      );
    }
    if (!nullToAbsent || grinderClicksPerRevolutionSnapshot != null) {
      map['grinder_clicks_per_revolution_snapshot'] = Variable<int>(
        grinderClicksPerRevolutionSnapshot,
      );
    }
    if (!nullToAbsent || doseGrams != null) {
      map['dose_grams'] = Variable<double>(doseGrams);
    }
    if (!nullToAbsent || waterGrams != null) {
      map['water_grams'] = Variable<double>(waterGrams);
    }
    if (!nullToAbsent || ratio != null) {
      map['ratio'] = Variable<double>(ratio);
    }
    if (!nullToAbsent || waterTemp != null) {
      map['water_temp'] = Variable<double>(waterTemp);
    }
    if (!nullToAbsent || totalTimeSeconds != null) {
      map['total_time_seconds'] = Variable<int>(totalTimeSeconds);
    }
    if (!nullToAbsent || dripper != null) {
      map['dripper'] = Variable<String>(dripper);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    {
      map['flavor_tags'] = Variable<String>(
        $BrewLogsTable.$converterflavorTags.toSql(flavorTags),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['brewed_at'] = Variable<DateTime>(brewedAt);
    map['is_best'] = Variable<bool>(isBest);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || tds != null) {
      map['tds'] = Variable<double>(tds);
    }
    if (!nullToAbsent || extractionYield != null) {
      map['extraction_yield'] = Variable<double>(extractionYield);
    }
    if (!nullToAbsent || waterPpm != null) {
      map['water_ppm'] = Variable<int>(waterPpm);
    }
    if (!nullToAbsent || ambientTemp != null) {
      map['ambient_temp'] = Variable<double>(ambientTemp);
    }
    if (!nullToAbsent || ambientHumidity != null) {
      map['ambient_humidity'] = Variable<double>(ambientHumidity);
    }
    if (!nullToAbsent || beanTemp != null) {
      map['bean_temp'] = Variable<double>(beanTemp);
    }
    if (!nullToAbsent || pressure != null) {
      map['pressure'] = Variable<double>(pressure);
    }
    if (!nullToAbsent || pourStages != null) {
      map['pour_stages'] = Variable<String>(
        $BrewLogsTable.$converterpourStages.toSql(pourStages),
      );
    }
    if (!nullToAbsent || beanRoastDate != null) {
      map['bean_roast_date'] = Variable<DateTime>(beanRoastDate);
    }
    if (!nullToAbsent || beanRoastLevel != null) {
      map['bean_roast_level'] = Variable<String>(
        $BrewLogsTable.$converterbeanRoastLevel.toSql(beanRoastLevel),
      );
    }
    if (!nullToAbsent || heatLevel != null) {
      map['heat_level'] = Variable<String>(heatLevel);
    }
    if (!nullToAbsent || yieldGrams != null) {
      map['yield_grams'] = Variable<double>(yieldGrams);
    }
    if (!nullToAbsent || preheatUpperChamber != null) {
      map['preheat_upper_chamber'] = Variable<bool>(preheatUpperChamber);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BrewLogsCompanion toCompanion(bool nullToAbsent) {
    return BrewLogsCompanion(
      id: Value(id),
      beanId: beanId == null && nullToAbsent
          ? const Value.absent()
          : Value(beanId),
      grinderId: grinderId == null && nullToAbsent
          ? const Value.absent()
          : Value(grinderId),
      recipeId: recipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeId),
      method: method == null && nullToAbsent
          ? const Value.absent()
          : Value(method),
      methodLabel: methodLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(methodLabel),
      grindSetting: grindSetting == null && nullToAbsent
          ? const Value.absent()
          : Value(grindSetting),
      grindClicks: grindClicks == null && nullToAbsent
          ? const Value.absent()
          : Value(grindClicks),
      grinderZeroPointSnapshot: grinderZeroPointSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(grinderZeroPointSnapshot),
      grinderClicksPerRevolutionSnapshot:
          grinderClicksPerRevolutionSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(grinderClicksPerRevolutionSnapshot),
      doseGrams: doseGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(doseGrams),
      waterGrams: waterGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(waterGrams),
      ratio: ratio == null && nullToAbsent
          ? const Value.absent()
          : Value(ratio),
      waterTemp: waterTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(waterTemp),
      totalTimeSeconds: totalTimeSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(totalTimeSeconds),
      dripper: dripper == null && nullToAbsent
          ? const Value.absent()
          : Value(dripper),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      flavorTags: Value(flavorTags),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      brewedAt: Value(brewedAt),
      isBest: Value(isBest),
      isFavorite: Value(isFavorite),
      tds: tds == null && nullToAbsent ? const Value.absent() : Value(tds),
      extractionYield: extractionYield == null && nullToAbsent
          ? const Value.absent()
          : Value(extractionYield),
      waterPpm: waterPpm == null && nullToAbsent
          ? const Value.absent()
          : Value(waterPpm),
      ambientTemp: ambientTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(ambientTemp),
      ambientHumidity: ambientHumidity == null && nullToAbsent
          ? const Value.absent()
          : Value(ambientHumidity),
      beanTemp: beanTemp == null && nullToAbsent
          ? const Value.absent()
          : Value(beanTemp),
      pressure: pressure == null && nullToAbsent
          ? const Value.absent()
          : Value(pressure),
      pourStages: pourStages == null && nullToAbsent
          ? const Value.absent()
          : Value(pourStages),
      beanRoastDate: beanRoastDate == null && nullToAbsent
          ? const Value.absent()
          : Value(beanRoastDate),
      beanRoastLevel: beanRoastLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(beanRoastLevel),
      heatLevel: heatLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(heatLevel),
      yieldGrams: yieldGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(yieldGrams),
      preheatUpperChamber: preheatUpperChamber == null && nullToAbsent
          ? const Value.absent()
          : Value(preheatUpperChamber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BrewLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrewLogRow(
      id: serializer.fromJson<int>(json['id']),
      beanId: serializer.fromJson<int?>(json['beanId']),
      grinderId: serializer.fromJson<int?>(json['grinderId']),
      recipeId: serializer.fromJson<int?>(json['recipeId']),
      method: serializer.fromJson<BrewMethod?>(json['method']),
      methodLabel: serializer.fromJson<String?>(json['methodLabel']),
      grindSetting: serializer.fromJson<double?>(json['grindSetting']),
      grindClicks: serializer.fromJson<int?>(json['grindClicks']),
      grinderZeroPointSnapshot: serializer.fromJson<double?>(
        json['grinderZeroPointSnapshot'],
      ),
      grinderClicksPerRevolutionSnapshot: serializer.fromJson<int?>(
        json['grinderClicksPerRevolutionSnapshot'],
      ),
      doseGrams: serializer.fromJson<double?>(json['doseGrams']),
      waterGrams: serializer.fromJson<double?>(json['waterGrams']),
      ratio: serializer.fromJson<double?>(json['ratio']),
      waterTemp: serializer.fromJson<double?>(json['waterTemp']),
      totalTimeSeconds: serializer.fromJson<int?>(json['totalTimeSeconds']),
      dripper: serializer.fromJson<String?>(json['dripper']),
      rating: serializer.fromJson<int?>(json['rating']),
      flavorTags: serializer.fromJson<List<String>>(json['flavorTags']),
      notes: serializer.fromJson<String?>(json['notes']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      brewedAt: serializer.fromJson<DateTime>(json['brewedAt']),
      isBest: serializer.fromJson<bool>(json['isBest']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      tds: serializer.fromJson<double?>(json['tds']),
      extractionYield: serializer.fromJson<double?>(json['extractionYield']),
      waterPpm: serializer.fromJson<int?>(json['waterPpm']),
      ambientTemp: serializer.fromJson<double?>(json['ambientTemp']),
      ambientHumidity: serializer.fromJson<double?>(json['ambientHumidity']),
      beanTemp: serializer.fromJson<double?>(json['beanTemp']),
      pressure: serializer.fromJson<double?>(json['pressure']),
      pourStages: serializer.fromJson<List<PourStage>?>(json['pourStages']),
      beanRoastDate: serializer.fromJson<DateTime?>(json['beanRoastDate']),
      beanRoastLevel: serializer.fromJson<RoastLevel?>(json['beanRoastLevel']),
      heatLevel: serializer.fromJson<String?>(json['heatLevel']),
      yieldGrams: serializer.fromJson<double?>(json['yieldGrams']),
      preheatUpperChamber: serializer.fromJson<bool?>(
        json['preheatUpperChamber'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'beanId': serializer.toJson<int?>(beanId),
      'grinderId': serializer.toJson<int?>(grinderId),
      'recipeId': serializer.toJson<int?>(recipeId),
      'method': serializer.toJson<BrewMethod?>(method),
      'methodLabel': serializer.toJson<String?>(methodLabel),
      'grindSetting': serializer.toJson<double?>(grindSetting),
      'grindClicks': serializer.toJson<int?>(grindClicks),
      'grinderZeroPointSnapshot': serializer.toJson<double?>(
        grinderZeroPointSnapshot,
      ),
      'grinderClicksPerRevolutionSnapshot': serializer.toJson<int?>(
        grinderClicksPerRevolutionSnapshot,
      ),
      'doseGrams': serializer.toJson<double?>(doseGrams),
      'waterGrams': serializer.toJson<double?>(waterGrams),
      'ratio': serializer.toJson<double?>(ratio),
      'waterTemp': serializer.toJson<double?>(waterTemp),
      'totalTimeSeconds': serializer.toJson<int?>(totalTimeSeconds),
      'dripper': serializer.toJson<String?>(dripper),
      'rating': serializer.toJson<int?>(rating),
      'flavorTags': serializer.toJson<List<String>>(flavorTags),
      'notes': serializer.toJson<String?>(notes),
      'photoPath': serializer.toJson<String?>(photoPath),
      'brewedAt': serializer.toJson<DateTime>(brewedAt),
      'isBest': serializer.toJson<bool>(isBest),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'tds': serializer.toJson<double?>(tds),
      'extractionYield': serializer.toJson<double?>(extractionYield),
      'waterPpm': serializer.toJson<int?>(waterPpm),
      'ambientTemp': serializer.toJson<double?>(ambientTemp),
      'ambientHumidity': serializer.toJson<double?>(ambientHumidity),
      'beanTemp': serializer.toJson<double?>(beanTemp),
      'pressure': serializer.toJson<double?>(pressure),
      'pourStages': serializer.toJson<List<PourStage>?>(pourStages),
      'beanRoastDate': serializer.toJson<DateTime?>(beanRoastDate),
      'beanRoastLevel': serializer.toJson<RoastLevel?>(beanRoastLevel),
      'heatLevel': serializer.toJson<String?>(heatLevel),
      'yieldGrams': serializer.toJson<double?>(yieldGrams),
      'preheatUpperChamber': serializer.toJson<bool?>(preheatUpperChamber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BrewLogRow copyWith({
    int? id,
    Value<int?> beanId = const Value.absent(),
    Value<int?> grinderId = const Value.absent(),
    Value<int?> recipeId = const Value.absent(),
    Value<BrewMethod?> method = const Value.absent(),
    Value<String?> methodLabel = const Value.absent(),
    Value<double?> grindSetting = const Value.absent(),
    Value<int?> grindClicks = const Value.absent(),
    Value<double?> grinderZeroPointSnapshot = const Value.absent(),
    Value<int?> grinderClicksPerRevolutionSnapshot = const Value.absent(),
    Value<double?> doseGrams = const Value.absent(),
    Value<double?> waterGrams = const Value.absent(),
    Value<double?> ratio = const Value.absent(),
    Value<double?> waterTemp = const Value.absent(),
    Value<int?> totalTimeSeconds = const Value.absent(),
    Value<String?> dripper = const Value.absent(),
    Value<int?> rating = const Value.absent(),
    List<String>? flavorTags,
    Value<String?> notes = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    DateTime? brewedAt,
    bool? isBest,
    bool? isFavorite,
    Value<double?> tds = const Value.absent(),
    Value<double?> extractionYield = const Value.absent(),
    Value<int?> waterPpm = const Value.absent(),
    Value<double?> ambientTemp = const Value.absent(),
    Value<double?> ambientHumidity = const Value.absent(),
    Value<double?> beanTemp = const Value.absent(),
    Value<double?> pressure = const Value.absent(),
    Value<List<PourStage>?> pourStages = const Value.absent(),
    Value<DateTime?> beanRoastDate = const Value.absent(),
    Value<RoastLevel?> beanRoastLevel = const Value.absent(),
    Value<String?> heatLevel = const Value.absent(),
    Value<double?> yieldGrams = const Value.absent(),
    Value<bool?> preheatUpperChamber = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BrewLogRow(
    id: id ?? this.id,
    beanId: beanId.present ? beanId.value : this.beanId,
    grinderId: grinderId.present ? grinderId.value : this.grinderId,
    recipeId: recipeId.present ? recipeId.value : this.recipeId,
    method: method.present ? method.value : this.method,
    methodLabel: methodLabel.present ? methodLabel.value : this.methodLabel,
    grindSetting: grindSetting.present ? grindSetting.value : this.grindSetting,
    grindClicks: grindClicks.present ? grindClicks.value : this.grindClicks,
    grinderZeroPointSnapshot: grinderZeroPointSnapshot.present
        ? grinderZeroPointSnapshot.value
        : this.grinderZeroPointSnapshot,
    grinderClicksPerRevolutionSnapshot:
        grinderClicksPerRevolutionSnapshot.present
        ? grinderClicksPerRevolutionSnapshot.value
        : this.grinderClicksPerRevolutionSnapshot,
    doseGrams: doseGrams.present ? doseGrams.value : this.doseGrams,
    waterGrams: waterGrams.present ? waterGrams.value : this.waterGrams,
    ratio: ratio.present ? ratio.value : this.ratio,
    waterTemp: waterTemp.present ? waterTemp.value : this.waterTemp,
    totalTimeSeconds: totalTimeSeconds.present
        ? totalTimeSeconds.value
        : this.totalTimeSeconds,
    dripper: dripper.present ? dripper.value : this.dripper,
    rating: rating.present ? rating.value : this.rating,
    flavorTags: flavorTags ?? this.flavorTags,
    notes: notes.present ? notes.value : this.notes,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    brewedAt: brewedAt ?? this.brewedAt,
    isBest: isBest ?? this.isBest,
    isFavorite: isFavorite ?? this.isFavorite,
    tds: tds.present ? tds.value : this.tds,
    extractionYield: extractionYield.present
        ? extractionYield.value
        : this.extractionYield,
    waterPpm: waterPpm.present ? waterPpm.value : this.waterPpm,
    ambientTemp: ambientTemp.present ? ambientTemp.value : this.ambientTemp,
    ambientHumidity: ambientHumidity.present
        ? ambientHumidity.value
        : this.ambientHumidity,
    beanTemp: beanTemp.present ? beanTemp.value : this.beanTemp,
    pressure: pressure.present ? pressure.value : this.pressure,
    pourStages: pourStages.present ? pourStages.value : this.pourStages,
    beanRoastDate: beanRoastDate.present
        ? beanRoastDate.value
        : this.beanRoastDate,
    beanRoastLevel: beanRoastLevel.present
        ? beanRoastLevel.value
        : this.beanRoastLevel,
    heatLevel: heatLevel.present ? heatLevel.value : this.heatLevel,
    yieldGrams: yieldGrams.present ? yieldGrams.value : this.yieldGrams,
    preheatUpperChamber: preheatUpperChamber.present
        ? preheatUpperChamber.value
        : this.preheatUpperChamber,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BrewLogRow copyWithCompanion(BrewLogsCompanion data) {
    return BrewLogRow(
      id: data.id.present ? data.id.value : this.id,
      beanId: data.beanId.present ? data.beanId.value : this.beanId,
      grinderId: data.grinderId.present ? data.grinderId.value : this.grinderId,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      method: data.method.present ? data.method.value : this.method,
      methodLabel: data.methodLabel.present
          ? data.methodLabel.value
          : this.methodLabel,
      grindSetting: data.grindSetting.present
          ? data.grindSetting.value
          : this.grindSetting,
      grindClicks: data.grindClicks.present
          ? data.grindClicks.value
          : this.grindClicks,
      grinderZeroPointSnapshot: data.grinderZeroPointSnapshot.present
          ? data.grinderZeroPointSnapshot.value
          : this.grinderZeroPointSnapshot,
      grinderClicksPerRevolutionSnapshot:
          data.grinderClicksPerRevolutionSnapshot.present
          ? data.grinderClicksPerRevolutionSnapshot.value
          : this.grinderClicksPerRevolutionSnapshot,
      doseGrams: data.doseGrams.present ? data.doseGrams.value : this.doseGrams,
      waterGrams: data.waterGrams.present
          ? data.waterGrams.value
          : this.waterGrams,
      ratio: data.ratio.present ? data.ratio.value : this.ratio,
      waterTemp: data.waterTemp.present ? data.waterTemp.value : this.waterTemp,
      totalTimeSeconds: data.totalTimeSeconds.present
          ? data.totalTimeSeconds.value
          : this.totalTimeSeconds,
      dripper: data.dripper.present ? data.dripper.value : this.dripper,
      rating: data.rating.present ? data.rating.value : this.rating,
      flavorTags: data.flavorTags.present
          ? data.flavorTags.value
          : this.flavorTags,
      notes: data.notes.present ? data.notes.value : this.notes,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      brewedAt: data.brewedAt.present ? data.brewedAt.value : this.brewedAt,
      isBest: data.isBest.present ? data.isBest.value : this.isBest,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      tds: data.tds.present ? data.tds.value : this.tds,
      extractionYield: data.extractionYield.present
          ? data.extractionYield.value
          : this.extractionYield,
      waterPpm: data.waterPpm.present ? data.waterPpm.value : this.waterPpm,
      ambientTemp: data.ambientTemp.present
          ? data.ambientTemp.value
          : this.ambientTemp,
      ambientHumidity: data.ambientHumidity.present
          ? data.ambientHumidity.value
          : this.ambientHumidity,
      beanTemp: data.beanTemp.present ? data.beanTemp.value : this.beanTemp,
      pressure: data.pressure.present ? data.pressure.value : this.pressure,
      pourStages: data.pourStages.present
          ? data.pourStages.value
          : this.pourStages,
      beanRoastDate: data.beanRoastDate.present
          ? data.beanRoastDate.value
          : this.beanRoastDate,
      beanRoastLevel: data.beanRoastLevel.present
          ? data.beanRoastLevel.value
          : this.beanRoastLevel,
      heatLevel: data.heatLevel.present ? data.heatLevel.value : this.heatLevel,
      yieldGrams: data.yieldGrams.present
          ? data.yieldGrams.value
          : this.yieldGrams,
      preheatUpperChamber: data.preheatUpperChamber.present
          ? data.preheatUpperChamber.value
          : this.preheatUpperChamber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BrewLogRow(')
          ..write('id: $id, ')
          ..write('beanId: $beanId, ')
          ..write('grinderId: $grinderId, ')
          ..write('recipeId: $recipeId, ')
          ..write('method: $method, ')
          ..write('methodLabel: $methodLabel, ')
          ..write('grindSetting: $grindSetting, ')
          ..write('grindClicks: $grindClicks, ')
          ..write('grinderZeroPointSnapshot: $grinderZeroPointSnapshot, ')
          ..write(
            'grinderClicksPerRevolutionSnapshot: $grinderClicksPerRevolutionSnapshot, ',
          )
          ..write('doseGrams: $doseGrams, ')
          ..write('waterGrams: $waterGrams, ')
          ..write('ratio: $ratio, ')
          ..write('waterTemp: $waterTemp, ')
          ..write('totalTimeSeconds: $totalTimeSeconds, ')
          ..write('dripper: $dripper, ')
          ..write('rating: $rating, ')
          ..write('flavorTags: $flavorTags, ')
          ..write('notes: $notes, ')
          ..write('photoPath: $photoPath, ')
          ..write('brewedAt: $brewedAt, ')
          ..write('isBest: $isBest, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('tds: $tds, ')
          ..write('extractionYield: $extractionYield, ')
          ..write('waterPpm: $waterPpm, ')
          ..write('ambientTemp: $ambientTemp, ')
          ..write('ambientHumidity: $ambientHumidity, ')
          ..write('beanTemp: $beanTemp, ')
          ..write('pressure: $pressure, ')
          ..write('pourStages: $pourStages, ')
          ..write('beanRoastDate: $beanRoastDate, ')
          ..write('beanRoastLevel: $beanRoastLevel, ')
          ..write('heatLevel: $heatLevel, ')
          ..write('yieldGrams: $yieldGrams, ')
          ..write('preheatUpperChamber: $preheatUpperChamber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    beanId,
    grinderId,
    recipeId,
    method,
    methodLabel,
    grindSetting,
    grindClicks,
    grinderZeroPointSnapshot,
    grinderClicksPerRevolutionSnapshot,
    doseGrams,
    waterGrams,
    ratio,
    waterTemp,
    totalTimeSeconds,
    dripper,
    rating,
    flavorTags,
    notes,
    photoPath,
    brewedAt,
    isBest,
    isFavorite,
    tds,
    extractionYield,
    waterPpm,
    ambientTemp,
    ambientHumidity,
    beanTemp,
    pressure,
    pourStages,
    beanRoastDate,
    beanRoastLevel,
    heatLevel,
    yieldGrams,
    preheatUpperChamber,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrewLogRow &&
          other.id == this.id &&
          other.beanId == this.beanId &&
          other.grinderId == this.grinderId &&
          other.recipeId == this.recipeId &&
          other.method == this.method &&
          other.methodLabel == this.methodLabel &&
          other.grindSetting == this.grindSetting &&
          other.grindClicks == this.grindClicks &&
          other.grinderZeroPointSnapshot == this.grinderZeroPointSnapshot &&
          other.grinderClicksPerRevolutionSnapshot ==
              this.grinderClicksPerRevolutionSnapshot &&
          other.doseGrams == this.doseGrams &&
          other.waterGrams == this.waterGrams &&
          other.ratio == this.ratio &&
          other.waterTemp == this.waterTemp &&
          other.totalTimeSeconds == this.totalTimeSeconds &&
          other.dripper == this.dripper &&
          other.rating == this.rating &&
          other.flavorTags == this.flavorTags &&
          other.notes == this.notes &&
          other.photoPath == this.photoPath &&
          other.brewedAt == this.brewedAt &&
          other.isBest == this.isBest &&
          other.isFavorite == this.isFavorite &&
          other.tds == this.tds &&
          other.extractionYield == this.extractionYield &&
          other.waterPpm == this.waterPpm &&
          other.ambientTemp == this.ambientTemp &&
          other.ambientHumidity == this.ambientHumidity &&
          other.beanTemp == this.beanTemp &&
          other.pressure == this.pressure &&
          other.pourStages == this.pourStages &&
          other.beanRoastDate == this.beanRoastDate &&
          other.beanRoastLevel == this.beanRoastLevel &&
          other.heatLevel == this.heatLevel &&
          other.yieldGrams == this.yieldGrams &&
          other.preheatUpperChamber == this.preheatUpperChamber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BrewLogsCompanion extends UpdateCompanion<BrewLogRow> {
  final Value<int> id;
  final Value<int?> beanId;
  final Value<int?> grinderId;
  final Value<int?> recipeId;
  final Value<BrewMethod?> method;
  final Value<String?> methodLabel;
  final Value<double?> grindSetting;
  final Value<int?> grindClicks;
  final Value<double?> grinderZeroPointSnapshot;
  final Value<int?> grinderClicksPerRevolutionSnapshot;
  final Value<double?> doseGrams;
  final Value<double?> waterGrams;
  final Value<double?> ratio;
  final Value<double?> waterTemp;
  final Value<int?> totalTimeSeconds;
  final Value<String?> dripper;
  final Value<int?> rating;
  final Value<List<String>> flavorTags;
  final Value<String?> notes;
  final Value<String?> photoPath;
  final Value<DateTime> brewedAt;
  final Value<bool> isBest;
  final Value<bool> isFavorite;
  final Value<double?> tds;
  final Value<double?> extractionYield;
  final Value<int?> waterPpm;
  final Value<double?> ambientTemp;
  final Value<double?> ambientHumidity;
  final Value<double?> beanTemp;
  final Value<double?> pressure;
  final Value<List<PourStage>?> pourStages;
  final Value<DateTime?> beanRoastDate;
  final Value<RoastLevel?> beanRoastLevel;
  final Value<String?> heatLevel;
  final Value<double?> yieldGrams;
  final Value<bool?> preheatUpperChamber;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BrewLogsCompanion({
    this.id = const Value.absent(),
    this.beanId = const Value.absent(),
    this.grinderId = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.method = const Value.absent(),
    this.methodLabel = const Value.absent(),
    this.grindSetting = const Value.absent(),
    this.grindClicks = const Value.absent(),
    this.grinderZeroPointSnapshot = const Value.absent(),
    this.grinderClicksPerRevolutionSnapshot = const Value.absent(),
    this.doseGrams = const Value.absent(),
    this.waterGrams = const Value.absent(),
    this.ratio = const Value.absent(),
    this.waterTemp = const Value.absent(),
    this.totalTimeSeconds = const Value.absent(),
    this.dripper = const Value.absent(),
    this.rating = const Value.absent(),
    this.flavorTags = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.brewedAt = const Value.absent(),
    this.isBest = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.tds = const Value.absent(),
    this.extractionYield = const Value.absent(),
    this.waterPpm = const Value.absent(),
    this.ambientTemp = const Value.absent(),
    this.ambientHumidity = const Value.absent(),
    this.beanTemp = const Value.absent(),
    this.pressure = const Value.absent(),
    this.pourStages = const Value.absent(),
    this.beanRoastDate = const Value.absent(),
    this.beanRoastLevel = const Value.absent(),
    this.heatLevel = const Value.absent(),
    this.yieldGrams = const Value.absent(),
    this.preheatUpperChamber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BrewLogsCompanion.insert({
    this.id = const Value.absent(),
    this.beanId = const Value.absent(),
    this.grinderId = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.method = const Value.absent(),
    this.methodLabel = const Value.absent(),
    this.grindSetting = const Value.absent(),
    this.grindClicks = const Value.absent(),
    this.grinderZeroPointSnapshot = const Value.absent(),
    this.grinderClicksPerRevolutionSnapshot = const Value.absent(),
    this.doseGrams = const Value.absent(),
    this.waterGrams = const Value.absent(),
    this.ratio = const Value.absent(),
    this.waterTemp = const Value.absent(),
    this.totalTimeSeconds = const Value.absent(),
    this.dripper = const Value.absent(),
    this.rating = const Value.absent(),
    this.flavorTags = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.brewedAt = const Value.absent(),
    this.isBest = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.tds = const Value.absent(),
    this.extractionYield = const Value.absent(),
    this.waterPpm = const Value.absent(),
    this.ambientTemp = const Value.absent(),
    this.ambientHumidity = const Value.absent(),
    this.beanTemp = const Value.absent(),
    this.pressure = const Value.absent(),
    this.pourStages = const Value.absent(),
    this.beanRoastDate = const Value.absent(),
    this.beanRoastLevel = const Value.absent(),
    this.heatLevel = const Value.absent(),
    this.yieldGrams = const Value.absent(),
    this.preheatUpperChamber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<BrewLogRow> custom({
    Expression<int>? id,
    Expression<int>? beanId,
    Expression<int>? grinderId,
    Expression<int>? recipeId,
    Expression<String>? method,
    Expression<String>? methodLabel,
    Expression<double>? grindSetting,
    Expression<int>? grindClicks,
    Expression<double>? grinderZeroPointSnapshot,
    Expression<int>? grinderClicksPerRevolutionSnapshot,
    Expression<double>? doseGrams,
    Expression<double>? waterGrams,
    Expression<double>? ratio,
    Expression<double>? waterTemp,
    Expression<int>? totalTimeSeconds,
    Expression<String>? dripper,
    Expression<int>? rating,
    Expression<String>? flavorTags,
    Expression<String>? notes,
    Expression<String>? photoPath,
    Expression<DateTime>? brewedAt,
    Expression<bool>? isBest,
    Expression<bool>? isFavorite,
    Expression<double>? tds,
    Expression<double>? extractionYield,
    Expression<int>? waterPpm,
    Expression<double>? ambientTemp,
    Expression<double>? ambientHumidity,
    Expression<double>? beanTemp,
    Expression<double>? pressure,
    Expression<String>? pourStages,
    Expression<DateTime>? beanRoastDate,
    Expression<String>? beanRoastLevel,
    Expression<String>? heatLevel,
    Expression<double>? yieldGrams,
    Expression<bool>? preheatUpperChamber,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (beanId != null) 'bean_id': beanId,
      if (grinderId != null) 'grinder_id': grinderId,
      if (recipeId != null) 'recipe_id': recipeId,
      if (method != null) 'method': method,
      if (methodLabel != null) 'method_label': methodLabel,
      if (grindSetting != null) 'grind_setting': grindSetting,
      if (grindClicks != null) 'grind_clicks': grindClicks,
      if (grinderZeroPointSnapshot != null)
        'grinder_zero_point_snapshot': grinderZeroPointSnapshot,
      if (grinderClicksPerRevolutionSnapshot != null)
        'grinder_clicks_per_revolution_snapshot':
            grinderClicksPerRevolutionSnapshot,
      if (doseGrams != null) 'dose_grams': doseGrams,
      if (waterGrams != null) 'water_grams': waterGrams,
      if (ratio != null) 'ratio': ratio,
      if (waterTemp != null) 'water_temp': waterTemp,
      if (totalTimeSeconds != null) 'total_time_seconds': totalTimeSeconds,
      if (dripper != null) 'dripper': dripper,
      if (rating != null) 'rating': rating,
      if (flavorTags != null) 'flavor_tags': flavorTags,
      if (notes != null) 'notes': notes,
      if (photoPath != null) 'photo_path': photoPath,
      if (brewedAt != null) 'brewed_at': brewedAt,
      if (isBest != null) 'is_best': isBest,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (tds != null) 'tds': tds,
      if (extractionYield != null) 'extraction_yield': extractionYield,
      if (waterPpm != null) 'water_ppm': waterPpm,
      if (ambientTemp != null) 'ambient_temp': ambientTemp,
      if (ambientHumidity != null) 'ambient_humidity': ambientHumidity,
      if (beanTemp != null) 'bean_temp': beanTemp,
      if (pressure != null) 'pressure': pressure,
      if (pourStages != null) 'pour_stages': pourStages,
      if (beanRoastDate != null) 'bean_roast_date': beanRoastDate,
      if (beanRoastLevel != null) 'bean_roast_level': beanRoastLevel,
      if (heatLevel != null) 'heat_level': heatLevel,
      if (yieldGrams != null) 'yield_grams': yieldGrams,
      if (preheatUpperChamber != null)
        'preheat_upper_chamber': preheatUpperChamber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BrewLogsCompanion copyWith({
    Value<int>? id,
    Value<int?>? beanId,
    Value<int?>? grinderId,
    Value<int?>? recipeId,
    Value<BrewMethod?>? method,
    Value<String?>? methodLabel,
    Value<double?>? grindSetting,
    Value<int?>? grindClicks,
    Value<double?>? grinderZeroPointSnapshot,
    Value<int?>? grinderClicksPerRevolutionSnapshot,
    Value<double?>? doseGrams,
    Value<double?>? waterGrams,
    Value<double?>? ratio,
    Value<double?>? waterTemp,
    Value<int?>? totalTimeSeconds,
    Value<String?>? dripper,
    Value<int?>? rating,
    Value<List<String>>? flavorTags,
    Value<String?>? notes,
    Value<String?>? photoPath,
    Value<DateTime>? brewedAt,
    Value<bool>? isBest,
    Value<bool>? isFavorite,
    Value<double?>? tds,
    Value<double?>? extractionYield,
    Value<int?>? waterPpm,
    Value<double?>? ambientTemp,
    Value<double?>? ambientHumidity,
    Value<double?>? beanTemp,
    Value<double?>? pressure,
    Value<List<PourStage>?>? pourStages,
    Value<DateTime?>? beanRoastDate,
    Value<RoastLevel?>? beanRoastLevel,
    Value<String?>? heatLevel,
    Value<double?>? yieldGrams,
    Value<bool?>? preheatUpperChamber,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BrewLogsCompanion(
      id: id ?? this.id,
      beanId: beanId ?? this.beanId,
      grinderId: grinderId ?? this.grinderId,
      recipeId: recipeId ?? this.recipeId,
      method: method ?? this.method,
      methodLabel: methodLabel ?? this.methodLabel,
      grindSetting: grindSetting ?? this.grindSetting,
      grindClicks: grindClicks ?? this.grindClicks,
      grinderZeroPointSnapshot:
          grinderZeroPointSnapshot ?? this.grinderZeroPointSnapshot,
      grinderClicksPerRevolutionSnapshot:
          grinderClicksPerRevolutionSnapshot ??
          this.grinderClicksPerRevolutionSnapshot,
      doseGrams: doseGrams ?? this.doseGrams,
      waterGrams: waterGrams ?? this.waterGrams,
      ratio: ratio ?? this.ratio,
      waterTemp: waterTemp ?? this.waterTemp,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      dripper: dripper ?? this.dripper,
      rating: rating ?? this.rating,
      flavorTags: flavorTags ?? this.flavorTags,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      brewedAt: brewedAt ?? this.brewedAt,
      isBest: isBest ?? this.isBest,
      isFavorite: isFavorite ?? this.isFavorite,
      tds: tds ?? this.tds,
      extractionYield: extractionYield ?? this.extractionYield,
      waterPpm: waterPpm ?? this.waterPpm,
      ambientTemp: ambientTemp ?? this.ambientTemp,
      ambientHumidity: ambientHumidity ?? this.ambientHumidity,
      beanTemp: beanTemp ?? this.beanTemp,
      pressure: pressure ?? this.pressure,
      pourStages: pourStages ?? this.pourStages,
      beanRoastDate: beanRoastDate ?? this.beanRoastDate,
      beanRoastLevel: beanRoastLevel ?? this.beanRoastLevel,
      heatLevel: heatLevel ?? this.heatLevel,
      yieldGrams: yieldGrams ?? this.yieldGrams,
      preheatUpperChamber: preheatUpperChamber ?? this.preheatUpperChamber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (beanId.present) {
      map['bean_id'] = Variable<int>(beanId.value);
    }
    if (grinderId.present) {
      map['grinder_id'] = Variable<int>(grinderId.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<int>(recipeId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(
        $BrewLogsTable.$convertermethod.toSql(method.value),
      );
    }
    if (methodLabel.present) {
      map['method_label'] = Variable<String>(methodLabel.value);
    }
    if (grindSetting.present) {
      map['grind_setting'] = Variable<double>(grindSetting.value);
    }
    if (grindClicks.present) {
      map['grind_clicks'] = Variable<int>(grindClicks.value);
    }
    if (grinderZeroPointSnapshot.present) {
      map['grinder_zero_point_snapshot'] = Variable<double>(
        grinderZeroPointSnapshot.value,
      );
    }
    if (grinderClicksPerRevolutionSnapshot.present) {
      map['grinder_clicks_per_revolution_snapshot'] = Variable<int>(
        grinderClicksPerRevolutionSnapshot.value,
      );
    }
    if (doseGrams.present) {
      map['dose_grams'] = Variable<double>(doseGrams.value);
    }
    if (waterGrams.present) {
      map['water_grams'] = Variable<double>(waterGrams.value);
    }
    if (ratio.present) {
      map['ratio'] = Variable<double>(ratio.value);
    }
    if (waterTemp.present) {
      map['water_temp'] = Variable<double>(waterTemp.value);
    }
    if (totalTimeSeconds.present) {
      map['total_time_seconds'] = Variable<int>(totalTimeSeconds.value);
    }
    if (dripper.present) {
      map['dripper'] = Variable<String>(dripper.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (flavorTags.present) {
      map['flavor_tags'] = Variable<String>(
        $BrewLogsTable.$converterflavorTags.toSql(flavorTags.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (brewedAt.present) {
      map['brewed_at'] = Variable<DateTime>(brewedAt.value);
    }
    if (isBest.present) {
      map['is_best'] = Variable<bool>(isBest.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (tds.present) {
      map['tds'] = Variable<double>(tds.value);
    }
    if (extractionYield.present) {
      map['extraction_yield'] = Variable<double>(extractionYield.value);
    }
    if (waterPpm.present) {
      map['water_ppm'] = Variable<int>(waterPpm.value);
    }
    if (ambientTemp.present) {
      map['ambient_temp'] = Variable<double>(ambientTemp.value);
    }
    if (ambientHumidity.present) {
      map['ambient_humidity'] = Variable<double>(ambientHumidity.value);
    }
    if (beanTemp.present) {
      map['bean_temp'] = Variable<double>(beanTemp.value);
    }
    if (pressure.present) {
      map['pressure'] = Variable<double>(pressure.value);
    }
    if (pourStages.present) {
      map['pour_stages'] = Variable<String>(
        $BrewLogsTable.$converterpourStages.toSql(pourStages.value),
      );
    }
    if (beanRoastDate.present) {
      map['bean_roast_date'] = Variable<DateTime>(beanRoastDate.value);
    }
    if (beanRoastLevel.present) {
      map['bean_roast_level'] = Variable<String>(
        $BrewLogsTable.$converterbeanRoastLevel.toSql(beanRoastLevel.value),
      );
    }
    if (heatLevel.present) {
      map['heat_level'] = Variable<String>(heatLevel.value);
    }
    if (yieldGrams.present) {
      map['yield_grams'] = Variable<double>(yieldGrams.value);
    }
    if (preheatUpperChamber.present) {
      map['preheat_upper_chamber'] = Variable<bool>(preheatUpperChamber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrewLogsCompanion(')
          ..write('id: $id, ')
          ..write('beanId: $beanId, ')
          ..write('grinderId: $grinderId, ')
          ..write('recipeId: $recipeId, ')
          ..write('method: $method, ')
          ..write('methodLabel: $methodLabel, ')
          ..write('grindSetting: $grindSetting, ')
          ..write('grindClicks: $grindClicks, ')
          ..write('grinderZeroPointSnapshot: $grinderZeroPointSnapshot, ')
          ..write(
            'grinderClicksPerRevolutionSnapshot: $grinderClicksPerRevolutionSnapshot, ',
          )
          ..write('doseGrams: $doseGrams, ')
          ..write('waterGrams: $waterGrams, ')
          ..write('ratio: $ratio, ')
          ..write('waterTemp: $waterTemp, ')
          ..write('totalTimeSeconds: $totalTimeSeconds, ')
          ..write('dripper: $dripper, ')
          ..write('rating: $rating, ')
          ..write('flavorTags: $flavorTags, ')
          ..write('notes: $notes, ')
          ..write('photoPath: $photoPath, ')
          ..write('brewedAt: $brewedAt, ')
          ..write('isBest: $isBest, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('tds: $tds, ')
          ..write('extractionYield: $extractionYield, ')
          ..write('waterPpm: $waterPpm, ')
          ..write('ambientTemp: $ambientTemp, ')
          ..write('ambientHumidity: $ambientHumidity, ')
          ..write('beanTemp: $beanTemp, ')
          ..write('pressure: $pressure, ')
          ..write('pourStages: $pourStages, ')
          ..write('beanRoastDate: $beanRoastDate, ')
          ..write('beanRoastLevel: $beanRoastLevel, ')
          ..write('heatLevel: $heatLevel, ')
          ..write('yieldGrams: $yieldGrams, ')
          ..write('preheatUpperChamber: $preheatUpperChamber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BrewLogBeansTable extends BrewLogBeans
    with TableInfo<$BrewLogBeansTable, BeanUsageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrewLogBeansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _brewLogIdMeta = const VerificationMeta(
    'brewLogId',
  );
  @override
  late final GeneratedColumn<int> brewLogId = GeneratedColumn<int>(
    'brew_log_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES brew_logs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _beanIdMeta = const VerificationMeta('beanId');
  @override
  late final GeneratedColumn<int> beanId = GeneratedColumn<int>(
    'bean_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES coffee_beans (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<int> batchId = GeneratedColumn<int>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bean_batches (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _beanNameSnapshotMeta = const VerificationMeta(
    'beanNameSnapshot',
  );
  @override
  late final GeneratedColumn<String> beanNameSnapshot = GeneratedColumn<String>(
    'bean_name_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roastDateSnapshotMeta = const VerificationMeta(
    'roastDateSnapshot',
  );
  @override
  late final GeneratedColumn<DateTime> roastDateSnapshot =
      GeneratedColumn<DateTime>(
        'roast_date_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _doseGramsMeta = const VerificationMeta(
    'doseGrams',
  );
  @override
  late final GeneratedColumn<double> doseGrams = GeneratedColumn<double>(
    'dose_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brewLogId,
    beanId,
    batchId,
    beanNameSnapshot,
    roastDateSnapshot,
    doseGrams,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brew_log_beans';
  @override
  VerificationContext validateIntegrity(
    Insertable<BeanUsageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('brew_log_id')) {
      context.handle(
        _brewLogIdMeta,
        brewLogId.isAcceptableOrUnknown(data['brew_log_id']!, _brewLogIdMeta),
      );
    } else if (isInserting) {
      context.missing(_brewLogIdMeta);
    }
    if (data.containsKey('bean_id')) {
      context.handle(
        _beanIdMeta,
        beanId.isAcceptableOrUnknown(data['bean_id']!, _beanIdMeta),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    if (data.containsKey('bean_name_snapshot')) {
      context.handle(
        _beanNameSnapshotMeta,
        beanNameSnapshot.isAcceptableOrUnknown(
          data['bean_name_snapshot']!,
          _beanNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('roast_date_snapshot')) {
      context.handle(
        _roastDateSnapshotMeta,
        roastDateSnapshot.isAcceptableOrUnknown(
          data['roast_date_snapshot']!,
          _roastDateSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('dose_grams')) {
      context.handle(
        _doseGramsMeta,
        doseGrams.isAcceptableOrUnknown(data['dose_grams']!, _doseGramsMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BeanUsageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BeanUsageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      brewLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}brew_log_id'],
      )!,
      beanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bean_id'],
      ),
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batch_id'],
      ),
      beanNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bean_name_snapshot'],
      ),
      roastDateSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}roast_date_snapshot'],
      ),
      doseGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dose_grams'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $BrewLogBeansTable createAlias(String alias) {
    return $BrewLogBeansTable(attachedDatabase, alias);
  }
}

class BeanUsageRow extends DataClass implements Insertable<BeanUsageRow> {
  final int id;
  final int brewLogId;

  /// 豆子被删除时置空——用量行本身要保留。
  final int? beanId;

  /// 消费的批次。批次被删时置空，历史记录仍保留。
  final int? batchId;

  /// 当时的豆子名快照：豆子被删或改名后，记录仍能显示用的什么豆。
  final String? beanNameSnapshot;

  /// 当时的烘焙日期快照。
  final DateTime? roastDateSnapshot;

  /// 这一支豆子用了多少克。
  final double doseGrams;

  /// 顺序，0 是主豆。
  final int position;
  const BeanUsageRow({
    required this.id,
    required this.brewLogId,
    this.beanId,
    this.batchId,
    this.beanNameSnapshot,
    this.roastDateSnapshot,
    required this.doseGrams,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['brew_log_id'] = Variable<int>(brewLogId);
    if (!nullToAbsent || beanId != null) {
      map['bean_id'] = Variable<int>(beanId);
    }
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<int>(batchId);
    }
    if (!nullToAbsent || beanNameSnapshot != null) {
      map['bean_name_snapshot'] = Variable<String>(beanNameSnapshot);
    }
    if (!nullToAbsent || roastDateSnapshot != null) {
      map['roast_date_snapshot'] = Variable<DateTime>(roastDateSnapshot);
    }
    map['dose_grams'] = Variable<double>(doseGrams);
    map['position'] = Variable<int>(position);
    return map;
  }

  BrewLogBeansCompanion toCompanion(bool nullToAbsent) {
    return BrewLogBeansCompanion(
      id: Value(id),
      brewLogId: Value(brewLogId),
      beanId: beanId == null && nullToAbsent
          ? const Value.absent()
          : Value(beanId),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      beanNameSnapshot: beanNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(beanNameSnapshot),
      roastDateSnapshot: roastDateSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(roastDateSnapshot),
      doseGrams: Value(doseGrams),
      position: Value(position),
    );
  }

  factory BeanUsageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BeanUsageRow(
      id: serializer.fromJson<int>(json['id']),
      brewLogId: serializer.fromJson<int>(json['brewLogId']),
      beanId: serializer.fromJson<int?>(json['beanId']),
      batchId: serializer.fromJson<int?>(json['batchId']),
      beanNameSnapshot: serializer.fromJson<String?>(json['beanNameSnapshot']),
      roastDateSnapshot: serializer.fromJson<DateTime?>(
        json['roastDateSnapshot'],
      ),
      doseGrams: serializer.fromJson<double>(json['doseGrams']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'brewLogId': serializer.toJson<int>(brewLogId),
      'beanId': serializer.toJson<int?>(beanId),
      'batchId': serializer.toJson<int?>(batchId),
      'beanNameSnapshot': serializer.toJson<String?>(beanNameSnapshot),
      'roastDateSnapshot': serializer.toJson<DateTime?>(roastDateSnapshot),
      'doseGrams': serializer.toJson<double>(doseGrams),
      'position': serializer.toJson<int>(position),
    };
  }

  BeanUsageRow copyWith({
    int? id,
    int? brewLogId,
    Value<int?> beanId = const Value.absent(),
    Value<int?> batchId = const Value.absent(),
    Value<String?> beanNameSnapshot = const Value.absent(),
    Value<DateTime?> roastDateSnapshot = const Value.absent(),
    double? doseGrams,
    int? position,
  }) => BeanUsageRow(
    id: id ?? this.id,
    brewLogId: brewLogId ?? this.brewLogId,
    beanId: beanId.present ? beanId.value : this.beanId,
    batchId: batchId.present ? batchId.value : this.batchId,
    beanNameSnapshot: beanNameSnapshot.present
        ? beanNameSnapshot.value
        : this.beanNameSnapshot,
    roastDateSnapshot: roastDateSnapshot.present
        ? roastDateSnapshot.value
        : this.roastDateSnapshot,
    doseGrams: doseGrams ?? this.doseGrams,
    position: position ?? this.position,
  );
  BeanUsageRow copyWithCompanion(BrewLogBeansCompanion data) {
    return BeanUsageRow(
      id: data.id.present ? data.id.value : this.id,
      brewLogId: data.brewLogId.present ? data.brewLogId.value : this.brewLogId,
      beanId: data.beanId.present ? data.beanId.value : this.beanId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      beanNameSnapshot: data.beanNameSnapshot.present
          ? data.beanNameSnapshot.value
          : this.beanNameSnapshot,
      roastDateSnapshot: data.roastDateSnapshot.present
          ? data.roastDateSnapshot.value
          : this.roastDateSnapshot,
      doseGrams: data.doseGrams.present ? data.doseGrams.value : this.doseGrams,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BeanUsageRow(')
          ..write('id: $id, ')
          ..write('brewLogId: $brewLogId, ')
          ..write('beanId: $beanId, ')
          ..write('batchId: $batchId, ')
          ..write('beanNameSnapshot: $beanNameSnapshot, ')
          ..write('roastDateSnapshot: $roastDateSnapshot, ')
          ..write('doseGrams: $doseGrams, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    brewLogId,
    beanId,
    batchId,
    beanNameSnapshot,
    roastDateSnapshot,
    doseGrams,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BeanUsageRow &&
          other.id == this.id &&
          other.brewLogId == this.brewLogId &&
          other.beanId == this.beanId &&
          other.batchId == this.batchId &&
          other.beanNameSnapshot == this.beanNameSnapshot &&
          other.roastDateSnapshot == this.roastDateSnapshot &&
          other.doseGrams == this.doseGrams &&
          other.position == this.position);
}

class BrewLogBeansCompanion extends UpdateCompanion<BeanUsageRow> {
  final Value<int> id;
  final Value<int> brewLogId;
  final Value<int?> beanId;
  final Value<int?> batchId;
  final Value<String?> beanNameSnapshot;
  final Value<DateTime?> roastDateSnapshot;
  final Value<double> doseGrams;
  final Value<int> position;
  const BrewLogBeansCompanion({
    this.id = const Value.absent(),
    this.brewLogId = const Value.absent(),
    this.beanId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.beanNameSnapshot = const Value.absent(),
    this.roastDateSnapshot = const Value.absent(),
    this.doseGrams = const Value.absent(),
    this.position = const Value.absent(),
  });
  BrewLogBeansCompanion.insert({
    this.id = const Value.absent(),
    required int brewLogId,
    this.beanId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.beanNameSnapshot = const Value.absent(),
    this.roastDateSnapshot = const Value.absent(),
    this.doseGrams = const Value.absent(),
    this.position = const Value.absent(),
  }) : brewLogId = Value(brewLogId);
  static Insertable<BeanUsageRow> custom({
    Expression<int>? id,
    Expression<int>? brewLogId,
    Expression<int>? beanId,
    Expression<int>? batchId,
    Expression<String>? beanNameSnapshot,
    Expression<DateTime>? roastDateSnapshot,
    Expression<double>? doseGrams,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brewLogId != null) 'brew_log_id': brewLogId,
      if (beanId != null) 'bean_id': beanId,
      if (batchId != null) 'batch_id': batchId,
      if (beanNameSnapshot != null) 'bean_name_snapshot': beanNameSnapshot,
      if (roastDateSnapshot != null) 'roast_date_snapshot': roastDateSnapshot,
      if (doseGrams != null) 'dose_grams': doseGrams,
      if (position != null) 'position': position,
    });
  }

  BrewLogBeansCompanion copyWith({
    Value<int>? id,
    Value<int>? brewLogId,
    Value<int?>? beanId,
    Value<int?>? batchId,
    Value<String?>? beanNameSnapshot,
    Value<DateTime?>? roastDateSnapshot,
    Value<double>? doseGrams,
    Value<int>? position,
  }) {
    return BrewLogBeansCompanion(
      id: id ?? this.id,
      brewLogId: brewLogId ?? this.brewLogId,
      beanId: beanId ?? this.beanId,
      batchId: batchId ?? this.batchId,
      beanNameSnapshot: beanNameSnapshot ?? this.beanNameSnapshot,
      roastDateSnapshot: roastDateSnapshot ?? this.roastDateSnapshot,
      doseGrams: doseGrams ?? this.doseGrams,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (brewLogId.present) {
      map['brew_log_id'] = Variable<int>(brewLogId.value);
    }
    if (beanId.present) {
      map['bean_id'] = Variable<int>(beanId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<int>(batchId.value);
    }
    if (beanNameSnapshot.present) {
      map['bean_name_snapshot'] = Variable<String>(beanNameSnapshot.value);
    }
    if (roastDateSnapshot.present) {
      map['roast_date_snapshot'] = Variable<DateTime>(roastDateSnapshot.value);
    }
    if (doseGrams.present) {
      map['dose_grams'] = Variable<double>(doseGrams.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrewLogBeansCompanion(')
          ..write('id: $id, ')
          ..write('brewLogId: $brewLogId, ')
          ..write('beanId: $beanId, ')
          ..write('batchId: $batchId, ')
          ..write('beanNameSnapshot: $beanNameSnapshot, ')
          ..write('roastDateSnapshot: $roastDateSnapshot, ')
          ..write('doseGrams: $doseGrams, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $BrewLogAddinsTable extends BrewLogAddins
    with TableInfo<$BrewLogAddinsTable, BrewLogAddInRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrewLogAddinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _brewLogIdMeta = const VerificationMeta(
    'brewLogId',
  );
  @override
  late final GeneratedColumn<int> brewLogId = GeneratedColumn<int>(
    'brew_log_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES brew_logs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AddInUnit?, String> unit =
      GeneratedColumn<String>(
        'unit',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('ml'),
      ).withConverter<AddInUnit?>($BrewLogAddinsTable.$converterunit);
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brewLogId,
    name,
    brand,
    amount,
    unit,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brew_log_addins';
  @override
  VerificationContext validateIntegrity(
    Insertable<BrewLogAddInRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('brew_log_id')) {
      context.handle(
        _brewLogIdMeta,
        brewLogId.isAcceptableOrUnknown(data['brew_log_id']!, _brewLogIdMeta),
      );
    } else if (isInserting) {
      context.missing(_brewLogIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BrewLogAddInRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrewLogAddInRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      brewLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}brew_log_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      ),
      unit: $BrewLogAddinsTable.$converterunit.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}unit'],
        )!,
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $BrewLogAddinsTable createAlias(String alias) {
    return $BrewLogAddinsTable(attachedDatabase, alias);
  }

  static TypeConverter<AddInUnit?, String?> $converterunit =
      const TolerantEnumConverter<AddInUnit>(
        AddInUnit.values,
        fallback: AddInUnit.ml,
      );
}

class BrewLogAddInRow extends DataClass implements Insertable<BrewLogAddInRow> {
  final int id;
  final int brewLogId;

  /// 辅料名快照，如「牛奶」。
  final String name;

  /// 牌子（v8 新增，T37）：如「Oatly」。可空 = 没记牌子。
  ///
  /// `withLength` 只是 **Dart 侧**校验，不生成 SQL `CHECK`（用 v7 快照的
  /// `customConstraints: null` 对照布尔列的 `CHECK` 可证），
  /// 所以给既有表 `addColumn` 一个带长度约束的可空列对旧行完全安全。
  /// ⚠️ 但 `min: 1` 意味着空串 `''` 不合法 → 写入路径要把 `''` 归一成 `null`。
  final String? brand;

  /// 数量；可空 = 只记「加了什么」没量。
  final double? amount;

  /// 单位，存枚举 name（`ml` / `gram` / `pump` / `serving`）。
  final AddInUnit? unit;

  /// 顺序。
  final int position;
  const BrewLogAddInRow({
    required this.id,
    required this.brewLogId,
    required this.name,
    this.brand,
    this.amount,
    this.unit,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['brew_log_id'] = Variable<int>(brewLogId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(
        $BrewLogAddinsTable.$converterunit.toSql(unit),
      );
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  BrewLogAddinsCompanion toCompanion(bool nullToAbsent) {
    return BrewLogAddinsCompanion(
      id: Value(id),
      brewLogId: Value(brewLogId),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      position: Value(position),
    );
  }

  factory BrewLogAddInRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrewLogAddInRow(
      id: serializer.fromJson<int>(json['id']),
      brewLogId: serializer.fromJson<int>(json['brewLogId']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      amount: serializer.fromJson<double?>(json['amount']),
      unit: serializer.fromJson<AddInUnit?>(json['unit']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'brewLogId': serializer.toJson<int>(brewLogId),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'amount': serializer.toJson<double?>(amount),
      'unit': serializer.toJson<AddInUnit?>(unit),
      'position': serializer.toJson<int>(position),
    };
  }

  BrewLogAddInRow copyWith({
    int? id,
    int? brewLogId,
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<double?> amount = const Value.absent(),
    Value<AddInUnit?> unit = const Value.absent(),
    int? position,
  }) => BrewLogAddInRow(
    id: id ?? this.id,
    brewLogId: brewLogId ?? this.brewLogId,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    amount: amount.present ? amount.value : this.amount,
    unit: unit.present ? unit.value : this.unit,
    position: position ?? this.position,
  );
  BrewLogAddInRow copyWithCompanion(BrewLogAddinsCompanion data) {
    return BrewLogAddInRow(
      id: data.id.present ? data.id.value : this.id,
      brewLogId: data.brewLogId.present ? data.brewLogId.value : this.brewLogId,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BrewLogAddInRow(')
          ..write('id: $id, ')
          ..write('brewLogId: $brewLogId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, brewLogId, name, brand, amount, unit, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrewLogAddInRow &&
          other.id == this.id &&
          other.brewLogId == this.brewLogId &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.position == this.position);
}

class BrewLogAddinsCompanion extends UpdateCompanion<BrewLogAddInRow> {
  final Value<int> id;
  final Value<int> brewLogId;
  final Value<String> name;
  final Value<String?> brand;
  final Value<double?> amount;
  final Value<AddInUnit?> unit;
  final Value<int> position;
  const BrewLogAddinsCompanion({
    this.id = const Value.absent(),
    this.brewLogId = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.position = const Value.absent(),
  });
  BrewLogAddinsCompanion.insert({
    this.id = const Value.absent(),
    required int brewLogId,
    required String name,
    this.brand = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.position = const Value.absent(),
  }) : brewLogId = Value(brewLogId),
       name = Value(name);
  static Insertable<BrewLogAddInRow> custom({
    Expression<int>? id,
    Expression<int>? brewLogId,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brewLogId != null) 'brew_log_id': brewLogId,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (position != null) 'position': position,
    });
  }

  BrewLogAddinsCompanion copyWith({
    Value<int>? id,
    Value<int>? brewLogId,
    Value<String>? name,
    Value<String?>? brand,
    Value<double?>? amount,
    Value<AddInUnit?>? unit,
    Value<int>? position,
  }) {
    return BrewLogAddinsCompanion(
      id: id ?? this.id,
      brewLogId: brewLogId ?? this.brewLogId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (brewLogId.present) {
      map['brew_log_id'] = Variable<int>(brewLogId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(
        $BrewLogAddinsTable.$converterunit.toSql(unit.value),
      );
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrewLogAddinsCompanion(')
          ..write('id: $id, ')
          ..write('brewLogId: $brewLogId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $FavoriteGroupsTable extends FavoriteGroups
    with TableInfo<$FavoriteGroupsTable, FavoriteGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoriteGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoriteGroupsTable createAlias(String alias) {
    return $FavoriteGroupsTable(attachedDatabase, alias);
  }
}

class FavoriteGroupRow extends DataClass
    implements Insertable<FavoriteGroupRow> {
  final int id;

  /// 用户起的组名，如「早餐配方」。与 [BrewLogAddins.name] 同量级。
  final String name;

  /// 展示顺序，越小越靠前。
  final int sortOrder;
  final DateTime createdAt;
  const FavoriteGroupRow({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoriteGroupsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteGroupsCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteGroupRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoriteGroupRow copyWith({
    int? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) => FavoriteGroupRow(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  FavoriteGroupRow copyWithCompanion(FavoriteGroupsCompanion data) {
    return FavoriteGroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteGroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteGroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class FavoriteGroupsCompanion extends UpdateCompanion<FavoriteGroupRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const FavoriteGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoriteGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FavoriteGroupRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoriteGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return FavoriteGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BrewLogFavoriteGroupsTable extends BrewLogFavoriteGroups
    with TableInfo<$BrewLogFavoriteGroupsTable, BrewLogFavoriteGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrewLogFavoriteGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _brewLogIdMeta = const VerificationMeta(
    'brewLogId',
  );
  @override
  late final GeneratedColumn<int> brewLogId = GeneratedColumn<int>(
    'brew_log_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES brew_logs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES favorite_groups (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, brewLogId, groupId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brew_log_favorite_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<BrewLogFavoriteGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('brew_log_id')) {
      context.handle(
        _brewLogIdMeta,
        brewLogId.isAcceptableOrUnknown(data['brew_log_id']!, _brewLogIdMeta),
      );
    } else if (isInserting) {
      context.missing(_brewLogIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BrewLogFavoriteGroupRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrewLogFavoriteGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      brewLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}brew_log_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BrewLogFavoriteGroupsTable createAlias(String alias) {
    return $BrewLogFavoriteGroupsTable(attachedDatabase, alias);
  }
}

class BrewLogFavoriteGroupRow extends DataClass
    implements Insertable<BrewLogFavoriteGroupRow> {
  final int id;
  final int brewLogId;
  final int groupId;
  final DateTime createdAt;
  const BrewLogFavoriteGroupRow({
    required this.id,
    required this.brewLogId,
    required this.groupId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['brew_log_id'] = Variable<int>(brewLogId);
    map['group_id'] = Variable<int>(groupId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BrewLogFavoriteGroupsCompanion toCompanion(bool nullToAbsent) {
    return BrewLogFavoriteGroupsCompanion(
      id: Value(id),
      brewLogId: Value(brewLogId),
      groupId: Value(groupId),
      createdAt: Value(createdAt),
    );
  }

  factory BrewLogFavoriteGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrewLogFavoriteGroupRow(
      id: serializer.fromJson<int>(json['id']),
      brewLogId: serializer.fromJson<int>(json['brewLogId']),
      groupId: serializer.fromJson<int>(json['groupId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'brewLogId': serializer.toJson<int>(brewLogId),
      'groupId': serializer.toJson<int>(groupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BrewLogFavoriteGroupRow copyWith({
    int? id,
    int? brewLogId,
    int? groupId,
    DateTime? createdAt,
  }) => BrewLogFavoriteGroupRow(
    id: id ?? this.id,
    brewLogId: brewLogId ?? this.brewLogId,
    groupId: groupId ?? this.groupId,
    createdAt: createdAt ?? this.createdAt,
  );
  BrewLogFavoriteGroupRow copyWithCompanion(
    BrewLogFavoriteGroupsCompanion data,
  ) {
    return BrewLogFavoriteGroupRow(
      id: data.id.present ? data.id.value : this.id,
      brewLogId: data.brewLogId.present ? data.brewLogId.value : this.brewLogId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BrewLogFavoriteGroupRow(')
          ..write('id: $id, ')
          ..write('brewLogId: $brewLogId, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, brewLogId, groupId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrewLogFavoriteGroupRow &&
          other.id == this.id &&
          other.brewLogId == this.brewLogId &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt);
}

class BrewLogFavoriteGroupsCompanion
    extends UpdateCompanion<BrewLogFavoriteGroupRow> {
  final Value<int> id;
  final Value<int> brewLogId;
  final Value<int> groupId;
  final Value<DateTime> createdAt;
  const BrewLogFavoriteGroupsCompanion({
    this.id = const Value.absent(),
    this.brewLogId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BrewLogFavoriteGroupsCompanion.insert({
    this.id = const Value.absent(),
    required int brewLogId,
    required int groupId,
    this.createdAt = const Value.absent(),
  }) : brewLogId = Value(brewLogId),
       groupId = Value(groupId);
  static Insertable<BrewLogFavoriteGroupRow> custom({
    Expression<int>? id,
    Expression<int>? brewLogId,
    Expression<int>? groupId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brewLogId != null) 'brew_log_id': brewLogId,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BrewLogFavoriteGroupsCompanion copyWith({
    Value<int>? id,
    Value<int>? brewLogId,
    Value<int>? groupId,
    Value<DateTime>? createdAt,
  }) {
    return BrewLogFavoriteGroupsCompanion(
      id: id ?? this.id,
      brewLogId: brewLogId ?? this.brewLogId,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (brewLogId.present) {
      map['brew_log_id'] = Variable<int>(brewLogId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrewLogFavoriteGroupsCompanion(')
          ..write('id: $id, ')
          ..write('brewLogId: $brewLogId, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSettingRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingRow copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExtraAttributesTable extends ExtraAttributes
    with TableInfo<$ExtraAttributesTable, ExtraAttributeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtraAttributesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerTypeMeta = const VerificationMeta(
    'ownerType',
  );
  @override
  late final GeneratedColumn<String> ownerType = GeneratedColumn<String>(
    'owner_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<int> ownerId = GeneratedColumn<int>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Object?, String> value =
      GeneratedColumn<String>(
        'value',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Object?>($ExtraAttributesTable.$convertervalue);
  static const VerificationMeta _valueTypeMeta = const VerificationMeta(
    'valueType',
  );
  @override
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
    'value_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBuiltinMeta = const VerificationMeta(
    'isBuiltin',
  );
  @override
  late final GeneratedColumn<bool> isBuiltin = GeneratedColumn<bool>(
    'is_builtin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_builtin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerType,
    ownerId,
    key,
    value,
    valueType,
    label,
    isBuiltin,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extra_attributes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtraAttributeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_type')) {
      context.handle(
        _ownerTypeMeta,
        ownerType.isAcceptableOrUnknown(data['owner_type']!, _ownerTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerTypeMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_type')) {
      context.handle(
        _valueTypeMeta,
        valueType.isAcceptableOrUnknown(data['value_type']!, _valueTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_valueTypeMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('is_builtin')) {
      context.handle(
        _isBuiltinMeta,
        isBuiltin.isAcceptableOrUnknown(data['is_builtin']!, _isBuiltinMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerType, ownerId, key};
  @override
  ExtraAttributeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtraAttributeRow(
      ownerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_type'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}owner_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: $ExtraAttributesTable.$convertervalue.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}value'],
        ),
      ),
      valueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_type'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      isBuiltin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_builtin'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExtraAttributesTable createAlias(String alias) {
    return $ExtraAttributesTable(attachedDatabase, alias);
  }

  static TypeConverter<Object?, String?> $convertervalue =
      const JsonValueConverter();
}

class ExtraAttributeRow extends DataClass
    implements Insertable<ExtraAttributeRow> {
  /// 归属对象的类型：`bean` / `grinder`（见 `ExtraOwnerType`）。
  final String ownerType;

  /// 归属对象的 id。
  final int ownerId;

  /// 属性名（稳定标识，不随界面文案变化）。
  final String key;

  /// 属性值，JSON 编码。
  final Object? value;

  /// 值类型名（`ExtraValueType`），便于 UI 决定控件与展示。
  final String valueType;

  /// 展示名。留空时 UI 直接用 [key]。
  final String? label;

  /// 是否是 App 内置属性（内置的不可删除）。
  final bool isBuiltin;

  /// 展示顺序。
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExtraAttributeRow({
    required this.ownerType,
    required this.ownerId,
    required this.key,
    this.value,
    required this.valueType,
    this.label,
    required this.isBuiltin,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_type'] = Variable<String>(ownerType);
    map['owner_id'] = Variable<int>(ownerId);
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(
        $ExtraAttributesTable.$convertervalue.toSql(value),
      );
    }
    map['value_type'] = Variable<String>(valueType);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['is_builtin'] = Variable<bool>(isBuiltin);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExtraAttributesCompanion toCompanion(bool nullToAbsent) {
    return ExtraAttributesCompanion(
      ownerType: Value(ownerType),
      ownerId: Value(ownerId),
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      valueType: Value(valueType),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      isBuiltin: Value(isBuiltin),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExtraAttributeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtraAttributeRow(
      ownerType: serializer.fromJson<String>(json['ownerType']),
      ownerId: serializer.fromJson<int>(json['ownerId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<Object?>(json['value']),
      valueType: serializer.fromJson<String>(json['valueType']),
      label: serializer.fromJson<String?>(json['label']),
      isBuiltin: serializer.fromJson<bool>(json['isBuiltin']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerType': serializer.toJson<String>(ownerType),
      'ownerId': serializer.toJson<int>(ownerId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<Object?>(value),
      'valueType': serializer.toJson<String>(valueType),
      'label': serializer.toJson<String?>(label),
      'isBuiltin': serializer.toJson<bool>(isBuiltin),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExtraAttributeRow copyWith({
    String? ownerType,
    int? ownerId,
    String? key,
    Value<Object?> value = const Value.absent(),
    String? valueType,
    Value<String?> label = const Value.absent(),
    bool? isBuiltin,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExtraAttributeRow(
    ownerType: ownerType ?? this.ownerType,
    ownerId: ownerId ?? this.ownerId,
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
    valueType: valueType ?? this.valueType,
    label: label.present ? label.value : this.label,
    isBuiltin: isBuiltin ?? this.isBuiltin,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExtraAttributeRow copyWithCompanion(ExtraAttributesCompanion data) {
    return ExtraAttributeRow(
      ownerType: data.ownerType.present ? data.ownerType.value : this.ownerType,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      label: data.label.present ? data.label.value : this.label,
      isBuiltin: data.isBuiltin.present ? data.isBuiltin.value : this.isBuiltin,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtraAttributeRow(')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('valueType: $valueType, ')
          ..write('label: $label, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerType,
    ownerId,
    key,
    value,
    valueType,
    label,
    isBuiltin,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtraAttributeRow &&
          other.ownerType == this.ownerType &&
          other.ownerId == this.ownerId &&
          other.key == this.key &&
          other.value == this.value &&
          other.valueType == this.valueType &&
          other.label == this.label &&
          other.isBuiltin == this.isBuiltin &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExtraAttributesCompanion extends UpdateCompanion<ExtraAttributeRow> {
  final Value<String> ownerType;
  final Value<int> ownerId;
  final Value<String> key;
  final Value<Object?> value;
  final Value<String> valueType;
  final Value<String?> label;
  final Value<bool> isBuiltin;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExtraAttributesCompanion({
    this.ownerType = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.valueType = const Value.absent(),
    this.label = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExtraAttributesCompanion.insert({
    required String ownerType,
    required int ownerId,
    required String key,
    this.value = const Value.absent(),
    required String valueType,
    this.label = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerType = Value(ownerType),
       ownerId = Value(ownerId),
       key = Value(key),
       valueType = Value(valueType);
  static Insertable<ExtraAttributeRow> custom({
    Expression<String>? ownerType,
    Expression<int>? ownerId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? valueType,
    Expression<String>? label,
    Expression<bool>? isBuiltin,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerType != null) 'owner_type': ownerType,
      if (ownerId != null) 'owner_id': ownerId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (valueType != null) 'value_type': valueType,
      if (label != null) 'label': label,
      if (isBuiltin != null) 'is_builtin': isBuiltin,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExtraAttributesCompanion copyWith({
    Value<String>? ownerType,
    Value<int>? ownerId,
    Value<String>? key,
    Value<Object?>? value,
    Value<String>? valueType,
    Value<String?>? label,
    Value<bool>? isBuiltin,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ExtraAttributesCompanion(
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
      key: key ?? this.key,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
      label: label ?? this.label,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerType.present) {
      map['owner_type'] = Variable<String>(ownerType.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<int>(ownerId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(
        $ExtraAttributesTable.$convertervalue.toSql(value.value),
      );
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(valueType.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (isBuiltin.present) {
      map['is_builtin'] = Variable<bool>(isBuiltin.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtraAttributesCompanion(')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('valueType: $valueType, ')
          ..write('label: $label, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CoffeeBeansTable coffeeBeans = $CoffeeBeansTable(this);
  late final $BeanBatchesTable beanBatches = $BeanBatchesTable(this);
  late final $GrindersTable grinders = $GrindersTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $BrewLogsTable brewLogs = $BrewLogsTable(this);
  late final $BrewLogBeansTable brewLogBeans = $BrewLogBeansTable(this);
  late final $BrewLogAddinsTable brewLogAddins = $BrewLogAddinsTable(this);
  late final $FavoriteGroupsTable favoriteGroups = $FavoriteGroupsTable(this);
  late final $BrewLogFavoriteGroupsTable brewLogFavoriteGroups =
      $BrewLogFavoriteGroupsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $ExtraAttributesTable extraAttributes = $ExtraAttributesTable(
    this,
  );
  late final Index idxBeanBatchesBeanId = Index(
    'idx_bean_batches_bean_id',
    'CREATE INDEX idx_bean_batches_bean_id ON bean_batches (bean_id)',
  );
  late final Index idxBrewLogsBrewedAt = Index(
    'idx_brew_logs_brewed_at',
    'CREATE INDEX idx_brew_logs_brewed_at ON brew_logs (brewed_at)',
  );
  late final Index idxBrewLogBeansBrewLogId = Index(
    'idx_brew_log_beans_brew_log_id',
    'CREATE INDEX idx_brew_log_beans_brew_log_id ON brew_log_beans (brew_log_id)',
  );
  late final Index idxBrewLogBeansBeanId = Index(
    'idx_brew_log_beans_bean_id',
    'CREATE INDEX idx_brew_log_beans_bean_id ON brew_log_beans (bean_id)',
  );
  late final Index idxBrewLogAddinsBrewLogId = Index(
    'idx_brew_log_addins_brew_log_id',
    'CREATE INDEX idx_brew_log_addins_brew_log_id ON brew_log_addins (brew_log_id)',
  );
  late final Index idxBrewLogFavoriteGroupsBrewLogId = Index(
    'idx_brew_log_favorite_groups_brew_log_id',
    'CREATE INDEX idx_brew_log_favorite_groups_brew_log_id ON brew_log_favorite_groups (brew_log_id)',
  );
  late final Index idxBrewLogFavoriteGroupsGroupId = Index(
    'idx_brew_log_favorite_groups_group_id',
    'CREATE INDEX idx_brew_log_favorite_groups_group_id ON brew_log_favorite_groups (group_id)',
  );
  late final Index idxBrewLogFavoriteGroupsUnique = Index(
    'idx_brew_log_favorite_groups_unique',
    'CREATE UNIQUE INDEX idx_brew_log_favorite_groups_unique ON brew_log_favorite_groups (brew_log_id, group_id)',
  );
  late final Index idxExtraOwner = Index(
    'idx_extra_owner',
    'CREATE INDEX idx_extra_owner ON extra_attributes (owner_type, owner_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    coffeeBeans,
    beanBatches,
    grinders,
    recipes,
    brewLogs,
    brewLogBeans,
    brewLogAddins,
    favoriteGroups,
    brewLogFavoriteGroups,
    appSettings,
    extraAttributes,
    idxBeanBatchesBeanId,
    idxBrewLogsBrewedAt,
    idxBrewLogBeansBrewLogId,
    idxBrewLogBeansBeanId,
    idxBrewLogAddinsBrewLogId,
    idxBrewLogFavoriteGroupsBrewLogId,
    idxBrewLogFavoriteGroupsGroupId,
    idxBrewLogFavoriteGroupsUnique,
    idxExtraOwner,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'coffee_beans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bean_batches', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'coffee_beans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('brew_logs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'grinders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('brew_logs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('brew_logs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'brew_logs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('brew_log_beans', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'coffee_beans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('brew_log_beans', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bean_batches',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('brew_log_beans', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'brew_logs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('brew_log_addins', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'brew_logs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('brew_log_favorite_groups', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'favorite_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('brew_log_favorite_groups', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$CoffeeBeansTableCreateCompanionBuilder =
    CoffeeBeansCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> origin,
      Value<String?> farm,
      Value<List<ProcessMethod>> process,
      Value<List<String>> flavorTags,
      Value<bool> isFavorite,
      Value<String?> photoPath,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CoffeeBeansTableUpdateCompanionBuilder =
    CoffeeBeansCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> origin,
      Value<String?> farm,
      Value<List<ProcessMethod>> process,
      Value<List<String>> flavorTags,
      Value<bool> isFavorite,
      Value<String?> photoPath,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$CoffeeBeansTableReferences
    extends BaseReferences<_$AppDatabase, $CoffeeBeansTable, CoffeeBeanRow> {
  $$CoffeeBeansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BeanBatchesTable, List<BeanBatchRow>>
  _beanBatchesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.beanBatches,
    aliasName: 'coffee_beans__id__bean_batches__bean_id',
  );

  $$BeanBatchesTableProcessedTableManager get beanBatchesRefs {
    final manager = $$BeanBatchesTableTableManager(
      $_db,
      $_db.beanBatches,
    ).filter((f) => f.beanId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_beanBatchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BrewLogsTable, List<BrewLogRow>>
  _brewLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.brewLogs,
    aliasName: 'coffee_beans__id__brew_logs__bean_id',
  );

  $$BrewLogsTableProcessedTableManager get brewLogsRefs {
    final manager = $$BrewLogsTableTableManager(
      $_db,
      $_db.brewLogs,
    ).filter((f) => f.beanId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_brewLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BrewLogBeansTable, List<BeanUsageRow>>
  _brewLogBeansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.brewLogBeans,
    aliasName: 'coffee_beans__id__brew_log_beans__bean_id',
  );

  $$BrewLogBeansTableProcessedTableManager get brewLogBeansRefs {
    final manager = $$BrewLogBeansTableTableManager(
      $_db,
      $_db.brewLogBeans,
    ).filter((f) => f.beanId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_brewLogBeansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoffeeBeansTableFilterComposer
    extends Composer<_$AppDatabase, $CoffeeBeansTable> {
  $$CoffeeBeansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get farm => $composableBuilder(
    column: $table.farm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<ProcessMethod>,
    List<ProcessMethod>,
    String
  >
  get process => $composableBuilder(
    column: $table.process,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get flavorTags => $composableBuilder(
    column: $table.flavorTags,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> beanBatchesRefs(
    Expression<bool> Function($$BeanBatchesTableFilterComposer f) f,
  ) {
    final $$BeanBatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.beanBatches,
      getReferencedColumn: (t) => t.beanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeanBatchesTableFilterComposer(
            $db: $db,
            $table: $db.beanBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> brewLogsRefs(
    Expression<bool> Function($$BrewLogsTableFilterComposer f) f,
  ) {
    final $$BrewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.beanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableFilterComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> brewLogBeansRefs(
    Expression<bool> Function($$BrewLogBeansTableFilterComposer f) f,
  ) {
    final $$BrewLogBeansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogBeans,
      getReferencedColumn: (t) => t.beanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogBeansTableFilterComposer(
            $db: $db,
            $table: $db.brewLogBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoffeeBeansTableOrderingComposer
    extends Composer<_$AppDatabase, $CoffeeBeansTable> {
  $$CoffeeBeansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get farm => $composableBuilder(
    column: $table.farm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get process => $composableBuilder(
    column: $table.process,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flavorTags => $composableBuilder(
    column: $table.flavorTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoffeeBeansTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoffeeBeansTable> {
  $$CoffeeBeansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get farm =>
      $composableBuilder(column: $table.farm, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<ProcessMethod>, String> get process =>
      $composableBuilder(column: $table.process, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get flavorTags =>
      $composableBuilder(
        column: $table.flavorTags,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> beanBatchesRefs<T extends Object>(
    Expression<T> Function($$BeanBatchesTableAnnotationComposer a) f,
  ) {
    final $$BeanBatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.beanBatches,
      getReferencedColumn: (t) => t.beanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeanBatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.beanBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> brewLogsRefs<T extends Object>(
    Expression<T> Function($$BrewLogsTableAnnotationComposer a) f,
  ) {
    final $$BrewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.beanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> brewLogBeansRefs<T extends Object>(
    Expression<T> Function($$BrewLogBeansTableAnnotationComposer a) f,
  ) {
    final $$BrewLogBeansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogBeans,
      getReferencedColumn: (t) => t.beanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogBeansTableAnnotationComposer(
            $db: $db,
            $table: $db.brewLogBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoffeeBeansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoffeeBeansTable,
          CoffeeBeanRow,
          $$CoffeeBeansTableFilterComposer,
          $$CoffeeBeansTableOrderingComposer,
          $$CoffeeBeansTableAnnotationComposer,
          $$CoffeeBeansTableCreateCompanionBuilder,
          $$CoffeeBeansTableUpdateCompanionBuilder,
          (CoffeeBeanRow, $$CoffeeBeansTableReferences),
          CoffeeBeanRow,
          PrefetchHooks Function({
            bool beanBatchesRefs,
            bool brewLogsRefs,
            bool brewLogBeansRefs,
          })
        > {
  $$CoffeeBeansTableTableManager(_$AppDatabase db, $CoffeeBeansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoffeeBeansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoffeeBeansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoffeeBeansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> farm = const Value.absent(),
                Value<List<ProcessMethod>> process = const Value.absent(),
                Value<List<String>> flavorTags = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CoffeeBeansCompanion(
                id: id,
                name: name,
                origin: origin,
                farm: farm,
                process: process,
                flavorTags: flavorTags,
                isFavorite: isFavorite,
                photoPath: photoPath,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> origin = const Value.absent(),
                Value<String?> farm = const Value.absent(),
                Value<List<ProcessMethod>> process = const Value.absent(),
                Value<List<String>> flavorTags = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CoffeeBeansCompanion.insert(
                id: id,
                name: name,
                origin: origin,
                farm: farm,
                process: process,
                flavorTags: flavorTags,
                isFavorite: isFavorite,
                photoPath: photoPath,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoffeeBeansTable, CoffeeBeanRow>(table),
                  $$CoffeeBeansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                beanBatchesRefs = false,
                brewLogsRefs = false,
                brewLogBeansRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (beanBatchesRefs) db.beanBatches,
                    if (brewLogsRefs) db.brewLogs,
                    if (brewLogBeansRefs) db.brewLogBeans,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (beanBatchesRefs)
                        await $_getPrefetchedData<
                          CoffeeBeanRow,
                          $CoffeeBeansTable,
                          BeanBatchRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoffeeBeansTableReferences
                              ._beanBatchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoffeeBeansTableReferences(
                                db,
                                table,
                                p0,
                              ).beanBatchesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.beanId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (brewLogsRefs)
                        await $_getPrefetchedData<
                          CoffeeBeanRow,
                          $CoffeeBeansTable,
                          BrewLogRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoffeeBeansTableReferences
                              ._brewLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoffeeBeansTableReferences(
                                db,
                                table,
                                p0,
                              ).brewLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.beanId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (brewLogBeansRefs)
                        await $_getPrefetchedData<
                          CoffeeBeanRow,
                          $CoffeeBeansTable,
                          BeanUsageRow
                        >(
                          currentTable: table,
                          referencedTable: $$CoffeeBeansTableReferences
                              ._brewLogBeansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoffeeBeansTableReferences(
                                db,
                                table,
                                p0,
                              ).brewLogBeansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.beanId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CoffeeBeansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoffeeBeansTable,
      CoffeeBeanRow,
      $$CoffeeBeansTableFilterComposer,
      $$CoffeeBeansTableOrderingComposer,
      $$CoffeeBeansTableAnnotationComposer,
      $$CoffeeBeansTableCreateCompanionBuilder,
      $$CoffeeBeansTableUpdateCompanionBuilder,
      (CoffeeBeanRow, $$CoffeeBeansTableReferences),
      CoffeeBeanRow,
      PrefetchHooks Function({
        bool beanBatchesRefs,
        bool brewLogsRefs,
        bool brewLogBeansRefs,
      })
    >;
typedef $$BeanBatchesTableCreateCompanionBuilder =
    BeanBatchesCompanion Function({
      Value<int> id,
      required int beanId,
      Value<DateTime?> roastDate,
      Value<RoastLevel?> roastLevel,
      Value<double> remainingGrams,
      Value<double?> initialGrams,
      Value<double?> price,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$BeanBatchesTableUpdateCompanionBuilder =
    BeanBatchesCompanion Function({
      Value<int> id,
      Value<int> beanId,
      Value<DateTime?> roastDate,
      Value<RoastLevel?> roastLevel,
      Value<double> remainingGrams,
      Value<double?> initialGrams,
      Value<double?> price,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$BeanBatchesTableReferences
    extends BaseReferences<_$AppDatabase, $BeanBatchesTable, BeanBatchRow> {
  $$BeanBatchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoffeeBeansTable _beanIdTable(_$AppDatabase db) =>
      db.coffeeBeans.createAlias('bean_batches__bean_id__coffee_beans__id');

  $$CoffeeBeansTableProcessedTableManager get beanId {
    final $_column = $_itemColumn<int>('bean_id')!;

    final manager = $$CoffeeBeansTableTableManager(
      $_db,
      $_db.coffeeBeans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_beanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BrewLogBeansTable, List<BeanUsageRow>>
  _brewLogBeansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.brewLogBeans,
    aliasName: 'bean_batches__id__brew_log_beans__batch_id',
  );

  $$BrewLogBeansTableProcessedTableManager get brewLogBeansRefs {
    final manager = $$BrewLogBeansTableTableManager(
      $_db,
      $_db.brewLogBeans,
    ).filter((f) => f.batchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_brewLogBeansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BeanBatchesTableFilterComposer
    extends Composer<_$AppDatabase, $BeanBatchesTable> {
  $$BeanBatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get roastDate => $composableBuilder(
    column: $table.roastDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RoastLevel?, RoastLevel, String>
  get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get remainingGrams => $composableBuilder(
    column: $table.remainingGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialGrams => $composableBuilder(
    column: $table.initialGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CoffeeBeansTableFilterComposer get beanId {
    final $$CoffeeBeansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.coffeeBeans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoffeeBeansTableFilterComposer(
            $db: $db,
            $table: $db.coffeeBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> brewLogBeansRefs(
    Expression<bool> Function($$BrewLogBeansTableFilterComposer f) f,
  ) {
    final $$BrewLogBeansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogBeans,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogBeansTableFilterComposer(
            $db: $db,
            $table: $db.brewLogBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BeanBatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BeanBatchesTable> {
  $$BeanBatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get roastDate => $composableBuilder(
    column: $table.roastDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingGrams => $composableBuilder(
    column: $table.remainingGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialGrams => $composableBuilder(
    column: $table.initialGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoffeeBeansTableOrderingComposer get beanId {
    final $$CoffeeBeansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.coffeeBeans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoffeeBeansTableOrderingComposer(
            $db: $db,
            $table: $db.coffeeBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BeanBatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BeanBatchesTable> {
  $$BeanBatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get roastDate =>
      $composableBuilder(column: $table.roastDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RoastLevel?, String> get roastLevel =>
      $composableBuilder(
        column: $table.roastLevel,
        builder: (column) => column,
      );

  GeneratedColumn<double> get remainingGrams => $composableBuilder(
    column: $table.remainingGrams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get initialGrams => $composableBuilder(
    column: $table.initialGrams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CoffeeBeansTableAnnotationComposer get beanId {
    final $$CoffeeBeansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.coffeeBeans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoffeeBeansTableAnnotationComposer(
            $db: $db,
            $table: $db.coffeeBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> brewLogBeansRefs<T extends Object>(
    Expression<T> Function($$BrewLogBeansTableAnnotationComposer a) f,
  ) {
    final $$BrewLogBeansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogBeans,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogBeansTableAnnotationComposer(
            $db: $db,
            $table: $db.brewLogBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BeanBatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BeanBatchesTable,
          BeanBatchRow,
          $$BeanBatchesTableFilterComposer,
          $$BeanBatchesTableOrderingComposer,
          $$BeanBatchesTableAnnotationComposer,
          $$BeanBatchesTableCreateCompanionBuilder,
          $$BeanBatchesTableUpdateCompanionBuilder,
          (BeanBatchRow, $$BeanBatchesTableReferences),
          BeanBatchRow,
          PrefetchHooks Function({bool beanId, bool brewLogBeansRefs})
        > {
  $$BeanBatchesTableTableManager(_$AppDatabase db, $BeanBatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeanBatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeanBatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeanBatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> beanId = const Value.absent(),
                Value<DateTime?> roastDate = const Value.absent(),
                Value<RoastLevel?> roastLevel = const Value.absent(),
                Value<double> remainingGrams = const Value.absent(),
                Value<double?> initialGrams = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BeanBatchesCompanion(
                id: id,
                beanId: beanId,
                roastDate: roastDate,
                roastLevel: roastLevel,
                remainingGrams: remainingGrams,
                initialGrams: initialGrams,
                price: price,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int beanId,
                Value<DateTime?> roastDate = const Value.absent(),
                Value<RoastLevel?> roastLevel = const Value.absent(),
                Value<double> remainingGrams = const Value.absent(),
                Value<double?> initialGrams = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BeanBatchesCompanion.insert(
                id: id,
                beanId: beanId,
                roastDate: roastDate,
                roastLevel: roastLevel,
                remainingGrams: remainingGrams,
                initialGrams: initialGrams,
                price: price,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BeanBatchesTable, BeanBatchRow>(table),
                  $$BeanBatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({beanId = false, brewLogBeansRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (brewLogBeansRefs) db.brewLogBeans],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (beanId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.beanId,
                        referencedTable: $$BeanBatchesTableReferences
                            ._beanIdTable(db),
                        referencedColumn: $$BeanBatchesTableReferences
                            ._beanIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (brewLogBeansRefs)
                    await $_getPrefetchedData<
                      BeanBatchRow,
                      $BeanBatchesTable,
                      BeanUsageRow
                    >(
                      currentTable: table,
                      referencedTable: $$BeanBatchesTableReferences
                          ._brewLogBeansRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BeanBatchesTableReferences(
                            db,
                            table,
                            p0,
                          ).brewLogBeansRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.batchId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BeanBatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BeanBatchesTable,
      BeanBatchRow,
      $$BeanBatchesTableFilterComposer,
      $$BeanBatchesTableOrderingComposer,
      $$BeanBatchesTableAnnotationComposer,
      $$BeanBatchesTableCreateCompanionBuilder,
      $$BeanBatchesTableUpdateCompanionBuilder,
      (BeanBatchRow, $$BeanBatchesTableReferences),
      BeanBatchRow,
      PrefetchHooks Function({bool beanId, bool brewLogBeansRefs})
    >;
typedef $$GrindersTableCreateCompanionBuilder = GrindersCompanion Function({
  Value<int> id,
  required String brand,
  required String model,
  Value<String?> burrType,
  Value<GrindScaleUnit?> scaleUnit,
  Value<double?> zeroPoint,
  Value<int?> clicksPerRevolution,
  Value<double?> micronsPerClick,
  Value<String?> calibrationNote,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$GrindersTableUpdateCompanionBuilder = GrindersCompanion Function({
  Value<int> id,
  Value<String> brand,
  Value<String> model,
  Value<String?> burrType,
  Value<GrindScaleUnit?> scaleUnit,
  Value<double?> zeroPoint,
  Value<int?> clicksPerRevolution,
  Value<double?> micronsPerClick,
  Value<String?> calibrationNote,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$GrindersTableReferences
    extends BaseReferences<_$AppDatabase, $GrindersTable, GrinderRow> {
  $$GrindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BrewLogsTable, List<BrewLogRow>>
  _brewLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.brewLogs,
    aliasName: 'grinders__id__brew_logs__grinder_id',
  );

  $$BrewLogsTableProcessedTableManager get brewLogsRefs {
    final manager = $$BrewLogsTableTableManager(
      $_db,
      $_db.brewLogs,
    ).filter((f) => f.grinderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_brewLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GrindersTableFilterComposer
    extends Composer<_$AppDatabase, $GrindersTable> {
  $$GrindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get burrType => $composableBuilder(
    column: $table.burrType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GrindScaleUnit?, GrindScaleUnit, String>
  get scaleUnit => $composableBuilder(
    column: $table.scaleUnit,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get zeroPoint => $composableBuilder(
    column: $table.zeroPoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clicksPerRevolution => $composableBuilder(
    column: $table.clicksPerRevolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get micronsPerClick => $composableBuilder(
    column: $table.micronsPerClick,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calibrationNote => $composableBuilder(
    column: $table.calibrationNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> brewLogsRefs(
    Expression<bool> Function($$BrewLogsTableFilterComposer f) f,
  ) {
    final $$BrewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.grinderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableFilterComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GrindersTableOrderingComposer
    extends Composer<_$AppDatabase, $GrindersTable> {
  $$GrindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get burrType => $composableBuilder(
    column: $table.burrType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scaleUnit => $composableBuilder(
    column: $table.scaleUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zeroPoint => $composableBuilder(
    column: $table.zeroPoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clicksPerRevolution => $composableBuilder(
    column: $table.clicksPerRevolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get micronsPerClick => $composableBuilder(
    column: $table.micronsPerClick,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calibrationNote => $composableBuilder(
    column: $table.calibrationNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GrindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrindersTable> {
  $$GrindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get burrType =>
      $composableBuilder(column: $table.burrType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GrindScaleUnit?, String> get scaleUnit =>
      $composableBuilder(column: $table.scaleUnit, builder: (column) => column);

  GeneratedColumn<double> get zeroPoint =>
      $composableBuilder(column: $table.zeroPoint, builder: (column) => column);

  GeneratedColumn<int> get clicksPerRevolution => $composableBuilder(
    column: $table.clicksPerRevolution,
    builder: (column) => column,
  );

  GeneratedColumn<double> get micronsPerClick => $composableBuilder(
    column: $table.micronsPerClick,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calibrationNote => $composableBuilder(
    column: $table.calibrationNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> brewLogsRefs<T extends Object>(
    Expression<T> Function($$BrewLogsTableAnnotationComposer a) f,
  ) {
    final $$BrewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.grinderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GrindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrindersTable,
          GrinderRow,
          $$GrindersTableFilterComposer,
          $$GrindersTableOrderingComposer,
          $$GrindersTableAnnotationComposer,
          $$GrindersTableCreateCompanionBuilder,
          $$GrindersTableUpdateCompanionBuilder,
          (GrinderRow, $$GrindersTableReferences),
          GrinderRow,
          PrefetchHooks Function({bool brewLogsRefs})
        > {
  $$GrindersTableTableManager(_$AppDatabase db, $GrindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String?> burrType = const Value.absent(),
                Value<GrindScaleUnit?> scaleUnit = const Value.absent(),
                Value<double?> zeroPoint = const Value.absent(),
                Value<int?> clicksPerRevolution = const Value.absent(),
                Value<double?> micronsPerClick = const Value.absent(),
                Value<String?> calibrationNote = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GrindersCompanion(
                id: id,
                brand: brand,
                model: model,
                burrType: burrType,
                scaleUnit: scaleUnit,
                zeroPoint: zeroPoint,
                clicksPerRevolution: clicksPerRevolution,
                micronsPerClick: micronsPerClick,
                calibrationNote: calibrationNote,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String brand,
                required String model,
                Value<String?> burrType = const Value.absent(),
                Value<GrindScaleUnit?> scaleUnit = const Value.absent(),
                Value<double?> zeroPoint = const Value.absent(),
                Value<int?> clicksPerRevolution = const Value.absent(),
                Value<double?> micronsPerClick = const Value.absent(),
                Value<String?> calibrationNote = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GrindersCompanion.insert(
                id: id,
                brand: brand,
                model: model,
                burrType: burrType,
                scaleUnit: scaleUnit,
                zeroPoint: zeroPoint,
                clicksPerRevolution: clicksPerRevolution,
                micronsPerClick: micronsPerClick,
                calibrationNote: calibrationNote,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GrindersTable, GrinderRow>(table),
                  $$GrindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({brewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (brewLogsRefs) db.brewLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (brewLogsRefs)
                    await $_getPrefetchedData<
                      GrinderRow,
                      $GrindersTable,
                      BrewLogRow
                    >(
                      currentTable: table,
                      referencedTable: $$GrindersTableReferences
                          ._brewLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$GrindersTableReferences(db, table, p0).brewLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.grinderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GrindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrindersTable,
      GrinderRow,
      $$GrindersTableFilterComposer,
      $$GrindersTableOrderingComposer,
      $$GrindersTableAnnotationComposer,
      $$GrindersTableCreateCompanionBuilder,
      $$GrindersTableUpdateCompanionBuilder,
      (GrinderRow, $$GrindersTableReferences),
      GrinderRow,
      PrefetchHooks Function({bool brewLogsRefs})
    >;
typedef $$RecipesTableCreateCompanionBuilder = RecipesCompanion Function({
  Value<int> id,
  required String name,
  Value<BrewMethod?> method,
  Value<double?> doseGrams,
  Value<double?> waterGrams,
  Value<double?> ratio,
  Value<double?> waterTemp,
  Value<int?> totalTimeSeconds,
  Value<List<PourStage>?> pourStages,
  Value<String?> grindSuggestion,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$RecipesTableUpdateCompanionBuilder = RecipesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<BrewMethod?> method,
  Value<double?> doseGrams,
  Value<double?> waterGrams,
  Value<double?> ratio,
  Value<double?> waterTemp,
  Value<int?> totalTimeSeconds,
  Value<List<PourStage>?> pourStages,
  Value<String?> grindSuggestion,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, RecipeRow> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BrewLogsTable, List<BrewLogRow>>
  _brewLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.brewLogs,
    aliasName: 'recipes__id__brew_logs__recipe_id',
  );

  $$BrewLogsTableProcessedTableManager get brewLogsRefs {
    final manager = $$BrewLogsTableTableManager(
      $_db,
      $_db.brewLogs,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_brewLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BrewMethod?, BrewMethod, String> get method =>
      $composableBuilder(
        column: $table.method,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get doseGrams => $composableBuilder(
    column: $table.doseGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterGrams => $composableBuilder(
    column: $table.waterGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ratio => $composableBuilder(
    column: $table.ratio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterTemp => $composableBuilder(
    column: $table.waterTemp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTimeSeconds => $composableBuilder(
    column: $table.totalTimeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<PourStage>?, List<PourStage>, String>
  get pourStages => $composableBuilder(
    column: $table.pourStages,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get grindSuggestion => $composableBuilder(
    column: $table.grindSuggestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> brewLogsRefs(
    Expression<bool> Function($$BrewLogsTableFilterComposer f) f,
  ) {
    final $$BrewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableFilterComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get doseGrams => $composableBuilder(
    column: $table.doseGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterGrams => $composableBuilder(
    column: $table.waterGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ratio => $composableBuilder(
    column: $table.ratio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterTemp => $composableBuilder(
    column: $table.waterTemp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTimeSeconds => $composableBuilder(
    column: $table.totalTimeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pourStages => $composableBuilder(
    column: $table.pourStages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grindSuggestion => $composableBuilder(
    column: $table.grindSuggestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BrewMethod?, String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<double> get doseGrams =>
      $composableBuilder(column: $table.doseGrams, builder: (column) => column);

  GeneratedColumn<double> get waterGrams => $composableBuilder(
    column: $table.waterGrams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ratio =>
      $composableBuilder(column: $table.ratio, builder: (column) => column);

  GeneratedColumn<double> get waterTemp =>
      $composableBuilder(column: $table.waterTemp, builder: (column) => column);

  GeneratedColumn<int> get totalTimeSeconds => $composableBuilder(
    column: $table.totalTimeSeconds,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<PourStage>?, String> get pourStages =>
      $composableBuilder(
        column: $table.pourStages,
        builder: (column) => column,
      );

  GeneratedColumn<String> get grindSuggestion => $composableBuilder(
    column: $table.grindSuggestion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> brewLogsRefs<T extends Object>(
    Expression<T> Function($$BrewLogsTableAnnotationComposer a) f,
  ) {
    final $$BrewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          RecipeRow,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (RecipeRow, $$RecipesTableReferences),
          RecipeRow,
          PrefetchHooks Function({bool brewLogsRefs})
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<BrewMethod?> method = const Value.absent(),
                Value<double?> doseGrams = const Value.absent(),
                Value<double?> waterGrams = const Value.absent(),
                Value<double?> ratio = const Value.absent(),
                Value<double?> waterTemp = const Value.absent(),
                Value<int?> totalTimeSeconds = const Value.absent(),
                Value<List<PourStage>?> pourStages = const Value.absent(),
                Value<String?> grindSuggestion = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                name: name,
                method: method,
                doseGrams: doseGrams,
                waterGrams: waterGrams,
                ratio: ratio,
                waterTemp: waterTemp,
                totalTimeSeconds: totalTimeSeconds,
                pourStages: pourStages,
                grindSuggestion: grindSuggestion,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<BrewMethod?> method = const Value.absent(),
                Value<double?> doseGrams = const Value.absent(),
                Value<double?> waterGrams = const Value.absent(),
                Value<double?> ratio = const Value.absent(),
                Value<double?> waterTemp = const Value.absent(),
                Value<int?> totalTimeSeconds = const Value.absent(),
                Value<List<PourStage>?> pourStages = const Value.absent(),
                Value<String?> grindSuggestion = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                name: name,
                method: method,
                doseGrams: doseGrams,
                waterGrams: waterGrams,
                ratio: ratio,
                waterTemp: waterTemp,
                totalTimeSeconds: totalTimeSeconds,
                pourStages: pourStages,
                grindSuggestion: grindSuggestion,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipesTable, RecipeRow>(table),
                  $$RecipesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({brewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (brewLogsRefs) db.brewLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (brewLogsRefs)
                    await $_getPrefetchedData<
                      RecipeRow,
                      $RecipesTable,
                      BrewLogRow
                    >(
                      currentTable: table,
                      referencedTable: $$RecipesTableReferences
                          ._brewLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecipesTableReferences(db, table, p0).brewLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.recipeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      RecipeRow,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (RecipeRow, $$RecipesTableReferences),
      RecipeRow,
      PrefetchHooks Function({bool brewLogsRefs})
    >;
typedef $$BrewLogsTableCreateCompanionBuilder = BrewLogsCompanion Function({
  Value<int> id,
  Value<int?> beanId,
  Value<int?> grinderId,
  Value<int?> recipeId,
  Value<BrewMethod?> method,
  Value<String?> methodLabel,
  Value<double?> grindSetting,
  Value<int?> grindClicks,
  Value<double?> grinderZeroPointSnapshot,
  Value<int?> grinderClicksPerRevolutionSnapshot,
  Value<double?> doseGrams,
  Value<double?> waterGrams,
  Value<double?> ratio,
  Value<double?> waterTemp,
  Value<int?> totalTimeSeconds,
  Value<String?> dripper,
  Value<int?> rating,
  Value<List<String>> flavorTags,
  Value<String?> notes,
  Value<String?> photoPath,
  Value<DateTime> brewedAt,
  Value<bool> isBest,
  Value<bool> isFavorite,
  Value<double?> tds,
  Value<double?> extractionYield,
  Value<int?> waterPpm,
  Value<double?> ambientTemp,
  Value<double?> ambientHumidity,
  Value<double?> beanTemp,
  Value<double?> pressure,
  Value<List<PourStage>?> pourStages,
  Value<DateTime?> beanRoastDate,
  Value<RoastLevel?> beanRoastLevel,
  Value<String?> heatLevel,
  Value<double?> yieldGrams,
  Value<bool?> preheatUpperChamber,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$BrewLogsTableUpdateCompanionBuilder = BrewLogsCompanion Function({
  Value<int> id,
  Value<int?> beanId,
  Value<int?> grinderId,
  Value<int?> recipeId,
  Value<BrewMethod?> method,
  Value<String?> methodLabel,
  Value<double?> grindSetting,
  Value<int?> grindClicks,
  Value<double?> grinderZeroPointSnapshot,
  Value<int?> grinderClicksPerRevolutionSnapshot,
  Value<double?> doseGrams,
  Value<double?> waterGrams,
  Value<double?> ratio,
  Value<double?> waterTemp,
  Value<int?> totalTimeSeconds,
  Value<String?> dripper,
  Value<int?> rating,
  Value<List<String>> flavorTags,
  Value<String?> notes,
  Value<String?> photoPath,
  Value<DateTime> brewedAt,
  Value<bool> isBest,
  Value<bool> isFavorite,
  Value<double?> tds,
  Value<double?> extractionYield,
  Value<int?> waterPpm,
  Value<double?> ambientTemp,
  Value<double?> ambientHumidity,
  Value<double?> beanTemp,
  Value<double?> pressure,
  Value<List<PourStage>?> pourStages,
  Value<DateTime?> beanRoastDate,
  Value<RoastLevel?> beanRoastLevel,
  Value<String?> heatLevel,
  Value<double?> yieldGrams,
  Value<bool?> preheatUpperChamber,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$BrewLogsTableReferences
    extends BaseReferences<_$AppDatabase, $BrewLogsTable, BrewLogRow> {
  $$BrewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoffeeBeansTable _beanIdTable(_$AppDatabase db) =>
      db.coffeeBeans.createAlias('brew_logs__bean_id__coffee_beans__id');

  $$CoffeeBeansTableProcessedTableManager? get beanId {
    final $_column = $_itemColumn<int>('bean_id');
    if ($_column == null) return null;
    final manager = $$CoffeeBeansTableTableManager(
      $_db,
      $_db.coffeeBeans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_beanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GrindersTable _grinderIdTable(_$AppDatabase db) =>
      db.grinders.createAlias('brew_logs__grinder_id__grinders__id');

  $$GrindersTableProcessedTableManager? get grinderId {
    final $_column = $_itemColumn<int>('grinder_id');
    if ($_column == null) return null;
    final manager = $$GrindersTableTableManager(
      $_db,
      $_db.grinders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_grinderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('brew_logs__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager? get recipeId {
    final $_column = $_itemColumn<int>('recipe_id');
    if ($_column == null) return null;
    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BrewLogBeansTable, List<BeanUsageRow>>
  _brewLogBeansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.brewLogBeans,
    aliasName: 'brew_logs__id__brew_log_beans__brew_log_id',
  );

  $$BrewLogBeansTableProcessedTableManager get brewLogBeansRefs {
    final manager = $$BrewLogBeansTableTableManager(
      $_db,
      $_db.brewLogBeans,
    ).filter((f) => f.brewLogId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_brewLogBeansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BrewLogAddinsTable, List<BrewLogAddInRow>>
  _brewLogAddinsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.brewLogAddins,
    aliasName: 'brew_logs__id__brew_log_addins__brew_log_id',
  );

  $$BrewLogAddinsTableProcessedTableManager get brewLogAddinsRefs {
    final manager = $$BrewLogAddinsTableTableManager(
      $_db,
      $_db.brewLogAddins,
    ).filter((f) => f.brewLogId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_brewLogAddinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $BrewLogFavoriteGroupsTable,
    List<BrewLogFavoriteGroupRow>
  >
  _brewLogFavoriteGroupsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.brewLogFavoriteGroups,
        aliasName: 'brew_logs__id__brew_log_favorite_groups__brew_log_id',
      );

  $$BrewLogFavoriteGroupsTableProcessedTableManager
  get brewLogFavoriteGroupsRefs {
    final manager = $$BrewLogFavoriteGroupsTableTableManager(
      $_db,
      $_db.brewLogFavoriteGroups,
    ).filter((f) => f.brewLogId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _brewLogFavoriteGroupsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BrewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $BrewLogsTable> {
  $$BrewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BrewMethod?, BrewMethod, String> get method =>
      $composableBuilder(
        column: $table.method,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get methodLabel => $composableBuilder(
    column: $table.methodLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grindSetting => $composableBuilder(
    column: $table.grindSetting,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grindClicks => $composableBuilder(
    column: $table.grindClicks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grinderZeroPointSnapshot => $composableBuilder(
    column: $table.grinderZeroPointSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grinderClicksPerRevolutionSnapshot =>
      $composableBuilder(
        column: $table.grinderClicksPerRevolutionSnapshot,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<double> get doseGrams => $composableBuilder(
    column: $table.doseGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterGrams => $composableBuilder(
    column: $table.waterGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ratio => $composableBuilder(
    column: $table.ratio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterTemp => $composableBuilder(
    column: $table.waterTemp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTimeSeconds => $composableBuilder(
    column: $table.totalTimeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dripper => $composableBuilder(
    column: $table.dripper,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get flavorTags => $composableBuilder(
    column: $table.flavorTags,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get brewedAt => $composableBuilder(
    column: $table.brewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBest => $composableBuilder(
    column: $table.isBest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tds => $composableBuilder(
    column: $table.tds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get extractionYield => $composableBuilder(
    column: $table.extractionYield,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get waterPpm => $composableBuilder(
    column: $table.waterPpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ambientTemp => $composableBuilder(
    column: $table.ambientTemp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ambientHumidity => $composableBuilder(
    column: $table.ambientHumidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get beanTemp => $composableBuilder(
    column: $table.beanTemp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pressure => $composableBuilder(
    column: $table.pressure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<PourStage>?, List<PourStage>, String>
  get pourStages => $composableBuilder(
    column: $table.pourStages,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get beanRoastDate => $composableBuilder(
    column: $table.beanRoastDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RoastLevel?, RoastLevel, String>
  get beanRoastLevel => $composableBuilder(
    column: $table.beanRoastLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get heatLevel => $composableBuilder(
    column: $table.heatLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get yieldGrams => $composableBuilder(
    column: $table.yieldGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get preheatUpperChamber => $composableBuilder(
    column: $table.preheatUpperChamber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CoffeeBeansTableFilterComposer get beanId {
    final $$CoffeeBeansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.coffeeBeans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoffeeBeansTableFilterComposer(
            $db: $db,
            $table: $db.coffeeBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GrindersTableFilterComposer get grinderId {
    final $$GrindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.grinderId,
      referencedTable: $db.grinders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindersTableFilterComposer(
            $db: $db,
            $table: $db.grinders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> brewLogBeansRefs(
    Expression<bool> Function($$BrewLogBeansTableFilterComposer f) f,
  ) {
    final $$BrewLogBeansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogBeans,
      getReferencedColumn: (t) => t.brewLogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogBeansTableFilterComposer(
            $db: $db,
            $table: $db.brewLogBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> brewLogAddinsRefs(
    Expression<bool> Function($$BrewLogAddinsTableFilterComposer f) f,
  ) {
    final $$BrewLogAddinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogAddins,
      getReferencedColumn: (t) => t.brewLogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogAddinsTableFilterComposer(
            $db: $db,
            $table: $db.brewLogAddins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> brewLogFavoriteGroupsRefs(
    Expression<bool> Function($$BrewLogFavoriteGroupsTableFilterComposer f) f,
  ) {
    final $$BrewLogFavoriteGroupsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.brewLogFavoriteGroups,
          getReferencedColumn: (t) => t.brewLogId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BrewLogFavoriteGroupsTableFilterComposer(
                $db: $db,
                $table: $db.brewLogFavoriteGroups,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BrewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $BrewLogsTable> {
  $$BrewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodLabel => $composableBuilder(
    column: $table.methodLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grindSetting => $composableBuilder(
    column: $table.grindSetting,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grindClicks => $composableBuilder(
    column: $table.grindClicks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grinderZeroPointSnapshot => $composableBuilder(
    column: $table.grinderZeroPointSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grinderClicksPerRevolutionSnapshot =>
      $composableBuilder(
        column: $table.grinderClicksPerRevolutionSnapshot,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<double> get doseGrams => $composableBuilder(
    column: $table.doseGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterGrams => $composableBuilder(
    column: $table.waterGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ratio => $composableBuilder(
    column: $table.ratio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterTemp => $composableBuilder(
    column: $table.waterTemp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTimeSeconds => $composableBuilder(
    column: $table.totalTimeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dripper => $composableBuilder(
    column: $table.dripper,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flavorTags => $composableBuilder(
    column: $table.flavorTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get brewedAt => $composableBuilder(
    column: $table.brewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBest => $composableBuilder(
    column: $table.isBest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tds => $composableBuilder(
    column: $table.tds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get extractionYield => $composableBuilder(
    column: $table.extractionYield,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get waterPpm => $composableBuilder(
    column: $table.waterPpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ambientTemp => $composableBuilder(
    column: $table.ambientTemp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ambientHumidity => $composableBuilder(
    column: $table.ambientHumidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get beanTemp => $composableBuilder(
    column: $table.beanTemp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pressure => $composableBuilder(
    column: $table.pressure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pourStages => $composableBuilder(
    column: $table.pourStages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get beanRoastDate => $composableBuilder(
    column: $table.beanRoastDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beanRoastLevel => $composableBuilder(
    column: $table.beanRoastLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heatLevel => $composableBuilder(
    column: $table.heatLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get yieldGrams => $composableBuilder(
    column: $table.yieldGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get preheatUpperChamber => $composableBuilder(
    column: $table.preheatUpperChamber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoffeeBeansTableOrderingComposer get beanId {
    final $$CoffeeBeansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.coffeeBeans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoffeeBeansTableOrderingComposer(
            $db: $db,
            $table: $db.coffeeBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GrindersTableOrderingComposer get grinderId {
    final $$GrindersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.grinderId,
      referencedTable: $db.grinders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindersTableOrderingComposer(
            $db: $db,
            $table: $db.grinders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrewLogsTable> {
  $$BrewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BrewMethod?, String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get methodLabel => $composableBuilder(
    column: $table.methodLabel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grindSetting => $composableBuilder(
    column: $table.grindSetting,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grindClicks => $composableBuilder(
    column: $table.grindClicks,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grinderZeroPointSnapshot => $composableBuilder(
    column: $table.grinderZeroPointSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grinderClicksPerRevolutionSnapshot =>
      $composableBuilder(
        column: $table.grinderClicksPerRevolutionSnapshot,
        builder: (column) => column,
      );

  GeneratedColumn<double> get doseGrams =>
      $composableBuilder(column: $table.doseGrams, builder: (column) => column);

  GeneratedColumn<double> get waterGrams => $composableBuilder(
    column: $table.waterGrams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ratio =>
      $composableBuilder(column: $table.ratio, builder: (column) => column);

  GeneratedColumn<double> get waterTemp =>
      $composableBuilder(column: $table.waterTemp, builder: (column) => column);

  GeneratedColumn<int> get totalTimeSeconds => $composableBuilder(
    column: $table.totalTimeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dripper =>
      $composableBuilder(column: $table.dripper, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get flavorTags =>
      $composableBuilder(
        column: $table.flavorTags,
        builder: (column) => column,
      );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get brewedAt =>
      $composableBuilder(column: $table.brewedAt, builder: (column) => column);

  GeneratedColumn<bool> get isBest =>
      $composableBuilder(column: $table.isBest, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tds =>
      $composableBuilder(column: $table.tds, builder: (column) => column);

  GeneratedColumn<double> get extractionYield => $composableBuilder(
    column: $table.extractionYield,
    builder: (column) => column,
  );

  GeneratedColumn<int> get waterPpm =>
      $composableBuilder(column: $table.waterPpm, builder: (column) => column);

  GeneratedColumn<double> get ambientTemp => $composableBuilder(
    column: $table.ambientTemp,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ambientHumidity => $composableBuilder(
    column: $table.ambientHumidity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get beanTemp =>
      $composableBuilder(column: $table.beanTemp, builder: (column) => column);

  GeneratedColumn<double> get pressure =>
      $composableBuilder(column: $table.pressure, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<PourStage>?, String> get pourStages =>
      $composableBuilder(
        column: $table.pourStages,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get beanRoastDate => $composableBuilder(
    column: $table.beanRoastDate,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RoastLevel?, String> get beanRoastLevel =>
      $composableBuilder(
        column: $table.beanRoastLevel,
        builder: (column) => column,
      );

  GeneratedColumn<String> get heatLevel =>
      $composableBuilder(column: $table.heatLevel, builder: (column) => column);

  GeneratedColumn<double> get yieldGrams => $composableBuilder(
    column: $table.yieldGrams,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get preheatUpperChamber => $composableBuilder(
    column: $table.preheatUpperChamber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CoffeeBeansTableAnnotationComposer get beanId {
    final $$CoffeeBeansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.coffeeBeans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoffeeBeansTableAnnotationComposer(
            $db: $db,
            $table: $db.coffeeBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GrindersTableAnnotationComposer get grinderId {
    final $$GrindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.grinderId,
      referencedTable: $db.grinders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GrindersTableAnnotationComposer(
            $db: $db,
            $table: $db.grinders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> brewLogBeansRefs<T extends Object>(
    Expression<T> Function($$BrewLogBeansTableAnnotationComposer a) f,
  ) {
    final $$BrewLogBeansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogBeans,
      getReferencedColumn: (t) => t.brewLogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogBeansTableAnnotationComposer(
            $db: $db,
            $table: $db.brewLogBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> brewLogAddinsRefs<T extends Object>(
    Expression<T> Function($$BrewLogAddinsTableAnnotationComposer a) f,
  ) {
    final $$BrewLogAddinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.brewLogAddins,
      getReferencedColumn: (t) => t.brewLogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogAddinsTableAnnotationComposer(
            $db: $db,
            $table: $db.brewLogAddins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> brewLogFavoriteGroupsRefs<T extends Object>(
    Expression<T> Function($$BrewLogFavoriteGroupsTableAnnotationComposer a) f,
  ) {
    final $$BrewLogFavoriteGroupsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.brewLogFavoriteGroups,
          getReferencedColumn: (t) => t.brewLogId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BrewLogFavoriteGroupsTableAnnotationComposer(
                $db: $db,
                $table: $db.brewLogFavoriteGroups,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BrewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrewLogsTable,
          BrewLogRow,
          $$BrewLogsTableFilterComposer,
          $$BrewLogsTableOrderingComposer,
          $$BrewLogsTableAnnotationComposer,
          $$BrewLogsTableCreateCompanionBuilder,
          $$BrewLogsTableUpdateCompanionBuilder,
          (BrewLogRow, $$BrewLogsTableReferences),
          BrewLogRow,
          PrefetchHooks Function({
            bool beanId,
            bool grinderId,
            bool recipeId,
            bool brewLogBeansRefs,
            bool brewLogAddinsRefs,
            bool brewLogFavoriteGroupsRefs,
          })
        > {
  $$BrewLogsTableTableManager(_$AppDatabase db, $BrewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> beanId = const Value.absent(),
                Value<int?> grinderId = const Value.absent(),
                Value<int?> recipeId = const Value.absent(),
                Value<BrewMethod?> method = const Value.absent(),
                Value<String?> methodLabel = const Value.absent(),
                Value<double?> grindSetting = const Value.absent(),
                Value<int?> grindClicks = const Value.absent(),
                Value<double?> grinderZeroPointSnapshot = const Value.absent(),
                Value<int?> grinderClicksPerRevolutionSnapshot =
                    const Value.absent(),
                Value<double?> doseGrams = const Value.absent(),
                Value<double?> waterGrams = const Value.absent(),
                Value<double?> ratio = const Value.absent(),
                Value<double?> waterTemp = const Value.absent(),
                Value<int?> totalTimeSeconds = const Value.absent(),
                Value<String?> dripper = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<List<String>> flavorTags = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> brewedAt = const Value.absent(),
                Value<bool> isBest = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<double?> tds = const Value.absent(),
                Value<double?> extractionYield = const Value.absent(),
                Value<int?> waterPpm = const Value.absent(),
                Value<double?> ambientTemp = const Value.absent(),
                Value<double?> ambientHumidity = const Value.absent(),
                Value<double?> beanTemp = const Value.absent(),
                Value<double?> pressure = const Value.absent(),
                Value<List<PourStage>?> pourStages = const Value.absent(),
                Value<DateTime?> beanRoastDate = const Value.absent(),
                Value<RoastLevel?> beanRoastLevel = const Value.absent(),
                Value<String?> heatLevel = const Value.absent(),
                Value<double?> yieldGrams = const Value.absent(),
                Value<bool?> preheatUpperChamber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BrewLogsCompanion(
                id: id,
                beanId: beanId,
                grinderId: grinderId,
                recipeId: recipeId,
                method: method,
                methodLabel: methodLabel,
                grindSetting: grindSetting,
                grindClicks: grindClicks,
                grinderZeroPointSnapshot: grinderZeroPointSnapshot,
                grinderClicksPerRevolutionSnapshot:
                    grinderClicksPerRevolutionSnapshot,
                doseGrams: doseGrams,
                waterGrams: waterGrams,
                ratio: ratio,
                waterTemp: waterTemp,
                totalTimeSeconds: totalTimeSeconds,
                dripper: dripper,
                rating: rating,
                flavorTags: flavorTags,
                notes: notes,
                photoPath: photoPath,
                brewedAt: brewedAt,
                isBest: isBest,
                isFavorite: isFavorite,
                tds: tds,
                extractionYield: extractionYield,
                waterPpm: waterPpm,
                ambientTemp: ambientTemp,
                ambientHumidity: ambientHumidity,
                beanTemp: beanTemp,
                pressure: pressure,
                pourStages: pourStages,
                beanRoastDate: beanRoastDate,
                beanRoastLevel: beanRoastLevel,
                heatLevel: heatLevel,
                yieldGrams: yieldGrams,
                preheatUpperChamber: preheatUpperChamber,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> beanId = const Value.absent(),
                Value<int?> grinderId = const Value.absent(),
                Value<int?> recipeId = const Value.absent(),
                Value<BrewMethod?> method = const Value.absent(),
                Value<String?> methodLabel = const Value.absent(),
                Value<double?> grindSetting = const Value.absent(),
                Value<int?> grindClicks = const Value.absent(),
                Value<double?> grinderZeroPointSnapshot = const Value.absent(),
                Value<int?> grinderClicksPerRevolutionSnapshot =
                    const Value.absent(),
                Value<double?> doseGrams = const Value.absent(),
                Value<double?> waterGrams = const Value.absent(),
                Value<double?> ratio = const Value.absent(),
                Value<double?> waterTemp = const Value.absent(),
                Value<int?> totalTimeSeconds = const Value.absent(),
                Value<String?> dripper = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<List<String>> flavorTags = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> brewedAt = const Value.absent(),
                Value<bool> isBest = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<double?> tds = const Value.absent(),
                Value<double?> extractionYield = const Value.absent(),
                Value<int?> waterPpm = const Value.absent(),
                Value<double?> ambientTemp = const Value.absent(),
                Value<double?> ambientHumidity = const Value.absent(),
                Value<double?> beanTemp = const Value.absent(),
                Value<double?> pressure = const Value.absent(),
                Value<List<PourStage>?> pourStages = const Value.absent(),
                Value<DateTime?> beanRoastDate = const Value.absent(),
                Value<RoastLevel?> beanRoastLevel = const Value.absent(),
                Value<String?> heatLevel = const Value.absent(),
                Value<double?> yieldGrams = const Value.absent(),
                Value<bool?> preheatUpperChamber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BrewLogsCompanion.insert(
                id: id,
                beanId: beanId,
                grinderId: grinderId,
                recipeId: recipeId,
                method: method,
                methodLabel: methodLabel,
                grindSetting: grindSetting,
                grindClicks: grindClicks,
                grinderZeroPointSnapshot: grinderZeroPointSnapshot,
                grinderClicksPerRevolutionSnapshot:
                    grinderClicksPerRevolutionSnapshot,
                doseGrams: doseGrams,
                waterGrams: waterGrams,
                ratio: ratio,
                waterTemp: waterTemp,
                totalTimeSeconds: totalTimeSeconds,
                dripper: dripper,
                rating: rating,
                flavorTags: flavorTags,
                notes: notes,
                photoPath: photoPath,
                brewedAt: brewedAt,
                isBest: isBest,
                isFavorite: isFavorite,
                tds: tds,
                extractionYield: extractionYield,
                waterPpm: waterPpm,
                ambientTemp: ambientTemp,
                ambientHumidity: ambientHumidity,
                beanTemp: beanTemp,
                pressure: pressure,
                pourStages: pourStages,
                beanRoastDate: beanRoastDate,
                beanRoastLevel: beanRoastLevel,
                heatLevel: heatLevel,
                yieldGrams: yieldGrams,
                preheatUpperChamber: preheatUpperChamber,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BrewLogsTable, BrewLogRow>(table),
                  $$BrewLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                beanId = false,
                grinderId = false,
                recipeId = false,
                brewLogBeansRefs = false,
                brewLogAddinsRefs = false,
                brewLogFavoriteGroupsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (brewLogBeansRefs) db.brewLogBeans,
                    if (brewLogAddinsRefs) db.brewLogAddins,
                    if (brewLogFavoriteGroupsRefs) db.brewLogFavoriteGroups,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (beanId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.beanId,
                            referencedTable: $$BrewLogsTableReferences
                                ._beanIdTable(db),
                            referencedColumn: $$BrewLogsTableReferences
                                ._beanIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (grinderId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.grinderId,
                            referencedTable: $$BrewLogsTableReferences
                                ._grinderIdTable(db),
                            referencedColumn: $$BrewLogsTableReferences
                                ._grinderIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (recipeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.recipeId,
                            referencedTable: $$BrewLogsTableReferences
                                ._recipeIdTable(db),
                            referencedColumn: $$BrewLogsTableReferences
                                ._recipeIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (brewLogBeansRefs)
                        await $_getPrefetchedData<
                          BrewLogRow,
                          $BrewLogsTable,
                          BeanUsageRow
                        >(
                          currentTable: table,
                          referencedTable: $$BrewLogsTableReferences
                              ._brewLogBeansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BrewLogsTableReferences(
                                db,
                                table,
                                p0,
                              ).brewLogBeansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.brewLogId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (brewLogAddinsRefs)
                        await $_getPrefetchedData<
                          BrewLogRow,
                          $BrewLogsTable,
                          BrewLogAddInRow
                        >(
                          currentTable: table,
                          referencedTable: $$BrewLogsTableReferences
                              ._brewLogAddinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BrewLogsTableReferences(
                                db,
                                table,
                                p0,
                              ).brewLogAddinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.brewLogId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (brewLogFavoriteGroupsRefs)
                        await $_getPrefetchedData<
                          BrewLogRow,
                          $BrewLogsTable,
                          BrewLogFavoriteGroupRow
                        >(
                          currentTable: table,
                          referencedTable: $$BrewLogsTableReferences
                              ._brewLogFavoriteGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BrewLogsTableReferences(
                                db,
                                table,
                                p0,
                              ).brewLogFavoriteGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.brewLogId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BrewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrewLogsTable,
      BrewLogRow,
      $$BrewLogsTableFilterComposer,
      $$BrewLogsTableOrderingComposer,
      $$BrewLogsTableAnnotationComposer,
      $$BrewLogsTableCreateCompanionBuilder,
      $$BrewLogsTableUpdateCompanionBuilder,
      (BrewLogRow, $$BrewLogsTableReferences),
      BrewLogRow,
      PrefetchHooks Function({
        bool beanId,
        bool grinderId,
        bool recipeId,
        bool brewLogBeansRefs,
        bool brewLogAddinsRefs,
        bool brewLogFavoriteGroupsRefs,
      })
    >;
typedef $$BrewLogBeansTableCreateCompanionBuilder =
    BrewLogBeansCompanion Function({
      Value<int> id,
      required int brewLogId,
      Value<int?> beanId,
      Value<int?> batchId,
      Value<String?> beanNameSnapshot,
      Value<DateTime?> roastDateSnapshot,
      Value<double> doseGrams,
      Value<int> position,
    });
typedef $$BrewLogBeansTableUpdateCompanionBuilder =
    BrewLogBeansCompanion Function({
      Value<int> id,
      Value<int> brewLogId,
      Value<int?> beanId,
      Value<int?> batchId,
      Value<String?> beanNameSnapshot,
      Value<DateTime?> roastDateSnapshot,
      Value<double> doseGrams,
      Value<int> position,
    });

final class $$BrewLogBeansTableReferences
    extends BaseReferences<_$AppDatabase, $BrewLogBeansTable, BeanUsageRow> {
  $$BrewLogBeansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BrewLogsTable _brewLogIdTable(_$AppDatabase db) =>
      db.brewLogs.createAlias('brew_log_beans__brew_log_id__brew_logs__id');

  $$BrewLogsTableProcessedTableManager get brewLogId {
    final $_column = $_itemColumn<int>('brew_log_id')!;

    final manager = $$BrewLogsTableTableManager(
      $_db,
      $_db.brewLogs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_brewLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CoffeeBeansTable _beanIdTable(_$AppDatabase db) =>
      db.coffeeBeans.createAlias('brew_log_beans__bean_id__coffee_beans__id');

  $$CoffeeBeansTableProcessedTableManager? get beanId {
    final $_column = $_itemColumn<int>('bean_id');
    if ($_column == null) return null;
    final manager = $$CoffeeBeansTableTableManager(
      $_db,
      $_db.coffeeBeans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_beanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BeanBatchesTable _batchIdTable(_$AppDatabase db) =>
      db.beanBatches.createAlias('brew_log_beans__batch_id__bean_batches__id');

  $$BeanBatchesTableProcessedTableManager? get batchId {
    final $_column = $_itemColumn<int>('batch_id');
    if ($_column == null) return null;
    final manager = $$BeanBatchesTableTableManager(
      $_db,
      $_db.beanBatches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BrewLogBeansTableFilterComposer
    extends Composer<_$AppDatabase, $BrewLogBeansTable> {
  $$BrewLogBeansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beanNameSnapshot => $composableBuilder(
    column: $table.beanNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get roastDateSnapshot => $composableBuilder(
    column: $table.roastDateSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get doseGrams => $composableBuilder(
    column: $table.doseGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$BrewLogsTableFilterComposer get brewLogId {
    final $$BrewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.brewLogId,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableFilterComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoffeeBeansTableFilterComposer get beanId {
    final $$CoffeeBeansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.coffeeBeans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoffeeBeansTableFilterComposer(
            $db: $db,
            $table: $db.coffeeBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BeanBatchesTableFilterComposer get batchId {
    final $$BeanBatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.beanBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeanBatchesTableFilterComposer(
            $db: $db,
            $table: $db.beanBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrewLogBeansTableOrderingComposer
    extends Composer<_$AppDatabase, $BrewLogBeansTable> {
  $$BrewLogBeansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beanNameSnapshot => $composableBuilder(
    column: $table.beanNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get roastDateSnapshot => $composableBuilder(
    column: $table.roastDateSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get doseGrams => $composableBuilder(
    column: $table.doseGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$BrewLogsTableOrderingComposer get brewLogId {
    final $$BrewLogsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.brewLogId,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableOrderingComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoffeeBeansTableOrderingComposer get beanId {
    final $$CoffeeBeansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.coffeeBeans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoffeeBeansTableOrderingComposer(
            $db: $db,
            $table: $db.coffeeBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BeanBatchesTableOrderingComposer get batchId {
    final $$BeanBatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.beanBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeanBatchesTableOrderingComposer(
            $db: $db,
            $table: $db.beanBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrewLogBeansTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrewLogBeansTable> {
  $$BrewLogBeansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get beanNameSnapshot => $composableBuilder(
    column: $table.beanNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get roastDateSnapshot => $composableBuilder(
    column: $table.roastDateSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get doseGrams =>
      $composableBuilder(column: $table.doseGrams, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$BrewLogsTableAnnotationComposer get brewLogId {
    final $$BrewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.brewLogId,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoffeeBeansTableAnnotationComposer get beanId {
    final $$CoffeeBeansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.beanId,
      referencedTable: $db.coffeeBeans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoffeeBeansTableAnnotationComposer(
            $db: $db,
            $table: $db.coffeeBeans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BeanBatchesTableAnnotationComposer get batchId {
    final $$BeanBatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.beanBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeanBatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.beanBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrewLogBeansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrewLogBeansTable,
          BeanUsageRow,
          $$BrewLogBeansTableFilterComposer,
          $$BrewLogBeansTableOrderingComposer,
          $$BrewLogBeansTableAnnotationComposer,
          $$BrewLogBeansTableCreateCompanionBuilder,
          $$BrewLogBeansTableUpdateCompanionBuilder,
          (BeanUsageRow, $$BrewLogBeansTableReferences),
          BeanUsageRow,
          PrefetchHooks Function({bool brewLogId, bool beanId, bool batchId})
        > {
  $$BrewLogBeansTableTableManager(_$AppDatabase db, $BrewLogBeansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrewLogBeansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrewLogBeansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrewLogBeansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> brewLogId = const Value.absent(),
                Value<int?> beanId = const Value.absent(),
                Value<int?> batchId = const Value.absent(),
                Value<String?> beanNameSnapshot = const Value.absent(),
                Value<DateTime?> roastDateSnapshot = const Value.absent(),
                Value<double> doseGrams = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => BrewLogBeansCompanion(
                id: id,
                brewLogId: brewLogId,
                beanId: beanId,
                batchId: batchId,
                beanNameSnapshot: beanNameSnapshot,
                roastDateSnapshot: roastDateSnapshot,
                doseGrams: doseGrams,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int brewLogId,
                Value<int?> beanId = const Value.absent(),
                Value<int?> batchId = const Value.absent(),
                Value<String?> beanNameSnapshot = const Value.absent(),
                Value<DateTime?> roastDateSnapshot = const Value.absent(),
                Value<double> doseGrams = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => BrewLogBeansCompanion.insert(
                id: id,
                brewLogId: brewLogId,
                beanId: beanId,
                batchId: batchId,
                beanNameSnapshot: beanNameSnapshot,
                roastDateSnapshot: roastDateSnapshot,
                doseGrams: doseGrams,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BrewLogBeansTable, BeanUsageRow>(table),
                  $$BrewLogBeansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({brewLogId = false, beanId = false, batchId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (brewLogId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.brewLogId,
                            referencedTable: $$BrewLogBeansTableReferences
                                ._brewLogIdTable(db),
                            referencedColumn: $$BrewLogBeansTableReferences
                                ._brewLogIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (beanId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.beanId,
                            referencedTable: $$BrewLogBeansTableReferences
                                ._beanIdTable(db),
                            referencedColumn: $$BrewLogBeansTableReferences
                                ._beanIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (batchId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.batchId,
                            referencedTable: $$BrewLogBeansTableReferences
                                ._batchIdTable(db),
                            referencedColumn: $$BrewLogBeansTableReferences
                                ._batchIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$BrewLogBeansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrewLogBeansTable,
      BeanUsageRow,
      $$BrewLogBeansTableFilterComposer,
      $$BrewLogBeansTableOrderingComposer,
      $$BrewLogBeansTableAnnotationComposer,
      $$BrewLogBeansTableCreateCompanionBuilder,
      $$BrewLogBeansTableUpdateCompanionBuilder,
      (BeanUsageRow, $$BrewLogBeansTableReferences),
      BeanUsageRow,
      PrefetchHooks Function({bool brewLogId, bool beanId, bool batchId})
    >;
typedef $$BrewLogAddinsTableCreateCompanionBuilder =
    BrewLogAddinsCompanion Function({
      Value<int> id,
      required int brewLogId,
      required String name,
      Value<String?> brand,
      Value<double?> amount,
      Value<AddInUnit?> unit,
      Value<int> position,
    });
typedef $$BrewLogAddinsTableUpdateCompanionBuilder =
    BrewLogAddinsCompanion Function({
      Value<int> id,
      Value<int> brewLogId,
      Value<String> name,
      Value<String?> brand,
      Value<double?> amount,
      Value<AddInUnit?> unit,
      Value<int> position,
    });

final class $$BrewLogAddinsTableReferences
    extends
        BaseReferences<_$AppDatabase, $BrewLogAddinsTable, BrewLogAddInRow> {
  $$BrewLogAddinsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BrewLogsTable _brewLogIdTable(_$AppDatabase db) =>
      db.brewLogs.createAlias('brew_log_addins__brew_log_id__brew_logs__id');

  $$BrewLogsTableProcessedTableManager get brewLogId {
    final $_column = $_itemColumn<int>('brew_log_id')!;

    final manager = $$BrewLogsTableTableManager(
      $_db,
      $_db.brewLogs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_brewLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BrewLogAddinsTableFilterComposer
    extends Composer<_$AppDatabase, $BrewLogAddinsTable> {
  $$BrewLogAddinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AddInUnit?, AddInUnit, String> get unit =>
      $composableBuilder(
        column: $table.unit,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$BrewLogsTableFilterComposer get brewLogId {
    final $$BrewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.brewLogId,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableFilterComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrewLogAddinsTableOrderingComposer
    extends Composer<_$AppDatabase, $BrewLogAddinsTable> {
  $$BrewLogAddinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$BrewLogsTableOrderingComposer get brewLogId {
    final $$BrewLogsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.brewLogId,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableOrderingComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrewLogAddinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrewLogAddinsTable> {
  $$BrewLogAddinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AddInUnit?, String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$BrewLogsTableAnnotationComposer get brewLogId {
    final $$BrewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.brewLogId,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrewLogAddinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrewLogAddinsTable,
          BrewLogAddInRow,
          $$BrewLogAddinsTableFilterComposer,
          $$BrewLogAddinsTableOrderingComposer,
          $$BrewLogAddinsTableAnnotationComposer,
          $$BrewLogAddinsTableCreateCompanionBuilder,
          $$BrewLogAddinsTableUpdateCompanionBuilder,
          (BrewLogAddInRow, $$BrewLogAddinsTableReferences),
          BrewLogAddInRow,
          PrefetchHooks Function({bool brewLogId})
        > {
  $$BrewLogAddinsTableTableManager(_$AppDatabase db, $BrewLogAddinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrewLogAddinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrewLogAddinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrewLogAddinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> brewLogId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<AddInUnit?> unit = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => BrewLogAddinsCompanion(
                id: id,
                brewLogId: brewLogId,
                name: name,
                brand: brand,
                amount: amount,
                unit: unit,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int brewLogId,
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<AddInUnit?> unit = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => BrewLogAddinsCompanion.insert(
                id: id,
                brewLogId: brewLogId,
                name: name,
                brand: brand,
                amount: amount,
                unit: unit,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BrewLogAddinsTable, BrewLogAddInRow>(table),
                  $$BrewLogAddinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({brewLogId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (brewLogId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.brewLogId,
                        referencedTable: $$BrewLogAddinsTableReferences
                            ._brewLogIdTable(db),
                        referencedColumn: $$BrewLogAddinsTableReferences
                            ._brewLogIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BrewLogAddinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrewLogAddinsTable,
      BrewLogAddInRow,
      $$BrewLogAddinsTableFilterComposer,
      $$BrewLogAddinsTableOrderingComposer,
      $$BrewLogAddinsTableAnnotationComposer,
      $$BrewLogAddinsTableCreateCompanionBuilder,
      $$BrewLogAddinsTableUpdateCompanionBuilder,
      (BrewLogAddInRow, $$BrewLogAddinsTableReferences),
      BrewLogAddInRow,
      PrefetchHooks Function({bool brewLogId})
    >;
typedef $$FavoriteGroupsTableCreateCompanionBuilder =
    FavoriteGroupsCompanion Function({
      Value<int> id,
      required String name,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });
typedef $$FavoriteGroupsTableUpdateCompanionBuilder =
    FavoriteGroupsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$FavoriteGroupsTableReferences
    extends
        BaseReferences<_$AppDatabase, $FavoriteGroupsTable, FavoriteGroupRow> {
  $$FavoriteGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $BrewLogFavoriteGroupsTable,
    List<BrewLogFavoriteGroupRow>
  >
  _brewLogFavoriteGroupsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.brewLogFavoriteGroups,
        aliasName: 'favorite_groups__id__brew_log_favorite_groups__group_id',
      );

  $$BrewLogFavoriteGroupsTableProcessedTableManager
  get brewLogFavoriteGroupsRefs {
    final manager = $$BrewLogFavoriteGroupsTableTableManager(
      $_db,
      $_db.brewLogFavoriteGroups,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _brewLogFavoriteGroupsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FavoriteGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteGroupsTable> {
  $$FavoriteGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> brewLogFavoriteGroupsRefs(
    Expression<bool> Function($$BrewLogFavoriteGroupsTableFilterComposer f) f,
  ) {
    final $$BrewLogFavoriteGroupsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.brewLogFavoriteGroups,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BrewLogFavoriteGroupsTableFilterComposer(
                $db: $db,
                $table: $db.brewLogFavoriteGroups,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FavoriteGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteGroupsTable> {
  $$FavoriteGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteGroupsTable> {
  $$FavoriteGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> brewLogFavoriteGroupsRefs<T extends Object>(
    Expression<T> Function($$BrewLogFavoriteGroupsTableAnnotationComposer a) f,
  ) {
    final $$BrewLogFavoriteGroupsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.brewLogFavoriteGroups,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BrewLogFavoriteGroupsTableAnnotationComposer(
                $db: $db,
                $table: $db.brewLogFavoriteGroups,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FavoriteGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteGroupsTable,
          FavoriteGroupRow,
          $$FavoriteGroupsTableFilterComposer,
          $$FavoriteGroupsTableOrderingComposer,
          $$FavoriteGroupsTableAnnotationComposer,
          $$FavoriteGroupsTableCreateCompanionBuilder,
          $$FavoriteGroupsTableUpdateCompanionBuilder,
          (FavoriteGroupRow, $$FavoriteGroupsTableReferences),
          FavoriteGroupRow,
          PrefetchHooks Function({bool brewLogFavoriteGroupsRefs})
        > {
  $$FavoriteGroupsTableTableManager(
    _$AppDatabase db,
    $FavoriteGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoriteGroupsCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoriteGroupsCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoriteGroupsTable, FavoriteGroupRow>(table),
                  $$FavoriteGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({brewLogFavoriteGroupsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (brewLogFavoriteGroupsRefs) db.brewLogFavoriteGroups,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (brewLogFavoriteGroupsRefs)
                    await $_getPrefetchedData<
                      FavoriteGroupRow,
                      $FavoriteGroupsTable,
                      BrewLogFavoriteGroupRow
                    >(
                      currentTable: table,
                      referencedTable: $$FavoriteGroupsTableReferences
                          ._brewLogFavoriteGroupsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FavoriteGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).brewLogFavoriteGroupsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.groupId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FavoriteGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteGroupsTable,
      FavoriteGroupRow,
      $$FavoriteGroupsTableFilterComposer,
      $$FavoriteGroupsTableOrderingComposer,
      $$FavoriteGroupsTableAnnotationComposer,
      $$FavoriteGroupsTableCreateCompanionBuilder,
      $$FavoriteGroupsTableUpdateCompanionBuilder,
      (FavoriteGroupRow, $$FavoriteGroupsTableReferences),
      FavoriteGroupRow,
      PrefetchHooks Function({bool brewLogFavoriteGroupsRefs})
    >;
typedef $$BrewLogFavoriteGroupsTableCreateCompanionBuilder =
    BrewLogFavoriteGroupsCompanion Function({
      Value<int> id,
      required int brewLogId,
      required int groupId,
      Value<DateTime> createdAt,
    });
typedef $$BrewLogFavoriteGroupsTableUpdateCompanionBuilder =
    BrewLogFavoriteGroupsCompanion Function({
      Value<int> id,
      Value<int> brewLogId,
      Value<int> groupId,
      Value<DateTime> createdAt,
    });

final class $$BrewLogFavoriteGroupsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BrewLogFavoriteGroupsTable,
          BrewLogFavoriteGroupRow
        > {
  $$BrewLogFavoriteGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BrewLogsTable _brewLogIdTable(_$AppDatabase db) => db.brewLogs
      .createAlias('brew_log_favorite_groups__brew_log_id__brew_logs__id');

  $$BrewLogsTableProcessedTableManager get brewLogId {
    final $_column = $_itemColumn<int>('brew_log_id')!;

    final manager = $$BrewLogsTableTableManager(
      $_db,
      $_db.brewLogs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_brewLogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FavoriteGroupsTable _groupIdTable(_$AppDatabase db) => db
      .favoriteGroups
      .createAlias('brew_log_favorite_groups__group_id__favorite_groups__id');

  $$FavoriteGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$FavoriteGroupsTableTableManager(
      $_db,
      $_db.favoriteGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BrewLogFavoriteGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $BrewLogFavoriteGroupsTable> {
  $$BrewLogFavoriteGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BrewLogsTableFilterComposer get brewLogId {
    final $$BrewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.brewLogId,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableFilterComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FavoriteGroupsTableFilterComposer get groupId {
    final $$FavoriteGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.favoriteGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteGroupsTableFilterComposer(
            $db: $db,
            $table: $db.favoriteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrewLogFavoriteGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $BrewLogFavoriteGroupsTable> {
  $$BrewLogFavoriteGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BrewLogsTableOrderingComposer get brewLogId {
    final $$BrewLogsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.brewLogId,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableOrderingComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FavoriteGroupsTableOrderingComposer get groupId {
    final $$FavoriteGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.favoriteGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.favoriteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrewLogFavoriteGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrewLogFavoriteGroupsTable> {
  $$BrewLogFavoriteGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BrewLogsTableAnnotationComposer get brewLogId {
    final $$BrewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.brewLogId,
      referencedTable: $db.brewLogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BrewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.brewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FavoriteGroupsTableAnnotationComposer get groupId {
    final $$FavoriteGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.favoriteGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.favoriteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BrewLogFavoriteGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrewLogFavoriteGroupsTable,
          BrewLogFavoriteGroupRow,
          $$BrewLogFavoriteGroupsTableFilterComposer,
          $$BrewLogFavoriteGroupsTableOrderingComposer,
          $$BrewLogFavoriteGroupsTableAnnotationComposer,
          $$BrewLogFavoriteGroupsTableCreateCompanionBuilder,
          $$BrewLogFavoriteGroupsTableUpdateCompanionBuilder,
          (BrewLogFavoriteGroupRow, $$BrewLogFavoriteGroupsTableReferences),
          BrewLogFavoriteGroupRow,
          PrefetchHooks Function({bool brewLogId, bool groupId})
        > {
  $$BrewLogFavoriteGroupsTableTableManager(
    _$AppDatabase db,
    $BrewLogFavoriteGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrewLogFavoriteGroupsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BrewLogFavoriteGroupsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BrewLogFavoriteGroupsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> brewLogId = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BrewLogFavoriteGroupsCompanion(
                id: id,
                brewLogId: brewLogId,
                groupId: groupId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int brewLogId,
                required int groupId,
                Value<DateTime> createdAt = const Value.absent(),
              }) => BrewLogFavoriteGroupsCompanion.insert(
                id: id,
                brewLogId: brewLogId,
                groupId: groupId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $BrewLogFavoriteGroupsTable,
                    BrewLogFavoriteGroupRow
                  >(table),
                  $$BrewLogFavoriteGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({brewLogId = false, groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (brewLogId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.brewLogId,
                        referencedTable: $$BrewLogFavoriteGroupsTableReferences
                            ._brewLogIdTable(db),
                        referencedColumn: $$BrewLogFavoriteGroupsTableReferences
                            ._brewLogIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$BrewLogFavoriteGroupsTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$BrewLogFavoriteGroupsTableReferences
                            ._groupIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BrewLogFavoriteGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrewLogFavoriteGroupsTable,
      BrewLogFavoriteGroupRow,
      $$BrewLogFavoriteGroupsTableFilterComposer,
      $$BrewLogFavoriteGroupsTableOrderingComposer,
      $$BrewLogFavoriteGroupsTableAnnotationComposer,
      $$BrewLogFavoriteGroupsTableCreateCompanionBuilder,
      $$BrewLogFavoriteGroupsTableUpdateCompanionBuilder,
      (BrewLogFavoriteGroupRow, $$BrewLogFavoriteGroupsTableReferences),
      BrewLogFavoriteGroupRow,
      PrefetchHooks Function({bool brewLogId, bool groupId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;
typedef $$ExtraAttributesTableCreateCompanionBuilder =
    ExtraAttributesCompanion Function({
      required String ownerType,
      required int ownerId,
      required String key,
      Value<Object?> value,
      required String valueType,
      Value<String?> label,
      Value<bool> isBuiltin,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ExtraAttributesTableUpdateCompanionBuilder =
    ExtraAttributesCompanion Function({
      Value<String> ownerType,
      Value<int> ownerId,
      Value<String> key,
      Value<Object?> value,
      Value<String> valueType,
      Value<String?> label,
      Value<bool> isBuiltin,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ExtraAttributesTableFilterComposer
    extends Composer<_$AppDatabase, $ExtraAttributesTable> {
  $$ExtraAttributesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Object?, Object, String> get value =>
      $composableBuilder(
        column: $table.value,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExtraAttributesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExtraAttributesTable> {
  $$ExtraAttributesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExtraAttributesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExtraAttributesTable> {
  $$ExtraAttributesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerType =>
      $composableBuilder(column: $table.ownerType, builder: (column) => column);

  GeneratedColumn<int> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Object?, String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get valueType =>
      $composableBuilder(column: $table.valueType, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltin =>
      $composableBuilder(column: $table.isBuiltin, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ExtraAttributesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExtraAttributesTable,
          ExtraAttributeRow,
          $$ExtraAttributesTableFilterComposer,
          $$ExtraAttributesTableOrderingComposer,
          $$ExtraAttributesTableAnnotationComposer,
          $$ExtraAttributesTableCreateCompanionBuilder,
          $$ExtraAttributesTableUpdateCompanionBuilder,
          (
            ExtraAttributeRow,
            BaseReferences<
              _$AppDatabase,
              $ExtraAttributesTable,
              ExtraAttributeRow
            >,
          ),
          ExtraAttributeRow,
          PrefetchHooks Function()
        > {
  $$ExtraAttributesTableTableManager(
    _$AppDatabase db,
    $ExtraAttributesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtraAttributesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtraAttributesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExtraAttributesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerType = const Value.absent(),
                Value<int> ownerId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<Object?> value = const Value.absent(),
                Value<String> valueType = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExtraAttributesCompanion(
                ownerType: ownerType,
                ownerId: ownerId,
                key: key,
                value: value,
                valueType: valueType,
                label: label,
                isBuiltin: isBuiltin,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerType,
                required int ownerId,
                required String key,
                Value<Object?> value = const Value.absent(),
                required String valueType,
                Value<String?> label = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExtraAttributesCompanion.insert(
                ownerType: ownerType,
                ownerId: ownerId,
                key: key,
                value: value,
                valueType: valueType,
                label: label,
                isBuiltin: isBuiltin,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExtraAttributesTable, ExtraAttributeRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExtraAttributesTable,
                    ExtraAttributeRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExtraAttributesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExtraAttributesTable,
      ExtraAttributeRow,
      $$ExtraAttributesTableFilterComposer,
      $$ExtraAttributesTableOrderingComposer,
      $$ExtraAttributesTableAnnotationComposer,
      $$ExtraAttributesTableCreateCompanionBuilder,
      $$ExtraAttributesTableUpdateCompanionBuilder,
      (
        ExtraAttributeRow,
        BaseReferences<_$AppDatabase, $ExtraAttributesTable, ExtraAttributeRow>,
      ),
      ExtraAttributeRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CoffeeBeansTableTableManager get coffeeBeans =>
      $$CoffeeBeansTableTableManager(_db, _db.coffeeBeans);
  $$BeanBatchesTableTableManager get beanBatches =>
      $$BeanBatchesTableTableManager(_db, _db.beanBatches);
  $$GrindersTableTableManager get grinders =>
      $$GrindersTableTableManager(_db, _db.grinders);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$BrewLogsTableTableManager get brewLogs =>
      $$BrewLogsTableTableManager(_db, _db.brewLogs);
  $$BrewLogBeansTableTableManager get brewLogBeans =>
      $$BrewLogBeansTableTableManager(_db, _db.brewLogBeans);
  $$BrewLogAddinsTableTableManager get brewLogAddins =>
      $$BrewLogAddinsTableTableManager(_db, _db.brewLogAddins);
  $$FavoriteGroupsTableTableManager get favoriteGroups =>
      $$FavoriteGroupsTableTableManager(_db, _db.favoriteGroups);
  $$BrewLogFavoriteGroupsTableTableManager get brewLogFavoriteGroups =>
      $$BrewLogFavoriteGroupsTableTableManager(_db, _db.brewLogFavoriteGroups);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$ExtraAttributesTableTableManager get extraAttributes =>
      $$ExtraAttributesTableTableManager(_db, _db.extraAttributes);
}
