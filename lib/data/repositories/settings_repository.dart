/// 设置项仓储。
///
/// 底层是一张 key-value 表（`AppSettings`），本类提供类型化的读写便利方法。
/// 支持的 key 与默认值见 `lib/domain/settings_keys.dart`（对应手册 §6.3）。
library;

import 'dart:convert';

import 'package:beanclick/data/database.dart';
import 'package:beanclick/domain/settings_keys.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show ThemeMode;

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// 监听某个 key 的变化。
  Stream<String?> watch(String key) {
    final settings = _db.appSettings;
    final query = _db.select(settings)..where((t) => t.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  /// 读取某个 key，未设置时返回该 key 的默认值。
  Future<String?> get(String key) async {
    final settings = _db.appSettings;
    final row = await (_db.select(
      settings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value ?? SettingsDefaults.byKey[key];
  }

  /// 写入某个 key（不存在则插入）。
  Future<void> set(String key, String value) async {
    final settings = _db.appSettings;
    await _db
        .into(settings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> remove(String key) async {
    final settings = _db.appSettings;
    await (_db.delete(settings)..where((t) => t.key.equals(key))).go();
  }

  // --- 类型化便利方法 ---

  Future<bool> getBool(String key, {required bool fallback}) async {
    final value = await get(key);
    if (value == null) return fallback;
    return value.toLowerCase() == 'true';
  }

  Future<void> setBool(String key, bool value) => set(key, value.toString());

  /// 主题模式，默认 `ThemeMode.system`（手册 §17 决策 7）。
  Future<ThemeMode> getThemeMode() async {
    final value = await get(SettingsKeys.themeMode);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      set(SettingsKeys.themeMode, mode.name);

  /// 监听主题模式，供根 MaterialApp 实时响应设置变化。
  Stream<ThemeMode> watchThemeMode() => watch(SettingsKeys.themeMode).map(
    (value) => switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    },
  );

  /// 冲煮后是否自动扣减余量，默认 true（手册 §6.2）。
  Future<bool> getAutoDeductStock() =>
      getBool(SettingsKeys.autoDeductStock, fallback: true);

  Future<void> setAutoDeductStock(bool value) =>
      setBool(SettingsKeys.autoDeductStock, value);

  Stream<bool> watchAutoDeductStock() =>
      watch(SettingsKeys.autoDeductStock)
          .map((value) => value == null || value.toLowerCase() == 'true');

  /// 默认冲煮方法。
  Future<String> getDefaultMethod() async =>
      await get(SettingsKeys.defaultMethod) ?? 'pourOver';

  /// 自定义冲煮方法库（有序）。
  ///
  /// 存成 JSON 字符串数组；内容坏掉（手工改过库）时当作空列表，
  /// 不让设置页把整个 App 拖崩。
  Future<List<String>> getCustomBrewMethods() async {
    final String? raw = await get(SettingsKeys.customBrewMethods);
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return decoded
          .map((Object? e) => e.toString().trim())
          .where((String value) => value.isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      return const <String>[];
    }
  }

  Future<void> setCustomBrewMethods(List<String> methods) =>
      set(SettingsKeys.customBrewMethods, jsonEncode(methods));

  /// 监听自定义方法库（表单的方法 chip 行跟着变）。
  Stream<List<String>> watchCustomBrewMethods() =>
      watch(SettingsKeys.customBrewMethods).map(_decodeMethods);

  static List<String> _decodeMethods(String? raw) {
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return decoded
          .map((Object? e) => e.toString().trim())
          .where((String value) => value.isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      return const <String>[];
    }
  }
}
